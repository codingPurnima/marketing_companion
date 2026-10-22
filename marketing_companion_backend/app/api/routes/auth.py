
from typing import Annotated

from fastapi import APIRouter, Depends

from app.dependencies.auth import (
    AuthenticatedUser,
    get_current_user,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.get("/me", response_model=AuthenticatedUser)
async def get_me(
    current_user: Annotated[
        AuthenticatedUser,
        Depends(get_current_user),
    ],
) -> AuthenticatedUser:
    return current_user
