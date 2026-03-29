from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


WalletStatus = Literal["not_started", "pending", "active", "failed"]
OnboardingNextStep = Literal[
    "verify_bvn",
    "provision_wallet",
    "retry_wallet_provisioning",
    "completed",
]


class WalletResponse(BaseModel):
    id: str
    user_id: str | None
    group_id: str | None
    provider: str
    provider_wallet_id: str | None
    provider_reference: str | None
    account_name: str
    account_number: str | None
    amount: float | None
    bank_name: str | None
    bank_code: str | None
    status: WalletStatus
    failure_reason: str | None
    provisioned_at: datetime | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

class FundWalletRequest(BaseModel):
    amount: float = Field(..., gt=0, description="Amount to credit, must be positive")
    reference: str = Field(..., min_length=1, max_length=100)
    description: str | None = None

class TransactionResponse(BaseModel):
    id: str
    wallet_id: str
    type: str
    amount: float
    reference: str
    description: str | None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
