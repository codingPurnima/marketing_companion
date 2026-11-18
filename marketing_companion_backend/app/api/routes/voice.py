from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException

from app.dependencies.auth import (
    AuthenticatedUser,
    get_current_user,
)

from app.schemas.voice import (
    VoiceUnderstandRequest,
    VoiceCommandResult,
)

from app.services.voice_service import (
    VoiceUnderstandingError,
    understand_voice_command,
)


router = APIRouter(
    prefix="/voice",
    tags=["voice"],
)


@router.post(
    "/understand",
    response_model=VoiceCommandResult,
)
def understand_command(
    request: VoiceUnderstandRequest,
    _current_user: Annotated[
        AuthenticatedUser,
        Depends(get_current_user),
    ],
) -> VoiceCommandResult:

    try:
        return understand_voice_command(request)

    except VoiceUnderstandingError as exc:

        if str(exc) == "Gemini API key is not configured.":
            raise HTTPException(
                status_code=503,
                detail="Voice understanding is not configured.",
            ) from exc

        if exc.provider_status_code == 503:
            raise HTTPException(
                status_code=503,
                detail="AI service is temporarily unavailable.",
            ) from exc

        if exc.provider_status_code == 429:
            raise HTTPException(
                status_code=429,
                detail="AI service rate limit reached.",
            ) from exc

        raise HTTPException(
            status_code=502,
            detail="Unable to understand the voice command.",
        ) from exc