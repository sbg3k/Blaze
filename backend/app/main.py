"""
Application entrypoint.

Startup order:
  1. Import all models (populates SQLAlchemy metadata for Alembic).
  2. Create the FastAPI app with CORS and global exception handling.
  3. Register routers.
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.openapi.docs import (
    get_swagger_ui_html,
    get_swagger_ui_oauth2_redirect_html,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from swagger_ui_bundle import swagger_ui_path

import app.models  # noqa: F401
from app.config import ALLOWED_ORIGINS
from app.database import Base, engine
from app.routes import auth, groups, home, kyc, wallet, user, cycle
from app.scheduler import start_scheduler

# -- App -----------------------------------------------------------------------


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    scheduler = start_scheduler()
    try:
        yield
    finally:
        scheduler.shutdown(wait=False)


app = FastAPI(
    title       = "Auth API",
    version     = "1.0.0",
    description = "Authentication, KYC, and group management API.",
    docs_url=None,
    lifespan=lifespan
)
app.openapi_version = "3.0.3"

app.mount("/docs-assets", StaticFiles(directory=swagger_ui_path), name="docs-assets")


# -- CORS ----------------------------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins     = ALLOWED_ORIGINS,
    allow_credentials = True,
    allow_methods     = ["*"],
    allow_headers     = ["*"],
)

# -- Global exception handlers -------------------------------------------------

@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    Catch-all for unhandled exceptions.
    Returns a generic 500 so internal error details are never leaked to clients.
    In production, plug in Sentry / structured logging here.
    """
    # TODO: log exc with your logging/APM framework
    return JSONResponse(
        status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
        content     = {"detail": "An unexpected error occurred. Please try again later."},
    )

# -- Routers -------------------------------------------------------------------

@app.get("/docs", include_in_schema=False)
async def custom_swagger_ui_html():
    return get_swagger_ui_html(
        openapi_url=app.openapi_url,
        title=f"{app.title} - Swagger UI",
        oauth2_redirect_url=app.swagger_ui_oauth2_redirect_url,
        swagger_js_url="/docs-assets/swagger-ui-bundle.js",
        swagger_css_url="/docs-assets/swagger-ui.css",
    )


@app.get(app.swagger_ui_oauth2_redirect_url, include_in_schema=False)
async def swagger_ui_redirect():
    return get_swagger_ui_oauth2_redirect_html()

app.include_router(home.router,   prefix="",   tags=["Docs"])
app.include_router(auth.router,   prefix="/auth",   tags=["Auth"])
app.include_router(kyc.router,    prefix="/kyc",    tags=["KYC"])
app.include_router(wallet.router, prefix="/wallet", tags=["Wallet"])
app.include_router(groups.router, prefix="/groups", tags=["Groups"])
app.include_router(user.router,   prefix="/user",   tags=["User"])
app.include_router(cycle.router, tags=["Cycles"])


# -- Health check --------------------------------------------------------------

@app.get("/health", tags=["Health"], include_in_schema=False)
def health() -> dict:
    return {"status": "ok"}
