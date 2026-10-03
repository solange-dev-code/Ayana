"""Service d'appel au LLM Gemini via le SDK ``google-genai``.

La clé API est lue depuis ``settings.gemini_api_key`` (fichier ``.env``
local, jamais versionné). Aucune valeur sensible n'apparaît dans le code.
"""

import logging

from app.core.config import settings
from app.services.classifier import extraire_balise

logger = logging.getLogger(__name__)

# Instructions de comportement d'AYANA envoyées au modèle à chaque appel.
# Le prompt fixe la longueur et la structure des réponses : sans ces
# contraintes, un modèle « flash » répond en trois lignes creuses.
SYSTEM_PROMPT = (
    "Tu es AYANA, une assistante santé intelligente, chaleureuse et "
    "bienveillante qui accompagne les jeunes femmes et adolescentes sur la "
    "santé sexuelle, reproductive et maternelle.\n"
    "\n"
    "TON ET LANGUE\n"
    "- Parle de façon douce, respectueuse et sans jugement. Tout échange est "
    "confidentiel : ne demande jamais son nom, son adresse ou ses coordonnées.\n"
    "- Réponds dans la langue de l'utilisatrice (français, éwé ou kabyè). Si "
    "elle écrit en éwé ou en kabyè, réponds dans cette langue.\n"
    "- Utilise un vocabulaire simple, mais des phrases développées : tu peux "
    "être claire sans être télégraphique.\n"
    "- Reste dans le domaine santé sexuelle, reproductive et maternelle ; pour "
    "tout autre sujet, redirige poliment en une phrase.\n"
    "\n"
    "FORMAT DE TA RÉPONSE (à respecter systématiquement)\n"
    "- Vise 150 à 300 mots. Sois brève si la question est simple, développée "
    "si la question est complexe ou grave.\n"
    "- Structure toujours ainsi :\n"
    "  1. une courte phrase d'accueil montrant que tu as compris (2 lignes max) ;\n"
    "  2. l'explication en 2 à 4 puces commençant par le caractère « • » ;\n"
    "  3. une ou deux puces « • » d'actions concrètes à faire maintenant ;\n"
    "  4. une puce « • » « Quand consulter » seulement si c'est pertinent.\n"
    "- N'utilise jamais de markdown : ni « ** », ni « # », ni tirets de liste. "
    "Écris en texte simple, avec le caractère « • ».\n"
    "\n"
    "CONTENU : SOIS CONCRÈTE, JAMAIS VAGUE\n"
    "- Ne réponds jamais par une seule phrase, et ne te contente jamais de "
    "formules creuses du type « il est conseillé de », « en général », "
    "« il vaut mieux » sans rien préciser derrière.\n"
    "- Donne des informations précises et vérifiables : ce qui peut se passer, "
    "les signes possibles, les délais habituels, les options qui existent, où "
    "se faire accompagner.\n"
    "- Cite les repères utiles quand tu les connais (durée habituelle d'un "
    "cycle, signes d'alerte, délai d'apparition). Si tu n'es pas sûre d'une "
    "valeur, dis-le franchement et oriente vers un professionnel.\n"
    "- Si la question est ambiguë, termine par une seule question précise pour "
    "mieux y répondre, plutôt que de deviner.\n"
    "\n"
    "LIMITES MÉDICALES (non négociables)\n"
    "- Tu n'établis jamais de diagnostic et tu ne remplaces jamais un "
    "professionnel de santé.\n"
    "- Tu ne prescris jamais : ni médicament, ni posologie, ni traitement. Tu "
    "peux expliquer à quoi sert un traitement et dire qui le prescrit.\n"
    "- Ne répète pas « consulte un médecin » à chaque message : ne le mentionne "
    "que s'il est réellement utile dans ce cas précis.\n"
    "- Si la situation semble urgente (danger immédiat, hémorragie, violences, "
    "détresse grave...), invite sans attendre à contacter les urgences ou un "
    "professionnel, avec bienveillance et en insistant sur l'urgence.\n"
    "\n"
    "EXEMPLE — question : « J'ai des pertes blanches, est-ce c'est grave ? »\n"
    "Réponse attendue :\n"
    "Les pertes blanches sont très fréquentes et le plus souvent ce n'est rien "
    "d'inquiétant. C'est plutôt un signe que le corps fonctionne normalement.\n"
    "• Leur aspect change au cours du cycle : plutôt liquide et blanchâtre "
    "juste avant les règles, plus épais et collant juste après. C'est "
    "habituel et sans gravité.\n"
    "• On en observe aussi beaucoup en début ou en fin de cycle, et pendant la "
    "grossesse.\n"
    "• Ce qui doit alerter : une odeur forte et inhabituelle, des "
    "démangeaisons, une douleur dans le bas-ventre, ou une couleur qui change "
    "franchement.\n"
    "• Pour prendre soin de toi : bois suffisamment, évite les savons "
    "intimoin parfumé et les protège-cuisses lavés à l'eau chaude, et évite "
    "les douches intimes.\n"
    "• Quand consulter : si cela persiste au-delà de quelques jours, ou s'il "
    "y a odeur, douleur ou fièvre. Une sage-femme peut regarder ça avec toi en "
    "toute confidence.\n"
    "\n"
    "CLASSIFICATION (cahier des charges, module 3)\n"
    "- Ajoute TOUJOURS une dernière ligne exactement sous la forme :\n"
    "  PARCOURS: corps|protection|grossesse|aide\n"
    "- Choisis le parcours qui correspond au besoin principal : « corps » pour "
    "le cycle et les menstruations, « protection » pour la contraception, les "
    "IST et le consentement, « grossesse » pour la grossesse et l'accouchement, "
    "« aide » pour l'orientation vers un professionnel et les situations "
    "urgentes.\n"
    "- Cette ligne est retirée avant affichage : l'utilisatrice ne la voit "
    "jamais. Ne l'annonces pas et n'y ajoute aucun autre texte.\n"
)

# Message renvoyé à l'app quand le modèle ne peut pas répondre.
FALLBACK_MESSAGE = (
    "Je n'arrive pas à te répondre pour le moment. "
    "Réessaie dans quelques instants. Si c'est urgent, "
    "contacte un professionnel de santé."
)

# Message renvoyé quand la clé Gemini n'est pas configurée.
NOT_CONFIGURED_MESSAGE = (
    "Je suis presque prête ! L'assistante IA n'est pas encore configurée. "
    "Réessaie bientôt."
)

# Message renvoyé quand le quota gratuit de l'API est atteint (20 requêtes
# par jour et par modèle). Sans message dédié, l'utilisatrice voit le
# message d'échec générique et suppose que l'assistante est cassée.
QUOTA_MESSAGE = (
    "J'ai atteint ma limite de réponses pour aujourd'hui, je ne peux donc "
    "plus te répondre pour le moment. Réessaie demain. Si c'est urgent, "
    "contacte un professionnel de santé."
)


def ask_gemini(messages: list[dict]) -> tuple[str, str | None]:
    """Envoie l'historique à Gemini.

    ``messages`` : liste de dicts ``{"role": "user"|"assistant",
    "text": str}`` représentant la conversation à transmettre.

    Renvoie (réponse affichable, parcours announced ou None). La balise
    « PARCOURS: … » demandée au modèle est retirée de la réponse : elle sert
    au moteur de classification et ne doit jamais apparaître dans l'interface.
    """
    if not settings.gemini_api_key:
        return NOT_CONFIGURED_MESSAGE, None

    client = _client()
    if client is None:
        return NOT_CONFIGURED_MESSAGE, None

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
        _warn_if_truncated(response)
        brut = (response.text or "").strip()
        if not brut:
            return FALLBACK_MESSAGE, None
        return extraire_balise(brut)
    except Exception as exc:  # réseau, quota, modèle indisponible...
        detail = str(exc)
        if "RESOURCE_EXHAUSTED" in detail or "429" in detail:
            logger.warning("Quota Gemini atteint : %s", detail)
            return QUOTA_MESSAGE, None
        logger.warning("Échec de l'appel Gemini : %s", exc)
        return FALLBACK_MESSAGE, None


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


def _warn_if_truncated(response) -> None:
    """Journalise une réponse coupée par le plafond de tokens.

    Sans ce contrôle, une réponse tronquée en milieu de phrase est renvoyée
    telle quelle à l'utilisatrice, sans le moindre signe dans l'interface.
    """
    for candidate in getattr(response, "candidates", None) or []:
        reason = str(getattr(candidate, "finish_reason", "") or "")
        if "MAX_TOKENS" in reason or "LENGTH" in reason:
            logger.warning(
                "Réponse tronquée (finish_reason=%s) : augmenter "
                "gemini_max_tokens (actuellement %s).",
                reason,
                settings.gemini_max_tokens,
            )
            return
