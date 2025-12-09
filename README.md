# Spring Boot + Angular + Hetzner Cloud Template

🚀 **Production-ready template** for deploying Spring Boot backend and Angular frontend to Hetzner Cloud with Infrastructure as Code (Terraform) and automated CI/CD pipelines.

## Features

- ✅ **Spring Boot 3** with Java 21
- ✅ **Angular 17** with TypeScript
- ✅ **PostgreSQL** database
- ✅ **Docker** & **Docker Compose**
- ✅ **Terraform** for infrastructure provisioning
- ✅ **GitHub Actions** CI/CD pipeline
- ✅ **Traefik** reverse proxy with automatic SSL
- ✅ **Hetzner Cloud** deployment (~5-10 EUR/month)
- ✅ **Health checks** and monitoring
- ✅ **Auto-updates** with Watchtower

## Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Docker](https://docs.docker.com/get-docker/)
- [Node.js](https://nodejs.org/) >= 20 (for frontend development)
- [Java](https://adoptium.net/) >= 21
- [Maven](https://maven.apache.org/) >= 3.9
- [Hetzner Cloud Account](https://console.hetzner.cloud)
- [GitHub Account](https://github.com)

**Note:** Frontend is currently a minimal placeholder. You'll develop the full Angular app locally.

### 1. Use This Template

Click **"Use this template"** button on GitHub to create your repository.

### 2. Clone Your Repository

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
```

### 3. Local Development

#### Backend
```bash
cd backend
mvn spring-boot:run
# Backend runs on http://localhost:8080
```

#### Frontend
```bash
cd frontend
npm install
npm start
# Frontend runs on http://localhost:4200
```

#### Full Stack with Docker Compose
```bash
cp .env.example .env
# Edit .env with your values
docker compose up -d
```

### 4. Infrastructure Setup

#### Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
hcloud_token     = "your-hetzner-api-token"
ssh_public_key   = "your-ssh-public-key"
project_name     = "my-app"
server_type      = "cx21"
location         = "nbg1"
```

#### Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

After ~3 minutes, your server is ready!

```bash
# Get connection info
terraform output

# SSH into server
ssh root@YOUR_SERVER_IP
```

### 5. Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these secrets:
- `SERVER_HOST`: Your Hetzner server IP
- `SSH_PRIVATE_KEY`: Your SSH private key
- `DOMAIN`: Your domain (optional, for SSL)

### 6. Deploy Application

Push to main branch triggers automatic deployment:

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

GitHub Actions will:
1. Build and test backend
2. Build and test frontend
3. Create Docker images
4. Push to GitHub Container Registry
5. Deploy to your Hetzner server

## Project Structure

```
.
├── terraform/              # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── cloud-init.yaml
├── backend/                # Spring Boot application
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
├── frontend/               # Angular application
│   ├── src/
│   ├── package.json
│   ├── Dockerfile
│   └── nginx.conf
├── .github/workflows/      # CI/CD pipelines
│   └── ci-cd.yml
├── docker-compose.yml      # Local development
├── docker-compose.prod.yml # Production deployment
└── README.md
```

## Technology Stack

### Backend
- **Spring Boot 3.2** - Application framework
- **Spring Data JPA** - Data persistence
- **PostgreSQL** - Database
- **Maven** - Build tool
- **Lombok** - Reduce boilerplate
- **Spring Actuator** - Health monitoring

### Frontend
- **Angular 17** - Frontend framework
- **TypeScript** - Type safety
- **RxJS** - Reactive programming
- **Nginx** - Web server

### Infrastructure
- **Hetzner Cloud** - Hosting (~5.83 EUR/month for CX21)
- **Terraform** - Infrastructure as Code
- **Docker** - Containerization
- **Docker Compose** - Container orchestration
- **Traefik** - Reverse proxy & SSL
- **GitHub Actions** - CI/CD

## Architecture

```
Internet
   ↓
Traefik (Port 80/443) - SSL Termination
   ↓
   ├─→ Angular Frontend (nginx) - Port 80
   │
   └─→ Spring Boot Backend - Port 8080
          ↓
       PostgreSQL - Port 5432
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env`:

```bash
# Database
POSTGRES_DB=appdb
POSTGRES_USER=appuser
POSTGRES_PASSWORD=secure_password_here

# Domain (for SSL)
DOMAIN=example.com
ACME_EMAIL=admin@example.com

# Docker Registry
DOCKER_REGISTRY=ghcr.io/username/repo
```

### Spring Profiles

- `dev` - Development (H2 database, detailed logging)
- `prod` - Production (PostgreSQL, optimized)

## API Endpoints

### Backend (http://localhost:8080 or http://YOUR_SERVER_IP:8080)

**Currently available:**
- `GET /api/items` - Get all items
- `GET /api/items/{id}` - Get item by ID
- `GET /api/items/search?name=...` - Search items
- `POST /api/items` - Create item
- `PUT /api/items/{id}` - Update item
- `DELETE /api/items/{id}` - Delete item
- `GET /api/items/health` - Health check
- `GET /actuator/health` - Spring Actuator health

### Frontend (http://localhost:4200)

**Status:** Minimal placeholder HTML. Full Angular application to be developed.

The template provides the infrastructure and backend. You'll build the Angular frontend locally and deploy it.

## Deployment

### Manual Deployment

```bash
# SSH into server
ssh root@YOUR_SERVER_IP

# Navigate to app directory
cd /opt/spring-angular-app

# Pull latest changes
git pull

# Update and restart
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### Automatic Deployment

Push to `main` branch triggers automatic deployment via GitHub Actions.

## Monitoring

### Health Checks

```bash
# Backend health
curl http://YOUR_SERVER_IP/api/items/health

# Actuator health
curl http://YOUR_SERVER_IP/actuator/health

# Frontend health
curl http://YOUR_SERVER_IP/health
```

### Container Status

```bash
ssh root@YOUR_SERVER_IP
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f
```

### Traefik Dashboard

Access at: `http://traefik.YOUR_DOMAIN` (requires authentication)

## Costs

### Hetzner Cloud Server Pricing

| Server | vCPU | RAM | Storage | Price/Month |
|--------|------|-----|---------|-------------|
| CX22   | 2    | 4GB | 40GB    | ~4.90 EUR   |
| CX32   | 2    | 8GB | 80GB    | ~9.50 EUR   |
| CX42   | 4    | 16GB| 160GB   | ~18.50 EUR  |
| CPX11  | 2    | 2GB | 40GB    | ~4.75 EUR   |
| CPX21  | 3    | 4GB | 80GB    | ~8.90 EUR   |

### Additional Costs
- Domain: ~10 EUR/year (optional)
- Backup: ~20% of server cost (optional)

## Security Best Practices

### Before Production

1. **Change default passwords** in `.env`
2. **Restrict SSH access** in `terraform/variables.tf`:
   ```hcl
   allowed_ssh_ips = ["YOUR_IP/32"]
   ```
3. **Enable domain & SSL** in `docker-compose.prod.yml`
4. **Configure backups** (Hetzner Backups or external)
5. **Set up monitoring** (Prometheus, Grafana)
6. **Review security headers** in nginx.conf

### Recommendations

- Use strong passwords (>20 characters)
- Enable 2FA on GitHub and Hetzner
- Regularly update dependencies
- Monitor logs for suspicious activity
- Keep infrastructure code in private repository
- Use GitHub secrets for sensitive data

## Troubleshooting

### Backend won't start

```bash
# Check logs
docker compose logs backend

# Common issues:
# - Database not ready: wait 30 seconds
# - Wrong credentials: check .env file
# - Port conflict: change port in docker-compose.yml
```

### Frontend can't reach backend

```bash
# Check CORS configuration in backend/src/main/java/com/example/app/config/WebConfig.java
# Verify nginx proxy in frontend/nginx.conf
```

### Database connection errors

```bash
# Verify PostgreSQL is running
docker compose ps postgres

# Check credentials match in:
# - .env
# - application.yml
```

### Terraform apply fails

```bash
# Check API token is valid
# Verify SSH key is correct
# Ensure server type is available in chosen location
```

## Useful Commands

```bash
# Development
docker compose up -d              # Start all services
docker compose down               # Stop all services
docker compose logs -f            # View logs

# Production
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml restart backend

# Terraform
terraform plan                    # Preview changes
terraform apply                   # Apply changes
terraform destroy                 # Destroy infrastructure
terraform output                  # Show outputs

# Docker
docker system prune -a            # Clean up all unused data
docker volume ls                  # List volumes
docker network ls                 # List networks
```

## Customization

### Change Project Name

1. Update `project_name` in `terraform/terraform.tfvars`
2. Update `name` in `backend/pom.xml`
3. Update `name` in `frontend/package.json`
4. Update paths in `docker-compose.yml`

### Add New Endpoints

1. Create entity in `backend/src/main/java/com/example/app/model/`
2. Create repository in `backend/src/main/java/com/example/app/repository/`
3. Create service in `backend/src/main/java/com/example/app/service/`
4. Create controller in `backend/src/main/java/com/example/app/controller/`

### Add Angular Components

```bash
cd frontend
ng generate component components/my-component
ng generate service services/my-service
```

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add my feature'`
4. Push to branch: `git push origin feature/my-feature`
5. Submit pull request

## License

This template is open source and available under the [MIT License](LICENSE).

## Support

- 📖 [Documentation](./docs/)
- 🐛 [Issue Tracker](https://github.com/YOUR_USERNAME/YOUR_REPO/issues)
- 💬 [Discussions](https://github.com/YOUR_USERNAME/YOUR_REPO/discussions)

## Credits

Created with ❤️ by [Your Name]

---

**Happy Coding! 🚀**
## CI/CD Test

## CI/CD Active
