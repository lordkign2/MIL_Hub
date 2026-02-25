from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List
import uuid
from datetime import datetime, timedelta
import logging
from app.utils.database import get_db
from app.models.verification import MediaMetadata

router = APIRouter()
logger = logging.getLogger(__name__)

class MediaUploadResponse(BaseModel):
    media_id: str
    media_type: str
    file_name: str
    file_size: int
    upload_timestamp: datetime
    status: str

class MediaStatusResponse(BaseModel):
    media_id: str
    status: str
    progress: Optional[float]
    estimated_completion: Optional[datetime]
    error_message: Optional[str]

UPLOAD_DIR = os.getenv('MEDIA_UPLOAD_PATH', '/app/uploads')
MAX_FILE_SIZE = int(os.getenv('MEDIA_MAX_SIZE_MB', 50)) * 1024 * 1024

def validate_file_type(content_type: str) -> bool:
    """Validate allowed file types"""
    allowed_types = [
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'video/mp4', 'video/quicktime', 'video/x-msvideo',
        'audio/mpeg', 'audio/wav', 'audio/ogg'
    ]
    return content_type in allowed_types

def get_media_type(content_type: str) -> str:
    """Determine media type from content type"""
    if content_type.startswith('image/'):
        return 'image'
    elif content_type.startswith('video/'):
        return 'video'
    elif content_type.startswith('audio/'):
        return 'audio'
    else:
        return 'unknown'

@router.post("/upload", response_model=MediaUploadResponse)
async def upload_media(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    metadata: Optional[str] = Form(None),
    db = Depends(get_db)
):
    """Upload media file for verification"""
    try:
        # Validate file size
        content = await file.read()
        file_size = len(content)
        
        if file_size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=413,
                detail=f"File too large. Maximum size is {MAX_FILE_SIZE} bytes"
            )
        
        # Validate file type
        if not validate_file_type(file.content_type):
            # Try to get extension if content_type is generic
            pass
        
        # Generate unique media ID
        media_id = str(uuid.uuid4())
        media_type = get_media_type(file.content_type)
        
        # Create upload directory if it doesn't exist
        os.makedirs(UPLOAD_DIR, exist_ok=True)
        
        # Save file
        file_path = os.path.join(UPLOAD_DIR, f"{media_id}_{file.filename}")
        with open(file_path, "wb") as f:
            f.write(content)
        
        # Save metadata to database
        db_media = MediaMetadata(
            media_id=media_id,
            media_type=media_type,
            file_name=file.filename,
            file_size=file_size,
            mime_type=file.content_type,
            user_id=user_id,
            status="uploaded"
        )
        db.add(db_media)
        db.commit()
        
        logger.info(f"File uploaded and metadata saved: {media_id}")
        
        return MediaUploadResponse(
            media_id=media_id,
            media_type=media_type,
            file_name=file.filename,
            file_size=file_size,
            upload_timestamp=datetime.utcnow(),
            status="uploaded"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Upload failed: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@router.get("/media/{media_id}/status", response_model=MediaStatusResponse)
async def get_media_status(
    media_id: str,
    db = Depends(get_db)
):
    """Get status of media processing from database"""
    try:
        media = db.query(MediaMetadata).filter(MediaMetadata.media_id == media_id).first()
        if not media:
            raise HTTPException(status_code=404, detail="Media not found")
            
        progress = 0.0
        if media.status == 'completed':
            progress = 1.0
        elif media.status == 'processing':
            progress = 0.5 # Default middle progress if not detailed
            
        return MediaStatusResponse(
            media_id=media_id,
            status=media.status,
            progress=progress,
            estimated_completion=media.processing_completed or (media.processing_started + timedelta(minutes=5) if media.processing_started else None),
            error_message=media.error_message
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Status check failed: {e}")
        raise HTTPException(status_code=500, detail="Status check failed")

@router.delete("/media/{media_id}")
async def delete_media(
    media_id: str,
    db = Depends(get_db)
):
    """Delete media file and its database record"""
    try:
        media = db.query(MediaMetadata).filter(MediaMetadata.media_id == media_id).first()
        if not media:
            raise HTTPException(status_code=404, detail="Media not found")
            
        # Delete file from disk (simplified matching)
        for f in os.listdir(UPLOAD_DIR):
            if f.startswith(media_id):
                os.remove(os.path.join(UPLOAD_DIR, f))
        
        # Delete from database
        db.delete(media)
        db.commit()
        
        return JSONResponse(
            status_code=200,
            content={"message": f"Media {media_id} and metadata deleted successfully"}
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Delete failed: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail="Delete failed")
