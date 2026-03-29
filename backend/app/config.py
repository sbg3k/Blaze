"""
Centralised application settings.
All values are read from environment variables (or a .env file via python-dotenv).
Missing required vars raise at import time so the app fails fast on bad config.
"""
import os
from dotenv import load_dotenv

load_dotenv()


def _require(key: str) -> str:
    value = os.getenv(key, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {key}")
    return value


def _optional(key: str, default: str = "") -> str:
    return os.getenv(key, default).strip()


def _optional_bool(key: str, default: bool = False) -> bool:
    raw_value = os.getenv(key)
    if raw_value is None:
        return default
    return raw_value.strip().lower() in {"1", "true", "yes", "on"}


def _build_virtual_account_url() -> str:
    explicit = _optional("ISW_VIRTUAL_ACCOUNT_URL")
    if explicit:
        return explicit.rstrip("/")

    base = _optional("ISW_QA_URL")
    if not base:
        return ""

    normalized = base.rstrip("/")
    if normalized.endswith("/api/v1/payable/virtualaccount"):
        return normalized
    return f"{normalized}/api/v1/payable/virtualaccount"


# -- Database ------------------------------------------------------------------
# Supabase connection-pooler URI (port 6543), e.g.:
#   postgresql://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:6543/postgres
DATABASE_URL: str = _require("DATABASE_URL")

# -- Security ------------------------------------------------------------------
SECRET_KEY: str = _require("SECRET_KEY")
BVN_SALT: str   = _require("BVN_SALT")

# -- Email / SMTP --------------------------------------------------------------
SMTP_HOST: str = _require("SMTP_HOST")
SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER: str = _require("SMTP_USER")
SMTP_PASS: str = _require("SMTP_PASS")

# Interswitch identity verification
ISW_CLIENT_ID: str = _require("ISW_CLIENT_ID")
ISW_CLIENT_SECRET: str = _require("ISW_CLIENT_SECRET")
ISW_TOKEN_URL: str = _optional(
    "ISW_TOKEN_URL",
    "https://passport-v2.k8.isw.la/passport/oauth/token",
)
ISW_BVN_VERIFY_URL: str = _optional(
    "ISW_BVN_VERIFY_URL",
    "https://api-marketplace-routing.k8.isw.la/marketplace-routing/api/v1/verify/identity/bvn",
)
ISW_TIMEOUT_SECONDS: float = float(_optional("ISW_TIMEOUT_SECONDS", "15"))

# Interswitch wallet / virtual-account settings
ISW_MERCHANT_CODE: str = _optional("ISW_MERCHANT_CODE")
ISW_QA_URL: str = _optional("ISW_QA_URL")
ISW_QA_CLIENT_ID: str = _optional("ISW_QA_CLIENT_ID")
ISW_QA_CLIENT_SECRET: str = _optional("ISW_QA_CLIENT_SECRET")
ISW_VIRTUAL_ACCOUNT_URL: str = _build_virtual_account_url()
ISW_ALLOW_STATIC_VIRTUAL_ACCOUNT_FALLBACK: bool = _optional_bool(
    "ISW_ALLOW_STATIC_VIRTUAL_ACCOUNT_FALLBACK",
    True,
)
ISW_FORCE_STATIC_VIRTUAL_ACCOUNT: bool = _optional_bool(
    "ISW_FORCE_STATIC_VIRTUAL_ACCOUNT",
    False,
)
STATIC_VIRTUAL_ACCOUNT_BANK_NAME: str = _optional(
    "STATIC_VIRTUAL_ACCOUNT_BANK_NAME",
    "Blaze Demo Bank",
)
STATIC_VIRTUAL_ACCOUNT_BANK_CODE: str = _optional(
    "STATIC_VIRTUAL_ACCOUNT_BANK_CODE",
    "999",
)

# -- Token / OTP lifetimes -----------------------------------------------------
ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
REFRESH_TOKEN_EXPIRE_DAYS: int   = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS",   "30"))
OTP_EXPIRY_MINUTES: int          = int(os.getenv("OTP_EXPIRY_MINUTES",          "5"))
OTP_RATE_LIMIT_SECONDS: int      = int(os.getenv("OTP_RATE_LIMIT_SECONDS",      "60"))

# -- CORS ----------------------------------------------------------------------
# Comma-separated allowed origins, e.g. "https://app.example.com,http://localhost:3000"
_raw_origins: str          = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000")
ALLOWED_ORIGINS: list[str] = [o.strip() for o in _raw_origins.split(",") if o.strip()]
