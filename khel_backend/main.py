from sqlalchemy import text
from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware
from khel_backend import database 
from khel_backend import models
from khel_backend.auth import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    get_current_user,
)
from khel_backend.schemas import RegisterIn, LoginIn, ResultIn, ProfileUpdateIn
from khel_backend.config import FIREBASE_SERVICE_ACCOUNT, FIREBASE_BUCKET
import uuid, firebase_admin, datetime
from firebase_admin import credentials, storage

# -------------------------
# App Setup
# -------------------------
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ⚠️ restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

models.Base.metadata.create_all(bind=database.engine)

# -------------------------
# Firebase Config
# -------------------------
try:
    cred = credentials.Certificate(FIREBASE_SERVICE_ACCOUNT)
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred, {"storageBucket": FIREBASE_BUCKET})
    bucket = storage.bucket()
except Exception as e:
    raise RuntimeError(f"Firebase initialization failed: {e}")

# -------------------------
# Utils
# -------------------------
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# -------------------------
# Auth Routes
# -------------------------
@app.post("/register")
def register(user: RegisterIn, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(
        (models.User.username == user.username) | (models.User.email == user.email)
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already taken")

    hashed_pw = hash_password(user.password)
    new_user = models.User(
        username=user.username,
        email=user.email,
        password_hash=hashed_pw,
        age=user.age,
        location=user.location,
        sport=user.sport
    )
    db.add(new_user)
    db.commit()
    return {"status": "registered"}


@app.post("/login")
def login(user: LoginIn, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter_by(email=user.email).first()
    if not db_user or not verify_password(user.password, db_user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    access_token = create_access_token(str(db_user.id))
    refresh_token = create_refresh_token(str(db_user.id))

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
    }


@app.post("/refresh")
def refresh_token(refresh_token: str):
    try:
        user_id = decode_token(refresh_token, expected_type="refresh")
        new_access = create_access_token(user_id)
        return {"access_token": new_access, "token_type": "bearer"}
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token refresh failed: {e}")

# -------------------------
# Video Upload & Results
# -------------------------
@app.post("/upload")
def upload_video(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
):
    try:
        if not file.filename:
            raise HTTPException(status_code=400, detail="No file provided")

        unique_name = f"{uuid.uuid4()}_{file.filename}"
        blob = bucket.blob(f"videos/{unique_name}")
        content = file.file.read()
        blob.upload_from_string(content, content_type=file.content_type)
        blob.make_public()
        return {"video_url": blob.public_url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {e}")


@app.post("/results")
def save_result(
    item: ResultIn,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if item.reps <= 0:
        raise HTTPException(status_code=400, detail="Reps must be greater than 0")
    if not item.exercise.strip():
        raise HTTPException(status_code=400, detail="Exercise name required")

    try:
        new = models.Result(
            user_id=current_user.id,
            exercise=item.exercise,
            reps=item.reps,
            video_url=item.video_url,
            video_hash=item.video_hash,
            timestamp=item.timestamp,
        )
        db.add(new)
        db.commit()
        return {"status": "ok"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Result save failed: {e}")


@app.post("/submit")
def submit_result(
    file: UploadFile = File(...),
    exercise: str = Form(...),
    reps: int = Form(...),
    video_hash: str = Form(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if reps <= 0:
        raise HTTPException(status_code=400, detail="Reps must be greater than 0")
    if not exercise.strip():
        raise HTTPException(status_code=400, detail="Exercise name required")

    try:
        unique_name = f"{uuid.uuid4()}_{file.filename}"
        blob = bucket.blob(f"videos/{unique_name}")
        content = file.file.read()
        blob.upload_from_string(content, content_type=file.content_type)
        blob.make_public()
        video_url = blob.public_url

        new = models.Result(
            user_id=current_user.id,
            exercise=exercise,
            reps=reps,
            video_url=video_url,
            video_hash=video_hash,
        )
        db.add(new)
        db.commit()
        return {"status": "ok", "video_url": video_url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Submit failed: {e}")

# -------------------------
# Leaderboard
# -------------------------
@app.get("/leaderboard")
def leaderboard(
    exercise: str = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    try:
        query = """
            SELECT u.id, u.username, u.avatar_url, u.location, u.sport, COALESCE(MAX(r.reps), 0) AS best
            FROM users u
            LEFT JOIN results r ON r.user_id = u.id
        """
        params = {}
        if exercise:
            # Add filter into the JOIN so users with no results still show (best=0)
            query += " AND r.exercise = :exercise"
            params["exercise"] = exercise

        query += " GROUP BY u.id, u.username, u.avatar_url, u.location, u.sport ORDER BY best DESC"

        rows = db.execute(text(query), params).fetchall()
        leaderboard_list, current_rank, prev_best, user_rank_info = [], 1, None, None

        for i, r in enumerate(rows):
            best = r[5]
            if prev_best is not None and best < prev_best:
                current_rank = i + 1
            entry = {
                "rank": current_rank,
                "user_id": r[0],
                "username": r[1],
                "avatar_url": r[2],
                "location": r[3],
                "sport": r[4],
                "best": best,
                "is_current_user": r[0] == current_user.id
            }
            leaderboard_list.append(entry)
            if r[0] == current_user.id:
                user_rank_info = entry
            prev_best = best

        return {"top": leaderboard_list[:20], "current_user": user_rank_info}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Leaderboard fetch failed: {e}")

# -------------------------
# User Profile & History
# -------------------------
@app.get("/user/history")
def user_history(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    try:
        rows = db.execute(
            text(
                "SELECT exercise, reps, timestamp, video_url "
                "FROM results WHERE user_id = :uid ORDER BY timestamp DESC"
            ),
            {"uid": current_user.id},
        ).fetchall()
        return [
            {"exercise": r[0], "reps": r[1], "timestamp": str(r[2]), "video_url": r[3]}
            for r in rows
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"History fetch failed: {e}")


@app.get("/profile/me")
def profile_me(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    try:
        total_reps = (
            db.execute(
                text("SELECT SUM(reps) FROM results WHERE user_id = :uid"),
                {"uid": current_user.id},
            ).scalar()
            or 0
        )
        return {
            "username": current_user.username,
            "email": current_user.email,
            "bio": current_user.bio,
            "age": current_user.age,
            "location": current_user.location,
            "sport": current_user.sport,
            "avatar_url": current_user.avatar_url,
            "total_reps": total_reps,
            "created_at": str(current_user.created_at),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Profile fetch failed: {e}")


@app.patch("/profile/me")
def update_profile_me(
    data: ProfileUpdateIn,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    try:
        if data.email is not None and not data.email.strip():
            raise HTTPException(status_code=400, detail="Email cannot be empty")
        if data.bio is not None:
            current_user.bio = data.bio
        if data.email is not None:
            current_user.email = data.email
        if data.avatar_url is not None:
            current_user.avatar_url = data.avatar_url

        db.commit()
        return {"status": "updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Profile update failed: {e}")

# -------------------------
# Achievements (custom logic)
# -------------------------
@app.get("/achievements/me")
def achievements_me(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Compute achievements server-side and persist any newly earned achievement rows.
    Returns a list of achievements with: title, description, earned (bool), progress (0..1), points, earned_at (nullable)
    """
    try:
        # total reps (coalesce to 0)
        total_reps = (
            db.execute(
                text("SELECT COALESCE(SUM(reps), 0) FROM results WHERE user_id = :uid"),
                {"uid": current_user.id},
            ).scalar()
            or 0
        )

        # per-exercise totals for this user
        exercise_stats = db.execute(
            text(
                "SELECT exercise, COALESCE(SUM(reps), 0) as total FROM results WHERE user_id = :uid GROUP BY exercise"
            ),
            {"uid": current_user.id},
        ).fetchall()
        exercise_totals = {row[0].lower(): row[1] for row in exercise_stats}  # normalize lower-case

        # distinct exercises present in the system (to evaluate "10 in each")
        distinct_exercises = [r[0].lower() for r in db.execute(text("SELECT DISTINCT exercise FROM results")).fetchall()]

        # number of workout submissions
        total_sessions = (
            db.execute(
                text("SELECT COUNT(*) FROM results WHERE user_id = :uid"),
                {"uid": current_user.id},
            ).scalar()
            or 0
        )

        # Load existing persisted achievements for this user (titles)
        persisted = db.query(models.Achievement).filter_by(user_id=current_user.id).all()
        persisted_titles = {a.title for a in persisted}

        # Define catalog with evaluation and progress calculation
        # Each entry: (title, description, points, condition_bool, progress_float)
        catalog = []

        # Newcomer: award when user has zero sessions (new user) OR if already persisted
        newcomer_earned = total_sessions == 0 or "Newcomer" in persisted_titles
        catalog.append(("Newcomer", "Welcome to KhelSaksham!", 20, newcomer_earned,
                        1.0 if newcomer_earned else 0.0))

        # First Recording
        first_recording_earned = total_sessions >= 1 or "First Recording" in persisted_titles
        catalog.append(("First Recording", "Completed your first workout recording", 50, first_recording_earned,
                        1.0 if first_recording_earned else 0.0))

        # 10 in Each: requires there to be known exercises in the system;
        # User must have >=10 reps in every distinct exercise that exists in DB
        ten_each_earned = False
        ten_each_progress = 0.0
        if distinct_exercises:
            # compute fraction of exercises where user has >=10 reps
            cnt_met = sum(1 for ex in distinct_exercises if exercise_totals.get(ex, 0) >= 10)
            ten_each_progress = cnt_met / len(distinct_exercises)
            ten_each_earned = cnt_met == len(distinct_exercises)
        else:
            # no exercises in DB yet -> false, progress 0
            ten_each_earned = False
            ten_each_progress = 0.0
        catalog.append(("10 in Each", "Complete 10 reps in every exercise", 120, ten_each_earned, min(1.0, ten_each_progress)))

        # Total reps thresholds (Century Club / Half K / K Legend)
        catalog.append(("Century Club", "Completed 100 total reps", 100, total_reps >= 100, min(1.0, total_reps / 100.0)))
        catalog.append(("Half K Hero", "Completed 500 total reps", 200, total_reps >= 500, min(1.0, total_reps / 500.0)))
        catalog.append(("K Legend", "Completed 1000 total reps", 500, total_reps >= 1000, min(1.0, total_reps / 1000.0)))

        # Jump King: check user total jump-like reps (case-insensitive partial match)
        jump_count = 0
        # sum any exercise names containing 'jump'
        for ex_name, tot in exercise_totals.items():
            if "jump" in ex_name:
                jump_count += tot
        jump_earned = jump_count >= 50
        jump_progress = min(1.0, jump_count / 50.0)
        catalog.append(("Jump King", "Achieved 50 total jumps", 120, jump_earned, jump_progress))

        # You can expand catalog with more rules using same pattern

        # Persist newly earned achievements (if not already persisted)
        newly_persisted = []
        for title, desc, points, earned, progress in catalog:
            if earned and title not in persisted_titles:
                ach = models.Achievement(
                    user_id=current_user.id,
                    title=title,
                    description=desc,
                    earned_at=datetime.datetime.utcnow(),
                )
                db.add(ach)
                newly_persisted.append(title)

        if newly_persisted:
            db.commit()
            # refresh persisted list
            persisted = db.query(models.Achievement).filter_by(user_id=current_user.id).all()
            persisted_titles = {a.title for a in persisted}

        # Build response: include persisted earned_at where available, and include earned flag + progress + points + desc
        persisted_map = {a.title: a for a in persisted}
        response_achievements = []
        for title, desc, points, earned, progress in catalog:
            earned_at = None
            if title in persisted_map:
                earned_at = persisted_map[title].earned_at
                # convert to string for JSON; keep None if not present
                earned_at = str(earned_at) if earned_at else None
            response_achievements.append({
                "title": title,
                "description": desc,
                "points": points,
                "earned": title in persisted_titles,
                "progress": float(progress),
                "earned_at": earned_at,
            })

        return {
            "user_id": current_user.id,
            "total_reps": total_reps,
            "total_sessions": total_sessions,
            "achievements": response_achievements,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Achievements fetch failed: {e}")

# -------------------------
# Dashboard Stats
# -------------------------
@app.get("/dashboard/me")
def dashboard_me(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    try:
        total_reps = (
            db.execute(
                text("SELECT SUM(reps) FROM results WHERE user_id = :uid"),
                {"uid": current_user.id},
            ).scalar()
            or 0
        )

        best_workout = (
            db.execute(
                text("SELECT MAX(reps) FROM results WHERE user_id = :uid"),
                {"uid": current_user.id},
            ).scalar()
            or 0
        )

        recent_rows = db.execute(
            text(
                "SELECT exercise, reps, timestamp FROM results "
                "WHERE user_id = :uid ORDER BY timestamp DESC LIMIT 5"
            ),
            {"uid": current_user.id},
        ).fetchall()
        recent_activity = [
            {"exercise": r[0], "reps": r[1], "timestamp": str(r[2])}
            for r in recent_rows
        ]

        weekly_rows = db.execute(
            text(
                """
                SELECT DATE(timestamp) as day, SUM(reps) 
                FROM results 
                WHERE user_id = :uid 
                  AND timestamp >= DATE('now', '-6 day')
                GROUP BY day ORDER BY day
                """
            ),
            {"uid": current_user.id},
        ).fetchall()
        weekly_trend = [{"day": str(r[0]), "reps": r[1]} for r in weekly_rows]

        return {
            "total_reps": total_reps,
            "best_workout": best_workout,
            "recent_activity": recent_activity or [],
            "weekly_trend": weekly_trend or [],
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dashboard fetch failed: {e}")
