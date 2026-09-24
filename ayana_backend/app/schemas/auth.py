"""Schémas de validation (Pydantic) pour l'authentification."""

from datetime import datetime

from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    full_name: str | None = Field(None, max_length=120)
    pseudo: str = Field(..., min_length=2, max_length=60)
    phone: str = Field(..., min_length=8, max_length=30)
    password: str = Field(..., min_length=6, max_length=128)
    consent: bool = True
    language: str = Field("fr", pattern="^(fr|ewe|kbp)$")


class LoginRequest(BaseModel):
    phone: str = Field(..., min_length=8, max_length=30)
    password: str = Field(..., min_length=1, max_length=128)


class OTPRequestRequest(BaseModel):
    phone: str = Field(..., min_length=8, max_length=30)


class OTPVerifyRequest(BaseModel):
    phone: str = Field(..., min_length=8, max_length=30)
    code: str = Field(..., min_length=4, max_length=10)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"
    is_new_user: bool = False


class UserResponse(BaseModel):
    id: int
    pseudo: str
    full_name: str | None = None
    phone: str | None = None
    language: str
    is_guest: bool
    consent_accepted: bool
    date_joined: datetime

    model_config = {"from_attributes": True}


TokenResponse.model_rebuild()