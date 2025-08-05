# Hello World Birthday API

[![Build, Push, and Deploy to ECS](https://github.com/diogo-pessoa/hello-you-api/actions/workflows/docker-image.yml/badge.svg)](https://github.com/diogo-pessoa/hello-you-api/actions/workflows/docker-image.yml)
[![CI Pipeline](https://github.com/diogo-pessoa/hello-you-api/actions/workflows/ci.yml/badge.svg)](https://github.com/diogo-pessoa/hello-you-api/actions/workflows/ci.yml)
[![Dependabot Updates](https://github.com/diogo-pessoa/hello-you-api/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/diogo-pessoa/hello-you-api/actions/workflows/dependabot/dependabot-updates)

A simple Flask-based REST API that manages user birthdays and provides personalized birthday messages.

## Description

This application provides HTTP-based APIs to:

- Store user information (username and date of birth)
- Retrieve personalized birthday messages based on how many days until their next birthday
- Return "Happy birthday!" message when it's the user's birthday

### System diagram and Terraform Deployment

- [System Architecture](docs/system_diagram.md)
- [Terraform](Terraform/README.md)

### API Endpoints

Live API: http://hello-you-api-dev-alb-2030191343.eu-central-1.elb.amazonaws.com

- **PUT** `/hello/<username>` - Save/update user's date of birth
```bash 
curl -X PUT http://hello-you-api-dev-alb-2030191343.eu-central-1.elb.amazonaws.com/hello/Phaedrus \
-H "Content-Type: application/json" \
  -d '{"dateOfBirth": "1928-09-06"}'
````
- **GET** `/hello/<username>` - Get personalized birthday message
```bash 
curl http://hello-you-api-dev-alb-2030191343.eu-central-1.elb.amazonaws.com/hello/Phaedrus
{"message":"Hello, robert! Your birthday is in 32 day(s)"}

````
- **GET** `/health` - Health check endpoint
```bash 
curl http://hello-you-api-dev-alb-2030191343.eu-central-1.elb.amazonaws.com/health
{"status":"healthy"}
````

- **GET** `/users`

```bash

curl -XGET http://hello-you-api-dev-alb-2030191343.eu-central-1.elb.amazonaws.com/users
[{"date_of_birth":"1928-09-06","username":"Phaedrus"},{"date_of_birth":"1928-09-06","username":"robert"}]
```

### Database

- ️[Database Schema](docs/db.md)

### App Development

- [Local Development Setup](docs/local_development.md)
- [Testing Guide](docs/local_testing.md)
- [Docker Compose Development](docs/run-local-dev.md)

### CI Pipelines

- [CI_CD-Pipeline-proposal.md](docs/CI_CD-Pipeline-proposal.md)
- [GitHub Actions](.github/workflows)

## License

MIT License - see LICENSE file for details.

