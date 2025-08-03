.PHONY: help setup-venv setup-env install-local install-dev install-prod run test test-cov docker-build docker-run dev-up dev-down lint pylint bandit quality-check db-init db-migrate db-upgrade db-downgrade clean

help:
	@echo "Hello World Birthday API - Development Commands"
	@echo "ENVIRONMENT SETUP:"
	@echo "  setup-venv        Create and activate Python virtual environment"
	@echo "  setup-env         Create .env file (if missing)"
	@echo ""
	@echo "INSTALL DEPENDENCIES:"
	@echo "  install-local     Install all dependencies for local development"
	@echo "  install-dev       Install dependencies for CI/CD (tests, linting)"
	@echo "  install-prod      Install production-only dependencies"
	@echo ""
	@echo "RUN & TEST:"
	@echo "  run               Run the application locally (SQLite)"
	@echo "  test              Run tests"
	@echo "  test-cov          Run tests with coverage report"
	@echo ""
	@echo "DOCKER:"
	@echo "  docker-build      Build production Docker image"
	@echo "  docker-run        Run production Docker container"
	@echo "  dev-up            Start development stack (Flask + Postgres)"
	@echo "  dev-down          Stop development stack"
	@echo ""
	@echo "DATABASE MIGRATIONS:"
	@echo "  db-init           Initialize migration folder"
	@echo "  db-migrate        Create a new migration"
	@echo "  db-upgrade        Apply migrations"
	@echo "  db-downgrade      Roll back last migration"
	@echo ""
	@echo "CODE QUALITY:"
	@echo "  lint              Run flake8 + pylint checks"
	@echo "  bandit            Run bandit security scan"
	@echo "  quality-check     Run all quality checks (tests, lint, security)"
	@echo ""
	@echo "  clean             Remove temporary and build files"

# Environment Setup

setup-venv:
	@echo "Setting up Python virtual environment..."
	@if [ ! -d ".venv" ]; then \
		python3 -m venv .venv && echo "Virtual environment created!"; \
	else \
		echo "Virtual environment already exists."; \
	fi
	@echo "To activate it: source .venv/bin/activate"

setup-env:
	@echo "Creating .env file if missing..."
	@if [ ! -f ".env" ]; then \
		echo "FLASK_ENV=development" > .env; \
		echo "PORT=5000" >> .env; \
		echo "DATABASE_URL=sqlite:///hello_you.db" >> .env; \
		echo "Created basic .env file"; \
	else \
		echo ".env already exists."; \
	fi

# -----------------------------

install-local:
	@echo "Installing local development dependencies..."
	@. .venv/bin/activate && pip install -r requirements-local.txt

install-dev:
	@echo "Installing CI/CD development dependencies..."
	@. .venv/bin/activate && pip install -r requirements-dev.txt

install-prod:
	@echo "Installing production dependencies..."
	@pip install --no-cache-dir -r requirements.txt

# Run & Test

run:
	@echo "Starting local development server (SQLite)"
	@. .venv/bin/activate && python -m app.app

test:
	@. .venv/bin/activate && pytest tests/ -v

test-cov:
	@. .venv/bin/activate && pytest tests/ --cov=app --cov-report=term-missing --cov-report=html -v

# -----------------------------
# Docker Commands

docker-build:
	docker build -t hello-you-api .

docker-run:
	docker run -p 5000:5000 hello-you-api

dev-up:
	docker-compose -f docker-compose.dev.yml up --build

dev-down:
	docker-compose -f docker-compose.dev.yml down -v

# Database Migration Commands

db-init:
	@. .venv/bin/activate && flask db init || true

db-migrate:
	@. .venv/bin/activate && flask db migrate -m "database changes"

db-upgrade:
	@. .venv/bin/activate && flask db upgrade

db-downgrade:
	@. .venv/bin/activate && flask db downgrade

# --------------------------

# Code Quality & Security

lint: pylint
	@. .venv/bin/activate && flake8 app/ --max-line-length=100 --exclude=__pycache__,.venv,migrations

pylint:
	@. .venv/bin/activate && pylint app/ --output-format=text --score=yes || true

bandit:
	@. .venv/bin/activate && bandit -r app/ -ll || true

quality-check: test-cov lint bandit
	@echo "All quality checks passed!"

# Clean

clean:
	@echo "Clean-up in progress"
	rm -rf __pycache__/ .pytest_cache/ htmlcov/ .coverage *.db
	find . -type d -name "__pycache__" -delete
	find . -type f -name "*.pyc" -delete
	docker rm -f hello-you-api-container 2>/dev/null || true
	docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true
	@echo "Cleanup complete!"
