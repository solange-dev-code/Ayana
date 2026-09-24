"""Routes d'authentification : inscription, connexion, OTP simulé, anonyme."""

from datetime import datetime, timedelta, timezone
from random import randint
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.api.deps import DbSession, generate_pseudo
from app.core.config import settings
from app.core.security import create_access_token, hash_password, verify_password
from app.models.user import User
from app.schemas import (
    MessageResponse,
    OTPRequestRequest,
    OTPVerifyRequest,
    RegisterRequest,
    TokenResponse,
)

router = APIRouter(prefix="/api/auth", tags=["auth"])

# SIMULATION : en production, le code serait envoyé par SMS et stocké
# dans un cache/Redis. Ici, un simple dict mémoire suffit pour le MVP.
_otp_store: dict[str, dict] = {}


def _issue_token(user: User, is_new_user: bool = False) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(user.id),
        user=user,
        is_new_user=is_new_user,
    )


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: DbSession) -> TokenResponse:
    if not payload.consent:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Merci d'accepter les conditions d'utilisation.",
        )
    existing = db.query(User).filter(User.phone == payload.phone).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Un compte existe déjà avec ce numéro de téléphone.",
        )
    user = User(
        pseudo=payload.pseudo.strip(),
        full_name=payload.full_name.strip() if payload.full_name else None,
        phone=payload.phone,
        hashed_password=hash_password(payload.password),
        language=payload.language,
        consent_accepted=True,
        is_guest=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return _issue_token(user)


@router.post("/login", response_model=TokenResponse)
def login(
    form: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: DbSession,
) -> TokenResponse:
    user = db.query(User).filter(User.phone == form.username).first()
    if user is None or not user.hashed_password or not verify_password(
        form.password, user.hashed_password
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Numéro ou mot de passe incorrect.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return _issue_token(user)


@router.post("/guest", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def guest_account(db: DbSession) -> TokenResponse:
    """Mode « Continuer sans compte (anonyme) » : pseudonyme auto-généré,
    aucune donnée personnelle obligatoire (cahier des charges § 6.1)."""
    user = User(
        pseudo=generate_pseudo(db),
        is_guest=True,
        language="fr",
        consent_accepted=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return _issue_token(user, is_new_user=True)


@router.post("/otp/request", response_model=MessageResponse)
def request_otp(payload: OTPRequestRequest) -> MessageResponse:
    code = str(randint(10 ** (settings.otp_length - 1), 10**settings.otp_length - 1))
    _otp_store[payload.phone] = {
        "code": code,
        "expires_at": datetime.now(timezone.utc)
        + timedelta(minutes=settings.otp_expire_minutes),
    }
    detail = f"Un code vient d'être envoyé par SMS à {payload.phone}."
    if settings.otp_mock:
        detail += f" [MODE DÉMO — code : {code}]"
    return MessageResponse(detail=detail)


@router.post("/otp/verify", response_model=TokenResponse)
def verify_otp(payload: OTPVerifyRequest, db: DbSession) -> TokenResponse:
    stored = _otp_store.get(payload.phone)
    if stored is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucun code demandé pour ce numéro.",
        )
    if stored["expires_at"] < datetime.now(timezone.utc):
        _otp_store.pop(payload.phone, None)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ce code a expiré. Demande un nouveau code.",
        )
    if stored["code"] != payload.code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code incorrect.",
        )
    _otp_store.pop(payload.phone, None)

    user = db.query(User).filter(User.phone == payload.phone).first()
    is_new_user = user is None
    if user is None:
        user = User(
            pseudo=generate_pseudo(db),
            phone=payload.phone,
            is_guest=False,
            language="fr",
            consent_accepted=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return _issue_token(user, is_new_user=is_new_user)


@router.get("/ping", response_model=MessageResponse)
def ping(response: Response) -> MessageResponse:
    return MessageResponse(detail="pong")