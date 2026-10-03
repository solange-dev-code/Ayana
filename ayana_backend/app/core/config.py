"""Configuration de l'application AYANA.

Les valeurs sensibles peuvent être surchargées via un fichier ``.env``
(voir ``.env.example``).
"""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Générique
    app_name: str = "AYANA API"
    app_version: str = "1.0.0"
    debug: bool = True

    # Base de données
    database_url: str = "sqlite:///./ayana.db"

    # Sécurité / JWT
    secret_key: str = "ayana-dev-secret-change-me-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 jours (mobile)

    # OTP (simulé en dev : le code est renvoyé dans la réponse)
    otp_mock: bool = True
    otp_expire_minutes: int = 10
    otp_length: int = 6

    # Gemini (LLM du chat)
    gemini_api_key: str = ""
    gemini_model: str = "gemini-3.6-flash"
    # Plafond TOTAL de sortie, raisonnement compris. Ce modèle raisonne avant
    # de répondre (~600 à ~1150 tokens mesurés) et ce raisonnement est
    # décompté de ce plafond : un plafond de 1200 tokens laissait à peine
    # 200 tokens de réponse visible, coupée en milieu de phrase
    # (finish_reason MAX_TOKENS). À maintenir bien au-dessus de
    # « raisonnement + longueur visée » ; le prompt fixe la longueur.
    # Le modèle ignore le paramètre thinking_budget, d'où ce plafond large.
    gemini_max_tokens: int = 2500
    # Longueur max d'un message de l'utilisatrice. Les réponses d'AYANA
    # renvoyées dans l'historique ont leur propre limite (voir schemas/chat.py).
    chat_max_len: int = 500

    # Langues proposées par l'application
    available_languages: list[str] = ["fr", "ewe", "kbp"]

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()