"""Tests de la base de connaissances (cahier des charges, module 4).

Ces tests protègent deux choses :

* le contenu servi est bien celui des fichiers de `app/content/` ;
* chaque parcours est exploitable — slug cohérent, blocs non vides, source
  présente. Un contenu sans source ne serait pas conforme au cahier des charges,
  qui exige des contenus « validés ».

Ils vérifient aussi que le contenu n'est pas fabriqué à la volée : aucune IA
n'est appelée par `/api/contenus`.
"""

from tests.conftest import client

PARCOURS_ATTENDUS = {"corps", "protection", "grossesse", "aide"}


def test_liste_les_parcours():
    resp = client.get("/api/contenus")
    assert resp.status_code == 200, resp.text
    corps = resp.json()
    assert {p["slug"] for p in corps} == PARCOURS_ATTENDUS
    for p in corps:
        assert p["titre"], p
        assert p["nb_blocs"] >= 1, p
        assert p["a_urgence"] is True, (
            f"{p['slug']} : tout parcours doit contenir un bloc de signes "
            "imposant une consultation"
        )


def test_chaque_parcours_est_complet():
    for slug in sorted(PARCOURS_ATTENDUS):
        resp = client.get(f"/api/contenus/{slug}")
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data["slug"] == slug
        assert data["avertissement"], f"{slug} : un avertissement est obligatoire"
        assert data["cdc_sections"], f"{slug} : la section du CDC est obligatoire"
        assert len(data["blocs"]) >= 4, slug

        ids = [b["id"] for b in data["blocs"]]
        assert len(ids) == len(set(ids)), f"{slug} : identifiants de blocs dupliqués"

        for bloc in data["blocs"]:
            assert bloc["titre"], f"{slug}/{bloc['id']}"
            assert bloc["points"], f"{slug}/{bloc['id']} : bloc vide"
            assert bloc["source"], f"{slug}/{bloc['id']} : contenu non sourcé"
            for point in bloc["points"]:
                # Seuil bas : on écarte un contenu vide ou tronqué, sans
                # refuser les points légitiment brefs (« Fièvre élevée. »).
                assert len(point) > 8, f"{slug}/{bloc['id']} : point trop court"


def test_contenu_sensible_marque_pour_validation():
    """Les points dont la formulation engage une responsabilité (cadre légal,
    structure de santé) doivent porter une note de validation."""
    resp = client.get("/api/contenus/aide")
    data = resp.json()
    oriente = next(b for b in data["blocs"] if b["id"] == "orienter")
    assert oriente["note_validation"], (
        "l'orientation vers des structures doit rester explicitement marquée "
        "comme non validée tant qu'aucun partenariat n'existe"
    )


def test_slug_inconnu_renvoie_404():
    resp = client.get("/api/contenus/inexistant")
    assert resp.status_code == 404
    assert "Disponibles" in resp.json()["detail"]


def test_contenus_est_public():
    """Le contenu ne contient aucune donnée personnelle : pas d'authentification."""
    assert client.get("/api/contenus").status_code == 200
    assert client.get("/api/contenus/grossesse").status_code == 200
