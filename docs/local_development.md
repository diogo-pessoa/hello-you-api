## Prerequisites

This project uses a single `Makefile` to simplify development tasks.

## Getting Started

You can set up and run the application locally using only `make` commands:

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/hello-world-birthday-api.git
   cd hello-world-birthday-api
   ```

2. **Create a virtual environment**

   ```bash
   make setup-venv
   ```

3. **Create `.env` file**

   ```bash
   make setup-env
   ```

4. **Install dependencies**

   ```bash
   make install-local
   ```

5. **Run the application**

   ```bash
   make run
   ```

   The API will be available at `http://localhost:5000`

6. **Run tests**

   ```bash
   make test
   ```

### Main Commands

**Environment Setup:**

* `make setup-venv` → Create and activate Python virtual environment
* `make setup-env` → Create `.env` file (if missing)

**Install Dependencies:**

* `make install-local` → Install all dependencies for local development
* `make install-dev` → Install dependencies for CI/CD (tests, linting)
* `make install-prod` → Install production-only dependencies

**Run & Test:**

* `make run` → Run the application locally (SQLite)
* `make test` → Run tests
* `make test-cov` → Run tests with coverage report

**Docker:**

* `make docker-build` → Build production Docker image
* `make docker-run` → Run production Docker container
* `make dev-up` → Start development stack (Flask + Postgres)
* `make dev-down` → Stop development stack

**Database Migrations:**

* `make db-init` → Initialize migration folder
* `make db-migrate` → Create a new migration
* `make db-upgrade` → Apply migrations
* `make db-downgrade` → Roll back last migration

**Code Quality & Security:**

* `make lint` → Run flake8 + pylint checks
* `make bandit` → Run bandit security scan
* `make quality-check` → Run all quality checks (tests, lint, security)

**Cleanup:**

* `make clean` → Remove temporary and build files

## Next Steps

* Run the test suite: [Testing Guide](local_testing.md)
* Build Docker container: [Docker Guide](docker.md)
* Review database schema: [Database Schema](db.md)
