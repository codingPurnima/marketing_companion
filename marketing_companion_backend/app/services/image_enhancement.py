import json
import mimetypes
import time
import uuid

from dataclasses import dataclass
from pathlib import PurePosixPath
from typing import Protocol
from urllib.parse import quote

import httpx

from app.core.config import get_settings


PRODUCT_IMAGE_ENHANCEMENT_PROMPT = """
Improve this photograph for an artisan product catalogue.

Preserve the exact physical product shown in the reference image.
Do not redesign, replace, invent, remove, or add product details.
Preserve its original shape, proportions, colours, patterns,
texture, materials, craftsmanship, and handmade imperfections.

Improve lighting, exposure, sharpness, and photographic clarity.
Use a clean, subtle, professional product-photography background.
Keep the product as the central subject.

The result must accurately represent the actual item being sold.
Do not add text, logos, watermarks, decorations, or extra objects.
"""


@dataclass
class EnhancementResult:
    status: str
    enhanced_storage_path: str | None
    message: str


class ImageEnhancementProvider(Protocol):
    def enhance(self, original_storage_path: str) -> EnhancementResult:
        ...


class MockImageEnhancementProvider:
    def enhance(self, original_storage_path: str) -> EnhancementResult:
        if not original_storage_path.strip():
            raise ValueError("An original image path is required.")

        return EnhancementResult(
            status="mock",
            enhanced_storage_path=None,
            message=(
                "Mock provider is active. No image was modified "
                "or generated. Connect a real provider to enhance it."
            ),
        )


class KieImageEnhancementProvider:
    def __init__(self, access_token: str):
        settings = get_settings()

        if not settings.kie_api_key:
            raise ValueError("KIE_API_KEY is not configured.")

        self.access_token = access_token
        self.supabase_url = settings.supabase_url.rstrip("/")
        self.supabase_key = settings.supabase_publishable_key
        self.kie_api_key = settings.kie_api_key
        self.kie_base_url = settings.kie_api_base_url.rstrip("/")
        self.timeout_seconds = settings.kie_task_timeout_seconds

        self.supabase_headers = {
            "apikey": self.supabase_key,
            "Authorization": f"Bearer {self.access_token}",
        }

        self.kie_headers = {
            "Authorization": f"Bearer {self.kie_api_key}",
            "Content-Type": "application/json",
        }

    def _create_signed_url(self, storage_path: str) -> str:
        encoded_path = quote(storage_path, safe="/")

        response = httpx.post(
            f"{self.supabase_url}/storage/v1/object/sign/"
            f"product-images/{encoded_path}",
            headers=self.supabase_headers,
            json={"expiresIn": 600},
            timeout=20,
        )
        response.raise_for_status()

        data = response.json()
        signed_url = data.get("signedURL") or data.get("signedUrl")

        if not signed_url:
            raise RuntimeError("Supabase did not return a signed image URL.")

        if signed_url.startswith("/"):
            signed_url = f"{self.supabase_url}/storage/v1{signed_url}"

        return signed_url

    def _create_kie_task(self, image_url: str) -> str:
        response = httpx.post(
            f"{self.kie_base_url}/api/v1/jobs/createTask",
            headers=self.kie_headers,
            json={
                "model": "gpt-image-2-image-to-image",
                "input": {
                    "prompt": PRODUCT_IMAGE_ENHANCEMENT_PROMPT,
                    "input_urls": [image_url],
                    "aspect_ratio": "auto",
                },
            },
            timeout=30,
        )
        response.raise_for_status()

        data = response.json()

        if data.get("code") != 200:
            raise RuntimeError(
                data.get("msg", "KIE rejected the enhancement request.")
            )

        task_id = data.get("data", {}).get("taskId")

        if not task_id:
            raise RuntimeError("KIE did not return a task ID.")

        return task_id

    def _wait_for_result(self, task_id: str) -> str:
        deadline = time.monotonic() + self.timeout_seconds
        delay = 3

        while time.monotonic() < deadline:
            response = httpx.get(
                f"{self.kie_base_url}/api/v1/jobs/recordInfo",
                headers=self.kie_headers,
                params={"taskId": task_id},
                timeout=20,
            )
            response.raise_for_status()

            data = response.json()

            if data.get("code") != 200:
                raise RuntimeError(
                    data.get("msg", "Could not retrieve KIE task status.")
                )

            task = data.get("data", {})
            state = task.get("state")

            if state == "success":
                result_json = task.get("resultJson")

                if isinstance(result_json, str):
                    result_json = json.loads(result_json)

                result_urls = result_json.get("resultUrls", [])

                if not result_urls:
                    raise RuntimeError("KIE completed without an output image.")

                return result_urls[0]

            if state == "fail":
                raise RuntimeError(
                    task.get("failMsg") or "KIE image generation failed."
                )

            if state not in {"waiting", "queuing", "generating"}:
                raise RuntimeError(
                    f"KIE returned an unexpected task state: {state}"
                )

            time.sleep(delay)
            delay = min(delay + 2, 10)

        raise TimeoutError("KIE image generation timed out.")

    def _download_and_upload(
        self,
        result_url: str,
        original_storage_path: str,
    ) -> str:
        download_response = httpx.get(
            result_url,
            follow_redirects=True,
            timeout=60,
        )
        download_response.raise_for_status()

        content_type = download_response.headers.get(
            "content-type", ""
        ).split(";")[0].lower()

        extension_by_type = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/webp": ".webp",
        }

        extension = extension_by_type.get(content_type)

        if not extension:
            raise RuntimeError(
                f"KIE returned an unsupported image type: {content_type}"
            )

        original_path = PurePosixPath(original_storage_path)

        enhanced_path = str(
            original_path.parent
            / f"enhanced-{uuid.uuid4().hex}{extension}"
        )

        encoded_path = quote(enhanced_path, safe="/")

        upload_response = httpx.post(
            f"{self.supabase_url}/storage/v1/object/"
            f"product-images/{encoded_path}",
            headers={
                **self.supabase_headers,
                "Content-Type": content_type,
                "x-upsert": "false",
            },
            content=download_response.content,
            timeout=60,
        )
        upload_response.raise_for_status()

        return enhanced_path

    def enhance(self, original_storage_path: str) -> EnhancementResult:
        if not original_storage_path.strip():
            raise ValueError("An original image path is required.")

        signed_url = self._create_signed_url(original_storage_path)
        task_id = self._create_kie_task(signed_url)
        result_url = self._wait_for_result(task_id)

        enhanced_path = self._download_and_upload(
            result_url,
            original_storage_path,
        )

        return EnhancementResult(
            status="completed",
            enhanced_storage_path=enhanced_path,
            message="Image enhancement completed successfully.",
        )


def get_image_enhancement_provider(
    access_token: str,
) -> ImageEnhancementProvider:
    settings = get_settings()

    if settings.image_enhancement_provider == "kie":
        return KieImageEnhancementProvider(access_token)

    return MockImageEnhancementProvider()