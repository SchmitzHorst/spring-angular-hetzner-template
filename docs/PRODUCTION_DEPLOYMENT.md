# Production Deployment Guide

This guide covers the complete production deployment as successfully implemented.

## Overview

This template provides a fully automated, production-ready deployment with:

- ✅ **HTTPS/SSL** - Automatic Let's Encrypt certificates via Traefik
- ✅ **Domain** - Custom domain support (e.g., ai-alpine.ch)
- ✅ **CI/CD** - GitHub Actions for automated deployments
- ✅ **Security** - Only ports 80/443 exposed, internal backend access
- ✅ **Monitoring** - Health checks for all services
- ✅ **Cost-Effective** - ~17-18 CHF/year total

## Prerequisites

- Hetzner Cloud account
- Domain (recommended: Green.ch for Swiss domains, ~3.90 CHF/year)
- GitHub account
- SSH key pair

## Step 1: Infrastructure Setup

### 1.1 Create Hetzner Cloud Resources

```bash
cd terraform

# Copy and configure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Set:
```hcl
hcloud_token = "YOUR_HETZNER_API_TOKEN"
ssh_public_key = "ssh-ed25519 AAAA... your-email@example.com"
project_name = "your-app-name"
server_type = "cx22"
location = "nbg1"
allowed_ssh_ips = ["YOUR_IP/32"]
```

```bash
# Deploy infrastructure
terraform init
terraform plan
terraform apply
```

**Result:** Server at `<SERVER_IP>`, ports 22, 80, 443 open.

### 1.2 Configure DNS

At your domain provider (e.g., Green.ch):

**A Record:**
```
Type: A
Name: @ (or leave empty)
Value: <SERVER_IP>
TTL: 300
```

**A Record for www:**
```
Type: A
Name: www
Value: <SERVER_IP>
TTL: 300
```

Wait 5-15 minutes for DNS propagation.

**Verify:**
```bash
dig your-domain.com +short
# Should show: <SERVER_IP>
```

## Step 2: Application Deployment

### 2.1 Configure Environment

On your server:

```bash
ssh root@<SERVER_IP>
cd /opt/spring-angular-app

# Create .env file
nano .env
```

Set:
```bash
# Database Configuration
POSTGRES_DB=appdb
POSTGRES_USER=appuser
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD  # Change this!

# Domain Configuration
DOMAIN=your-domain.com
ACME_EMAIL=your-email@example.com

# Docker Registry (not used with local build, but keep for compatibility)
DOCKER_REGISTRY=ghcr.io/yourusername/your-repo-name
IMAGE_TAG=latest
```

### 2.2 Deploy with Docker Compose

```bash
# Build images locally
docker compose -f docker-compose.prod.yml build

# Start all services
docker compose -f docker-compose.prod.yml --env-file .env up -d

# Check status (wait ~30 seconds)
docker compose -f docker-compose.prod.yml ps

# All should show "healthy"
```

### 2.3 Verify Deployment

```bash
# Check logs
docker compose -f docker-compose.prod.yml logs traefik | tail -20
docker compose -f docker-compose.prod.yml logs backend | tail -20
docker compose -f docker-compose.prod.yml logs frontend | tail -20

# Test endpoints
curl https://your-domain.com
curl https://your-domain.com/api/items/health
```

## Step 3: GitHub Actions CI/CD

### 3.1 Configure GitHub Secrets

In your GitHub repository: Settings → Secrets and variables → Actions

Add these secrets:

**SERVER_HOST:**
```
<SERVER_IP>
```

**SSH_PRIVATE_KEY_BASE64:**
```bash
# On your local machine:
cat ~/.ssh/your_key | base64 -w 0
# Copy the output
```

**DOMAIN:**
```
your-domain.com
```

### 3.2 Workflow Configuration

The workflow is already configured in `.github/workflows/ci-cd.yml`. It will:

1. Build backend and frontend
2. Push images to GitHub Container Registry (optional)
3. Deploy to server via SSH
4. Run health checks

**Trigger deployment:**
```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

GitHub Actions will automatically deploy to your server!

## Step 4: Testing

### 4.1 Frontend Test

Open in browser: `https://your-domain.com`

You should see the Item Manager interface. Try:
- Creating a new item
- Viewing the items list
- Deleting an item

### 4.2 API Test

```bash
# Health check
curl https://your-domain.com/api/items/health

# Get all items
curl https://your-domain.com/api/items

# Create item
curl -X POST https://your-domain.com/api/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Item",
    "description": "Production test"
  }'

# Get items (should show your new item)
curl https://your-domain.com/api/items
```

### 4.3 SSL Certificate

In browser:
1. Click lock icon in address bar
2. Should show "Connection is secure"
3. Certificate from: Let's Encrypt
4. Valid for: your-domain.com

### 4.4 HTTP Redirect

```bash
curl -I http://your-domain.com
# Should return: 308 Permanent Redirect
# Location: https://your-domain.com/
```

## Architecture

### Network Flow

```
Internet
    ↓
Port 443 (HTTPS)
    ↓
Traefik (Reverse Proxy + SSL Termination)
    ↓
    ├→ Frontend (nginx:80) → / 
    └→ Backend (Spring Boot:8080) → /api
           ↓
       PostgreSQL:5432
```

### Security

- **External Access:** Only ports 80/443
- **Backend:** Not exposed externally, only via Traefik
- **Database:** Only accessible by backend
- **SSL:** Automatic Let's Encrypt certificates
- **HTTP:** Redirects to HTTPS

### Services

| Service | Internal Port | External Access | Health Check |
|---------|--------------|-----------------|--------------|
| Traefik | 80, 443 | ✅ Ports 80, 443 | - |
| Frontend | 80 | ✅ Via Traefik (/) | ✅ exit 0 |
| Backend | 8080 | ✅ Via Traefik (/api) | ✅ exit 0 |
| PostgreSQL | 5432 | ❌ Internal only | ✅ pg_isready |

## Troubleshooting

### 404 Not Found

**Symptoms:** `https://your-domain.com` shows "404 page not found"

**Causes:**
1. Containers are unhealthy
2. Traefik cannot see containers

**Solution:**
```bash
# Check container status
docker compose -f docker-compose.prod.yml ps

# If unhealthy, check logs
docker compose -f docker-compose.prod.yml logs backend
docker compose -f docker-compose.prod.yml logs frontend

# Common fix: Restart all
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml --env-file .env up -d
```

### Backend Unhealthy

**Symptoms:** Backend shows "unhealthy" status

**Causes:**
1. Database connection failed
2. Wrong credentials in .env

**Solution:**
```bash
# Check backend logs
docker compose -f docker-compose.prod.yml logs backend

# Look for:
# - "Started Application" (good!)
# - "password authentication failed" (wrong password)
# - "database ... does not exist" (wrong database name)

# Fix .env and restart
nano .env
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml --env-file .env up -d
```

### Frontend Restart Loop

**Symptoms:** Frontend keeps restarting

**Causes:**
1. nginx cannot find backend
2. Backend started after frontend

**Solution:**
```bash
# Check if depends_on is correct in docker-compose.prod.yml
# Should have:
# frontend:
#   depends_on:
#     backend:
#       condition: service_healthy

# Restart in correct order
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

### SSL Certificate Not Working

**Symptoms:** Browser shows "Not Secure" or "Self-signed certificate"

**Causes:**
1. Let's Encrypt still generating certificate (takes 1-2 minutes)
2. Domain DNS not propagated
3. ACME email not configured

**Solution:**
```bash
# Check Traefik logs
docker compose -f docker-compose.prod.yml logs traefik | grep -i certificate

# Verify .env has correct values
cat .env | grep DOMAIN
cat .env | grep ACME_EMAIL

# Wait 2-3 minutes and test again
sleep 120
curl -I https://your-domain.com
```

### GitHub Actions Deploy Fails

**Symptoms:** Deploy step fails with "Permission denied" or "Connection refused"

**Causes:**
1. SSH key not configured correctly
2. Wrong SERVER_HOST

**Solution:**
```bash
# Test SSH manually
ssh -i ~/.ssh/your_key root@<SERVER_IP>

# If works, check GitHub secret SSH_PRIVATE_KEY_BASE64
# Must be base64 encoded without spaces/newlines
cat ~/.ssh/your_key | base64 -w 0

# Update secret in GitHub
```

## Maintenance

### Update Application

Simply push code changes:

```bash
git add .
git commit -m "New feature"
git push origin main
```

GitHub Actions automatically builds and deploys!

### Update Infrastructure

```bash
cd terraform

# Make changes to main.tf or variables.tf
nano main.tf

# Apply changes
terraform plan
terraform apply
```

### Database Backup

```bash
# On server
docker compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U appuser appdb > backup_$(date +%Y%m%d).sql

# Download backup
scp root@<SERVER_IP>:/opt/spring-angular-app/backup_*.sql .
```

### View Logs

```bash
# Real-time logs
docker compose -f docker-compose.prod.yml logs -f

# Specific service
docker compose -f docker-compose.prod.yml logs -f backend

# Last 100 lines
docker compose -f docker-compose.prod.yml logs --tail=100
```

### Restart Services

```bash
# Restart specific service
docker compose -f docker-compose.prod.yml restart backend

# Restart all
docker compose -f docker-compose.prod.yml restart

# Full restart (rebuild if needed)
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

## Cost Breakdown

| Item | Provider | Cost |
|------|----------|------|
| Server (CX22) | Hetzner Cloud | ~4.90 EUR/month (~59 EUR/year) |
| Domain (.ch) | Green.ch | ~3.90 CHF/year (first year) |
| SSL Certificate | Let's Encrypt | Free |
| **Total** | | **~17-18 CHF/year** |

## Security Hardening (Production)

### 1. Change Default Passwords

```bash
# Generate strong password
openssl rand -base64 32

# Update .env
nano .env
# Set POSTGRES_PASSWORD to generated password

# Restart
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

### 2. Restrict SSH Access

In `terraform/terraform.tfvars`:
```hcl
allowed_ssh_ips = ["YOUR_SPECIFIC_IP/32"]
```

```bash
terraform apply
```

### 3. Enable Firewall Logging

```bash
# On server
ufw logging on
```

### 4. Regular Updates

```bash
# On server
apt update && apt upgrade -y
docker compose pull
docker compose up -d
```

## Next Steps

1. **Monitoring:** Add Prometheus/Grafana for metrics
2. **Logging:** Configure centralized logging (ELK stack)
3. **Backups:** Automate database backups
4. **Scaling:** Add more servers behind load balancer
5. **CI/CD:** Add automated tests before deployment

## Support

- [Terraform Hetzner Provider Docs](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Spring Boot Docs](https://spring.io/projects/spring-boot)
- [Angular Docs](https://angular.dev)
- [Docker Compose Docs](https://docs.docker.com/compose/)

---

**Deployed successfully!** Your application is now running in production with automatic SSL, CI/CD, and professional infrastructure. 🚀
