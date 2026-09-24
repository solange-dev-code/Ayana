"""Schémas liés au profil utilisatrice."""

from pydantic import BaseModel, Field


class UserUpdateRequest(BaseModel):
    pseudo: str | None = Field(None, min_length=2, max_length=60)
    full_name: str | None = Field(None, max_length=120)
    language: str | None = Field(None, pattern="^(fr|ewe|kbp)$")


class MessageResponse(BaseModel):
    detail: str