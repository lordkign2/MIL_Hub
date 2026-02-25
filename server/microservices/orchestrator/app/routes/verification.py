from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPAuthorizationCredentials
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, timedelta
import logging
from app.utils.database import get_db

router = APIRouter()
logger = logging.getLogger(__name__)

class VerificationRequest(BaseModel):
    media_id: str
    verification_types: List[str] = ["image", "context"]
    priority: str = "normal"  # normal, high, low

class VerificationResponse(BaseModel):
    job_id: str
    media_id: str
    status: str
    created_at: datetime
    estimated_completion: Optional[datetime]

class VerificationResult(BaseModel):
    job_id: str
    media_id: str
    trust_score: float
    verdict: str
    detailed_results: dict
    recommendations: List[str]
    created_at: datetime

@router.post("/analyze", response_model=VerificationResponse)
async def start_verification(
    request: VerificationRequest,
    credentials: HTTPAuthorizationCredentials = Depends()
):
    """Start verification process for uploaded media"""
    try:
        from main import celery_app
        
        # 1. Generate unique job ID
        job_id = f"job_{datetime.utcnow().timestamp()}"
        
        # 2. Dispatch to appropriate services via Celery
        # Map request verification types to Celery tasks
        task_mapping = {
            "image": "image_tasks.analyze_image",
            "video": "video_tasks.analyze_video",
            "context": "context_tasks.analyze_context"
        }
        
        dispatched_tasks = []
        for v_type in request.verification_types:
            if v_type in task_mapping:
                task_name = task_mapping[v_type]
                # Dispatch task asynchronously
                # In production, we'd pass the media_id and any needed options
                celery_app.send_task(
                    task_name,
                    args=[request.media_id, job_id],
                    kwargs={"priority": request.priority},
                    queue=f"{v_type}_verification" if v_type != "context" else "context_engine"
                )
                dispatched_tasks.append(v_type)
        
        # 3. Always dispatch scoring task to aggregate results (dependency of other tasks)
        # Note: In a real scenario, scoring might wait for other tasks
        celery_app.send_task(
            "scoring_tasks.aggregate_signals",
            args=[job_id, request.media_id],
            queue="scoring_engine"
        )
        
        logger.info(f"Verification job {job_id} started for media {request.media_id}. Services: {dispatched_tasks}")
        
        return VerificationResponse(
            job_id=job_id,
            media_id=request.media_id,
            status="processing",
            created_at=datetime.utcnow(),
            estimated_completion=datetime.utcnow() + timedelta(minutes=5)
        )
    except Exception as e:
        logger.error(f"Verification start failed: {e}")
        raise HTTPException(status_code=500, detail=f"Verification start failed: {str(e)}")

@router.get("/results/{job_id}", response_model=VerificationResult)
async def get_verification_result(
    job_id: str,
    db = Depends(get_db)
):
    """Get verification results by job ID"""
    try:
        from app.models.verification import VerificationReport
        
        # Query the database for the report
        # Note: In our implementation, job_id is used for tracking, but reports are linked by media_id.
        # However, for simplicity and to match the API, let's assume we can find it by job_id or media_id.
        # In a more complete system, we'd have a jobs table mapping job_id to media_id.
        
        # For now, let's try to find a report where job_id or media_id matches (if job_id was media_id)
        report = db.query(VerificationReport).filter(
            (VerificationReport.id == job_id) | (VerificationReport.media_id == job_id)
        ).first()
        
        if not report:
            # Check if it's still processing
            from app.models.verification import MediaMetadata
            media = db.query(MediaMetadata).filter(MediaMetadata.media_id == job_id).first()
            if media and media.status == 'processing':
                raise HTTPException(status_code=202, detail="Verification still in progress")
            
            raise HTTPException(status_code=404, detail="Verification result not found")
        
        return VerificationResult(
            job_id=str(report.id),
            media_id=report.media_id,
            trust_score=report.trust_score,
            verdict=report.verdict,
            detailed_results=report.detailed_results or {},
            recommendations=report.recommendations or [],
            created_at=report.created_at
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Result retrieval failed: {e}")
        raise HTTPException(status_code=500, detail="Result retrieval failed")

@router.get("/status")
async def verification_status():
    """Check verification service status"""
    return {"status": "healthy", "service": "verification", "active_jobs": 0}