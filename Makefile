.PHONY: help install test test-cov run clean docker-build docker-run dev-up dev-down lint bandit pylint quality-check setup-venv setup-env db-init db-migrate db-upgrade db-downgrade first-time-setup

help:
	@echo "Hello World Birthday API - Development Commands"
	@echo "DEVELOPMENT:"
	@echo "  setup-venv        Create and activate virtual environment"
	@echo "  install           Install dependencies"
	@echo "  setup-env         Create .env file from template"
	@echo "  run               Run the application locally"
	@echo "  test              Run tests"
	@echo "  test-cov          Run tests with coverage report"
	@echo ""
	@echo "  dev-up            Start development environment with Docker (Flask + PostgreSQL)"
	@echo "  dev-down          Stop development environment"
	@echo ""
	@echo "DATABASE MIGRATIONS:"
	@echo "  db-init           Initialize migration folder"
	@echo "  db-migrate        Generate migration script"
	@echo "  db-upgrade        Apply migrations to database"
	@echo "  db-downgrade      Revert last migration"
	@echo ""
	@echo "CODE QUALITY:"
	@echo "  lint              Run pylint and flake8 checks"
	@echo "  bandit            Run bandit SAST scan"
	@echo "  quality-check     Run all quality checks (tests, coverage, lint, security)"
	@echo ""
	@echo "  clean             Clean up generated files"

setup-venv:
	@echo "🐍 Setting up Python virtual environment..."
	@if [ ! -d ".venv" ]; then \
		echo "Creating virtual environment..."; \
		python3 -m venv .venv; \
		echo "Virtual environment created!"; \
	else \
		echo "Virtual environment already exists"; \
	fi
	@echo ""
	@echo "To activate the virtual environment, run:"
	@echo "  source .venv/bin/activate"

setup-env:
	@echo "Setting up environment configuration."
	@if [ ! -f ".env" ]; then \
		echo "FLASK_ENV=development" > .env; \
		echo "PORT=5000" >> .env; \
		echo "DATABASE_URL=sqlite:///hello_you.db" >> .env; \
		echo "✅ Created basic .env file"; \
	else \
		echo ".env file already exists"; \
	fi

install:
	@echo "📦 Installing dependencies..."
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && pip install -r requirements.txt; \
		else \
			pip3 install -r requirements.txt; \
		fi \
	)

test:
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && pytest tests/ -v; \
		else \
			pytest tests/ -v; \
		fi \
	)

test-cov:
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && pytest tests/ --cov=. --cov-report=term-missing --cov-report=html -v; \
		else \
			pytest tests/ --cov=. --cov-report=term-missing --cov-report=html -v; \
		fi \
	)

run:
	@echo "Starting local development server"
	@echo "Server available at http://localhost:5000"
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && python app.py; \
		else \
			python app.py; \
		fi \
	)

docker-build:
	docker build -t hello-you-api .

docker-run:
	docker run -p 5000:5000 hello-you-api

dev-up:
	@echo "Starting docker-compose Hello-you-app"
	docker-compose -f docker-compose.dev.yml up --build

dev-down:
	@echo "Stopping docker-compose environment"
	docker-compose -f docker-compose.dev.yml down -v

lint: pylint
	@echo "Running flake8"
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && flake8 . --max-line-length=100 --exclude=__pycache__,.venv,migrations; \
		else \
			flake8 . --max-line-length=100 --exclude=__pycache__,.venv,migrations; \
		fi \
	)

pylint:
	@echo "Running pylint."
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && pylint *.py --output-format=text --score=yes || true; \
		else \
			pylint *.py --output-format=text --score=yes || true; \
		fi \
	)

bandit:
	@echo "Running bandit security scan."
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && bandit -r . -ll || true; \
		else \
			bandit -r . -ll || true; \
		fi \
	)

db-init:
	@echo "Initializing migration folder..."
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && flask db init || true; \
		else \
			flask db init || true; \
		fi \
	)

db-migrate:
	@echo "Creating migration..."
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && flask db migrate -m "database changes"; \
		else \
			flask db migrate -m "database changes"; \
		fi \
	)

db-upgrade:
	@echo "Applying migrations..."
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && flask db upgrade; \
		else \
			flask db upgrade; \
		fi \
	)

db-downgrade:
	@echo "Downgrading last migration..."
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && flask db downgrade; \
		else \
			flask db downgrade; \
		fi \
	)

clean:
	@echo "Cleaning up generated files."
	rm -rf __pycache__/ .pytest_cache/ htmlcov/ .coverage *.db
	find . -type d -name "__pycache__" -delete
	find . -type f -name "*.pyc" -delete
	docker rm -f hello-you-api-container 2>/dev/null || true
	docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true
	@echo "Cleanup complete!"

quality-check: test-cov lint bandit clean
	@echo "All quality checks completed!"
