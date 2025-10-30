from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from .database import Base
import datetime


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(120), unique=True, index=True, nullable=False)  # optional but unique
    password_hash = Column(String(255), nullable=False)
    age = Column(Integer, nullable=True)
    location = Column(String, nullable=True)
    sport = Column(String, nullable=True)  # hashed password
    bio = Column(Text, nullable=True)  # profile bio
    avatar_url = Column(String(255), nullable=True)  # profile picture URL
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    # relationships
    results = relationship(
        "Result", back_populates="user", cascade="all, delete-orphan"
    )
    achievements = relationship(
        "Achievement", back_populates="user", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<User(id={self.id}, username='{self.username}')>"


class Result(Base):
    __tablename__ = "results"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    exercise = Column(String(50), nullable=False)  # e.g., pushup, situp
    reps = Column(Integer, nullable=False)
    video_url = Column(String(255), nullable=False)
    video_hash = Column(String(64), nullable=False, index=True)  # hash for duplicate detection
    timestamp = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    # relationship
    user = relationship("User", back_populates="results")

    def __repr__(self) -> str:
        return (
            f"<Result(id={self.id}, user_id={self.user_id}, "
            f"exercise='{self.exercise}', reps={self.reps})>"
        )


class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(100), nullable=False)  # e.g., Bronze, Silver, Gold
    description = Column(Text, nullable=True)
    earned_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    # relationship
    user = relationship("User", back_populates="achievements")

    __table_args__ = (
        UniqueConstraint("user_id", "title", name="uq_user_achievement"),
    )

    def __repr__(self) -> str:
        return f"<Achievement(id={self.id}, user_id={self.user_id}, title='{self.title}')>"
