.PHONY: help install test test-cov run clean docker-build docker-run dev-up dev-down terraform-init terraform-plan terraform-apply terraform-destroy lint security bandit pylint quality-check

help:
	@echo "Available commands:"
	@echo "  install           Install dependencies"
	@echo "  test              Run tests"
	@echo "  test-cov          Run tests with coverage report"
	@echo "  run               Run the application locally"
	@echo "  docker-build      Build Docker image"
	@echo "  docker-run        Run Docker container"
	@echo "  dev-up            Start development environment (Flask + PostgreSQL)"
	@echo "  dev-down          Stop development environment"
	@echo "  terraform-init    Initialize Terraform"
	@echo "  terraform-plan    Show Terraform execution plan"
	@echo "  terraform-apply   Apply Terraform configuration"
	@echo "  terraform-destroy Destroy Terraform infrastructure"
	@echo "  lint              Run all linting tools (pylint + flake8)"
	@echo "  pylint            Run pylint code analysis"
	@echo "  security          Run security analysis with bandit"
	@echo "  bandit            Run bandit SAST scan"
	@echo "  quality-check     Run all quality checks (tests, coverage, lint, security)"
	@echo "  clean             Clean up generated files"

install:
	pip install -r requirements-local.txt

test:
	pytest tests/ -v

test-cov:
	pytest tests/ --cov=app --cov-report=term-missing --cov-report=html -v

run:
	cd app && python app.py

docker-build:
	docker build -t helloworld-app:latest .

docker-run:
	docker rm -f helloworld-container 2>/dev/null || true
	docker run -d --name helloworld-container -p 5000:5000 helloworld-app:latest

dev-up:
	docker-compose -f docker-compose.dev.yml up --build

dev-down:
	docker-compose -f docker-compose.dev.yml down

# Terraform commands
terraform-init:
	cd terraform && terraform init

terraform-plan:
	cd terraform && terraform plan

terraform-apply:
	cd terraform && terraform apply

terraform-destroy:
	cd terraform && terraform destroy

# Code quality commands
lint: pylint
	@echo "Running flake8..."
	flake8 app/ --max-line-length=100 --exclude=__pycache__

pylint:
	@echo "Running pylint..."
	pylint app/ --output-format=text --score=yes || true

security: bandit

bandit:
	@echo "Running bandit security scan..."
	bandit -r app/ -ll || true

quality-check: test-cov lint security
	@echo "All quality checks completed!"

clean:
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