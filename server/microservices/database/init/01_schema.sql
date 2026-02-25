-- Create pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create tables for verification system

-- Media metadata table
CREATE TABLE IF NOT EXISTS media_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    media_id VARCHAR(100) UNIQUE NOT NULL,
    media_type VARCHAR(20) NOT NULL, -- image, video, audio
    file_name VARCHAR(255),
    file_size BIGINT,
    mime_type VARCHAR(100),
    upload_timestamp TIMESTAMP DEFAULT NOW(),
    user_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed
    processing_started TIMESTAMP,
    processing_completed TIMESTAMP,
    error_message TEXT
);

-- Image verification results
CREATE TABLE IF NOT EXISTS image_verification_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    media_id VARCHAR(100) REFERENCES media_metadata(media_id),
    perceptual_hash VARCHAR(100),
    perceptual_hash_vector vector(64), -- for similarity search
    exif_data JSONB,
    ai_generated_probability FLOAT,
    reverse_search_matches JSONB,
    verification_timestamp TIMESTAMP DEFAULT NOW(),
    confidence_score FLOAT
);

-- Video verification results
CREATE TABLE IF NOT EXISTS video_verification_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    media_id VARCHAR(100) REFERENCES media_metadata(media_id),
    frame_count INTEGER,
    duration_seconds FLOAT,
    deepfake_probability FLOAT,
    audio_deepfake_probability FLOAT,
    temporal_consistency_score FLOAT,
    verification_timestamp TIMESTAMP DEFAULT NOW(),
    confidence_score FLOAT
);

-- Context verification results
CREATE TABLE IF NOT EXISTS context_verification_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    media_id VARCHAR(100) REFERENCES media_metadata(media_id),
    extracted_claims JSONB,
    fact_check_results JSONB,
    news_api_matches JSONB,
    credibility_score FLOAT,
    verification_timestamp TIMESTAMP DEFAULT NOW()
);

-- Verification reports (aggregated results)
CREATE TABLE IF NOT EXISTS verification_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    media_id VARCHAR(100) REFERENCES media_metadata(media_id),
    trust_score FLOAT NOT NULL,
    verdict VARCHAR(50) NOT NULL, -- authentic, suspicious, manipulated, ai_generated
    detailed_results JSONB,
    confidence_breakdown JSONB,
    recommendations JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP
);

-- Hash storage for similarity search
CREATE TABLE IF NOT EXISTS hash_storage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hash_type VARCHAR(50) NOT NULL, -- perceptual, dhash, ahash, phash
    hash_value VARCHAR(100) NOT NULL,
    hash_vector vector(64),
    media_id VARCHAR(100) REFERENCES media_metadata(media_id),
    source_url TEXT,
    first_seen TIMESTAMP DEFAULT NOW(),
    last_seen TIMESTAMP DEFAULT NOW()
);

-- Signal aggregation table
CREATE TABLE IF NOT EXISTS verification_signals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    media_id VARCHAR(100) REFERENCES media_metadata(media_id),
    signal_type VARCHAR(50) NOT NULL, -- reverse_search, ai_detection, context_match, etc.
    signal_value FLOAT,
    confidence FLOAT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- User verification history
CREATE TABLE IF NOT EXISTS user_verification_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(100) NOT NULL,
    media_id VARCHAR(100) REFERENCES media_metadata(media_id),
    verification_type VARCHAR(50),
    result_summary JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_media_metadata_media_id ON media_metadata(media_id);
CREATE INDEX IF NOT EXISTS idx_media_metadata_user_id ON media_metadata(user_id);
CREATE INDEX IF NOT EXISTS idx_media_metadata_status ON media_metadata(status);
CREATE INDEX IF NOT EXISTS idx_verification_reports_media_id ON verification_reports(media_id);
CREATE INDEX IF NOT EXISTS idx_verification_reports_created_at ON verification_reports(created_at);
CREATE INDEX IF NOT EXISTS idx_verification_signals_media_id ON verification_signals(media_id);
CREATE INDEX IF NOT EXISTS idx_hash_storage_hash_value ON hash_storage(hash_value);
CREATE INDEX IF NOT EXISTS idx_user_history_user_id ON user_verification_history(user_id);

-- Create vector indexes for similarity search
CREATE INDEX IF NOT EXISTS idx_image_hashes_vector ON image_verification_results USING ivfflat (perceptual_hash_vector vector_l2_ops);
CREATE INDEX IF NOT EXISTS idx_hash_storage_vector ON hash_storage USING ivfflat (hash_vector vector_l2_ops);

-- Create materialized view for analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS verification_analytics AS
SELECT 
    DATE(created_at) as date,
    verdict,
    COUNT(*) as count,
    AVG(trust_score) as avg_trust_score,
    AVG(confidence_breakdown->>'overall') as avg_confidence
FROM verification_reports
GROUP BY DATE(created_at), verdict
ORDER BY DATE(created_at) DESC;

-- Refresh function for materialized view
CREATE OR REPLACE FUNCTION refresh_verification_analytics()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW verification_analytics;
END;
$$ LANGUAGE plpgsql;