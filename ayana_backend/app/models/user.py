"""Utilisatrice AYANA.

La confidentialité est centrale : l'identité réelle est optionnelle
(``full_name``), un ``pseudo`` suffit et le mode anonyme (``is_guest``)
permet d'utiliser l'application sans aucun compte (cahier des charges § 6.1).
"""

from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    date_joined: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)

    # Identité minimale (principe de minimisation des données)
    pseudo: Mapped[str] = mapped_column(String(60), nullable=False)
    full_name: Mapped[str | None] = mapped_column(String(120), nullable=True)

    # Authentification
    phone: Mapped[str | None] = mapped_column(String(30), unique=True, nullable=True)
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # Compte anonyme (sans mot de passe, pseudo généré)
    is_guest: Mapped[bool] = mapped_column(Boolean, default=False)

    # Paramètres de l'application (cahier des charges § 10.6 multilingue)
    language: Mapped[str] = mapped_column(String(10), default="fr")

    # Consentement (cahier des charges — confidentialité)
    consent_accepted: Mapped[bool] = mapped_column(Boolean, default=False)

    # OTP (réinitialisation / connexion par téléphone)
    otp_code: Mapped[str | None] = mapped_column(String(10), nullable=True)
    otp_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    @property
    def is_authenticated(self) -> bool:
        return not self.is_guest