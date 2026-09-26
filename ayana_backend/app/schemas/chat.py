"""Schémas (Pydantic) de la conversation IA du chat."""

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    """Un message de l'historique de conversation."""

    role: str = Field(..., pattern="^(user|assistant)$")
    text: str = Field(..., min_length=1, max_length=500)


class ChatRequest(BaseModel):
    """Requête du chat : l'historique complet reçu par l'app."""

    messages: list[ChatMessage] = Field(..., min_length=1, max_length=60)


class ChatResponse(BaseModel):
    """Réponse de l'assistante à l'historique reçu."""

    reply: str