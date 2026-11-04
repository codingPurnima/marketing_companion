
import httpx

from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.config import get_settings
from app.dependencies.auth import AuthenticatedContext, get_current_user
from app.services.image_enhancement import get_image_enhancement_provider

router = APIRouter(prefix="/images", tags=["images"])


class EnhancementRequest(BaseModel):
    original_storage_path: str = Field(min_length=1, max_length=1024)


class ImageSelectionRequest(BaseModel):
    selection: Literal["original", "enhanced"]


def get_supabase_headers(context: AuthenticatedContext) -> dict:
    settings = get_settings()
    return {
        "apikey": settings.supabase_publishable_key,
        "Authorization": f"Bearer {context.access_token}",
    }


def update_image_record(
    base_url: str,
    headers: dict,
    image_id: str,
    payload: dict,
) -> None:
    response = httpx.patch(
        f"{base_url}/rest/v1/product_images",
        headers={**headers, "Prefer": "return=representation"},
        params={"id": f"eq.{image_id}"},
        json=payload,
        timeout=15,
    )
    response.raise_for_status()

    if not response.json():
        raise HTTPException(
            status_code=500,
            detail="Could not update the image record.",
        )


def get_owned_image(
    image_id: str,
    context: AuthenticatedContext,
) -> tuple[dict, str, dict]:
    settings = get_settings()
    base_url = settings.supabase_url.rstrip("/")
    headers = get_supabase_headers(context)

    try:
        image_response = httpx.get(
            f"{base_url}/rest/v1/product_images",
            headers=headers,
            params={
                "id": f"eq.{image_id}",
                "select": (
                    "id,product_id,storage_path,enhancement_status,"
                    "enhanced_storage_path,is_enhanced_selected"
                ),
                "limit": "1",
            },
            timeout=15,
        )
        image_response.raise_for_status()

        images = image_response.json()

        if not images:
            raise HTTPException(status_code=404, detail="Image not found.")

        image = images[0]

        product_response = httpx.get(
            f"{base_url}/rest/v1/products",
            headers=headers,
            params={
                "id": f"eq.{image['product_id']}",
                "owner_id": f"eq.{context.user.id}",
                "select": "id",
                "limit": "1",
            },
            timeout=15,
        )
        product_response.raise_for_status()

        if not product_response.json():
            raise HTTPException(
                status_code=403,
                detail="You cannot access another user's image.",
            )

        return image, base_url, headers

    except HTTPException:
        raise
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=503,
            detail="Could not verify image ownership with Supabase.",
        ) from exc


def create_signed_url(
    base_url: str,
    headers: dict,
    storage_path: str,
) -> str:
    from urllib.parse import quote

    encoded_path = quote(storage_path, safe="/")

    response = httpx.post(
        f"{base_url}/storage/v1/object/sign/"
        f"product-images/{encoded_path}",
        headers=headers,
        json={"expiresIn": 3600},
        timeout=20,
    )
    response.raise_for_status()

    data = response.json()
    signed_url = data.get("signedURL") or data.get("signedUrl")

    if not signed_url:
        raise RuntimeError("Supabase did not return a signed URL.")

    if signed_url.startswith("/"):
        signed_url = f"{base_url}/storage/v1{signed_url}"

    return signed_url


@router.post("/enhance")
def enhance_image(
    request: EnhancementRequest,
    context: AuthenticatedContext = Depends(get_current_user),
):
    settings = get_settings()
    headers = get_supabase_headers(context)
    base_url = settings.supabase_url.rstrip("/")

    try:
        image_response = httpx.get(
            f"{base_url}/rest/v1/product_images",
            headers=headers,
            params={
                "storage_path": f"eq.{request.original_storage_path}",
                "select": (
                    "id,product_id,storage_path,enhancement_status,"
                    "enhanced_storage_path,is_enhanced_selected"
                ),
                "limit": "1",
            },
            timeout=15,
        )
        image_response.raise_for_status()
        images = image_response.json()

        if not images:
            raise HTTPException(status_code=404, detail="Image not found.")

        image = images[0]

        product_response = httpx.get(
            f"{base_url}/rest/v1/products",
            headers=headers,
            params={
                "id": f"eq.{image['product_id']}",
                "owner_id": f"eq.{context.user.id}",
                "select": "id",
                "limit": "1",
            },
            timeout=15,
        )
        product_response.raise_for_status()

        if not product_response.json():
            raise HTTPException(
                status_code=403,
                detail="You cannot enhance another user's image.",
            )

    except HTTPException:
        raise
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=503,
            detail="Could not verify image ownership with Supabase.",
        ) from exc

    try:
        update_image_record(
            base_url,
            headers,
            image["id"],
            {"enhancement_status": "processing"},
        )
    except (httpx.HTTPError, HTTPException) as exc:
        raise HTTPException(
            status_code=503,
            detail="Could not update the image enhancement status.",
        ) from exc

    try:
        provider = get_image_enhancement_provider(context.access_token)
        result = provider.enhance(image["storage_path"])

        if result.status == "mock":
            update_image_record(
                base_url,
                headers,
                image["id"],
                {"enhancement_status": "not_requested"},
            )

        elif result.status == "completed" and result.enhanced_storage_path:
            update_image_record(
                base_url,
                headers,
                image["id"],
                {
                    "enhancement_status": "completed",
                    "enhanced_storage_path": result.enhanced_storage_path,
                    "is_enhanced_selected": False,
                },
            )

        else:
            raise ValueError("The provider returned an invalid result.")

    except Exception as exc:
        try:
            update_image_record(
                base_url,
                headers,
                image["id"],
                {"enhancement_status": "failed"},
            )
        except Exception:
            pass

        if isinstance(exc, HTTPException):
            raise exc

        raise HTTPException(
            status_code=502,
            detail="Image enhancement failed. Your original image is safe.",
        ) from exc

    return {
        "status": result.status,
        "enhanced_storage_path": result.enhanced_storage_path,
        "message": result.message,
    }


@router.get("/{image_id}/comparison")
def get_image_comparison(
    image_id: str,
    context: AuthenticatedContext = Depends(get_current_user),
):
    image, base_url, headers = get_owned_image(image_id, context)

    try:
        original_url = create_signed_url(
            base_url,
            headers,
            image["storage_path"],
        )

        enhanced_url = None

        if (
            image["enhancement_status"] == "completed"
            and image["enhanced_storage_path"]
        ):
            enhanced_url = create_signed_url(
                base_url,
                headers,
                image["enhanced_storage_path"],
            )

    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=503,
            detail="Could not retrieve image previews.",
        ) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return {
        "image_id": image["id"],
        "original_url": original_url,
        "enhanced_url": enhanced_url,
        "enhancement_status": image["enhancement_status"],
        "selected_image": (
            "enhanced" if image["is_enhanced_selected"] else "original"
        ),
    }


@router.patch("/{image_id}/selection")
def select_product_image(
    image_id: str,
    request: ImageSelectionRequest,
    context: AuthenticatedContext = Depends(get_current_user),
):
    image, base_url, headers = get_owned_image(image_id, context)

    if request.selection == "enhanced":
        if (
            image["enhancement_status"] != "completed"
            or not image["enhanced_storage_path"]
        ):
            raise HTTPException(
                status_code=400,
                detail="No completed enhanced image is available.",
            )

    try:
        update_image_record(
            base_url,
            headers,
            image_id,
            {"is_enhanced_selected": request.selection == "enhanced"},
        )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=503,
            detail="Could not save your image selection.",
        ) from exc

    return {
        "image_id": image_id,
        "selected_image": request.selection,
        "message": (
            "Enhanced image selected."
            if request.selection == "enhanced"
            else "Original image selected."
        ),
    }
