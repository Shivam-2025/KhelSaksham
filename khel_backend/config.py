import os
import json
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
FIREBASE_SERVICE_ACCOUNT = json.loads(os.getenv("FIREBASE_SERVICE_ACCOUNT"))

# Firebase storage bucket
FIREBASE_BUCKET = os.getenv("FIREBASE_BUCKET", "khelsakasham.firebasestorage.app")
