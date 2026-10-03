"""Route du chat : envoie la conversation à l'assistante IA (Gemini)."""

from typing import Annotated

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas import ChatMessage, ChatRequest, ChatResponse
from app.services.classifier import classer
from app.services.llm import ask_gemini

router = APIRouter(prefix="/api/chat", tags=["chat"])


def _dernier_message_utilisatrice(messages: list[ChatMessage]) -> str:
    """Texte du dernier message de l'utilisatrice, base de la classification."""
    for message in reversed(messages):
        if message.role == "user":
            return message.text
    return ""


@router.post("", response_model=ChatResponse)
def chat(
    payload: ChatRequest,
    _user: Annotated[User, Depends(get_current_user)],
) -> ChatResponse:
    """Répond à l'historique reçu (le dernier message est celui de l'app).

    Requiert un jeton JWT (Bearer). La réponse est générée par Gemini, qui
    indique aussi le parcours correspondant (module 3 du cahier des charges).
    """
    history = [
        {"role": msg.role, "text": msg.text} for msg in payload.messages
    ]
    reply, slug_modele = ask_gemini(history)

    # Les règles passent d'abord : elles sont gratuites et disponibles même si le
    # quota est épuisé. La balise du modèle ne sert qu'en second.
    classification = classer(_dernier_message_utilisatrice(payload.messages), slug_modele)

    return ChatResponse(
        reply=reply,
        parcours=classification.slug,
        methode_classification=classification.methode,
    )