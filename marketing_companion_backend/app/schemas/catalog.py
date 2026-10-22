from typing import Literal

from pydantic import BaseModel, Field


ProductCategory = Literal[
    "pottery",
    "textiles",
    "weaving",
    "woodwork",
    "metalwork",
    "jewelry",
    "paintings",
    "other",
]


class CatalogDraft(BaseModel):
    """Structured product information generated for artisan review."""

    title: str = Field(
        description="A concise, clear product name.",
        min_length=1,
        max_length=120,
    )
    description: str = Field(
        description="An appealing, truthful description based only on supplied details.",
        min_length=1,
        max_length=1500,
    )
    category: ProductCategory = Field(
        description="The best matching supported product category."
    )
    materials: list[str] = Field(
        description="Materials explicitly mentioned or clearly identified in the input."
    )
    tags: list[str] = Field(
        description="Relevant search keywords for discovering this product."
    )
    price_inr: float | None = Field(
        default=None,
        ge=0,
        description="Price in INR only if explicitly provided by the artisan; otherwise null.",
    )


class CatalogGenerateRequest(BaseModel):
    """Input supplied by the artisan."""

    product_text: str = Field(
        min_length=5,
        max_length=4000,
        description="A rough product description, including voice-transcribed text.",
    )