"""Service d'appel au LLM Gemini via le SDK ``google-genai``.

La clé API est lue depuis ``settings.gemini_api_key`` (fichier ``.env``
local, jamais versionné). Aucune valeur sensible n'apparaît dans le code.
"""

import logging

from app.core.config import settings

logger = logging.getLogger(__name__)

# Instructions de comportement d'AYANA envoyées au modèle à chaque appel.
SYSTEM_PROMPT = (
    "Tu es AYANA, une assistante santé intelligente, chaleureuse et "
    "bienveillante qui accompagne les jeunes femmes et adolescentes sur la "
    "santé sexuelle, reproductive et maternelle.\n"
    "\n"
    "Règles à respecter :\n"
    "- Parle toujours de façon douce, respectueuse et sans jugement. "
    "Tout échange est confidentiel.\n"
    "- Réponds dans la langue de l'utilisatrice (français, éwé ou kabyè "
    "selon sa question).\n"
    "- Reste claire et concise, évite le jargon médical complexe. "
    "Utilise des phrases courtes.\n"
    "- Tu informes et orientes, mais tu n'établis pas de diagnostic et tu ne "
    "remplaces jamais un professionnel de santé.\n"
    "- Ne donne pas de posologie ou de traitement précis. Recommande de "
    "consulter un médecin, une sage-femme ou un centre de santé.\n"
    "- Si la situation semble urgente (danger immédiat, hémorragie, violences, "
    "détresse grave...), invite à contacter les urgences ou un professionnel "
    "le plus tôt possible, avec bienveillance.\n"
    "- Reste dans le domaine santé sexuelle, reproductive et maternelle ; "
    "pour tout autre sujet, redirige poliment.\n"
)

# Message renvoyé à l'app quand le modèle ne peut pas répondre.
FALLBACK_MESSAGE = (
    "Je n'arrive pas à te répondre pour le moment 🌸"
    " Réessaie dans quelques instants. Si c'est urgent, "
    "contacte un professionnel de santé."
)

# Message renvoyé quand la clé Gemini n'est pas configurée.
NOT_CONFIGURED_MESSAGE = (
    "Je suis presque prête ! L'assistante IA n'est pas encore configurée. "
    "Réessaie bientôt 🌸"
)


def ask_gemini(messages: list[dict]) -> str:
    """Envoie l'historique à Gemini et retourne la réponse (texte seul).

    ``messages`` : liste de dicts ``{"role": "user"|"assistant",
    "text": str}`` représentant la conversation à transmettre.
    """
    if not settings.gemini_api_key:
        return NOT_CONFIGURED_MESSAGE

    client = _client()
    if client is None:
        return NOT_CONFIGURED_MESSAGE

    try:
        from google.genai import types

        # Historique (tous les messages sauf le dernier, transmis par send_message)
        history: list[dict] = []
        for msg in messages[:-1]:
            role = "model" if msg.get("role") == "assistant" else "user"
            text = msg.get("text", "")
            if text.strip():
                history.append({"role": role, "parts": [{"text": text}]})

        config = types.GenerateContentConfig(
            system_instruction=SYSTEM_PROMPT,
            max_output_tokens=settings.gemini_max_tokens,
        )
        chat = client.chats.create(
            model=settings.gemini_model,
            history=history,
            config=config,
        )
        user_text = messages[-1].get("text", "") if messages else "Bonjour"
        response = chat.send_message(user_text)
        return (response.text or "").strip() or FALLBACK_MESSAGE
    except Exception as exc:  # réseau, quota, modèle indisponible...
        logger.warning("Échec de l'appel Gemini : %s", exc)
        return FALLBACK_MESSAGE


_client_cache = None


def _client():
    """Client Gemini lazy (créé au premier appel uniquement)."""
    global _client_cache
    if _client_cache is None:
        try:
            from google import genai

            _client_cache = genai.Client(api_key=settings.gemini_api_key)
        except Exception as exc:  # SDK ou clé invalide
            logger.warning("Impossible de créer le client Gemini : %s", exc)
            return None
    return _client_cache