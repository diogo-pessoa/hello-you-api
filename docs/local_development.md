# Local Development Setup

This guide walks you through setting up the Hello World Birthday API for local development.

## Prerequisites

- **Python 3.11+** installed
- **pip** package manager
- **Git** for version control
- **curl** for testing API endpoints

## Step-by-Step Setup

### 1. Clone and Navigate
```bash
git clone <repository-url>
cd helloworld-app
```

### 2. Create Virtual Environment
```bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment
# On macOS/Linux:
source .venv/bin/activate

# On Windows:
.venv\Scripts\activate
```

### 3. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your preferences
# Default values work for local development
```

### 4. Install Dependencies
```bash
# Install local development dependencies (includes testing tools)
make install

# Or manually:
pip install -r requirements-local.txt
```

### 5. Run the Application
```bash
# Start the development server
make run

# Or manually:
python app.py
```

The application will start on `http://localhost:5000`

### 6. Verify Installation
```bash
# Test health endpoint
curl http://localhost:5000/health

# Expected response:
# {"status": "healthy"}
```

## Environment Variables

The `.env` file controls the application behavior:

```bash
# Flask Configuration
FLASK_ENV=development          # Enables debug mode
SECRET_KEY=your-secret-key-here
PORT=5000                      # Server port

# Database Configuration
DATABASE_URL=sqlite:///helloworld_dev.db  # SQLite for local dev

# Logging Configuration
LOG_LEVEL=INFO                 # DEBUG, INFO, WARNING, ERROR
```

## Development Workflow

### File Structure
```
helloworld-app/
├── app.py              # Main Flask application setup
├── models.py           # User database model
├── routes.py           # API endpoint handlers  
├── validators.py       # Input validation functions
├── config.py           # Configuration and logging setup
└── test_app.py         # Test suite
```

### Making Changes

1. **Models** (`models.py`) - Database schema changes
2. **Routes** (`routes.py`) - API endpoint logic
3. **Validators** (`validators.py`) - Input validation rules
4. **Config** (`config.py`) - Environment and logging setup

### Hot Reloading

When `FLASK_ENV=development`, the server automatically reloads when you save changes to Python files.

## Database

### SQLite (Default)
- **File**: `helloworld_dev.db` (created automatically)
- **Location**: Project root directory
- **Schema**: Automatically created on first run

### Switching to PostgreSQL
```bash
# Update .env file
DATABASE_URL=postgresql://username:password@localhost:5432/helloworld

# Install PostgreSQL dependencies
pip install psycopg2-binary
```

## Logging

Development logs are printed to console with this format:
```
2025-07-30 11:45:23,456 - app - INFO - PUT request for user: john
2025-07-30 11:45:23,458 - app - INFO - Creating new user: john
```

**Log Levels**: `DEBUG`, `INFO`, `WARNING`, `ERROR`

## Common Development Tasks

### Check Code Structure
```bash
# View all available commands
make help

# Clean up generated files
make clean
```

### Database Operations
```bash
# Database file is automatically created
# To reset database, simply delete the .db file
rm *.db

# Restart the application to recreate tables
make run
```

### API Testing During Development
```bash
# Save a user
curl -X PUT http://localhost:5000/hello/alice \
  -H "Content-Type: application/json" \
  -d '{"dateOfBirth": "1995-03-15"}'

# Get birthday message
curl http://localhost:5000/hello/alice

# Test validation (invalid username)
curl -X PUT http://localhost:5000/hello/alice123 \
  -H "Content-Type: application/json" \
  -d '{"dateOfBirth": "1995-03-15"}'
```

## Troubleshooting

### Common Issues

**1. Port 5000 already in use**
```bash
# Change port in .env file
PORT=8000

# Or kill the process using port 5000
lsof -ti:5000 | xargs kill -9
```

**2. SQLite permission errors**
```bash
# Ensure write permissions in project directory
chmod 755 .
```

**3. Python version issues**
```bash
# Check Python version
python --version

# Use specific Python version
python3.11 -m venv .venv
```

**4. Virtual environment issues**
```bash
# Deactivate and recreate
deactivate
rm -rf .venv
python -m venv .venv
source .venv/bin/activate
make install
```

## Next Steps

- Run the test suite: [Testing Guide](local_testing.md)
- Build Docker container: [Docker Guide](docker.md)
- Review database schema: [Database Schema](db.md)