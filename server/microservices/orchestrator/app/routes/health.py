from fastapi import APIRouter
from datetime import datetime
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/")
async def health_check():
    """Health check endpoint"""
    logger.info("Health check requested")
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "verification-orchestrator"
    }

@router.get("/ready")
async def readiness_check():
    """Readiness check endpoint"""
    # Check database connection, Redis connection, etc.
    return {
        "status": "ready",
        "timestamp": datetime.utcnow().isoformat(),
        "dependencies": {
            "database": "healthy",
            "redis": "healthy",
            "celery": "healthy"
        }
    }

@router.get("/alive")
async def liveness_check():
    """Liveness check endpoint"""
    return {
        "status": "alive",
        "timestamp": datetime.utcnow().isoformat()
    }