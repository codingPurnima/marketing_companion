
import uuid

from dataclasses import dataclass
from pathlib import PurePosixPath
from typing import Protocol
from urllib.parse import quote

import httpx

import cloudinary
import cloudinary.uploader

from app.core.config import get_settings
import time


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
            message="Mock provider is active. No image was modified.",
        )


class CloudinaryImageEnhancementProvider:
    def __init__(self, access_token: str):
        settings = get_settings()

        if not all([
            settings.cloudinary_cloud_name,
            settings.cloudinary_api_key,
            settings.cloudinary_api_secret,
        ]):
            raise ValueError("Cloudinary credentials are not configured.")

        self.access_token = access_token
        self.supabase_url = settings.supabase_url.rstrip("/")
        self.supabase_key = settings.supabase_publishable_key

        cloudinary.config(
            cloud_name=settings.cloudinary_cloud_name,
            api_key=settings.cloudinary_api_key,
            api_secret=settings.cloudinary_api_secret,
            secure=True,
        )

        self.supabase_headers = {
            "apikey": self.supabase_key,
            "Authorization": f"Bearer {self.access_token}",
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

    def _upload_to_cloudinary(self, signed_url: str) -> dict:
        result = cloudinary.uploader.upload(
            signed_url,
            resource_type="image",
            folder="artisan-enhancement-temp",
            unique_filename=True,
            overwrite=False,
            eager=[
                {"effect": "auto_enhance"}
            ],
            eager_async=False,
        )

        if not result.get("public_id"):
            raise RuntimeError("Cloudinary did not return an asset ID.")

        eager_results = result.get("eager", [])

        if not eager_results or not eager_results[0].get("secure_url"):
            raise RuntimeError(
                "Cloudinary did not return an enhanced image."
            )

        return {
            "public_id": result["public_id"],
            "enhanced_url": eager_results[0]["secure_url"],
        }

    def _download_and_upload(
        self,
        enhanced_url: str,
        original_storage_path: str,
    ) -> str:
        download_response = None
        delay = 2
        deadline = time.monotonic() + 90

        while time.monotonic() < deadline:
            response = httpx.get(
                enhanced_url,
                follow_redirects=True,
                timeout=60,
            )

            if response.status_code == 200:
                download_response = response
                break

            if response.status_code != 423:
                error_detail = response.headers.get(
                    "X-Cld-Error",
                    response.text[:500],
                )
                raise RuntimeError(
                    f"Cloudinary delivery failed "
                    f"({response.status_code}): {error_detail}"
            )

            time.sleep(delay)
            delay = min(delay + 2, 10)

        if download_response is None:
            raise TimeoutError(
                "Cloudinary enhancement is still processing after 90 seconds."
            )

        content_type = download_response.headers.get(
            "content-type", ""
        ).split(";")[0].lower()

        extension_by_type = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/webp": ".webp",
            "image/avif": ".avif",
        }

        extension = extension_by_type.get(content_type)

        if not extension:
            raise RuntimeError(
                f"Cloudinary returned an unsupported image type: "
                f"{content_type}"
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

        cloudinary_public_id = None

        try:
            signed_url = self._create_signed_url(original_storage_path)

            cloudinary_result = self._upload_to_cloudinary(signed_url)

            cloudinary_public_id = cloudinary_result["public_id"]

            enhanced_path = self._download_and_upload(
                cloudinary_result["enhanced_url"],
                original_storage_path,
            )

            return EnhancementResult(
                status="completed",
                enhanced_storage_path=enhanced_path,
                message="Image enhanced successfully using Cloudinary AI.",
            )

        finally:
            # Cloudinary is used temporarily.
            # Supabase remains the permanent image storage.
            if cloudinary_public_id:
                try:
                    cloudinary.uploader.destroy(
                        cloudinary_public_id,
                        resource_type="image",
                        invalidate=True,
                    )
                except Exception:
                    pass


def get_image_enhancement_provider(
    access_token: str,
) -> ImageEnhancementProvider:
    settings = get_settings()

    if settings.image_enhancement_provider == "mock":
        return MockImageEnhancementProvider()

    if settings.image_enhancement_provider == "cloudinary":
        return CloudinaryImageEnhancementProvider(access_token)

    raise ValueError("Unsupported image enhancement provider.")
