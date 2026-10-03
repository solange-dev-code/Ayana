"""Schémas de la base de connaissances (cahier des charges, module 4)."""

from pydantic import BaseModel, Field


class KnowledgeBlock(BaseModel):
    """Un bloc de contenu structuré d'un parcours."""

    id: str
    titre: str
    points: list[str] = Field(..., min_length=1)
    source: str
    # Un bloc d'urgence est rendu différemment par l'app et remonte en tête :
    # il contient des signes imposant une consultation rapide.
    urgence: bool = False
    # Réservé aux points dont la formulation doit être validée par un expert
    # (cadre juridique, structure de santé, contact d'aide).
    note_validation: str | None = None


class ParcoursContent(BaseModel):
    """Contenu complet d'un parcours."""

    slug: str
    titre: str
    resume: str = ""
    avertissement: str = ""
    cdc_sections: list[str] = []
    blocs: list[KnowledgeBlock] = Field(..., min_length=1)


class ParcoursSummary(BaseModel):
    """Version courte, utilisée pour lister les parcours d'un écran d'accueil."""

    slug: str
    titre: str
    resume: str = ""
    nb_blocs: int = 0
    a_urgence: bool = False
