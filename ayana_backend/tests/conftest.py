"""Tests de l'API AYANA.

Pour lancer ::
    python -m pytest -q

En mode test, la base SQLite en mémoire est recréée pour chaque session.
"""

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.base import Base, get_db
from app.main import app

# StaticPool : partage la MÊME base en mémoire entre toutes les connexions
# (indispensable car l'app tourne dans un autre thread que le test).
engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=engine)

from app.models.user import User  # noqa: E402   (enregistre les tables)


def override_get_db():
    db = TestingSession()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
Base.metadata.create_all(bind=engine)

client = TestClient(app)


def register_user(pseudo="Jolie", phone="90909090", password="secret6"):
    """Helper : crée un compte et retourne le jeton."""
    resp = client.post(
        "/api/auth/register",
        json={
            "full_name": "Ama Mènou",
            "pseudo": pseudo,
            "phone": phone,
            "password": password,
            "consent": True,
        },
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["access_token"]