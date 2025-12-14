import datetime
from fastapi import HTTPException, Depends
import jwt
from jwt import ExpiredSignatureError, InvalidTokenError
from passlib.context import CryptContext
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from khel_backend import database 
from khel_backend import models
from khel_backend.config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_HOURS

# -------------------------
# Security Setup
# -------------------------
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2PasswordBearer expects a login route where tokens are retrieved
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# -------------------------
# Token Expiry Settings
# -------------------------
ACCESS_TOKEN_EXPIRE_MINUTES = ACCESS_TOKEN_EXPIRE_HOURS * 60
REFRESH_TOKEN_EXPIRE_DAYS = 7

# -------------------------
# Password Utils
# -------------------------
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(password: str, hashed: str) -> bool:
    if not password or len(password.encode("utf-8")) > 72:
        return False
    return pwd_context.verify(password, hashed)

# -------------------------
# JWT Utils
# -------------------------
# -------------------------
# JWT Utils
# -------------------------
def create_token(user_id: str) -> str:
    expire = datetime.datetime.utcnow() + datetime.timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS)
    payload = {"sub": str(user_id), "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def create_access_token(user_id: str) -> str:
    """Create a short-lived access token"""
    expire = datetime.datetime.utcnow() + datetime.timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )
    payload = {"sub": str(user_id), "exp": expire, "type": "access"}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def create_refresh_token(user_id: str) -> str:
    """Create a long-lived refresh token"""
    expire = datetime.datetime.utcnow() + datetime.timedelta(
        days=REFRESH_TOKEN_EXPIRE_DAYS
    )
    payload = {"sub": str(user_id), "exp": expire, "type": "refresh"}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def decode_token(token: str, expected_type: str = "access") -> str:
    """Decode a JWT and validate its type (access or refresh)"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        token_type = payload.get("type")
        if token_type != expected_type:
            raise HTTPException(status_code=401, detail="Invalid token type")
        return payload.get("sub")
    except ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# -------------------------
# DB Dependency
# -------------------------
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# -------------------------
# Auth Dependency
# -------------------------
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    """Retrieve the current logged-in user from the access token"""
    user_id = decode_token(token, expected_type="access")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")

    user = db.query(models.User).filter_by(id=int(user_id)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user
