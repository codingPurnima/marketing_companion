
import httpx

from app.core.config import get_settings
from app.dependencies.auth import AuthenticatedContext
from app.schemas.profile import ArtisanProfileUpdate


class ProfileServiceError(Exception):
    """Raised when an artisan profile operation fails."""


async def _supabase_request(
    context: AuthenticatedContext,
    method: str,
    path: str,
    params: dict | None = None,
    payload: dict | None = None,
):
    settings = get_settings()

    headers = {
        "apikey": settings.supabase_publishable_key,
        "Authorization": f"Bearer {context.access_token}",
        "Content-Type": "application/json",
    }

    if method in ("POST", "PATCH"):
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

    except httpx.RequestError as exc:
        raise ProfileServiceError(
            "Unable to connect to Supabase."
        ) from exc

    if not response.is_success:
        raise ProfileServiceError(
            f"Supabase request failed: "
            f"{response.status_code} - {response.text}"
        )

    if not response.content:
        return None

    return response.json()


async def get_artisan_profile(
    context: AuthenticatedContext,
) -> dict | None:
    result = await _supabase_request(
        context,
        "GET",
        "artisan_profiles",
        params={
            "select": (
                "user_id,public_name,bio,craft,"
                "district,state,whatsapp_number"
            ),
            "user_id": f"eq.{context.user.id}",
            "limit": "1",
        },
    )

    if not isinstance(result, list):
        raise ProfileServiceError(
            "Unexpected profile response."
        )

    return result[0] if result else None


async def save_artisan_profile(
    context: AuthenticatedContext,
    profile: ArtisanProfileUpdate,
) -> dict:
    existing = await get_artisan_profile(context)

    payload = profile.model_dump()

    if existing:
        result = await _supabase_request(
            context,
            "PATCH",
            "artisan_profiles",
            params={
                "user_id": f"eq.{context.user.id}",
                "select": (
                    "user_id,public_name,bio,craft,"
                    "district,state,whatsapp_number"
                ),
            },
            payload=payload,
        )
    else:
        payload["user_id"] = str(context.user.id)

        result = await _supabase_request(
            context,
            "POST",
            "artisan_profiles",
            params={
                "select": (
                    "user_id,public_name,bio,craft,"
                    "district,state,whatsapp_number"
                ),
            },
            payload=payload,
        )

    if not isinstance(result, list) or not result:
        raise ProfileServiceError(
            "Unable to save the artisan profile."
        )

    return result[0]
