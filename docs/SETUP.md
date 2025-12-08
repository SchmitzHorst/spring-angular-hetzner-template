# Setup Guide

This guide walks you through setting up the complete development and production environment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Hetzner Cloud Setup](#hetzner-cloud-setup)
4. [GitHub Setup](#github-setup)
5. [Domain & SSL Setup](#domain--ssl-setup)
6. [First Deployment](#first-deployment)
7. [Verification](#verification)

## Prerequisites

### Required Tools

Install these on your development machine:

#### 1. Java Development Kit (JDK) 21
```bash
# macOS (Homebrew)
brew install openjdk@21

# Ubuntu/Debian
sudo apt install openjdk-21-jdk

# Verify
java -version  # Should show version 21
```

#### 2. Maven
```bash
# macOS
brew install maven

# Ubuntu/Debian
sudo apt install maven

# Verify
mvn -version  # Should show Maven 3.9+
```

#### 3. Node.js 20+
```bash
# macOS
brew install node@20

# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node -v   # Should show v20.x
npm -v    # Should show 10.x+
```

#### 4. Docker
```bash
# macOS
brew install --cask docker

# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Verify
docker --version
docker compose version
```

#### 5. Terraform
```bash
# macOS
brew install terraform

# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify
terraform -version  # Should show 1.0+
```

#### 6. Angular CLI
```bash
npm install -g @angular/cli

# Verify
ng version
```

### Required Accounts

1. **GitHub Account** - https://github.com/signup
2. **Hetzner Cloud Account** - https://console.hetzner.cloud
3. **Domain (optional)** - For SSL certificates

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies and build
mvn clean install

# Run tests
mvn test

# Start application
mvn spring-boot:run
```

Backend runs on: http://localhost:8080

Test it:
```bash
curl http://localhost:8080/api/items/health
# Should return: "Backend is running!"
```

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm start
```

Frontend runs on: http://localhost:4200

### 4. Database Setup (PostgreSQL)

#### Option A: Docker Compose (Recommended)

```bash
# In project root
cp .env.example .env

# Edit .env and set:
# POSTGRES_PASSWORD=your_secure_password

# Start database only
docker compose up -d postgres

# Verify
docker compose ps
docker compose logs postgres
```

#### Option B: Local PostgreSQL

```bash
# Install PostgreSQL
# macOS
brew install postgresql@16
brew services start postgresql@16

# Ubuntu/Debian
sudo apt install postgresql-16

# Create database and user
sudo -u postgres psql

postgres=# CREATE DATABASE appdb;
postgres=# CREATE USER appuser WITH PASSWORD 'changeme';
postgres=# GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;
postgres=# \q
```

### 5. Full Stack with Docker Compose

```bash
# In project root
cp .env.example .env

# Edit .env with your values
nano .env

# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f

# Stop services
docker compose down
```

Access:
- Frontend: http://localhost:4200
- Backend API: http://localhost:8080/api
- PostgreSQL: localhost:5432

## Hetzner Cloud Setup

### 1. Create Hetzner Account

1. Go to https://console.hetzner.cloud
2. Sign up and verify email
3. Add payment method (credit card or PayPal)

### 2. Create Project

1. Click "New Project"
2. Name it (e.g., "Spring Angular App")
3. Click on your project

### 3. Generate API Token

1. Go to **Security** → **API Tokens**
2. Click **Generate API Token**
3. Name: "Terraform"
4. Permissions: **Read & Write**
5. **Copy the token** (you won't see it again!)

### 4. Generate SSH Key Pair

```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/hetzner_key

# View public key (copy this)
cat ~/.ssh/hetzner_key.pub
```

### 5. Configure Terraform

```bash
cd terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Fill in:
```hcl
hcloud_token = "YOUR_HETZNER_API_TOKEN"
ssh_public_key = "ssh-ed25519 AAAA... your-email@example.com"
project_name = "my-app"
server_type = "cx21"
location = "nbg1"  # Nuremberg, Germany
allowed_ssh_ips = ["YOUR_IP/32"]  # Get your IP: curl -s https://api.ipify.org
```

### 6. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (takes ~3 minutes)
terraform apply

# Copy the server IP
terraform output server_ipv4
```

### 7. Verify Server

```bash
# SSH into server (replace with your IP)
ssh root@YOUR_SERVER_IP

# Wait for cloud-init to complete (~2-3 minutes)
tail -f /var/log/cloud-init-output.log

# Verify Docker is installed
docker --version
docker compose version

# Exit
exit
```

## GitHub Setup

### 1. Create Repository

1. Go to https://github.com/new
2. Name: `spring-angular-hetzner-template`
3. Visibility: Private (recommended)
4. Don't initialize with README (you already have one)
5. Click **Create repository**

### 2. Push Code

```bash
# In project root
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git add .
git commit -m "Initial commit"
git push -u origin main
```

### 3. Configure GitHub Secrets

1. Go to repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** for each:

#### Required Secrets:

**SERVER_HOST**
- Value: Your Hetzner server IP (from `terraform output`)
- Example: `65.21.123.45`

**SSH_PRIVATE_KEY**
- Value: Your private SSH key
- Get it: `cat ~/.ssh/hetzner_key`
- Copy the ENTIRE content including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`

**DOMAIN** (optional, for SSL)
- Value: Your domain name
- Example: `myapp.com`

### 4. Enable GitHub Container Registry

GitHub Container Registry (GHCR) is automatically enabled.

To use it, your workflow will authenticate with `GITHUB_TOKEN` (automatically provided).

### 5. Verify Workflow

1. Go to **Actions** tab
2. You should see "CI/CD Pipeline" workflow
3. Click on a workflow run to see details

## Domain & SSL Setup

### Option 1: Without Domain (HTTP only)

Use server IP directly:
- Frontend: `http://YOUR_SERVER_IP`
- Backend: `http://YOUR_SERVER_IP/api`

### Option 2: With Domain (HTTPS with SSL)

#### 1. Get a Domain

Buy from:
- Namecheap
- Google Domains
- Cloudflare
- GoDaddy

#### 2. Configure DNS

Add these DNS records:

```
Type    Name    Value               TTL
A       @       YOUR_SERVER_IP      300
A       www     YOUR_SERVER_IP      300
```

Wait 5-15 minutes for DNS propagation. Verify:
```bash
dig yourdomain.com +short
# Should show your server IP
```

#### 3. Update Configuration

Edit `.env` on server:
```bash
ssh root@YOUR_SERVER_IP
cd /opt/spring-angular-app
nano .env
```

Add/update:
```bash
DOMAIN=yourdomain.com
ACME_EMAIL=admin@yourdomain.com
```

#### 4. Deploy with SSL

```bash
# On server
docker compose -f docker-compose.prod.yml up -d

# Wait for SSL certificate (~30 seconds)
docker compose -f docker-compose.prod.yml logs traefik

# Verify SSL
curl https://yourdomain.com
```

Traefik will automatically:
- Request SSL certificate from Let's Encrypt
- Redirect HTTP to HTTPS
- Renew certificates before expiry

## First Deployment

### Manual Deployment

```bash
# SSH into server
ssh root@YOUR_SERVER_IP

# Create app directory
mkdir -p /opt/spring-angular-app
cd /opt/spring-angular-app

# Clone repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git .

# Configure environment
cp .env.example .env
nano .env  # Edit with your values

# Start services
docker compose -f docker-compose.prod.yml up -d

# Check status
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f
```

### Automatic Deployment (via GitHub Actions)

1. Push to `main` branch:
```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

2. GitHub Actions will automatically:
   - Build backend Docker image
   - Build frontend Docker image
   - Push images to GitHub Container Registry
   - Deploy to your server
   - Run health checks

3. Monitor deployment:
   - Go to GitHub → **Actions** tab
   - Click on running workflow
   - Watch the progress

## Verification

### 1. Check Services

```bash
ssh root@YOUR_SERVER_IP
cd /opt/spring-angular-app

# Check all containers are running
docker compose -f docker-compose.prod.yml ps

# Should show:
# - traefik (running)
# - postgres-db (running, healthy)
# - spring-backend (running, healthy)
# - angular-frontend (running, healthy)
# - watchtower (running)
```

### 2. Test Backend

```bash
# Health check
curl http://YOUR_SERVER_IP/api/items/health
# Should return: "Backend is running!"

# Actuator health
curl http://YOUR_SERVER_IP/actuator/health
# Should return: {"status":"UP"}

# Get items (empty at first)
curl http://YOUR_SERVER_IP/api/items
# Should return: []
```

### 3. Test Frontend

Open browser: `http://YOUR_SERVER_IP` or `https://yourdomain.com`

You should see the Angular application.

### 4. Test Database

```bash
# Connect to PostgreSQL
docker compose -f docker-compose.prod.yml exec postgres psql -U appuser -d appdb

# List tables
\dt

# Query items table
SELECT * FROM items;

# Exit
\q
```

### 5. View Logs

```bash
# All services
docker compose -f docker-compose.prod.yml logs

# Specific service
docker compose -f docker-compose.prod.yml logs backend
docker compose -f docker-compose.prod.yml logs frontend

# Follow logs
docker compose -f docker-compose.prod.yml logs -f --tail=50
```

## Troubleshooting

### Backend not starting

```bash
# Check logs
docker compose logs backend

# Common issues:
# 1. Database not ready → wait 30 seconds and restart
docker compose restart backend

# 2. Wrong database credentials → check .env file
nano .env

# 3. Port conflict → check docker-compose.yml
```

### Frontend 502 Bad Gateway

```bash
# Verify backend is running
curl http://localhost:8080/api/items/health

# Check nginx configuration
docker compose logs frontend

# Restart frontend
docker compose restart frontend
```

### SSL Certificate Issues

```bash
# Check Traefik logs
docker compose logs traefik

# Verify domain DNS
dig yourdomain.com +short

# Delete old certificates and retry
docker compose down
rm -rf /var/lib/docker/volumes/*letsencrypt*
docker compose up -d
```

### Can't SSH into server

```bash
# Verify SSH key
ssh -vvv root@YOUR_SERVER_IP

# Check firewall rules
terraform show | grep allowed_ssh_ips

# If IP changed, update terraform.tfvars and reapply
terraform apply
```

## Next Steps

1. ✅ Customize the application code
2. ✅ Add more API endpoints
3. ✅ Build Angular components
4. ✅ Set up monitoring (Prometheus, Grafana)
5. ✅ Configure backups
6. ✅ Add authentication (Spring Security, OAuth2)
7. ✅ Set up CI/CD for staging environment

## Support

If you run into issues:

1. Check logs: `docker compose logs`
2. Review documentation in `/docs`
3. Search GitHub issues
4. Create new issue with:
   - Error messages
   - Steps to reproduce
   - Environment details

---

**You're all set! Happy coding! 🚀**
