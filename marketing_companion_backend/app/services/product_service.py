import httpx

from app.core.config import get_settings
from app.dependencies.auth import AuthenticatedContext
from app.schemas.catalog import CatalogDraft


class ProductServiceError(Exception):
    """Raised when a Supabase product operation fails."""


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

# By default, Supabase doesn't return the inserted rows in the HTTP response. By adding this header, we fixed it. It tells PostgREST to return the inserted row as a representation in the response.
    if method.upper()== "POST":
        headers["Prefer"]= "return=representation"

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
            # Log the response safely during production debugging.
            # Do not return provider details or tokens to the client.
            raise ProductServiceError(
                f"Supabase operation failed with status "
                f"{response.status_code}."
            )

        if not response.content:
            return []

        return response.json()

    except httpx.RequestError as exc:
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