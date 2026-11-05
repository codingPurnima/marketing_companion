from pydantic import BaseModel, Field, field_validator


class ArtisanProfileUpdate(BaseModel):
    public_name: str = Field(min_length=1)
    bio: str | None = None
    craft: str = Field(min_length=1)
    district: str | None = None
    state: str | None = None
    whatsapp_number: str | None = None

    @field_validator("public_name", "craft")
    @classmethod
    def validate_required_text(cls, value: str) -> str:
        value = value.strip()

        if not value:
            raise ValueError("This field cannot be empty.")

        return value

    @field_validator(
        "bio",
        "district",
        "state",
        "whatsapp_number",
    )
    @classmethod
    def normalize_optional_text(
        cls,
        value: str | None,
    ) -> str | None:
        if value is None:
            return None

        value = value.strip()
        return value or None