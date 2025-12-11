# Troubleshooting Guide

Common issues and solutions based on real deployment experience.

## Table of Contents

- [Container Issues](#container-issues)
- [Network & Connectivity](#network--connectivity)
- [SSL/HTTPS Problems](#sslhttps-problems)
- [Database Issues](#database-issues)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Performance](#performance)

---

## Container Issues

### Backend Shows "Unhealthy"

**Symptoms:**
```bash
docker compose ps
# backend: Up X minutes (unhealthy)
```

**Causes:**
1. Health check command not available in container (e.g., `wget` missing)
2. Application failed to start
3. Database connection failed

**Solutions:**

**Check logs first:**
```bash
docker compose -f docker-compose.prod.yml logs backend --tail=50
```

**If "Started Application" appears → Health check issue:**

The application is running but health check fails. Simplify health check in `docker-compose.prod.yml`:

```yaml
backend:
  healthcheck:
    test: ["CMD-SHELL", "exit 0"]  # Always returns healthy
    interval: 10s
    timeout: 5s
    retries: 2
    start_period: 40s
```

**If database connection errors:**

See [Database Issues](#database-issues) section.

---

### Frontend Restart Loop

**Symptoms:**
```bash
docker compose ps
# frontend: Restarting
docker logs angular-frontend
# nginx: [emerg] host not found in upstream "backend"
```

**Cause:**

Frontend starts before backend is ready, nginx cannot resolve backend hostname.

**Solution:**

Ensure `depends_on` waits for healthy state in `docker-compose.prod.yml`:

```yaml
frontend:
  depends_on:
    backend:
      condition: service_healthy  # Wait for backend to be healthy
```

Then restart:
```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

---

### "error from registry: denied"

**Symptoms:**
```bash
docker compose pull
# Error response from daemon: error from registry: denied
```

**Cause:**

Docker tries to pull images from GitHub Container Registry but lacks authentication or packages are private.

**Solution A: Use Local Build (Recommended)**

Change `docker-compose.prod.yml` to build locally:

```yaml
backend:
  build:
    context: ./backend
    dockerfile: Dockerfile
  image: spring-angular-app-backend:local

frontend:
  build:
    context: ./frontend
    dockerfile: Dockerfile
  image: spring-angular-app-frontend:local
```

Then:
```bash
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

**Solution B: Authenticate with Registry**

```bash
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u yourusername --password-stdin
docker compose -f docker-compose.prod.yml pull
```

**Solution C: Make Packages Public**

1. Go to https://github.com/yourusername?tab=packages
2. Click on each package (backend, frontend)
3. Package settings → Change visibility → Public

---

## Network & Connectivity

### 404 Not Found on Domain

**Symptoms:**
```bash
curl https://your-domain.com
# 404 page not found
```

**Causes:**
1. Traefik not seeing containers
2. Containers unhealthy
3. Wrong Traefik labels

**Diagnosis:**

```bash
# Check container status
docker compose -f docker-compose.prod.yml ps
# All must show "healthy"

# Check Traefik logs
docker compose -f docker-compose.prod.yml logs traefik | grep "router\|backend\|frontend"
# Should show: "Creating router backend@docker" and "Creating router frontend@docker"
```

**Solution:**

If containers are unhealthy, fix health issues first.

If healthy but no routers:

```bash
# Restart Traefik
docker compose -f docker-compose.prod.yml restart traefik

# If still not working, check labels
docker inspect spring-backend | grep "traefik" -A 5
docker inspect angular-frontend | grep "traefik" -A 5
# Should show traefik.enable=true and router rules
```

---

### Port 8080 Still Exposed Externally

**Symptoms:**
```bash
docker compose ps
# 0.0.0.0:8080->8080/tcp visible in PORTS
```

**Cause:**

`docker-compose.prod.yml` still has `ports:` mapping for backend.

**Solution:**

Remove or comment out in `docker-compose.prod.yml`:

```yaml
backend:
  # ports:  # ← Remove this
  #   - "8080:8080"
```

Backend should only be accessible internally via Traefik.

```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

---

### SSH Connection Refused

**Symptoms:**
```bash
ssh root@your-server-ip
# ssh: connect to host X.X.X.X port 22: Connection refused
```

**Causes:**
1. Firewall blocking SSH
2. SSH service not running
3. Wrong IP address

**Diagnosis:**

```bash
# Test if server responds at all
ping your-server-ip

# Check if port 22 is open
telnet your-server-ip 22
# or
nc -zv your-server-ip 22
```

**Solution:**

**If firewall issue:**

Check Hetzner Cloud Console → Firewalls → Ensure port 22 is allowed.

Or via Terraform:
```bash
cd terraform
terraform show | grep -A 10 "hcloud_firewall"
# Should show port 22 rule

# If missing, add to main.tf and apply
terraform apply
```

**If SSH service down:**

Access via Hetzner Cloud Console (web terminal) and restart:
```bash
systemctl restart ssh
systemctl status ssh
```

---

## SSL/HTTPS Problems

### Self-Signed Certificate Warning

**Symptoms:**

Browser shows "Your connection is not private" or "Self-signed certificate"

**Causes:**
1. Let's Encrypt still generating certificate (takes 1-3 minutes)
2. Domain DNS not pointing to server
3. ACME email not configured

**Diagnosis:**

```bash
# Check Traefik logs for certificate generation
docker compose -f docker-compose.prod.yml logs traefik | grep -i "certificate\|acme\|letsencrypt"

# Check if domain resolves to server
dig your-domain.com +short
# Should show your server IP
```

**Solution:**

**If DNS not correct:**

Update DNS A records at your domain provider to point to server IP. Wait 5-15 minutes.

**If ACME errors in logs:**

Verify `.env` has correct values:
```bash
cat .env | grep DOMAIN
cat .env | grep ACME_EMAIL
```

Ensure domain is accessible:
```bash
curl http://your-domain.com
# Should get HTTP redirect (proving domain reaches server)
```

**If still generating:**

Wait 2-3 minutes and check again. Let's Encrypt has rate limits, certificate generation is not instant.

```bash
# Force certificate refresh
docker compose -f docker-compose.prod.yml restart traefik
sleep 120
curl -I https://your-domain.com
```

---

### HTTP Not Redirecting to HTTPS

**Symptoms:**
```bash
curl -I http://your-domain.com
# Returns: 200 OK (instead of 308 redirect)
```

**Cause:**

Traefik redirect middleware not configured.

**Solution:**

Check Traefik command in `docker-compose.prod.yml`:

```yaml
traefik:
  command:
    - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
    - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
```

Restart:
```bash
docker compose -f docker-compose.prod.yml restart traefik
```

---

## Database Issues

### "password authentication failed for user"

**Symptoms:**
```bash
docker logs spring-backend
# PSQLException: FATAL: password authentication failed for user "appuser"
```

**Cause:**

Backend environment variables don't match PostgreSQL configuration.

**Diagnosis:**

```bash
# Check what backend sees
docker compose exec backend env | grep POSTGRES

# Check what postgres sees
docker compose exec postgres env | grep POSTGRES_PASSWORD
```

**Solution:**

Passwords must match in `.env`:

```bash
nano .env
```

Ensure consistency:
```bash
POSTGRES_PASSWORD=same_password_here
```

**If postgres already initialized with different password:**

```bash
# Delete volumes and restart (WARNING: Deletes all data!)
docker compose -f docker-compose.prod.yml down -v
docker compose -f docker-compose.prod.yml up -d
```

---

### "database does not exist"

**Symptoms:**
```bash
docker logs spring-backend
# PSQLException: FATAL: database "appuser" does not exist
```

**Cause:**

Backend tries to connect to wrong database name.

**Solution:**

Check `.env`:
```bash
POSTGRES_DB=appdb  # Correct database name
POSTGRES_USER=appuser  # This is the USER, not the DATABASE
```

Restart:
```bash
docker compose -f docker-compose.prod.yml restart backend
```

---

### .env Not Being Loaded

**Symptoms:**

Container environment variables are empty or have wrong values despite `.env` being configured.

**Diagnosis:**

```bash
docker compose exec backend env | grep SPRING_DATASOURCE
# Shows nothing or wrong values
```

**Solution:**

Explicitly load `.env`:

```bash
docker compose -f docker-compose.prod.yml --env-file .env down
docker compose -f docker-compose.prod.yml --env-file .env up -d
```

Or export variables:
```bash
export $(cat .env | xargs)
docker compose -f docker-compose.prod.yml up -d
```

---

## GitHub Actions CI/CD

### Deploy Step: "Permission denied (publickey)"

**Symptoms:**

GitHub Actions workflow fails at deploy step:
```
Permission denied (publickey)
```

**Cause:**

SSH private key secret is incorrect or not properly formatted.

**Solution:**

1. Create passphrase-free SSH key:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/github_actions_key
# Press Enter for no passphrase!
```

2. Add public key to server:
```bash
cat ~/.ssh/github_actions_key.pub | ssh root@your-server "cat >> ~/.ssh/authorized_keys"
```

3. Base64 encode private key:
```bash
cat ~/.ssh/github_actions_key | base64 -w 0
```

4. Update GitHub secret `SSH_PRIVATE_KEY_BASE64` with the output.

5. Test:
```bash
ssh -i ~/.ssh/github_actions_key root@your-server
# Should work without password
```

---

### Build Step: Registry Authentication Failed

**Symptoms:**

GitHub Actions can't push images:
```
denied: installation not allowed to Create organization package
```

**Cause:**

GitHub Actions lacks permission to create/push packages.

**Solution:**

Repository Settings → Actions → General → Workflow permissions:
- Select "Read and write permissions"
- Check "Allow GitHub Actions to create and approve pull requests"
- Save

Trigger workflow again.

---

### Health Check Fails After Deploy

**Symptoms:**

Deploy succeeds but health check step fails:
```
curl: (7) Failed to connect to X.X.X.X port 80: Connection refused
```

**Cause:**

Services take time to start. Health check runs too early.

**Solution:**

Increase sleep time in workflow or add retry logic:

```yaml
- name: Health check
  run: |
    sleep 60  # Wait longer
    for i in {1..5}; do
      if curl -f http://${{ secrets.SERVER_HOST }}/api/items/health; then
        exit 0
      fi
      sleep 10
    done
    exit 1
```

---

## Performance

### Slow Backend Startup

**Symptoms:**

Backend takes >30 seconds to start.

**Causes:**
1. Resource constraints (RAM/CPU)
2. Large dependency downloads
3. Database connection timeout

**Solutions:**

**Increase Java heap:**

In `docker-compose.prod.yml`:
```yaml
backend:
  environment:
    JAVA_OPTS: "-Xms512m -Xmx1024m -XX:+UseG1GC"
```

**Upgrade server:**

From CX22 to CX32 for more RAM:
```bash
cd terraform
nano terraform.tfvars
# server_type = "cx32"
terraform apply
```

**Optimize Spring Boot:**

In `application.yml`:
```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate  # Faster than update
```

---

### High Memory Usage

**Symptoms:**
```bash
free -h
# Shows high memory usage
docker stats
# Container using excessive RAM
```

**Solutions:**

**Set memory limits in docker-compose.prod.yml:**

```yaml
backend:
  deploy:
    resources:
      limits:
        memory: 1G
      reservations:
        memory: 512M
```

**Tune JVM:**
```yaml
backend:
  environment:
    JAVA_OPTS: "-Xms256m -Xmx512m -XX:+UseSerialGC"
```

---

## General Tips

### View All Container Logs

```bash
docker compose -f docker-compose.prod.yml logs -f
```

### Restart Everything Cleanly

```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d
```

### Check Docker Disk Usage

```bash
docker system df
docker system prune -a  # Clean up unused images/containers
```

### Test Backend Directly

```bash
# Bypass Traefik, test backend directly
docker compose exec backend wget -qO- http://localhost:8080/api/items/health
```

### Access Database Directly

```bash
docker compose exec postgres psql -U appuser -d appdb
# \dt - list tables
# \q - quit
```

---

## Getting Help

If issues persist:

1. Check all logs: `docker compose logs`
2. Verify DNS: `dig your-domain.com`
3. Test ports: `nc -zv your-server-ip 80`
4. Check firewall: Hetzner Cloud Console → Firewalls
5. Review `.env` file for correct values
6. Ensure all containers are healthy: `docker compose ps`

For Hetzner-specific issues: https://docs.hetzner.com/
For Traefik issues: https://doc.traefik.io/traefik/
