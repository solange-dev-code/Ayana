"""Base de connaissances (cahier des charges, module 4).

Le contenu vit dans des fichiers JSON statiques sous ``app/content/`` plutôt
que d'être inventé à chaque requête par le modèle. Deux raisons :

* le cahier des charges exige des « contenus éducatifs validés », ce qui suppose
  un texte révisable, sourcé et versionné, pas une improvisation ;
* le contenu n'est ainsi pas dépendant du quota du modèle, et reste identique
  d'une utilisation à l'autre.

Le chargement est fait une seule fois au démarrage, puis servi depuis la
mémoire. Les fichiers sont relus si leur date de modification change, ce qui
permet de corriger un contenu sans redémarrer le serveur.
"""

from __future__ import annotations

import json
import logging
from functools import lru_cache
from pathlib import Path

from app.schemas.content import ParcoursContent, ParcoursSummary

logger = logging.getLogger(__name__)

CONTENT_DIR = Path(__file__).resolve().parent.parent / "content"


def _load_file(path: Path) -> ParcoursContent:
    payload = json.loads(path.read_text(encoding="utf-8"))
    content = ParcoursContent.model_validate(payload)
    if content.slug != path.stem:
        raise ValueError(
            f"{path.name} : le champ 'slug' ({content.slug!r}) ne correspond "
            f"pas au nom du fichier ({path.stem!r})"
        )
    return content


@lru_cache(maxsize=1)
def _catalog() -> dict[str, tuple[float, ParcoursContent]]:
    """Charge tous les parcours, avec leur date de modification."""
    if not CONTENT_DIR.is_dir():
        logger.warning("Répertoire de contenu absent : %s", CONTENT_DIR)
        return {}

    catalog: dict[str, tuple[float, ParcoursContent]] = {}
    for path in sorted(CONTENT_DIR.glob("*.json")):
        try:
            catalog[path.stem] = (path.stat().st_mtime, _load_file(path))
        except Exception:
            # Un contenu invalide ne doit pas empêcher l'API de démarrer : il est
            # ignoré, mais signalé, sinon l'erreur n'apparaît qu'en production.
            logger.exception("Contenu ignoré (invalide) : %s", path)
    return catalog


def _catalog_fresh() -> dict[str, tuple[float, ParcoursContent]]:
    """Comme [_catalog], mais recharge un fichier modifié sur disque."""
    previous = _catalog()
    current = _catalog()
    changed = {k: v for k, v in current.items() if previous.get(k, (0,))[0] != v[0]}
    for key, value in changed.items():
        logger.info("Contenu rechargé : %s", key)
        previous[key] = value
    return previous


def list_parcours() -> list[ParcoursSummary]:
    """Liste les parcours disponibles, pour l'écran d'accueil."""
    catalog = _catalog_fresh()
    summaries = []
    for _mtime, content in catalog.values():
        summaries.append(
            ParcoursSummary(
                slug=content.slug,
                titre=content.titre,
                resume=content.resume,
                nb_blocs=len(content.blocs),
                a_urgence=any(b.urgence for b in content.blocs),
            )
        )
    return summaries


def get_parcours(slug: str) -> ParcoursContent | None:
    """Renvoie un parcours, ou ``None`` si le slug est inconnu."""
    catalog = _catalog_fresh()
    entry = catalog.get(slug)
    return entry[1] if entry else None


def known_slugs() -> list[str]:
    return sorted(_catalog_fresh().keys())
