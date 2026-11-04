import httpx

from app.core.config import get_settings
from app.dependencies.auth import AuthenticatedContext
from app.schemas.catalog import CatalogDraft
from datetime import datetime, timezone

class ProductServiceError(Exception):
    """Raised when a Supabase product operation fails."""

class ProductNotFoundError(ProductServiceError):
    pass


class ProductStatusError(ProductServiceError):
    pass

async def _supabase_request(
    context: AuthenticatedContext,
    method: str,
    path: str,
    *,
    params: dict | None = None,
    payload: dict | None = None,
) -> list | dict:
    settings = get_settings()

    headers = {
        "apikey": settings.supabase_publishable_key,
        "Authorization": f"Bearer {context.access_token}",
        "Content-Type": "application/json",
    }

    if method.upper() in ("POST", "PATCH"):
        headers["Prefer"] = "return=representation"
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.request(
                method,
                f"{settings.supabase_url.rstrip('/')}/rest/v1/{path}",
                headers=headers,
                params=params,
                json=payload,
            )

        if not response.is_success:
            print("Supabase status:", response.status_code)
            print("Supabase error:", response.text)

            raise ProductServiceError(
                f"Supabase operation failed with status "
                f"{response.status_code}."
            )

        if not response.content:
            return []

        return response.json()

    except httpx.RequestError as exc:
        print("Supabase connection error:", str(exc))
        raise ProductServiceError(
            "Supabase is temporarily unavailable."
        ) from exc

async def save_product_draft(
    context: AuthenticatedContext,
    draft: CatalogDraft,
) -> dict:
    payload = {
        "owner_id": str(context.user.id),
        "title": draft.title,
        "description": draft.description,
        "category": draft.category,
        "price": draft.price_inr,
        "currency": "INR",
        "status": "draft",
    }
    print(payload)
    result = await _supabase_request(
        context,
        "POST",
        "products",
        params={"select": "id,title,description,category,price,currency,status,updated_at"},
        payload=payload,
    )
    print(str(result))

    if not isinstance(result, list) or not result:
        raise ProductServiceError(
            "Supabase did not return the created product."
        )

    return result[0]


async def list_product_drafts(
    context: AuthenticatedContext,
) -> list:
    result = await _supabase_request(
        context,
        "GET",
        "products",
        params={
            "select": "id,title,description,category,price,currency,status,updated_at",
            "owner_id": f"eq.{context.user.id}",
            "status": "eq.draft",
            "order": "updated_at.desc",
        },
    )

    if not isinstance(result, list):
        raise ProductServiceError(
            "Unexpected response while retrieving product drafts."
        )

    return result

async def update_product_publication(
    context: AuthenticatedContext,
    product_id: str,
    publish: bool,
) -> dict:
    # Verify ownership and retrieve the current status.
    result = await _supabase_request(
        context,
        "GET",
        "products",
        params={
            "select": "id,status",
            "id": f"eq.{product_id}",
            "owner_id": f"eq.{context.user.id}",
        },
    )

    if not isinstance(result, list) or not result:
        raise ProductNotFoundError("Product not found.")

    product = result[0]
    current_status = product["status"]

    target_status = "published" if publish else "draft"

    # Make repeated requests safe.
    if current_status == target_status:
        return product

    expected_status = "draft" if publish else "published"

    if current_status != expected_status:
        raise ProductStatusError(
            f"Cannot change publication status from {current_status}."
        )

    payload = {
        "status": target_status,
        "published_at": (
            datetime.now(timezone.utc).isoformat()
            if publish
            else None
        ),
    }

    updated = await _supabase_request(
        context,
        "PATCH",
        "products",
        params={
            "id": f"eq.{product_id}",
            "owner_id": f"eq.{context.user.id}",
            "select": "id,title,description,category,price,currency,status,published_at",
        },
        payload=payload,
    )

    if not isinstance(updated, list) or not updated:
        raise ProductServiceError(
            "Unable to update product publication status."
        )

    return updated[0]