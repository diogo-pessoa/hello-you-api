.PHONY: help install test test-cov run clean docker-build docker-run dev-up dev-down

help:
	@echo "Available commands:"
	@echo "  install       Install dependencies"
	@echo "  test          Run tests"
	@echo "  test-cov      Run tests with coverage report"
	@echo "  run           Run the application locally"
	@echo "  docker-build  Build Docker image"
	@echo "  docker-run    Run Docker container"
	@echo "  dev-up        Start development environment (Flask + PostgreSQL)"
	@echo "  dev-down      Stop development environment"
	@echo "  clean         Clean up generated files"

install:
	pip install -r requirements-local.txt

test:
	pytest test_app.py -v

test-cov:
	pytest test_app.py --cov=. --cov-report=term-missing --cov-report=html -v

run:
	python app.py

docker-build:
	docker build -t helloworld-app:latest .

docker-run:
	docker run -p 5000:5000 --name helloworld-container helloworld-app:latest

dev-up:
	docker-compose -f docker-compose.dev.yml up --build

dev-down:
	docker-compose -f docker-compose.dev.yml down

clean:
	rm -rf __pycache__/
	rm -rf .pytest_cache/
	rm -rf htmlcov/
	rm -f .coverage
	rm -f *.db
	find . -type d -name "__pycache__" -delete
	find . -type f -name "*.pyc" -delete
	docker rm -f helloworld-container 2>/dev/null || true
	docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true