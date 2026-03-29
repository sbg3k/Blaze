"""
Group routes — thin HTTP layer only.
All validation beyond schema parsing lives in app.services.groups.
"""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.auth import MessageResponse
from app.schemas.groups import (
    CreateGroupRequest,
    GroupRequestResponse,
    GroupResponse,
    GroupSummaryResponse,
    InviteUserRequest,
    MemberResponse,
    MyInviteResponse,
    MyMembershipResponse,
    UpdateMemberRoleRequest,
)
from app.schemas.wallet import WalletResponse, FundWalletRequest, TransactionResponse
from app.services.wallet import (
    get_wallet_by_group_id,
    provision_group_wallet,
    fund_wallet,
    WalletProvisioningError,
)
from app.services import groups as svc
from app.utils.dependencies import get_current_user, get_db

router = APIRouter()


# -- Discovery -----------------------------------------------------------------

@router.get("", response_model=list[GroupSummaryResponse])
def search_groups(
    q:  str     = Query("", description="Search term; omit or leave empty to list all public groups"),
    db: Session = Depends(get_db),
    _:  User    = Depends(get_current_user),
) -> list[GroupSummaryResponse]:
    return svc.search_groups(q, db)


# -- My groups & invites -------------------------------------------------------

@router.get("/me", response_model=list[MyMembershipResponse])
def my_groups(
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> list[MyMembershipResponse]:
    return svc.list_my_groups(current_user, db)


@router.get("/me/invites", response_model=list[MyInviteResponse])
def my_invites(
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> list[MyInviteResponse]:
    return svc.list_my_invites(current_user, db)


@router.post("/me/invites/{request_id}/accept", response_model=MessageResponse)
def accept_invite(
    request_id:   str,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> MessageResponse:
    svc.accept_invite(current_user, request_id, db)
    return MessageResponse(message="Invite accepted. Welcome to the group.")


@router.post("/me/invites/{request_id}/decline", response_model=MessageResponse)
def decline_invite(
    request_id:   str,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> MessageResponse:
    svc.decline_invite(current_user, request_id, db)
    return MessageResponse(message="Invite declined.")


# -- Group management ----------------------------------------------------------

@router.post("", response_model=GroupResponse, status_code=status.HTTP_201_CREATED)
def create_group(
    data:         CreateGroupRequest,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> GroupResponse:
    group = svc.create_group(
        name        = data.name,
        description = data.description,
        type_       = data.type,
        monthly_con = data.monthly_con,
        owner       = current_user,
        db          = db,
    )
    return GroupResponse.model_validate(group)


@router.delete("/{group_id}", response_model=MessageResponse)
def delete_group(
    group_id:     str,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> MessageResponse:
    svc.delete_group(current_user, group_id, db)
    return MessageResponse(message="Group deleted.")


# -- Membership ----------------------------------------------------------------

@router.get("/{group_id}/members", response_model=list[MemberResponse])
def list_members(
    group_id:     str,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> list[MemberResponse]:
    return svc.list_members(current_user, group_id, db)


@router.post("/{group_id}/leave", response_model=MessageResponse)
def leave_group(
    group_id:     str,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> MessageResponse:
    svc.leave_group(current_user, group_id, db)
    return MessageResponse(message="You have left the group.")


@router.delete("/{group_id}/members/{user_id}", response_model=MessageResponse)
def remove_member(
    group_id:     str,
    user_id:      str,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> MessageResponse:
    svc.remove_member(current_user, group_id, user_id, db)
    return MessageResponse(message="Member removed.")


@router.patch("/{group_id}/members/{user_id}/role", response_model=MessageResponse)
def update_role(
    group_id:     str,
    user_id:      str,
    data:         UpdateMemberRoleRequest,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> MessageResponse:
    svc.update_member_role(current_user, group_id, user_id, data.role, db)
    return MessageResponse(message="Role updated.")


# -- Join requests (user → group) ----------------------------------------------

@router.post("/{group_id}/request", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def request_to_join(
    group_id:     str,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> MessageResponse:
    svc.request_to_join(current_user, group_id, db)
    return MessageResponse(message="Join request sent.")


@router.get("/{group_id}/requests", response_model=list[GroupRequestResponse])
def list_join_requests(
    group_id:     str,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> list[GroupRequestResponse]:
    return svc.list_join_requests(current_user, group_id, db)


@router.post("/{group_id}/requests/{request_id}/approve", response_model=MessageResponse)
def approve_request(
    group_id:     str,
    request_id:   str,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> MessageResponse:
    svc.approve_request(current_user, group_id, request_id, db)
    return MessageResponse(message="Request approved.")


@router.post("/{group_id}/requests/{request_id}/reject", response_model=MessageResponse)
def reject_request(
    group_id:     str,
    request_id:   str,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> MessageResponse:
    svc.reject_request(current_user, group_id, request_id, db)
    return MessageResponse(message="Request rejected.")


# -- Invites (admin → user) ----------------------------------------------------

@router.post("/{group_id}/invite", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def invite_user(
    group_id:     str,
    data:         InviteUserRequest,
    current_user: User    = Depends(get_current_user),
    db:           Session = Depends(get_db),
) -> MessageResponse:
    svc.invite_user(current_user, group_id, data.email, data.username, db)
    return MessageResponse(message="Invite sent.")

@router.get("/{group_id}", response_model=GroupResponse)
def get_group(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> GroupResponse:
    group = svc._get_group_or_404(group_id, db)
    svc._require_membership(current_user.id, group_id, db)
    return GroupResponse.model_validate(group)


@router.get("/{group_id}/wallet", response_model=WalletResponse)
def get_group_wallet(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> WalletResponse:
    svc._get_group_or_404(group_id, db)
    svc._require_membership(current_user.id, group_id, db)

    wallet = get_wallet_by_group_id(group_id, db)
    if not wallet:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Group wallet not found.")
    return WalletResponse.model_validate(wallet)


@router.post("/{group_id}/wallet/provision", response_model=WalletResponse)
def provision_group_wallet_route(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> WalletResponse:
    group = svc._get_group_or_404(group_id, db)
    svc._require_admin(current_user.id, group_id, db)

    try:
        wallet = provision_group_wallet(db, group)
    except WalletProvisioningError as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail=str(exc))
    return WalletResponse.model_validate(wallet)


@router.post("/{group_id}/wallet/fund", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def fund_group_wallet(
    group_id: str,
    payload: FundWalletRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> TransactionResponse:
    svc._get_group_or_404(group_id, db)
    svc._require_membership(current_user.id, group_id, db)

    wallet = get_wallet_by_group_id(group_id, db)
    if not wallet:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Group wallet not found.")
    try:
        tx = fund_wallet(db, wallet, payload.amount, payload.reference, payload.description)
    except ValueError as exc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail=str(exc))
    return TransactionResponse.model_validate(tx)
