"""
Group service layer.

All DB access and business-rule enforcement lives here.
Routes are thin: they call one service function, get back a value, return it.

Key rules encoded here:
  - Only public groups accept join requests; private groups require an invite.
  - A user must have verified KYC + a bank statement with sufficient average
    balance to request joining any group.
  - Group owners cannot leave; they must transfer ownership or delete.
  - Admins cannot remove themselves via the remove-member endpoint (use /leave).
  - One pending request/invite per (user, group) pair at a time (DB unique constraint
    + service-layer guard).
"""
import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.bank_statement import BankStatement
from app.models.group import Group, GroupRequest, UserGroup
from app.models.kyc import KYC
from app.models.user import User


# ── Private helpers ───────────────────────────────────────────────────────────

def _get_group_or_404(group_id: str, db: Session) -> Group:
    group = db.query(Group).filter(
        Group.id == group_id,
        Group.is_active == True,  # noqa: E712
    ).first()
    if not group:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Group not found.")
    return group


def _get_membership(user_id: str, group_id: str, db: Session) -> UserGroup | None:
    return db.query(UserGroup).filter(
        UserGroup.user_id  == user_id,
        UserGroup.group_id == group_id,
    ).first()


def _require_membership(user_id: str, group_id: str, db: Session) -> UserGroup:
    membership = _get_membership(user_id, group_id, db)
    if not membership:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not a member of this group.")
    return membership


def _require_admin(user_id: str, group_id: str, db: Session) -> None:
    membership = _require_membership(user_id, group_id, db)
    if membership.role != "admin":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin access required.")


def _resolve_target_user(
    email: str | None,
    username: str | None,
    db: Session,
) -> User:
    if not email and not username:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Provide either email or username.")
    user = (
        db.query(User).filter(User.email    == email).first()    if email
        else db.query(User).filter(User.username == username).first()
    )
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found.")
    if not user.is_active:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "User account is inactive.")
    return user


def _get_pending_request(user_id: str, group_id: str, db: Session) -> GroupRequest | None:
    return db.query(GroupRequest).filter(
        GroupRequest.user_id  == user_id,
        GroupRequest.group_id == group_id,
        GroupRequest.status   == "pending",
    ).first()


def _assert_user_eligible(user_id: str, monthly_con: int, db: Session) -> None:
    """
    Raise HTTP 403 with a precise reason if the user does not meet the group's
    monthly-contribution threshold.

    Eligibility rule:  (average_balance / 3) >= monthly_con
    """
    kyc = db.query(KYC).filter(KYC.user_id == user_id).first()
    if not kyc:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "KYC not found. Complete BVN verification before joining a group.",
        )
    if not kyc.is_verified:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "KYC not verified. Complete verification before joining a group.",
        )

    statement = db.query(BankStatement).filter(BankStatement.user_id == user_id).first()
    if not statement:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "No bank statement found. Generate your statement before joining a group.",
        )

    if (statement.average_balance / 3) < monthly_con:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            f"Insufficient average balance. Required: ₦{monthly_con * 3:,.2f} average balance.",
        )


def _add_member(user_id: str, group_id: str, db: Session) -> None:
    """Create a UserGroup membership row (shared by approve + accept paths)."""
    db.add(UserGroup(
        user_id   = user_id,
        group_id  = group_id,
        role      = "member",
        joined_at = datetime.now(timezone.utc),
    ))


# ── Group CRUD ────────────────────────────────────────────────────────────────

def create_group(
    name:        str,
    description: str | None,
    type_:       str,
    monthly_con: int,
    owner:       User,
    db:          Session,
) -> Group:
    if db.query(Group).filter(Group.name == name).first():
        raise HTTPException(status.HTTP_409_CONFLICT, "Group name already taken.")

    group = Group(
        name        = name,
        description = description,
        type        = type_,
        monthly_con = monthly_con,
        owner_id    = owner.id,
        is_active   = True,
        created_at  = datetime.now(timezone.utc),
    )
    db.add(group)
    db.flush()  # get group.id before adding membership

    # Owner is automatically an admin member
    db.add(UserGroup(
        user_id   = owner.id,
        group_id  = group.id,
        role      = "admin",
        joined_at = datetime.now(timezone.utc),
    ))
    db.commit()
    db.refresh(group)
    return group


def search_groups(query: str, db: Session) -> list[Group]:
    """Case-insensitive substring search over active public groups."""
    return (
        db.query(Group)
        .filter(
            Group.is_active == True,  # noqa: E712
            Group.type      == "public",
            Group.name.ilike(f"%{query}%"),
        )
        .order_by(Group.name)
        .limit(50)
        .all()
    )


def delete_group(actor: User, group_id: str, db: Session) -> None:
    group = _get_group_or_404(group_id, db)
    if group.owner_id != actor.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only the group owner can delete it.")
    group.is_active = False
    db.commit()


# ── Membership ────────────────────────────────────────────────────────────────

def list_my_groups(user: User, db: Session) -> list[dict]:
    rows = (
        db.query(UserGroup, Group)
        .join(Group, Group.id == UserGroup.group_id)
        .filter(
            UserGroup.user_id == user.id,
            Group.is_active   == True,  # noqa: E712
        )
        .all()
    )
    return [
        {
            "group_id":  ug.group_id,
            "name":      g.name,
            "type":      g.type,
            "role":      ug.role,
            "joined_at": ug.joined_at,
        }
        for ug, g in rows
    ]


def list_members(actor: User, group_id: str, db: Session) -> list[dict]:
    _get_group_or_404(group_id, db)
    _require_membership(actor.id, group_id, db)

    rows = (
        db.query(UserGroup, User)
        .join(User, User.id == UserGroup.user_id)
        .filter(UserGroup.group_id == group_id)
        .all()
    )
    return [
        {
            "user_id":   ug.user_id,
            "username":  u.username,
            "email":     u.email,
            "role":      ug.role,
            "joined_at": ug.joined_at,
        }
        for ug, u in rows
    ]


def update_member_role(
    actor:          User,
    group_id:       str,
    target_user_id: str,
    role:           str,
    db:             Session,
) -> None:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    membership = _get_membership(target_user_id, group_id, db)
    if not membership:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User is not a member.")

    membership.role = role
    db.commit()


def remove_member(actor: User, group_id: str, target_user_id: str, db: Session) -> None:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    if target_user_id == actor.id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Use the /leave endpoint to remove yourself from a group.",
        )

    membership = _get_membership(target_user_id, group_id, db)
    if not membership:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User is not a member.")

    db.delete(membership)
    db.commit()


def leave_group(actor: User, group_id: str, db: Session) -> None:
    group      = _get_group_or_404(group_id, db)
    membership = _require_membership(actor.id, group_id, db)

    if group.owner_id == actor.id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Group owner cannot leave. Transfer ownership or delete the group first.",
        )

    db.delete(membership)
    db.commit()


# ── Join requests (user → group) ──────────────────────────────────────────────

def request_to_join(actor: User, group_id: str, db: Session) -> GroupRequest:
    group = _get_group_or_404(group_id, db)

    if group.owner_id == actor.id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "You cannot request to join a group you created.",
        )
    if group.type == "private":
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "This group is private. You need an invite to join.",
        )
    if _get_membership(actor.id, group_id, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "You are already a member.")
    if _get_pending_request(actor.id, group_id, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "You already have a pending request.")

    # Eligibility check — fetches KYC + BankStatement from DB using actor.id
    _assert_user_eligible(actor.id, group.monthly_con, db)

    req = GroupRequest(
        group_id     = group_id,
        user_id      = actor.id,
        initiated_by = actor.id,
        direction    = "join_request",
        status       = "pending",
        created_at   = datetime.now(timezone.utc),
    )
    db.add(req)
    db.commit()
    db.refresh(req)
    return req


def approve_request(actor: User, group_id: str, request_id: str, db: Session) -> None:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    req = db.query(GroupRequest).filter(
        GroupRequest.id        == request_id,
        GroupRequest.group_id  == group_id,
        GroupRequest.direction == "join_request",
        GroupRequest.status    == "pending",
    ).first()
    if not req:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Join request not found.")

    req.status      = "approved"
    req.resolved_at = datetime.now(timezone.utc)
    _add_member(req.user_id, group_id, db)
    db.commit()


def reject_request(actor: User, group_id: str, request_id: str, db: Session) -> None:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    req = db.query(GroupRequest).filter(
        GroupRequest.id        == request_id,
        GroupRequest.group_id  == group_id,
        GroupRequest.direction == "join_request",
        GroupRequest.status    == "pending",
    ).first()
    if not req:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Join request not found.")

    req.status      = "rejected"
    req.resolved_at = datetime.now(timezone.utc)
    db.commit()


def list_join_requests(actor: User, group_id: str, db: Session) -> list[dict]:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    rows = (
        db.query(GroupRequest, User)
        .join(User, User.id == GroupRequest.user_id)
        .filter(
            GroupRequest.group_id  == group_id,
            GroupRequest.direction == "join_request",
            GroupRequest.status    == "pending",
        )
        .all()
    )
    return [
        {
            "id":           req.id,
            "group_id":     req.group_id,
            "user_id":      req.user_id,
            "username":     u.username,
            "email":        u.email,
            "direction":    req.direction,
            "status":       req.status,
            "initiated_by": req.initiated_by,
            "created_at":   req.created_at,
        }
        for req, u in rows
    ]


# ── Invites (admin → user) ────────────────────────────────────────────────────

def invite_user(
    actor:    User,
    group_id: str,
    email:    str | None,
    username: str | None,
    db:       Session,
) -> GroupRequest:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    target = _resolve_target_user(email, username, db)

    if _get_membership(target.id, group_id, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "User is already a member.")
    if _get_pending_request(target.id, group_id, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "User already has a pending request or invite.")

    req = GroupRequest(
        group_id     = group_id,
        user_id      = target.id,
        initiated_by = actor.id,
        direction    = "invite",
        status       = "pending",
        created_at   = datetime.now(timezone.utc),
    )
    db.add(req)
    db.commit()
    db.refresh(req)
    return req


def accept_invite(actor: User, request_id: str, db: Session) -> None:
    req = db.query(GroupRequest).filter(
        GroupRequest.id        == request_id,
        GroupRequest.user_id   == actor.id,
        GroupRequest.direction == "invite",
        GroupRequest.status    == "pending",
    ).first()
    if not req:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Invite not found.")

    _get_group_or_404(req.group_id, db)  # ensure group is still active

    req.status      = "accepted"
    req.resolved_at = datetime.now(timezone.utc)
    _add_member(actor.id, req.group_id, db)
    db.commit()


def decline_invite(actor: User, request_id: str, db: Session) -> None:
    req = db.query(GroupRequest).filter(
        GroupRequest.id        == request_id,
        GroupRequest.user_id   == actor.id,
        GroupRequest.direction == "invite",
        GroupRequest.status    == "pending",
    ).first()
    if not req:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Invite not found.")

    req.status      = "declined"
    req.resolved_at = datetime.now(timezone.utc)
    db.commit()


def list_my_invites(actor: User, db: Session) -> list[dict]:
    rows = (
        db.query(GroupRequest, Group)
        .join(Group, Group.id == GroupRequest.group_id)
        .filter(
            GroupRequest.user_id   == actor.id,
            GroupRequest.direction == "invite",
            GroupRequest.status    == "pending",
            Group.is_active        == True,  # noqa: E712
        )
        .all()
    )
    return [
        {
            "id":         req.id,
            "group_id":   req.group_id,
            "group_name": g.name,
            "status":     req.status,
            "created_at": req.created_at,
        }
        for req, g in rows
    ]