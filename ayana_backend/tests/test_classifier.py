"""Tests du moteur de classification (cahier des charges, module 3).

Le module 3 demande l'« identification automatique du parcours correspondant à
la demande ». Ces tests verrouillent le comportement des règles et de la
balise renvoyée par le modèle.

Un point important est vérifié ici : la classification ne doit coûter aucun
appel supplémentaire au modèle. Le repli utilize la balise déjà présente dans
la réponse, pas un nouvel appel.
"""

import pytest

from app.services.classifier import (
    PARCOURS_SLUGS,
    Classification,
    classer,
    classer_par_regles,
    extraire_balise,
)

# Questions réelles, formulées comme une utilisatrice les écrirait.
CAS = [
    # Grossesse (cahier des charges 6.5)
    ("je suis enceinte de 3 mois, quand je dois aller au CPN ?", "grossesse"),
    ("comment se passe un accouchement ?", "grossesse"),
    ("je suis enceinte et j'ai mal au ventre", "grossesse"),
    # Corps (6.3)
    ("j'ai des saignements entre mes règles", "corps"),
    ("mon cycle est irrégulier, est ce grave ?", "corps"),
    ("les pertes blanches sont elles graves ?", "corps"),
    # Protection (6.4)
    ("quelle pilule prendre pour éviter une grossesse ?", "protection"),
    ("à quoi sert le dépistage du VIH ?", "protection"),
    ("j'ai eu un rapport sans protection, que faire ?", "protection"),
    # Aide (6.8)
    ("je me suis fait agresser, je ne sais où aller", "aide"),
    ("où je peux trouver une sage femme ?", "aide"),
    # Hors parcours : aucune classification ne doit être inventée
    ("bonjour", None),
    ("comment va le temps ?", None),
    ("merci beaucoup", None),
]


@pytest.mark.parametrize("texte,attendu", CAS)
def test_classification_par_regles(texte, attendu):
    resultat = classer_par_regles(texte)
    assert resultat.slug == attendu, f"{texte!r} -> {resultat.slug} ({resultat.scores})"
    if attendu is None:
        assert resultat.methode == "aucune"
    else:
        assert resultat.methode == "regles"
        assert 0 < resultat.confiance <= 1


def test_phrase_ambigue_ne_tranche_pas():
    """« avoiding » ne doit pas être classé « grossesse ».

    Le score de « grossesse » vient du mot lui-même présent dans la phrase ;
    l'expression « éviter une grossesse » doit l'emporter, faute de quoi
    l'utilisatrice serait envoyée vers le parcours grossesse au lieu du
    parcours protection.
    """
    resultat = classer_par_regles("quelle pilule pour éviter une grossesse ?")
    assert resultat.slug == "protection"


def test_relation_imposee_va_vers_aide():
    """Une phrase contenant « impose » et « rapport » doit pencher vers l'aide.

    C'est le parcours qui oriente vers un professionnel et une structure, donc
    le plus pertinent en cas de non-consentement.
    """
    resultat = classer_par_regles("il m'a imposé un rapport")
    assert resultat.slug == "aide"


def test_suivi_sans_indice_lexical():
    """Une question de suivi sans mot-clé n'est pas devinée.

    « à quelle semaine suis-je ? » ne contient aucun indice. Les règles doivent
    rester silencieuses et laisser le repli au modèle : inventer un parcours
    ferait afficher à l'utilisatrice un contenu qui ne répond pas à sa demande.
    """
    resultat = classer_par_regles("à quelle semaine suis-je ?")
    assert resultat.slug is None


def test_repli_sur_la_balise_du_modele():
    """Sans indice lexical, la balise du modèle est utilisée."""
    resultat = classer("à quelle semaine suis-je ?", fallback_modele="grossesse")
    assert resultat.slug == "grossesse"
    assert resultat.methode == "modele"


def test_les_regles_passent_avant_la_balise():
    """Un indice lexical fiable prime sur la balise du modèle.

    Le modèle peut se tromper : mieux vaut sa réponse quand les règles sont
    sûres, l'inverse étant le risque d'un contenu hors sujet.
    """
    resultat = classer("quelle pilule pour éviter une grossesse ?", "grossesse")
    assert resultat.slug == "protection"
    assert resultat.methode == "regles"


def test_balise_inconnue_ignoree():
    resultat = classer("bonjour", fallback_modele="inexistant")
    assert resultat.slug is None
    assert resultat.methode == "aucune"


@pytest.mark.parametrize(
    "brut,attendu_texte,attendu_slug",
    [
        ("Réponse.\nPARCOURS: grossesse", "Réponse.", "grossesse"),
        ("Réponse.\n\nPARCOURS: protection\n", "Réponse.", "protection"),
        ("Réponse.\nparcours: AIDE", "Réponse.", "aide"),
        ("Pas de balise.", "Pas de balise.", None),
        # Une balise mal formée ne doit jamaisbecquer dans l'interface.
        ("Réponse.\nPARCOURS: nawak", "Réponse.\nPARCOURS: nawak", None),
        # Réponse réduite à la balise : on ne vide pas la réponse.
        ("PARCOURS: corps", "PARCOURS: corps", None),
    ],
)
def test_extraction_de_la_balise(brut, attendu_texte, attendu_slug):
    texte, slug = extraire_balise(brut)
    assert texte == attendu_texte
    assert slug == attendu_slug


def test_les_quatre_parcours_du_cdc_sont_couverts():
    """Le cahier des charges décrit quatre parcours : ils doivent tous être
    atteignables par le classifieur."""
    constates = {classer_par_regles(texte).slug for texte, attendu in CAS if attendu}
    assert constates == set(PARCOURS_SLUGS)


def test_representation_booleenne():
    assert bool(Classification("corps", 1.0, "regles", {})) is True
    assert bool(Classification(None, 0.0, "aucune", {})) is False
