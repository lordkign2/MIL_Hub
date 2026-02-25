# MIL Hub Verification Microservices

Production-ready verification microservice architecture for the MIL Hub platform.

## Quick Start

1. **Verify Setup**
   ```bash
   python test_setup.py
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start Services**
   ```bash
   docker-compose up --build
   ```

4. **Access Services**
   - API Gateway: http://localhost:8080
   - Orchestrator API: http://localhost:8000
   - Flower Monitoring: http://localhost:5555

## Architecture Overview

```
Flutter App → API Gateway (NGINX) → Verification Orchestrator → [Specialized Services] → Database
```

### Core Components

- **API Gateway**: NGINX with JWT validation and rate limiting
- **Orchestrator**: FastAPI service managing verification workflows
- **Database**: PostgreSQL with pgvector for similarity search
- **Caching**: Redis for sessions and task queues
- **Microservices**: Specialized services for image, video, and context verification

## Documentation

- [Full Architecture Documentation](docs/MICROSERVICE_ARCHITECTURE.md)
- [API Reference](docs/API_REFERENCE.md) *(coming soon)*
- [Deployment Guide](docs/DEPLOYMENT.md) *(coming soon)*

## Development

### Directory Structure
```
microservices/
├── api_gateway/          # NGINX configuration
├── orchestrator/         # FastAPI orchestrator service
├── services/             # Specialized microservices
│   ├── image_verification/
│   ├── video_verification/
│  └── context_engine/
├── database/             # Database schema and migrations
├── ml/                  # ML model serving infrastructure
├── scoring/             # Trust scoring engine
└── config/              # Configuration files
```

### Testing

```bash
# Run setup verification
python test_setup.py

# Test individual components
# (Add specific test commands here)
```

## Security Features

- JWT authentication with Firebase
- Rate limiting per endpoint
- File type and size validation
- Media auto-deletion after processing
- Encrypted data storage
- Security headers and CORS protection

## Monitoring

- Health check endpoints
- Structured JSON logging
- Performance metrics
- Error tracking and alerting
- Service dependency monitoring

## Contributing

1. Follow the existing code structure
2. Add tests for new functionality
3. Update documentation
4. Ensure security best practices

## License

This project is part of the MIL Hub platform.