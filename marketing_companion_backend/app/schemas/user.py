from pydantic import BaseModel
from uuid import UUID

class AuthenticatedUser(BaseModel):
    id: UUID
    email: str | None = None

class AuthenticatedContext(BaseModel):
    user: AuthenticatedUser
    access_token: str
