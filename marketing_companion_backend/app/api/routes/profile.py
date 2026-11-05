from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException

from app.dependencies.auth import get_current_user
from app.schemas.profile import ArtisanProfileUpdate
from app.schemas.user import AuthenticatedContext
from app.services.profile_service import (
    ProfileServiceError,
    get_artisan_profile,
    save_artisan_profile,
)


router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("/me")
async def read_my_profile(
    context: Annotated[
        AuthenticatedContext,
        Depends(get_current_user),
    ],
):
    try:
        return await get_artisan_profile(context)

    except ProfileServiceError as exc:
        raise HTTPException(
            status_code=502,
            detail="Unable to retrieve the artisan profile.",
        ) from exc


@router.put("/me")
async def update_my_profile(
    profile: ArtisanProfileUpdate,
    context: Annotated[
        AuthenticatedContext,
        Depends(get_current_user),
    ],
):
    try:
        return await save_artisan_profile(
            context,
            profile,
        )

    except ProfileServiceError as exc:
        print(exc)
        raise HTTPException(
            status_code=502,
            detail="Unable to save the artisan profile.",
        ) from exc