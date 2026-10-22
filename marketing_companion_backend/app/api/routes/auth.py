
from typing import Annotated

from fastapi import APIRouter, Depends

from app.dependencies.auth import (
    AuthenticatedUser,
    get_current_user,
)
from app.schemas.user import AuthenticatedContext

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.get("/me", response_model=AuthenticatedUser)
async def get_me(
    context: Annotated[
        AuthenticatedContext,
        Depends(get_current_user),
    ],
):
    return context.user # ensures the access token is not included in response
