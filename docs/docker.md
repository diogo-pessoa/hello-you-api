# Docker Guide

This guide covers building, running, and deploying the Hello World Birthday API using Docker containers.

## Docker Overview

The application uses a **production-ready Docker setup** with:
- ✅ **Red Hat UBI 9 Python 3.11** hardened base image
- ✅ **Non-root user** execution (UID 1001)
- ✅ **Minimal attack surface** (no shell access)
- ✅ **Multi-architecture** support (amd64/arm64)
- ✅ **Security scanning** with Trivy
- ✅ **Health checks** built-in

## Quick Start

### Build and Run
```bash
# Build the Docker image
make docker-build

# Run the container
make docker-run

# Test the API
curl http://localhost:5000/health
```

### Manual Docker Commands
```bash
# Build image
docker build -t helloworld-app:latest .

# Run container
docker run -p 5000:5000 --name helloworld-container helloworld-app:latest

# Stop and remove container
docker stop helloworld-container
docker rm helloworld-container
```

## Dockerfile Architecture

### Base Image
```dockerfile
FROM registry.access.redhat.com/ubi9/python-311:latest
```
- **Red Hat Universal Base Image (UBI)** - Enterprise-grade, hardened
- **Python 3.11** - Latest stable Python version
- **No shell** - Reduced attack surface
- **CVE scanning** - Regularly updated for security

### Security Features

**1. Non-root User**
```dockerfile
# Uses existing UID 1001 from base image
USER 1001
```

**2. Minimal Permissions**
```dockerfile
# Only necessary file permissions
RUN chown -R 1001:0 /app && chmod 755 /app
```

**3. System Dependencies**
```dockerfile
# Only PostgreSQL dependencies for production
RUN dnf install -y postgresql-devel gcc python3-devel
```

**4. Clean Image**
```dockerfile
# Remove package manager caches
RUN dnf clean all && rm -rf /var/cache/dnf
```

## Production Configuration

### Environment Variables
The container uses these production settings:
```dockerfile
ENV FLASK_ENV=production
ENV DATABASE_URL=sqlite:///data/helloworld.db
ENV PORT=5000
```

### Runtime Configuration
```dockerfile
# Gunicorn production server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", 
     "--workers", "2", 
     "--timeout", "60", 
     "--access-logfile", "-", 
     "--error-logfile", "-", 
     "app:app"]
```

### Health Checks
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1
```

## Database Configuration

### SQLite (Default)
```bash
# Uses persistent volume for SQLite database
docker run -p 5000:5000 \
  -v $(pwd)/data:/app/data \
  helloworld-app:latest
```

### PostgreSQL (Production)
```bash
# Run with PostgreSQL connection
docker run -p 5000:5000 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  helloworld-app:latest
```

## Advanced Usage

### Custom Environment Variables
```bash
# Override default settings
docker run -p 8080:8080 \
  -e PORT=8080 \
  -e LOG_LEVEL=DEBUG \
  -e SECRET_KEY=your-secret-key \
  helloworld-app:latest
```

### Volume Mounts
```bash
# Persist SQLite database
docker run -p 5000:5000 \
  -v $(pwd)/data:/app/data \
  --name helloworld-persistent \
  helloworld-app:latest
```

### Network Configuration
```bash
# Create custom network
docker network create helloworld-net

# Run with custom network
docker run -p 5000:5000 \
  --network helloworld-net \
  --name helloworld-app \
  helloworld-app:latest
```

## Docker Compose

### Basic Setup
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=sqlite:///data/helloworld.db
    volumes:
      - ./data:/app/data
    restart: unless-stopped
```

### With PostgreSQL
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/helloworld
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=helloworld
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

## Container Registry

### GitHub Container Registry

**Build and Push**
```bash
# Tag for GitHub Container Registry
docker tag helloworld-app:latest ghcr.io/yourusername/helloworld-app:latest

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u yourusername --password-stdin

# Push image
docker push ghcr.io/yourusername/helloworld-app:latest
```

**Pull and Run**
```bash
# Pull from registry
docker pull ghcr.io/yourusername/helloworld-app:latest

# Run pulled image
docker run -p 5000:5000 ghcr.io/yourusername/helloworld-app:latest
```

## CI/CD Integration

### GitHub Actions
The repository includes `.github/workflows/docker.yml` that:
1. **Builds** the image on every push
2. **Tests** the application before building
3. **Scans** for security vulnerabilities
4. **Pushes** to GitHub Container Registry
5. **Tags** with branch names and versions

### Automatic Builds
```yaml
# Triggered on:
on:
  push:
    branches: [ main, develop ]
    tags: [ 'v*' ]
```

### Security Scanning
```yaml
# Uses Trivy for vulnerability scanning
- name: Run security scan
  uses: aquasecurity/trivy-action@master
```

## Monitoring and Logging

### Container Logs
```bash
# View application logs
docker logs helloworld-container

# Follow logs in real-time
docker logs -f helloworld-container

# View last 100 lines
docker logs --tail 100 helloworld-container
```

### Health Monitoring
```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' helloworld-container

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' helloworld-container
```

### Resource Usage
```bash
# Monitor resource usage
docker stats helloworld-container

# View container details
docker inspect helloworld-container
```

## Production Deployment

### Resource Limits
```bash
# Run with memory and CPU limits
docker run -p 5000:5000 \
  --memory=256m \
  --cpus=0.5 \
  --restart=unless-stopped \
  helloworld-app:latest
```

### Security Context
```bash
# Run with additional security options
docker run -p 5000:5000 \
  --read-only \
  --tmpfs /tmp \
  --security-opt=no-new-privileges:true \
  helloworld-app:latest
```

## Troubleshooting

### Common Issues

**1. Port conflicts**
```bash
# Check what's using port 5000
lsof -i :5000

# Use different port
docker run -p 8080:5000 helloworld-app:latest
```

**2. Permission issues**
```bash
# Check container user
docker exec helloworld-container id

# Expected output: uid=1001 gid=0(root)
```

**3. Database connection issues**
```bash
# Check database connectivity
docker exec -it helloworld-container python -c "
from models import db
print('Database connection:', db.engine.url)
"
```

**4. Build failures**
```bash
# Build with verbose output
docker build --progress=plain -t helloworld-app:latest .

# Build without cache
docker build --no-cache -t helloworld-app:latest .
```

### Debug Container
```bash
# Run container with shell access (for debugging only)
docker run -it --entrypoint /bin/bash helloworld-app:latest

# Check container filesystem
docker exec -it helloworld-container ls -la /app
```

## Performance Tuning

### Gunicorn Configuration
```bash
# Tune worker processes based on CPU cores
docker run -p 5000:5000 \
  -e GUNICORN_WORKERS=4 \
  -e GUNICORN_TIMEOUT=120 \
  helloworld-app:latest
```

### Memory Optimization
```bash
# Monitor memory usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
```

## Next Steps

- Review database schema: [Database Schema](db.md)
- Understand system architecture: [System Diagram](system_diagram.md)
- Set up local development: [Local Development](local_development.md)