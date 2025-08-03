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

### App Development

- [Local Development Setup](docs/local_development.md)
- [Testing Guide](docs/local_testing.md)
- [Docker Compose Development](docs/run-local-dev.md)
- [Docker Guide](docs/docker.md)

### Database
- ️[Database Schema](docs/db.md)

### CI Pipelines

#TODO 

- [ci.yml](.github/workflows/ci.yml)

#TODO
- [docker-image.yml](.github/workflows/docker-image.yml)

### System diagram and Terraform Deployment

- [System Architecture](docs/system_diagram.md)
- [Terraform](Terraform/README.md)

## License
MIT License - see LICENSE file for details.