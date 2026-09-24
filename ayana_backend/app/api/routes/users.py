"""Routes du profil utilisatrice : lecture et mise à jour du compte connecté."""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import DbSession, get_current_user
from app.models.user import User
from app.schemas import UserResponse, UserUpdateRequest

router = APIRouter(prefix="/api/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
def me(user: Annotated[User, Depends(get_current_user)]) -> User:
    return user


@router.patch("/me", response_model=UserResponse)
def update_me(
    payload: UserUpdateRequest,
    user: Annotated[User, Depends(get_current_user)],
    db: DbSession,
) -> User:
    if payload.language is not None:
        user.language = payload.language
    if payload.pseudo is not None:
        user.pseudo = payload.pseudo.strip()
    if payload.full_name is not None:
        user.full_name = payload.full_name.strip() or None
    db.commit()
    db.refresh(user)
    return user