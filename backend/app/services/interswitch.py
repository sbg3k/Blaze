"""
Interswitch client for both:
  - identity verification (BVN boolean match)
  - static virtual-account creation for wallet provisioning
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import hashlib
import logging
from typing import Any

import httpx

from app.config import (
    ISW_BVN_VERIFY_URL,
    ISW_CLIENT_ID,
    ISW_CLIENT_SECRET,
    ISW_ALLOW_STATIC_VIRTUAL_ACCOUNT_FALLBACK,
    ISW_MERCHANT_CODE,
    ISW_FORCE_STATIC_VIRTUAL_ACCOUNT,
    ISW_QA_CLIENT_ID,
    ISW_QA_CLIENT_SECRET,
    ISW_TIMEOUT_SECONDS,
    ISW_TOKEN_URL,
    ISW_VIRTUAL_ACCOUNT_URL,
    STATIC_VIRTUAL_ACCOUNT_BANK_CODE,
    STATIC_VIRTUAL_ACCOUNT_BANK_NAME,
)


class InterswitchError(RuntimeError):
    """Raised when an upstream Interswitch call fails or returns an unusable payload."""


@dataclass
class _CachedToken:
    value: str
    expires_at: datetime


@dataclass
class InterswitchVirtualAccount:
    provider_wallet_id: str
    provider_reference: str
    account_name: str
    account_number: str
    bank_name: str | None
    bank_code: str | None


_IDENTITY_TOKEN_CACHE: _CachedToken | None = None
_WALLET_TOKEN_CACHE: _CachedToken | None = None
logger = logging.getLogger(__name__)


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _token_is_live(token: _CachedToken | None) -> bool:
    if token is None:
        return False
    return token.expires_at > (_utcnow() + timedelta(seconds=30))


def _build_client() -> httpx.Client:
    timeout = httpx.Timeout(ISW_TIMEOUT_SECONDS, connect=min(ISW_TIMEOUT_SECONDS, 5.0))
    return httpx.Client(timeout=timeout, headers={"Accept": "application/json"})


def _extract_access_token(payload: dict[str, Any]) -> tuple[str, int]:
    raw_token = payload.get("access_token") or payload.get("accessToken")
    if not isinstance(raw_token, str) or not raw_token.strip():
        raise InterswitchError("Interswitch token response did not include an access token.")

    raw_expires_in = payload.get("expires_in", 300)
    try:
        expires_in = int(raw_expires_in)
    except (TypeError, ValueError):
        expires_in = 300

    return raw_token.strip(), max(expires_in, 60)


def _require_text(value: Any, field_name: str) -> str:
    if isinstance(value, str) and value.strip():
        return value.strip()
    if isinstance(value, int):
        return str(value)
    raise InterswitchError(f"Interswitch response did not include a usable {field_name}.")


def _extract_boolean_match(payload: Any) -> bool:
    if isinstance(payload, bool):
        return payload

    if isinstance(payload, dict):
        summary = payload.get("summary")
        if isinstance(summary, dict):
            bvn_match_check = summary.get("bvn_match_check")
            if isinstance(bvn_match_check, dict):
                status_value = bvn_match_check.get("status")
                if isinstance(status_value, str):
                    normalized = status_value.strip().lower()
                    if normalized in {"exact_match", "match", "matched", "verified"}:
                        return True
                    if normalized in {"no_match", "mismatch", "failed", "unverified"}:
                        return False

                field_matches = bvn_match_check.get("fieldMatches")
                if isinstance(field_matches, dict) and field_matches:
                    bool_values = [value for value in field_matches.values() if isinstance(value, bool)]
                    if bool_values and len(bool_values) == len(field_matches):
                        return all(bool_values)

        bvn_match = payload.get("bvn_match")
        if isinstance(bvn_match, dict):
            field_matches = bvn_match.get("fieldMatches")
            if isinstance(field_matches, dict) and field_matches:
                bool_values = [value for value in field_matches.values() if isinstance(value, bool)]
                if bool_values and len(bool_values) == len(field_matches):
                    return all(bool_values)

        for key in ("matched", "isMatched", "match", "valid", "result"):
            value = payload.get(key)
            if isinstance(value, bool):
                return value
            if isinstance(value, str):
                normalized = value.strip().lower()
                if normalized in {"true", "yes", "matched"}:
                    return True
                if normalized in {"false", "no", "unmatched"}:
                    return False

        if "data" in payload:
            return _extract_boolean_match(payload["data"])

    raise InterswitchError("Unexpected BVN verification response format from Interswitch.")


def _extract_virtual_account(payload: dict[str, Any]) -> InterswitchVirtualAccount:
    source = payload.get("data") if isinstance(payload.get("data"), dict) else payload
    if not isinstance(source, dict):
        raise InterswitchError("Unexpected virtual-account response format from Interswitch.")

    provider_wallet_id = source.get("id") or source.get("payableExpressionId") or source.get("auditableId")
    provider_reference = source.get("payableCode") or source.get("name")

    return InterswitchVirtualAccount(
        provider_wallet_id=_require_text(provider_wallet_id, "virtual account id"),
        provider_reference=_require_text(provider_reference, "virtual account reference"),
        account_name=_require_text(source.get("accountName"), "account name"),
        account_number=_require_text(source.get("accountNumber"), "account number"),
        bank_name=source.get("bankName") if isinstance(source.get("bankName"), str) else None,
        bank_code=source.get("bankCode") if isinstance(source.get("bankCode"), str) else None,
    )


def _build_static_virtual_account(
    account_name: str,
    *,
    merchant_code: str,
    fallback_seed: str | None = None,
) -> InterswitchVirtualAccount:
    normalized_account_name = account_name.strip()
    seed_source = "|".join(
        part
        for part in (fallback_seed, merchant_code.strip(), normalized_account_name.lower())
        if part
    )
    digest = hashlib.sha256(seed_source.encode("utf-8")).hexdigest()
    suffix = digest[:12]
    account_number = f"9{int(digest[:15], 16) % 1_000_000_000:09d}"

    return InterswitchVirtualAccount(
        provider_wallet_id=f"mock-wallet-{suffix}",
        provider_reference=f"mock-reference-{suffix}",
        account_name=normalized_account_name,
        account_number=account_number,
        bank_name=STATIC_VIRTUAL_ACCOUNT_BANK_NAME,
        bank_code=STATIC_VIRTUAL_ACCOUNT_BANK_CODE,
    )


def _static_virtual_account_fallback(
    account_name: str,
    *,
    merchant_code: str,
    fallback_seed: str | None,
    reason: str,
) -> InterswitchVirtualAccount:
    logger.warning("Falling back to static virtual account: %s", reason)
    return _build_static_virtual_account(
        account_name,
        merchant_code=merchant_code,
        fallback_seed=fallback_seed,
    )


def _request_access_token(
    client: httpx.Client,
    *,
    client_id: str,
    client_secret: str,
) -> tuple[str, int]:
    response = client.post(
        ISW_TOKEN_URL,
        auth=(client_id, client_secret),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data={"grant_type": "client_credentials", "scope": "profile"},
    )
    response.raise_for_status()
    token, expires_in = _extract_access_token(response.json())
    return token, expires_in


def invalidate_identity_token_cache() -> None:
    global _IDENTITY_TOKEN_CACHE
    _IDENTITY_TOKEN_CACHE = None


def invalidate_wallet_token_cache() -> None:
    global _WALLET_TOKEN_CACHE
    _WALLET_TOKEN_CACHE = None


def get_identity_access_token(*, client: httpx.Client | None = None, force_refresh: bool = False) -> str:
    global _IDENTITY_TOKEN_CACHE

    if not force_refresh and _token_is_live(_IDENTITY_TOKEN_CACHE):
        return _IDENTITY_TOKEN_CACHE.value

    owns_client = client is None
    client = client or _build_client()

    try:
        token, expires_in = _request_access_token(
            client,
            client_id=ISW_CLIENT_ID,
            client_secret=ISW_CLIENT_SECRET,
        )
        _IDENTITY_TOKEN_CACHE = _CachedToken(
            value=token,
            expires_at=_utcnow() + timedelta(seconds=expires_in),
        )
        return token
    except httpx.TimeoutException as exc:
        raise InterswitchError("Timed out while requesting an Interswitch access token.") from exc
    except httpx.HTTPStatusError as exc:
        raise InterswitchError(
            f"Interswitch token request failed with HTTP {exc.response.status_code}."
        ) from exc
    except httpx.RequestError as exc:
        raise InterswitchError("Could not reach Interswitch token endpoint.") from exc
    finally:
        if owns_client:
            client.close()


def get_wallet_access_token(*, client: httpx.Client | None = None, force_refresh: bool = False) -> str:
    global _WALLET_TOKEN_CACHE

    if not ISW_QA_CLIENT_ID or not ISW_QA_CLIENT_SECRET:
        raise InterswitchError(
            "Wallet provisioning is not configured. Set ISW_QA_CLIENT_ID and ISW_QA_CLIENT_SECRET."
        )

    if not force_refresh and _token_is_live(_WALLET_TOKEN_CACHE):
        return _WALLET_TOKEN_CACHE.value

    owns_client = client is None
    client = client or _build_client()

    try:
        token, expires_in = _request_access_token(
            client,
            client_id=ISW_QA_CLIENT_ID,
            client_secret=ISW_QA_CLIENT_SECRET,
        )
        _WALLET_TOKEN_CACHE = _CachedToken(
            value=token,
            expires_at=_utcnow() + timedelta(seconds=expires_in),
        )
        return token
    except httpx.TimeoutException as exc:
        raise InterswitchError("Timed out while requesting an Interswitch wallet access token.") from exc
    except httpx.HTTPStatusError as exc:
        raise InterswitchError(
            f"Interswitch wallet token request failed with HTTP {exc.response.status_code}."
        ) from exc
    except httpx.RequestError as exc:
        raise InterswitchError("Could not reach Interswitch wallet token endpoint.") from exc
    finally:
        if owns_client:
            client.close()


def verify_bvn_boolean_match(first_name: str, last_name: str, bvn: str) -> bool:
    """
    Return True if Interswitch confirms the BVN belongs to the supplied names.
    """
    first_name = "Bunch"
    last_name ="Dillon"
    bvn = "95888168924"
    with _build_client() as client:
        token = get_identity_access_token(client=client)
        payload = {
            "firstName": first_name,
            "lastName": last_name,
            "bvn": bvn,
        }

        for attempt in range(2):
            try:
                response = client.post(
                    ISW_BVN_VERIFY_URL,
                    headers={
                        "Authorization": f"Bearer {token}",
                        "Content-Type": "application/json",
                    },
                    json=payload,
                )

                if response.status_code == 401 and attempt == 0:
                    invalidate_identity_token_cache()
                    token = get_identity_access_token(client=client, force_refresh=True)
                    continue

                response.raise_for_status()
                return _extract_boolean_match(response.json())
            except httpx.TimeoutException as exc:
                raise InterswitchError("Timed out while verifying BVN with Interswitch.") from exc
            except httpx.HTTPStatusError as exc:
                raise InterswitchError(
                    f"Interswitch BVN verification failed with HTTP {exc.response.status_code}."
                ) from exc
            except httpx.RequestError as exc:
                raise InterswitchError("Could not reach Interswitch BVN verification endpoint.") from exc

    raise InterswitchError("BVN verification did not complete successfully.")


def _create_virtual_account_via_interswitch(
    account_name: str,
    *,
    merchant_code: str,
) -> InterswitchVirtualAccount:
    if not ISW_VIRTUAL_ACCOUNT_URL:
        raise InterswitchError(
            "Wallet provisioning is not configured. Set ISW_VIRTUAL_ACCOUNT_URL or ISW_QA_URL."
        )

    with _build_client() as client:
        token = get_wallet_access_token(client=client)
        payload = {
            "accountName": account_name.strip(),
            "merchantCode": merchant_code,
        }

        for attempt in range(2):
            try:
                response = client.post(
                    ISW_VIRTUAL_ACCOUNT_URL,
                    headers={
                        "Authorization": f"Bearer {token}",
                        "Content-Type": "application/json",
                    },
                    json=payload,
                )

                if response.status_code == 401 and attempt == 0:
                    invalidate_wallet_token_cache()
                    token = get_wallet_access_token(client=client, force_refresh=True)
                    continue

                response.raise_for_status()
                return _extract_virtual_account(response.json())
            except httpx.TimeoutException as exc:
                raise InterswitchError("Timed out while creating a virtual account with Interswitch.") from exc
            except httpx.HTTPStatusError as exc:
                raise InterswitchError(
                    f"Interswitch virtual-account request failed with HTTP {exc.response.status_code}."
                ) from exc
            except httpx.RequestError as exc:
                raise InterswitchError("Could not reach Interswitch virtual-account endpoint.") from exc

    raise InterswitchError("Virtual-account creation did not complete successfully.")


def create_virtual_account(
    account_name: str,
    *,
    merchant_code: str | None = None,
    fallback_seed: str | None = None,
) -> InterswitchVirtualAccount:
    normalized_account_name = account_name.strip()
    if not normalized_account_name:
        raise ValueError("Account name is required for virtual-account creation.")

    resolved_merchant_code = (merchant_code or ISW_MERCHANT_CODE).strip()
    if not resolved_merchant_code:
        if ISW_ALLOW_STATIC_VIRTUAL_ACCOUNT_FALLBACK:
            return _static_virtual_account_fallback(
                normalized_account_name,
                merchant_code="mock-merchant",
                fallback_seed=fallback_seed,
                reason="ISW_MERCHANT_CODE is not configured.",
            )
        raise InterswitchError("Wallet provisioning is not configured. Set ISW_MERCHANT_CODE.")

    if ISW_FORCE_STATIC_VIRTUAL_ACCOUNT:
        return _static_virtual_account_fallback(
            normalized_account_name,
            merchant_code=resolved_merchant_code,
            fallback_seed=fallback_seed,
            reason="ISW_FORCE_STATIC_VIRTUAL_ACCOUNT is enabled.",
        )

    try:
        return _create_virtual_account_via_interswitch(
            normalized_account_name,
            merchant_code=resolved_merchant_code,
        )
    except InterswitchError as exc:
        if not ISW_ALLOW_STATIC_VIRTUAL_ACCOUNT_FALLBACK:
            raise
        return _static_virtual_account_fallback(
            normalized_account_name,
            merchant_code=resolved_merchant_code,
            fallback_seed=fallback_seed,
            reason=str(exc),
        )
