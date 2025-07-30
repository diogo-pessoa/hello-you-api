# Hello World Birthday API

A simple Flask-based REST API that manages user birthdays and provides personalized birthday messages.

## Description

This application provides HTTP-based APIs to:
- Store user information (username and date of birth)
- Retrieve personalized birthday messages based on how many days until their next birthday
- Return "Happy birthday!" message when it's the user's birthday

### API Endpoints

- **PUT** `/hello/<username>` - Save/update user's date of birth
- **GET** `/hello/<username>` - Get personalized birthday message
- **GET** `/health` - Health check endpoint

## Quick Start

### Local Development
```bash
# Clone the repository
git clone <repository-url>
cd helloworld-app

# Option 1: SQLite (simplest)
cp .env.example .env
make install
make run

# Option 2: PostgreSQL with Docker Compose
make dev-up
```

### Docker (Production)
```bash
# Build and run container
make docker-build
make docker-run

# Test the API
curl http://localhost:5000/health
```

### Test the API
```bash
# Save a user
curl -X PUT http://localhost:5000/hello/john \
  -H "Content-Type: application/json" \
  -d '{"dateOfBirth": "1990-01-01"}'

# Get birthday message
curl http://localhost:5000/hello/john
```

## Documentation

- 📖 [Local Development Setup](docs/local_development.md)
- 🧪 [Testing Guide](docs/local_testing.md)
- 🗄️ [Database Schema](docs/db.md)
- 🐳 [Docker Guide](docs/docker.md)
- 🏗️ [System Architecture](docs/system_diagram.md)
- 🐳 [Docker Compose Development](docs/run-local-dev.md)


## License

MIT License - see LICENSE file for details.