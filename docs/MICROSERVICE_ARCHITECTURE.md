# MIL Hub Verification Microservice Architecture

## Overview

This document describes the production-ready verification microservice architecture implemented for the MIL Hub platform. The system provides enterprise-grade content verification capabilities including image analysis, video verification, context checking, and trust scoring.

## Architecture Components

### 1. API Gateway Layer
- **Technology**: NGINX with custom configuration
- **Features**:
  - JWT validation from Firebase
  - Rate limiting (API: 60 req/min, Upload: 10 req/min, Heavy: 30 req/min)
  - Request/response logging
  - File size validation (50MB max)
  - Security headers and CORS support
  - Abuse protection mechanisms

### 2. Verification Orchestrator Service
- **Technology**: Python FastAPI with Celery
- **Features**:
  - Media upload handling and validation
  - Job routing to specialized microservices
  - Async task management
  - Result aggregation and reporting
  - Firebase authentication integration

### 3. Database Layer
- **Primary**: PostgreSQL with pgvector extension
- **Caching**: Redis for sessions and caching
- **Schema**: 
  - Media metadata storage
  - Verification results with vector embeddings
  - Hash storage for similarity search
  - User verification history
  - Signal aggregation tables

### 4. Specialized Microservices

#### Image Verification Service
- Perceptual hashing (imagehash library)
- EXIF metadata extraction
- AI-generated image detection
- Reverse image search integration
- Vector embedding storage

#### Video Verification Service
- FFmpeg frame extraction (1 frame every 3 seconds)
- Frame-level analysis pipeline
- Deepfake detection with XceptionNet
- Audio deepfake detection
- Temporal consistency analysis

#### Context Verification Engine
- Claim extraction using spaCy NER
- News API integration
- Fact-checking database cross-reference
- Knowledge graph integration
- Semantic similarity matching

### 5. Scoring Engine
- Multi-signal aggregation
- Trust scoring algorithm:
  ```
  TrustScore = (0.25 × reverse_confidence) + 
               (0.20 × hash_confidence) + 
               (0.20 × ai_confidence) + 
               (0.20 × context_score) + 
               (0.15 × metadata_score)
  ```
- Confidence calibration and thresholding
- Result categorization

## Flutter Integration

### API Service
Located at: `lib/features/check/services/api/verification_api_service.dart`

**Key Features**:
- Media upload with progress tracking
- Verification job management
- Result polling with timeout
- Error handling and retry mechanisms
- Health check capabilities

### Usage Example

```dart
final apiService = VerificationApiService();

// Upload media
final uploadResponse = await apiService.uploadMedia(
  file: imageFile,
  userId: currentUser.uid,
);

// Start verification
final verificationResponse = await apiService.startVerification(
  mediaId: uploadResponse.mediaId,
  token: firebaseToken,
  verificationTypes: ['image', 'context'],
);

// Get results (with polling)
final result = await apiService.pollForResult(
  jobId: verificationResponse.jobId,
  token: firebaseToken,
  timeout: Duration(minutes: 10),
);
```

## Deployment

### Development Environment
```bash
# Navigate to microservices directory
cd server/microservices

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your configuration

# Run tests
python test_setup.py

# Start services
docker-compose up --build
```

### Production Deployment Options

#### Option A: Single VM (Budget Conscious)
- Single GPU-enabled VM
- Docker containers for each service
- NGINX as reverse proxy
- PostgreSQL and Redis on same VM

#### Option B: Kubernetes (Scalable)
- Separate GPU node pool
- Auto-scaling inference pods
- Managed services for database and caching
- CI/CD pipeline integration

## Environment Variables

Key configuration variables in `.env`:

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://host:6379/0

# Authentication
JWT_SECRET_KEY=your-secret-key
FIREBASE_PROJECT_ID=your-project-id

# API Keys
BING_API_KEY=your-key
TINEYE_API_KEY=your-key
NEWSAPI_KEY=your-key

# ML Configuration
ML_DEVICE=cuda  # or cpu
ML_BATCH_SIZE=32
```

## Security Features

- **Media Auto-deletion**: Raw media deleted after 24-48 hours
- **Encrypted Storage**: Sensitive data encryption
- **Rate Limiting**: Per-endpoint rate limiting
- **Malware Scanning**: File type validation and size limits
- **GDPR Compliance**: User data protection measures

## Monitoring and Observability

- **Logging**: Structured JSON logging
- **Health Checks**: Service health endpoints
- **Performance Metrics**: Response time monitoring
- **Error Tracking**: Exception monitoring and alerting
- **User Analytics**: Verification usage patterns

## Success Metrics

- Response time < 5 seconds for basic checks
- < 30 seconds for complex media analysis
- 99.9% uptime for core services
- User satisfaction rating > 4.5/5
- False positive rate < 5% for authentic content

## API Endpoints

### Authentication
- `POST /auth/validate` - Validate Firebase JWT token

### Media Management
- `POST /api/upload` - Upload media file
- `GET /api/media/{media_id}/status` - Get processing status
- `DELETE /api/media/{media_id}` - Delete media

### Verification
- `POST /api/analyze` - Start verification process
- `GET /api/results/{job_id}` - Get verification results
- `GET /api/status` - Service status

### Health
- `GET /health` - Basic health check
- `GET /health/ready` - Readiness check
- `GET /health/alive` - Liveness check

## Future Enhancements

1. **Advanced ML Models**: Integration with more sophisticated detection models
2. **Real-time Processing**: WebSocket support for live updates
3. **Multi-language Support**: NLP models for different languages
4. **Blockchain Integration**: Immutable verification records
5. **Federated Learning**: Collaborative model training while preserving privacy

This architecture provides a solid foundation for scalable, production-ready content verification services that can grow with the MIL Hub platform's needs.