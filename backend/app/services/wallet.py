from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.kyc import KYC
from app.models.user import User
from app.models.wallet import Wallet
from app.models.transaction import Transaction
from app.services.interswitch import InterswitchError, create_virtual_account


class WalletProvisioningError(RuntimeError):
    """Raised when wallet provisioning fails after local state has been persisted."""


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def get_wallet_by_user_id(user_id: str, db: Session) -> Wallet | None:
    return db.query(Wallet).filter(Wallet.user_id == user_id).first()


def get_wallet_status_value(wallet: Wallet | None) -> str:
    if wallet is None:
        return "not_started"
    if wallet.status in {"pending", "active", "failed"}:
        return wallet.status
    return "pending"


def provision_user_wallet(
    db: Session,
    user: User,
    *,
    raise_on_failure: bool = True,
) -> Wallet:
    kyc = db.query(KYC).filter(KYC.user_id == user.id).first()
    if not kyc or not kyc.is_verified:
        raise ValueError("Complete BVN verification before provisioning a wallet.")

    existing = get_wallet_by_user_id(user.id, db)
    if existing and existing.is_active:
        return existing

    now = _utcnow()
    account_name = " ".join(part.strip() for part in [user.first_name, user.last_name] if part.strip())

    wallet = existing or Wallet(
        user_id=user.id,
        provider="interswitch",
        account_name=account_name,
        status="pending",
        created_at=now,
        updated_at=now,
    )
    wallet.provider = "interswitch"
    wallet.account_name = account_name
    wallet.status = "pending"
    wallet.failure_reason = None
    wallet.provider_wallet_id = None
    wallet.provider_reference = None
    wallet.account_number = None
    wallet.bank_name = None
    wallet.bank_code = None
    wallet.provisioned_at = None
    wallet.updated_at = now

    if existing is None:
        db.add(wallet)

    db.commit()
    db.refresh(wallet)

    try:
        virtual_account = create_virtual_account(
            account_name,
            fallback_seed=f"user:{user.id}",
        )
    except InterswitchError as exc:
        wallet.status = "failed"
        wallet.failure_reason = str(exc)
        wallet.updated_at = _utcnow()
        db.commit()
        db.refresh(wallet)

        if raise_on_failure:
            raise WalletProvisioningError(str(exc)) from exc
        return wallet

    wallet.status = "active"
    wallet.provider_wallet_id = virtual_account.provider_wallet_id
    wallet.provider_reference = virtual_account.provider_reference
    wallet.account_number = virtual_account.account_number
    wallet.bank_name = virtual_account.bank_name
    wallet.bank_code = virtual_account.bank_code
    wallet.provisioned_at = _utcnow()
    wallet.updated_at = wallet.provisioned_at
    db.commit()
    db.refresh(wallet)
    return wallet


def get_wallet_by_group_id(group_id: str, db: Session) -> Wallet | None:
    return db.query(Wallet).filter(Wallet.group_id == group_id).first()


def provision_group_wallet(
    db: Session,
    group: "Group",
    *,
    raise_on_failure: bool = True,
) -> Wallet:
    existing = get_wallet_by_group_id(group.id, db)
    if existing and existing.is_active:
        return existing

    now = _utcnow()
    account_name = group.name.strip()

    wallet = existing or Wallet(
        group_id=group.id,
        user_id=None,
        provider="interswitch",
        account_name=account_name,
        status="pending",
        created_at=now,
        updated_at=now,
    )
    wallet.provider = "interswitch"
    wallet.account_name = account_name
    wallet.status = "pending"
    wallet.failure_reason = None
    wallet.provider_wallet_id = None
    wallet.provider_reference = None
    wallet.account_number = None
    wallet.bank_name = None
    wallet.bank_code = None
    wallet.provisioned_at = None
    wallet.updated_at = now

    if existing is None:
        db.add(wallet)

    db.commit()
    db.refresh(wallet)

    try:
        virtual_account = create_virtual_account(
            account_name,
            fallback_seed=f"group:{group.id}",
        )
    except InterswitchError as exc:
        wallet.status = "failed"
        wallet.failure_reason = str(exc)
        wallet.updated_at = _utcnow()
        db.commit()
        db.refresh(wallet)

        if raise_on_failure:
            raise WalletProvisioningError(str(exc)) from exc
        return wallet

    wallet.status = "active"
    wallet.provider_wallet_id = virtual_account.provider_wallet_id
    wallet.provider_reference = virtual_account.provider_reference
    wallet.account_number = virtual_account.account_number
    wallet.bank_name = virtual_account.bank_name
    wallet.bank_code = virtual_account.bank_code
    wallet.provisioned_at = _utcnow()
    wallet.updated_at = wallet.provisioned_at
    db.commit()
    db.refresh(wallet)
    return wallet

def fund_wallet(
    db: Session,
    wallet: Wallet,
    amount: float,
    reference: str,
    description: str | None = None,
) -> Transaction:
    if not wallet.is_active:
        raise ValueError("Cannot fund an inactive wallet.")

    if db.query(Transaction).filter(Transaction.reference == reference).first():
        raise ValueError(f"Transaction with reference '{reference}' already exists.")

    now = _utcnow()
    tx = Transaction(
        wallet_id=wallet.id,
        type="credit",
        amount=amount,
        reference=reference,
        description=description,
        status="success",
        created_at=now,
    )
    wallet.amount = (wallet.amount or 0.0) + amount
    wallet.updated_at = now

    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx
