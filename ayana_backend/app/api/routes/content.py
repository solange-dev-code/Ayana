"""Routes de la base de connaissances (cahier des charges, module 4).

Contenu public : il ne contient aucune donnée personnelle et sert à alimenter
les écrans de parcours. L'orientation vers un professionnel (module 5) reste,
elle, dépendante d'un partenariat de structures qui n'existe pas encore.
"""

from fastapi import APIRouter, HTTPException, status

from app.schemas.content import ParcoursContent, ParcoursSummary
from app.services import knowledge

router = APIRouter(prefix="/api/contenus", tags=["contenus"])


@router.get("", response_model=list[ParcoursSummary])
def lister_parcours() -> list[ParcoursSummary]:
    """Parcours disponibles, pour l'écran d'accueil."""
    return knowledge.list_parcours()


@router.get("/{slug}", response_model=ParcoursContent)
def lire_parcours(slug: str) -> ParcoursContent:
    """Contenu complet d'un parcours.

    Le slug est validé par l'existence dans le catalogue : un slug inconnu
    renvoie un 404, jamais un contenu vide.
    """
    contenu = knowledge.get_parcours(slug)
    if contenu is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Parcours inconnu. "
                f"Disponibles : {', '.join(knowledge.known_slugs())}."
            ),
        )
    return contenu
