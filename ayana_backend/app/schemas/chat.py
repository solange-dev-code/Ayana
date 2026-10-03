"""Schémas (Pydantic) de la conversation IA du chat."""

from pydantic import BaseModel, Field, model_validator

from app.core.config import settings

# Longueur max d'une réponse d'AYANA dans l'historique renvoyé par l'app.
# L'app renvoie tout l'historique à chaque tour (cf. chat_screen.dart) : si ce
# texte est borné à la limite des messages utilisatrices, la 2e réponse d'une
# conversation fait échouer la requête entière en 422.
MAX_ASSISTANT_TEXT = 4000


class ChatMessage(BaseModel):
    """Un message de l'historique de conversation.

    La limite dépend du rôle : l'utilisatrice est bornée par
    ``settings.chat_max_len``, les réponses d'AYANA par ``MAX_ASSISTANT_TEXT``.
    """

    role: str = Field(..., pattern="^(user|assistant)$")
    text: str = Field(..., min_length=1)

    @model_validator(mode="after")
    def _check_text_length(self) -> "ChatMessage":
        limit = (
            settings.chat_max_len if self.role == "user" else MAX_ASSISTANT_TEXT
        )
        if len(self.text) > limit:
            raise ValueError(
                f"Message {self.role} trop long : {len(self.text)} caractères, "
                f"maximum {limit}."
            )
        return self


class ChatRequest(BaseModel):
    """Requête du chat : l'historique complet reçu par l'app."""

    messages: list[ChatMessage] = Field(..., min_length=1, max_length=60)


class ChatResponse(BaseModel):
    """Réponse de l'assistante à l'historique reçu."""

    reply: str
    # Parcours identifié par le moteur de classification (module 3 du cahier des
    # charges) : "corps", "protection", "grossesse", "aide" ou None si la
    # demande n'entre dans aucun parcours. Sert à l'app pour proposer le contenu
    # correspondant, pas à choisir la réponse.
    parcours: str | None = None
    methode_classification: str = "aucune"
