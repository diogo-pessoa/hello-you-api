docker rm -f helloworld-container 2>/dev/null || true	@echo "  docker-run        Run Docker container".PHONY: help install test test-cov run clean docker-build docker-run dev-up dev-down terraform-init terraform-plan terraform-apply terraform-destroy

help:
	@echo "Available commands:"
	@echo "  install       Install dependencies"
	@echo "  test          Run tests"
	@echo "  test-cov      Run tests with coverage report"
	@echo "  run           Run the application locally"
	@echo "  docker-build  Build Docker image"
	@echo "  dev-up        Start development environment (Flask + PostgreSQL)"
	@echo "  dev-down      Stop development environment"
	@echo "  terraform-init Initialize Terraform"
	@echo "  terraform-plan Show Terraform execution plan"
	@echo "  terraform-apply Apply Terraform configuration"
	@echo "  terraform-destroy Destroy Terraform infrastructure"
	@echo "  clean         Clean up generated files"

install:
	pip install -r requirements-local.txt

test:
	cd app && pytest ../tests/ -v

test-cov:
	cd app && pytest ../tests/ --cov=. --cov-report=term-missing --cov-report=html -v

run:
	cd app && python app.py

docker-build:
	docker build -t helloworld-app:latest .

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

clean:
	rm -rf __pycache__/
	rm -rf app/__pycache__/
	rm -rf tests/__pycache__/
	rm -rf .pytest_cache/
	rm -rf htmlcov/
	rm -rf .coverage
	rm -f *.db
	rm -f instance/*.db
	find . -type d -name "__pycache__" -delete
	find . -type f -name "*.pyc" -delete
	docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true