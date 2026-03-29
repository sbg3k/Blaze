import os
import unittest
from datetime import datetime, timezone
from unittest.mock import patch

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool


for key, value in {
    "DATABASE_URL": "sqlite://",
    "SECRET_KEY": "test-secret",
    "BVN_SALT": "test-bvn-salt",
    "SMTP_HOST": "smtp.example.com",
    "SMTP_PORT": "587",
    "SMTP_USER": "user@example.com",
    "SMTP_PASS": "password",
    "ISW_CLIENT_ID": "client-id",
    "ISW_CLIENT_SECRET": "client-secret",
}.items():
    os.environ.setdefault(key, value)


import app.models  # noqa: E402,F401
from app.database import Base  # noqa: E402
from app.models.group import Group  # noqa: E402
from app.models.kyc import KYC  # noqa: E402
from app.models.user import User  # noqa: E402
from app.schemas.wallet import WalletResponse  # noqa: E402
from app.services.interswitch import InterswitchError, InterswitchVirtualAccount  # noqa: E402
from app.services.wallet import (  # noqa: E402
    WalletProvisioningError,
    get_wallet_by_group_id,
    get_wallet_by_user_id,
    provision_group_wallet,
    provision_user_wallet,
)


class WalletServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.engine = create_engine(
            "sqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        self.SessionLocal = sessionmaker(bind=self.engine, autocommit=False, autoflush=False)
        Base.metadata.create_all(bind=self.engine)
        self.db: Session = self.SessionLocal()

        self.user = User(
            id="user-1",
            email="wallet@example.com",
            username="wallet_user",
            first_name="Dillon",
            last_name="Bunch",
            password_hash="hashed",
            is_active=True,
            verified_at=datetime.now(timezone.utc),
            created_at=datetime.now(timezone.utc),
        )
        self.db.add(self.user)
        self.group = Group(
            id="group-1",
            name="Alpha Savers",
            description="Savings group",
            type="public",
            owner_id=self.user.id,
            is_active=True,
            monthly_con=1000,
            created_at=datetime.now(timezone.utc),
        )
        self.db.add(self.group)
        self.db.add(
            KYC(
                id="kyc-1",
                user_id=self.user.id,
                bvn_hash="hashed-bvn",
                status="verified",
            )
        )
        self.db.commit()

    def tearDown(self) -> None:
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)
        self.engine.dispose()

    def test_provision_user_wallet_persists_active_wallet(self) -> None:
        with patch(
            "app.services.wallet.create_virtual_account",
            return_value=InterswitchVirtualAccount(
                provider_wallet_id="404102",
                provider_reference="VIRTUAL_ACCOUNTMX2762031774566874219",
                account_name="Dillon Bunch",
                account_number="7620601622",
                bank_name="Wema Bank",
                bank_code="WEMA",
            ),
        ):
            wallet = provision_user_wallet(self.db, self.user)

        self.assertEqual(wallet.status, "active")
        self.assertEqual(wallet.account_number, "7620601622")
        self.assertEqual(wallet.provider_reference, "VIRTUAL_ACCOUNTMX2762031774566874219")
        self.assertIsNotNone(wallet.provisioned_at)

    def test_provision_user_wallet_persists_failed_wallet_state(self) -> None:
        with patch(
            "app.services.wallet.create_virtual_account",
            side_effect=InterswitchError("provider unavailable"),
        ):
            with self.assertRaises(WalletProvisioningError):
                provision_user_wallet(self.db, self.user)

        wallet = get_wallet_by_user_id(self.user.id, self.db)
        self.assertIsNotNone(wallet)
        assert wallet is not None
        self.assertEqual(wallet.status, "failed")
        self.assertEqual(wallet.failure_reason, "provider unavailable")

    def test_provision_user_wallet_can_suppress_upstream_failures(self) -> None:
        with patch(
            "app.services.wallet.create_virtual_account",
            side_effect=InterswitchError("temporary upstream issue"),
        ):
            wallet = provision_user_wallet(self.db, self.user, raise_on_failure=False)

        self.assertEqual(wallet.status, "failed")
        self.assertEqual(wallet.failure_reason, "temporary upstream issue")

    def test_provision_group_wallet_persists_active_wallet(self) -> None:
        with patch(
            "app.services.wallet.create_virtual_account",
            return_value=InterswitchVirtualAccount(
                provider_wallet_id="mock-group-wallet",
                provider_reference="mock-group-reference",
                account_name="Alpha Savers",
                account_number="9000000001",
                bank_name="Blaze Demo Bank",
                bank_code="999",
            ),
        ):
            wallet = provision_group_wallet(self.db, self.group)

        self.assertEqual(wallet.status, "active")
        self.assertIsNone(wallet.user_id)
        self.assertEqual(wallet.group_id, self.group.id)
        self.assertEqual(wallet.account_number, "9000000001")

        stored_wallet = get_wallet_by_group_id(self.group.id, self.db)
        self.assertIsNotNone(stored_wallet)
        response = WalletResponse.model_validate(wallet)
        self.assertIsNone(response.user_id)
        self.assertEqual(response.group_id, self.group.id)


if __name__ == "__main__":
    unittest.main()
