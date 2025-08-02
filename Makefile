.PHONY: help install test test-cov run clean docker-build docker-run dev-up dev-down terraform-init terraform-plan terraform-apply terraform-destroy lint security bandit pylint quality-check setup-mac check-prereqs setup-venv setup-env first-time-setup

help:
	@echo "Hello World Birthday API - Development Commands"
	@echo "  setup-mac         Install all Mac prerequisites (Homebrew, Python, Git, etc.)"
	@echo "DEVELOPMENT:"
	@echo "  setup-venv        Create and activate virtual environment"
	@echo "  install           Install dependencies"
	@echo "  setup-env         Create .env file from template"
	@echo "  run               Run the application locally"
	@echo "  test              Run tests"
	@echo "  test-cov          Run tests with coverage report"
	@echo ""
	@echo "  dev-up            Start development environment (Flask + PostgreSQL)"
	@echo "  dev-down          Stop development environment"
	@echo ""
	@echo "  lint              Run all linting tools (pylint + flake8)"
	@echo "  pylint            Run pylint code analysis"
	@echo "  security          Run security analysis with bandit"
	@echo "  bandit            Run bandit SAST scan"
	@echo "  quality-check     Run all quality checks (tests, coverage, lint, security)"
	@echo "  clean             Clean up generated files"

# Mac-specific setup commands
setup-mac:
	@echo "Setting up (Mac only) development environment"
	@echo "Installing Homebrew (if not already installed)"
	@/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || echo "Homebrew already installed or installation failed"
	@echo "Installing Python 3.11"
	@brew install python@3.11 || echo "Python 3.11 already installed"
	@echo "Installing Git"
	@brew install git || echo "Git already installed"
	@echo "Installing curl"
	@brew install curl || echo "curl already installed"
	@echo "Installing Docker Desktop (if not installed)"
	@brew install --cask docker || echo "Docker already installed"
	@echo "Installing PostgreSQL client tools"
	@brew install postgresql@15 || echo "PostgreSQL already installed"
	@echo ""
	@echo "Initial setup done."

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
	@echo ""
	@echo "Note: The virtual environment will be automatically activated for other make commands"

setup-env:
	@echo "Setting up environment configuration."
	@if [ ! -f ".env" ]; then \
		if [ -f ".env.example" ]; then \
			cp .env.example .env; \
			echo "Created .env file from template"; \
		else \
			echo "Creating basic .env file..."; \
			echo "FLASK_ENV=development" > .env; \
			echo "SECRET_KEY=your-secret-key-here-$$(date +%s)" >> .env; \
			echo "PORT=5000" >> .env; \
			echo "DATABASE_URL=sqlite:///helloworld_dev.db" >> .env; \
			echo "LOG_LEVEL=INFO" >> .env; \
			echo "✅ Created basic .env file"; \
		fi; \
	else \
		echo ".env file already exists"; \
	fi
	@echo ""
	@echo "You can edit .env file to customize your settings"

# Enhanced install command that ensures venv activation
install:
	@echo "📦 Installing dependencies..."
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && pip install -r requirements-local.txt; \
		else \
			pip3 install -r requirements-local.txt; \
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
			. .venv/bin/activate && pytest tests/ --cov=app --cov-report=term-missing --cov-report=html -v; \
		else \
			pytest tests/ --cov=app --cov-report=term-missing --cov-report=html -v; \
		fi \
	)

run:
	@echo "Starting local development server"
	@echo "Server will be available at http://localhost:5000"
	@echo "Press Ctrl+C to stop"
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && cd app && python app.py; \
		else \
			cd app && python app.py; \
		fi \
	)

docker-dev-up:
	@echo "Starting docker-compose-dev Hello-you-app (DB and flask)"
	@echo "Server will be available at http://localhost:5000"
	@echo "Press Ctrl+C to stop, make sure to run docker-dev-down to clean-up docker resources"
	docker-compose -f docker-compose.dev.yml up --build

docker-dev-down:
	@echo "Removing docker-compose-dev resources"
	docker-compose -f docker-compose.dev.yml down

# Code quality commands with venv support
lint: pylint
	@echo "Running flake8"
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && flake8 app/ --max-line-length=100 --exclude=__pycache__; \
		else \
			flake8 app/ --max-line-length=100 --exclude=__pycache__; \
		fi \
	)

pylint:
	@echo "Running pylint."
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && pylint app/ --output-format=text --score=yes || true; \
		else \
			pylint app/ --output-format=text --score=yes || true; \
		fi \
	)

security: bandit

bandit:
	@echo "Running bandit security scan."
	@( \
		if [ -f ".venv/bin/activate" ]; then \
			. .venv/bin/activate && bandit -r app/ -ll || true; \
		else \
			bandit -r app/ -ll || true; \
		fi \
	)

clean:
	@echo "Cleaning up generated files."
	rm -rf __pycache__/
	rm -rf app/__pycache__/
	rm -rf .pytest_cache/
	rm -rf htmlcov/
	rm -rf .coverage
	rm -f *.db
	rm -f instance/*.db
	rm -f pylint-report.txt
	rm -f bandit-report.json
	rm -f bandit-report.txt
	find . -type d -name "__pycache__" -delete
	find . -type f -name "*.pyc" -delete
	docker rm -f helloworld-container 2>/dev/null || true
	docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true
	@echo "Cleanup complete!"

quality-check: test-cov lint security clean
	@echo "All quality checks completed!"