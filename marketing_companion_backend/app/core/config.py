
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Marketing Companion API"
    app_env: str = "development"
    api_v1_prefix: str = "/api/v1"

    supabase_url: str
    supabase_publishable_key: str

    gemini_api_key: str | None = None

    # Cloudinary
    cloudinary_cloud_name: str | None = None
    cloudinary_api_key: str | None = None
    cloudinary_api_secret: str | None = None

    image_enhancement_provider: str = "cloudinary"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
