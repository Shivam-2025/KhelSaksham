import os
from dotenv import load_dotenv

# -------------------------
# Load environment variables
# -------------------------
load_dotenv()

# -------------------------
# Database
# -------------------------
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./results.db")

# -------------------------
# JWT / Security
# -------------------------
SECRET_KEY = os.getenv("SECRET_KEY", "supersecretkey")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_HOURS = int(os.getenv("ACCESS_TOKEN_EXPIRE_HOURS", "24"))

# -------------------------
# Firebase
# -------------------------
# Path to Firebase service account JSON file
FIREBASE_KEY = os.getenv("FIREBASE_KEY", "khel_backend/firebase_key.json")

# Firebase storage bucket
FIREBASE_BUCKET = os.getenv("FIREBASE_BUCKET", "khelsakasham.firebasestorage.app")
