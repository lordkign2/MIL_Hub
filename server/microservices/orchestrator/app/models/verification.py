from sqlalchemy import Column, String, Float, DateTime, JSON, ForeignKey, BigINT
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
import uuid
from app.utils.database import Base

class MediaMetadata(Base):
    __tablename__ = "media_metadata"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    media_id = Column(String(100), unique=True, nullable=False, index=True)
    media_type = Column(String(20), nullable=False)
    file_name = Column(String(255))
    file_size = Column(BigINT)
    mime_type = Column(String(100))
    upload_timestamp = Column(DateTime(timezone=True), server_default=func.now())
    user_id = Column(String(100), index=True)
    status = Column(String(20), default="pending", index=True)
    processing_started = Column(DateTime(timezone=True))
    processing_completed = Column(DateTime(timezone=True))
    error_message = Column(String)

class VerificationReport(Base):
    __tablename__ = "verification_reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    media_id = Column(String(100), ForeignKey("media_metadata.media_id"), nullable=False, index=True)
    trust_score = Column(Float, nullable=False)
    verdict = Column(String(50), nullable=False)
    detailed_results = Column(JSONB)
    confidence_breakdown = Column(JSONB)
    recommendations = Column(JSONB)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    expires_at = Column(DateTime(timezone=True))
