# Local Development with Docker Compose

Run the Flask app with PostgreSQL using Docker Compose for development.

## Quick Start

```bash
# Start Flask app + PostgreSQL
make dev-up

# Test the API
curl http://localhost:5000/health

# Stop everything
make dev-down
```

## What's Included

- **Flask App** - Running in development mode with debug logging
- **PostgreSQL 15** - Production-like database
- **Auto-restart** - Containers restart on failure
- **Health checks** - App waits for database to be ready

## Usage

### Start Development Environment
```bash
make dev-up
# or
docker-compose -f docker-compose.dev.yml up --build
```

### Test API Endpoints
```bash
# Save a user
curl -X PUT http://localhost:5000/hello/alice \
  -H "Content-Type: application/json" \
  -d '{"dateOfBirth": "1990-01-01"}'

# Get birthday message
curl http://localhost:5000/hello/alice

# Health check
curl http://localhost:5000/health
```

### Access PostgreSQL Database
```bash
# Connect with psql
psql -h localhost -U postgres -d helloworld
# Password: password

# Or use any PostgreSQL client
# Host: localhost, Port: 5432, User: postgres, Password: password, Database: helloworld
```

### View Logs
```bash
# All logs
docker-compose -f docker-compose.dev.yml logs -f

# App logs only
docker-compose -f docker-compose.dev.yml logs -f app

# Database logs only
docker-compose -f docker-compose.dev.yml logs -f db
```

### Stop Development Environment
```bash
make dev-down
# or
docker-compose -f docker-compose.dev.yml down
```

## Configuration

Environment variables are set in `docker-compose.dev.yml`:
- `FLASK_ENV=development` - Debug mode enabled
- `LOG_LEVEL=DEBUG` - Verbose logging
- `DATABASE_URL` - PostgreSQL connection string

## Data Persistence

Database data is stored in Docker volume `postgres_dev_data` and persists between restarts.

### Reset Database
```bash
# Stop and remove volumes
docker-compose -f docker-compose.dev.yml down -v

# Start fresh
make dev-up
```

## Troubleshooting

**Connection refused on localhost:5000**
- Check containers are running: `docker-compose -f docker-compose.dev.yml ps`
- Check app logs: `docker-compose -f docker-compose.dev.yml logs app`

**Database connection errors**
- Wait for health check: Database takes ~10 seconds to start
- Check database logs: `docker-compose -f docker-compose.dev.yml logs db`