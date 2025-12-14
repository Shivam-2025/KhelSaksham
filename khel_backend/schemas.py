from pydantic import BaseModel, Field, EmailStr, StringConstraints
from typing import Optional, List, Literal, Dict
from datetime import datetime
from typing_extensions import Annotated

# -------------------------
# Auth
# -------------------------
class RegisterIn(BaseModel):
    username: str
    email: EmailStr
    password: Annotated[
        str,
        StringConstraints(min_length=8, max_length=72)
    ]
    age: Optional[int] = 0
    location: Optional[str] = ""
    sport: Optional[str] = ""

class LoginIn(BaseModel):
    email: EmailStr
    password: Annotated[
        str,
        StringConstraints(min_length=8, max_length=72)
    ]


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


# -------------------------
# Results
# -------------------------
class ResultIn(BaseModel):
    exercise: Literal["pushup", "situp", "pullup", "jump"]
    reps: int = Field(..., gt=0)  # must be > 0
    video_url: str = Field(..., min_length=1)
    video_hash: str = Field(..., min_length=1)
    timestamp: datetime


class ResultOut(BaseModel):
    id: int
    exercise: str
    reps: int
    timestamp: datetime
    video_url: str

    class Config:
        from_attributes = True  # replaces orm_mode in Pydantic v2


# -------------------------
# Profile
# -------------------------
class ProfileOut(BaseModel):
    id: int
    username: str
    email: Optional[EmailStr] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    total_reps: int
    created_at: datetime

    class Config:
        from_attributes = True


class ProfileUpdateIn(BaseModel):
    email: Optional[EmailStr] = Field(None, max_length=255)
    bio: Optional[str] = Field(None, max_length=500)
    avatar_url: Optional[str] = Field(None, max_length=500)


# -------------------------
# Achievements
# -------------------------
class AchievementOut(BaseModel):
    id: int
    user_id: int
    title: str
    description: Optional[str] = None
    earned_at: datetime

    class Config:
        from_attributes = True


# -------------------------
# Dashboard
# -------------------------
class DashboardOut(BaseModel):
    total_reps: int
    best_reps: Dict[str, int]  # best reps per exercise
    recent_activity: List[ResultOut]  # recent workouts
    achievements: List[AchievementOut]  # earned achievements
