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
    CatalogGenerationError,
    generate_catalog,
)

from app.dependencies.auth import (
    AuthenticatedContext,
    get_current_user,
)

from app.services.product_service import (
    ProductServiceError,
    ProductNotFoundError,
    ProductStatusError,
    list_product_drafts,
    save_product_draft,
    update_product_publication,
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

    except CatalogGenerationError as exc:
        if str(exc) == "Gemini API key is not configured.":
            raise HTTPException(
                status_code=503,
                detail="Catalogue generation is not configured yet.",
            ) from exc

        if exc.provider_status_code == 503:
            raise HTTPException(
                status_code=503,
                detail=(
                    "The AI service is temporarily overloaded. "
                    "Please wait a little and try again."
                ),
            ) from exc

        if exc.provider_status_code == 429:
            raise HTTPException(
                status_code=429,
                detail=(
                    "The AI service is rate-limited. "
                    "Please wait before trying again."
                ),
            ) from exc

        raise HTTPException(
            status_code=502,
            detail="Unable to generate the catalog right now.",
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

@router.patch("/{product_id}/publish")
async def publish_product(
    product_id: str,
    context: Annotated[
        AuthenticatedContext,
        Depends(get_current_user),
    ],
):
    try:
        return await update_product_publication(
            context,
            product_id,
            publish=True,
        )

    except ProductNotFoundError as exc:
        raise HTTPException(
            status_code=404,
            detail="Product not found.",
        ) from exc

    except ProductStatusError as exc:
        raise HTTPException(
            status_code=409,
            detail=str(exc),
        ) from exc

    except ProductServiceError as exc:
        raise HTTPException(
            status_code=502,
            detail="Unable to publish the product.",
        ) from exc


@router.patch("/{product_id}/unpublish")
async def unpublish_product(
    product_id: str,
    context: Annotated[
        AuthenticatedContext,
        Depends(get_current_user),
    ],
):
    try:
        return await update_product_publication(
            context,
            product_id,
            publish=False,
        )

    except ProductNotFoundError as exc:
        raise HTTPException(
            status_code=404,
            detail="Product not found.",
        ) from exc

    except ProductStatusError as exc:
        raise HTTPException(
            status_code=409,
            detail=str(exc),
        ) from exc

    except ProductServiceError as exc:
        raise HTTPException(
            status_code=502,
            detail="Unable to unpublish the product.",
        ) from exc