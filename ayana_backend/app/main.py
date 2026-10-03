"""Point d'entrée FastAPI de l'application AYANA."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import auth, chat, content, users
from app.core.config import settings
from app.db.base import Base, engine


def create_app() -> FastAPI:
    Base.metadata.create_all(bind=engine)

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description=(
            "API backend d'AYANA — assistant d'éducation et d'accompagnement "
            "en santé sexuelle, reproductive et maternelle."
        ),
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # à restreindre en production
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(auth.router)
    app.include_router(users.router)
    app.include_router(chat.router)
    app.include_router(content.router)

    @app.get("/api/health", tags=["health"])
    def health() -> dict[str, str]:
        return {"status": "ok", "version": settings.app_version}

    return app


app = create_app()