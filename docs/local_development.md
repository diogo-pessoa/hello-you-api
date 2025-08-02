# Local Development Setup

This guide walks you through setting up the Hello World Birthday API for local development.


## Prerequisites

This project is managed through a single Makefile. Install the development tools for your platform:

### Mac OS Setup
```bash
# Install Xcode Command Line Tools (includes make, gcc, git)
xcode-select --install
```

## Makefile

```bash
make help
```

```bash
Hello World Birthday API - Development Commands

  setup-mac         Install all Mac prerequisites (Homebrew, Python, Git, etc.)
DEVELOPMENT:
  setup-venv        Create and activate virtual environment
  install           Install dependencies
  setup-env         Create .env file from template
  run               Run the application locally
  test              Run tests
  test-cov          Run tests with coverage report

  dev-up            Start development environment (Flask + PostgreSQL)
  dev-down          Stop development environment

  lint              Run all linting tools (pylint + flake8)
  pylint            Run pylint code analysis
  security          Run security analysis with bandit
  bandit            Run bandit SAST scan
  quality-check     Run all quality checks (tests, coverage, lint, security)
  clean             Clean up generated files


```

## Next Steps

- Run the test suite: [Testing Guide](local_testing.md)
- Build Docker container: [Docker Guide](docker.md)
- Review database schema: [Database Schema](db.md)