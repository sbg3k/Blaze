import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Group(Base):
    __tablename__ = "groups"

    id:            Mapped[str]                  = mapped_column(String,  primary_key=True, default=lambda: str(uuid.uuid4()))
    name:          Mapped[str]                  = mapped_column(String,  unique=True, nullable=False, index=True)
    description:   Mapped[str | None]           = mapped_column(String,  nullable=True)
    # "public" | "private"
    type:          Mapped[str]                  = mapped_column(String,  nullable=False, default="public")
    owner_id:      Mapped[str | None]           = mapped_column(String,  ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    is_active:     Mapped[bool]                 = mapped_column(Boolean, nullable=False, default=True)
    created_at:    Mapped[datetime]             = mapped_column(DateTime(timezone=True), nullable=False)
    monthly_con:   Mapped[int]                  = mapped_column(Integer, nullable=False, default=1000)

    memberships:   Mapped[list["UserGroup"]]    = relationship("UserGroup",    back_populates="group", cascade="all, delete-orphan")
    requests:      Mapped[list["GroupRequest"]] = relationship("GroupRequest", back_populates="group", cascade="all, delete-orphan")
    wallet:        Mapped["Wallet | None"]      = relationship("Wallet", back_populates="group", uselist=False)
    cycles:        Mapped[list["Cycle"]]        = relationship("Cycle", back_populates="group", cascade="all, delete-orphan")

class UserGroup(Base):
    __tablename__ = "user_groups"

    user_id:   Mapped[str]      = mapped_column(String, ForeignKey("users.id",  ondelete="CASCADE"), primary_key=True)
    group_id:  Mapped[str]      = mapped_column(String, ForeignKey("groups.id", ondelete="CASCADE"), primary_key=True)
    # "member" | "admin"
    role:      Mapped[str]      = mapped_column(String, nullable=False, default="member")
    joined_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_frozen: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    frozen_until_cycle_id: Mapped[str | None] = mapped_column(
        String, ForeignKey("cycles.id", ondelete="SET NULL"), nullable=True
    )

    group: Mapped["Group"] = relationship("Group", back_populates="memberships")



class GroupRequest(Base):
    __tablename__ = "group_requests"

    id:           Mapped[str]          = mapped_column(String,  primary_key=True, default=lambda: str(uuid.uuid4()))
    group_id:     Mapped[str]          = mapped_column(String,  ForeignKey("groups.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id:      Mapped[str]          = mapped_column(String,  ForeignKey("users.id",  ondelete="CASCADE"), nullable=False, index=True)
    initiated_by: Mapped[str]          = mapped_column(String,  ForeignKey("users.id",  ondelete="CASCADE"), nullable=False)
    # "join_request" | "invite"
    direction:    Mapped[str]          = mapped_column(String,  nullable=False)
    # "pending" | "approved" | "rejected" | "accepted" | "declined"
    status:       Mapped[str]          = mapped_column(String,  nullable=False, default="pending")
    created_at:   Mapped[datetime]     = mapped_column(DateTime(timezone=True), nullable=False)
    resolved_at:  Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    group: Mapped["Group"] = relationship("Group", back_populates="requests")

    __table_args__ = (
        UniqueConstraint("group_id", "user_id", name="uq_group_request_pair"),
    )
