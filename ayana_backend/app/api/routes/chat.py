"""Route du chat : envoie la conversation à l'assistante IA (Gemini)."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas import ChatRequest, ChatResponse
from app.services.llm import ask_gemini

router = APIRouter(prefix="/api/chat", tags=["chat"])


@router.post("", response_model=ChatResponse)
def chat(
    payload: ChatRequest,
    _user: Annotated[User, Depends(get_current_user)],
) -> ChatResponse:
    """Répond à l'historique reçu (le dernier message est celui de l'app).

    Requiert un jeton JWT (Bearer). La réponse est générée par Gemini.
    """
    history = [
        {"role": msg.role, "text": msg.text} for msg in payload.messages
    ]
    reply = ask_gemini(history)
    return ChatResponse(reply=reply)