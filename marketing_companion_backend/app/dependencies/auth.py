
from typing import Annotated
from uuid import UUID

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ValidationError

from app.core.config import get_settings
from app.schemas.user import AuthenticatedContext, AuthenticatedUser

bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None,
        Depends(bearer_scheme),
    ],
) -> AuthenticatedContext:
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    settings = get_settings()

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                f"{settings.supabase_url.rstrip('/')}/auth/v1/user",
                headers={
                    "apikey": settings.supabase_publishable_key,
                    "Authorization": (
                        f"Bearer {credentials.credentials}"
                    ),
                },
            )
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service temporarily unavailable",
        ) from exc

    if response.status_code in (401, 403):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired access token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if response.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Unable to validate access token",
        )

    try:
        user_data = response.json()
        return AuthenticatedContext(
            user=AuthenticatedUser(
                id=user_data["id"],
                email=user_data.get("email"),
            ),
            access_token=credentials.credentials,
        )
    except (ValueError, KeyError, ValidationError) as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Unexpected authentication service response",
        ) from exc
