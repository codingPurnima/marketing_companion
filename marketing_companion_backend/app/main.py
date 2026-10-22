
from fastapi import FastAPI

from app.api.routes import health, auth, catalog
from app.core.config import get_settings

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="Backend API for the Artisan Marketing Companion.",
)

app.include_router(
    health.router,prefix=settings.api_v1_prefix,
)
app.include_router(
    auth.router, prefix= settings.api_v1_prefix,
)
app.include_router(
    catalog.router, prefix=settings.api_v1_prefix,
)

@app.get("/")
def root():
    return {
        "message": "Artisan Marketing Companion API",
        "docs": "/docs",
    }