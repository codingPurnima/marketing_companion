from typing import Literal

from pydantic import BaseModel, Field


VoiceIntent = Literal[
    "list_products",
    "find_product",
    "edit_product",
    "publish_product",
    "archive_product",
    "republish_product",
    "save_draft",
    "load_archived_products",
    "unknown",
]


class ProductUpdates(BaseModel):
    title: str | None = None
    description: str | None = None
    category: Literal[
        "pottery",
        "textiles",
        "weaving",
        "woodwork",
        "metalwork",
        "jewelry",
        "paintings",
        "other",
    ] | None = None
    price: float | None = Field(default=None, ge=0)


class VoiceUnderstandRequest(BaseModel):
    transcript: str = Field(min_length=1, max_length=1000)
    language_hint: Literal["auto", "hi-IN", "en-IN"] = "auto"
    context_product_title: str | None = Field(
        default=None,
        max_length=200,
    )


class VoiceCommandResult(BaseModel):
    intent: VoiceIntent
    product_query: str | None = None
    updates: ProductUpdates | None = None

    confidence: float = Field(ge=0, le=1)

    response_language: Literal[
        "hi",
        "en",
        "hinglish",
        "unknown",
    ]

    needs_clarification: bool = False
    clarification_question: str | None = None