"""Moteur de classification (cahier des charges, module 3).

Le module 3 du cahier des charges demande « l'identification automatique du
parcours correspondant à la demande ». Ce moteur attribue chaque message à l'un
des quatre parcours de l'application, en privilégiant des règles déterministes.

Trois raisons de commencer par des règles plutôt que par le modèle :

* le quota gratuit du modèle est de 20 requêtes par jour. Un appel de
  classification supplémentaire par message consommerait une part importante de
  ce quota pour une information qu'une liste de mots-clés fournit gratuitement ;
* une classification par mots-clés est testable et reproductible, donc
  démontrable devant un jury ;
* elle reste disponible même quand le modèle est saturé ou hors ligne.

En cas d'échec des règles, on ne fait pas d'appel supplémentaire : le modèle
renvoie lui-même son parcours dans une balise de fin de réponse, retirée avant
affichage. Le repli est donc toujours gratuit.
"""

from __future__ import annotations

import logging
import re
import unicodedata
from dataclasses import dataclass

logger = logging.getLogger(__name__)

PARCOURS_SLUGS: tuple[str, ...] = ("corps", "protection", "grossesse", "aide")

# Balise attendue en fin de réponse du modèle, retirée avant affichage.
PARCOURS_TAG_RE = re.compile(
    r"^\s*PARCOURS\s*[:\-]\s*(corps|protection|grossesse|aide)\s*$",
    re.IGNORECASE | re.MULTILINE,
)

# Poids par mot-clé. Un poids de 3 indique un indice fort (« enceinte »), un
# poids de 1 un indice faible qui ne suffit pas seul à trancher. Les mots
# trop génériques sont volontairement absents : « santé », « corps » ou « femme »
# ne renseignent aucun parcours en particulier.
#
# Limite assumée : ces règles sont en français. Un message écrit en éwé ou en
# kabyè ne sera pas classifié par les mots-clés et basculera sur la balise du
# modèle. Un jeu de mots-clés dans ces langues demanderait des locuteurs natifs
# et n'a pas été fait dans le délai imparti.
_MOTS_CLES: dict[str, dict[str, int]] = {
    "corps": {
        "cycle": 3, "regle": 3, "regles": 3, "menstruat": 3, "ovulation": 3,
        "menopause": 3, "puberte": 3, "saignement": 2, "saignements": 2,
        "pertes blanches": 2, "hemorragie": 2, "periode": 2, "periodes": 2,
        "tache brune": 2, "douleur pelvienne": 2, "gynecolog": 2,
        "leucorrhee": 2, "hymen": 2, "gorge": 1, "sein": 1, "seins": 1,
    },
    "protection": {
        "contracep": 3, "pilule": 3, "pilules": 3, "preservatif": 3,
        "condom": 3, "ist": 3, "vih": 3, "sida": 3, "syphilis": 3,
        "papillomavirus": 3, "hpv": 3, "chlamydia": 3, "gonococcie": 3,
        "sterilet": 3, "consentement": 3, "rapport": 2, "rapports": 2,
        "depistage": 2, "vaccin": 2, "hepatite": 2, "implant": 2,
        "refuse": 2, "desire": 2, "test de grossesse": 2,
        # « éviter une grossesse » contient le mot « grossesse » mais relève de
        # la protection : ces expressions doivent l'emporter, sinon la question
        # est classée comme une demande de suivi de grossesse.
        "eviter une grossesse": 3, "eviter une grossese": 3, "pour eviter": 2,
        "sans protection": 3, "non protege": 2, "non protegee": 2,
    },
    "grossesse": {
        "grossesse": 3, "enceinte": 3, "enceint": 3, "cpn": 3,
        "prenatal": 3, "accouchement": 3, "echographie": 3, "foetus": 3,
        "trimestre": 3, "trimestres": 3, "amenorrhee": 3, "postnatal": 3,
        "fausse couche": 3, "terme": 2, "bebe": 2, "allait": 2,
        "post-partum": 2, "sage-femme": 1,
    },
    "aide": {
        "urgence": 3, "urgences": 3, "hopital": 3, "centre de sante": 3,
        "orientation": 3, "ou aller": 3, "violen": 3, "agress": 3,
        "abus": 3, "tortur": 3, "menac": 3, "coercition": 3, "abusif": 3,
        "structure": 2, "adresse": 2, "numero": 2, "rendez-vous": 2,
        "secret medical": 2, "orienter": 2, "aide": 1, "confidentiel": 1,
        # Une relation imposée est une question d'aide et de protection. Le poids
        # est supérieur au mot « rapport » (2) afin que, face à une phrase qui
        # contient les deux, le classement penche vers l'aide : c'est le
        # parcours qui oriente vers un professionnel et vers une structure.
        "impose": 4, "imposee": 4, "sage femme": 2, "trouver": 1,
        "ou je peux": 2,
    },
}

# Nombre de points au-delà duquel la classification est jugée fiable. Volontairement
# bas : une question courte comme « mon cycle est irrégulier » ne contient
# qu'un seul indice, et doit tout de même être routée. L'ambiguïté est traitée
# par la marge, pas par le seuil.
_SEUIL = 2

# Écart minimal avec le deuxième meilleur parcours. Sans cette marge, deux
# parcours voisins partagent assez de mots pour qu'un seul mot suffise à
# faire basculer la réponse.
_MARGE = 2


@dataclass(frozen=True)
class Classification:
    """Résultat du moteur de classification."""

    slug: str | None
    confiance: float
    methode: str  # "regles" | "modele" | "aucune"
    scores: dict[str, int]

    def __bool__(self) -> bool:
        return self.slug is not None


def _normaliser(texte: str) -> str:
    """Minuscules, sans accents, ponctuation remplacée par des espaces.

    Les accents sont retirés par décomposition Unicode plutôt que supprimés :
    sinon « éviter » devenait « viter » et plus aucun mot-clé ne trouvait. Les
    clés de ``_MOTS_CLES`` sont écrites sans accents, ce qui fait qu'un message
    accentué et le même message non accentué se classent identiquement.
    """
    minuscules = texte.lower().replace("œ", "oe").replace("æ", "ae")
    decompose = unicodedata.normalize("NFD", minuscules)
    sans_accent = "".join(c for c in decompose if unicodedata.category(c) != "Mn")
    return f" {re.sub(r'[^a-z0-9]+', ' ', sans_accent).strip()} "


def _scores(texte: str) -> dict[str, int]:
    normalise = _normaliser(texte)
    result: dict[str, int] = {}
    for slug, mots in _MOTS_CLES.items():
        total = 0
        for mot, poids in mots.items():
            if mot in normalise:
                total += poids
        result[slug] = total
    return result


def classer_par_regles(texte: str) -> Classification:
    """Classification déterministe, sans appel réseau."""
    scores = _scores(texte)
    classes = sorted(scores.items(), key=lambda kv: kv[1], reverse=True)
    meilleur, score_max = classes[0]
    second = classes[1][1] if len(classes) > 1 else 0

    if score_max >= _SEUIL and score_max - second >= _MARGE:
        return Classification(
            slug=meilleur,
            confiance=min(1.0, score_max / (_SEUIL * 2)),
            methode="regles",
            scores=scores,
        )
    return Classification(
        slug=None, confiance=0.0, methode="aucune", scores=scores
    )


def classer(message: str, fallback_modele: str | None = None) -> Classification:
    """Classifie un message.

    [fallback_modele] est le parcours déduit de la balise renvoyée par le
    modèle (« PARCOURS: grossesse »). Il n'est utilisé que si les règles ne
    donnent rien, ce qui évite tout appel supplémentaire.
    """
    resultat = classer_par_regles(message)
    if resultat.slug or not fallback_modele:
        return resultat
    if fallback_modele not in PARCOURS_SLUGS:
        logger.debug("Parcours renvoyé par le modèle ignoré : %r", fallback_modele)
        return resultat
    return Classification(
        slug=fallback_modele,
        confiance=0.5,
        methode="modele",
        scores=resultat.scores,
    )


def extraire_balise(reponse: str) -> tuple[str, str | None]:
    """Sépare la balise de parcours du texte à afficher.

    Renvoie (réponse sans balise, slug ou None). Le modèle peut omettre la
    balise, en inventer une mal formée ou la placer ailleurs : le texte
    affiché ne doit jamais contenir de marqueur technique.
    """
    correspondance = PARCOURS_TAG_RE.search(reponse)
    if not correspondance:
        return reponse.strip(), None
    nettoye = PARCOURS_TAG_RE.sub("", reponse).strip()
    # Une réponse réduite à sa balise ne laisserait rien à afficher.
    if not nettoye:
        return reponse.strip(), None
    return nettoye, correspondance.group(1).lower()
