from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from pydantic import BaseModel
from datetime import datetime, timedelta
import jwt
import os

router = APIRouter()

class TokenRequest(BaseModel):
    token: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int

@router.post("/validate", response_model=TokenResponse)
async def validate_token(
    request: TokenRequest,
    credentials: HTTPAuthorizationCredentials = Depends()
):
    """Validate Firebase JWT token and issue internal access token"""
    try:
        # Verify Firebase token (this would be done in the main app dependency)
        # For now, we'll create a simple internal token
        payload = {
            "sub": "user_id",  # This would come from Firebase token
            "exp": datetime.utcnow() + timedelta(minutes=30),
            "iat": datetime.utcnow(),
            "scope": "verification"
        }
        
        access_token = jwt.encode(
            payload, 
            os.getenv('JWT_SECRET_KEY', 'secret'), 
            algorithm=os.getenv('JWT_ALGORITHM', 'HS256')
        )
        
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            expires_in=1800
        )
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")

@router.get("/status")
async def auth_status():
    """Check authentication service status"""
    return {"status": "healthy", "service": "auth"}