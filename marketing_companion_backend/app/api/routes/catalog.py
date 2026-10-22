from fastapi import APIRouter, HTTPException, status, Depends
from typing import Annotated

from app.dependencies.auth import(
    AuthenticatedUser,
    get_current_user
)

from app.schemas.catalog import (
    CatalogDraft,
    CatalogGenerateRequest,
)
from app.services.catalog_service import (
    catalogGenerationError,
    generate_catalog,
)

from app.dependencies.auth import (
    AuthenticatedContext,
    get_current_user,
)

from app.services.product_service import (
    ProductServiceError,
    list_product_drafts,
    save_product_draft,
)

router = APIRouter(prefix="/catalog", tags=["catalog"])


@router.post("/generate", response_model=CatalogDraft)
def generate_catalog_draft(
    request: CatalogGenerateRequest,
    _current_user: Annotated[
        AuthenticatedUser, Depends(get_current_user)
    ]
) -> CatalogDraft:
    try:
        return generate_catalog(request.product_text)

    except catalogGenerationError as exc:
        message = str(exc)
        print(message)

        if message == "Gemini API key is not configured.":
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="catalog generation is not configured yet.",
            ) from exc

        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Unable to generate the catalog right now. Please try again.",
        ) from exc

@router.post("/drafts", status_code=201)
async def create_catalog_draft(
    draft: CatalogDraft,
    context: Annotated[
        AuthenticatedContext,
        Depends(get_current_user),
        ],
    ):
        try:
            return await save_product_draft(context, draft)

        except ProductServiceError as exc:
            print(str(exc))
            raise HTTPException(
                status_code=502,
                detail="Unable to save the product draft.",
            ) from exc


@router.get("/drafts")
async def get_catalog_drafts(
    context: Annotated[
            AuthenticatedContext,
            Depends(get_current_user),
        ],
    ):
    try:
        return await list_product_drafts(context)

    except ProductServiceError as exc:
        raise HTTPException(
            status_code=502,
            detail="Unable to retrieve product drafts.",
        ) from exc