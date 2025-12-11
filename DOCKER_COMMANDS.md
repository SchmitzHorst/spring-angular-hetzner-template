# Docker Commands Reference

Essential Docker and Docker Compose commands used in this project.

## Table of Contents

- [Docker Compose - Main Commands](#docker-compose---main-commands)
- [Docker - Base Commands](#docker---base-commands)
- [Debugging Commands](#debugging-commands)
- [Database Commands](#database-commands)
- [Typical Workflows](#typical-workflows)
- [Shortcuts & Tips](#shortcuts--tips)
- [Important Flags](#important-flags)

---

## Docker Compose - Main Commands

### Container Management

**Start all services (detached/background):**
```bash
docker compose -f docker-compose.prod.yml up -d
```

**Start with explicit .env file:**
```bash
docker compose -f docker-compose.prod.yml --env-file .env up -d
```

**Start only specific services:**
```bash
docker compose -f docker-compose.prod.yml up -d backend frontend
```

**Stop all services:**
```bash
docker compose -f docker-compose.prod.yml down
```

**Stop and remove volumes (⚠️ DELETES DATABASE!):**
```bash
docker compose -f docker-compose.prod.yml down -v
```

**Restart a service:**
```bash
docker compose -f docker-compose.prod.yml restart backend
```

**Force recreate a service:**
```bash
docker compose -f docker-compose.prod.yml up -d --force-recreate backend
```

---

### Images & Builds

**Build images (from Dockerfile):**
```bash
docker compose -f docker-compose.prod.yml build
```

**Build only one service:**
```bash
docker compose -f docker-compose.prod.yml build backend
```

**Build without cache (completely fresh):**
```bash
docker compose -f docker-compose.prod.yml build --no-cache
```

**Pull images from registry:**
```bash
docker compose -f docker-compose.prod.yml pull
```

---

### Status & Monitoring

**Show status of all containers:**
```bash
docker compose -f docker-compose.prod.yml ps
```
Shows: Name, Status (healthy/unhealthy), Ports

**View logs (all services):**
```bash
docker compose -f docker-compose.prod.yml logs
```

**View logs of one service (last 50 lines):**
```bash
docker compose -f docker-compose.prod.yml logs backend --tail=50
```

**Follow logs live (with -f):**
```bash
docker compose -f docker-compose.prod.yml logs -f
```

**Follow logs of one service:**
```bash
docker compose -f docker-compose.prod.yml logs -f traefik
```

**View logs with timestamps:**
```bash
docker compose -f docker-compose.prod.yml logs -f --timestamps
```

---

## Docker - Base Commands

### Container Commands

**List running containers:**
```bash
docker ps
```

**List all containers (including stopped):**
```bash
docker ps -a
```

**Show container details:**
```bash
docker inspect spring-backend
```

**Execute command in running container:**
```bash
docker exec -it spring-backend /bin/sh
```

**Execute command without interactive shell:**
```bash
docker compose -f docker-compose.prod.yml exec backend env | grep POSTGRES
```

**Stop container:**
```bash
docker stop spring-backend
```

**Remove container:**
```bash
docker rm spring-backend
```

**View container logs:**
```bash
docker logs spring-backend --tail=50 -f
```

---

### Image Commands

**List all images:**
```bash
docker images
```

**Filter images:**
```bash
docker images | grep spring-angular
```

**Remove image:**
```bash
docker rmi spring-angular-app-backend:local
```

**Remove unused images:**
```bash
docker image prune -af
```

**Tag image:**
```bash
docker tag local-image:latest registry/image:tag
```

---

### Registry Commands

**Login to GitHub Container Registry:**
```bash
echo "GITHUB_TOKEN" | docker login ghcr.io -u username --password-stdin
```

**Logout:**
```bash
docker logout ghcr.io
```

**Push image:**
```bash
docker push ghcr.io/username/image:tag
```

**Pull image:**
```bash
docker pull ghcr.io/username/image:tag
```

---

### System Commands

**Show disk usage:**
```bash
docker system df
```

**Clean up everything (⚠️ Caution!):**
```bash
docker system prune -a
```

**Remove unused volumes:**
```bash
docker volume prune
```

**List networks:**
```bash
docker network ls
```

**Inspect network:**
```bash
docker network inspect spring-angular-app_app-network
```

**List volumes:**
```bash
docker volume ls
```

**Remove specific volume:**
```bash
docker volume rm volume_name
```

---

## Debugging Commands

### Search Logs

**Filter logs by text:**
```bash
docker compose -f docker-compose.prod.yml logs traefik | grep "backend"
```

**Show context (20 lines after match):**
```bash
docker compose -f docker-compose.prod.yml logs traefik | grep -A 20 "certificate"
```

**Multiple services at once:**
```bash
docker compose -f docker-compose.prod.yml logs backend postgres | tail -50
```

**Search with case insensitive:**
```bash
docker compose -f docker-compose.prod.yml logs | grep -i "error"
```

---

### Inspect Container Environment

**Show environment variables:**
```bash
docker compose -f docker-compose.prod.yml exec backend env
```

**Filtered environment variables:**
```bash
docker compose -f docker-compose.prod.yml exec backend env | grep POSTGRES
```

**View file in container:**
```bash
docker compose -f docker-compose.prod.yml exec backend cat /app/application.yml
```

**List directory contents:**
```bash
docker compose -f docker-compose.prod.yml exec backend ls -la /app
```

**Check if file exists:**
```bash
docker compose -f docker-compose.prod.yml exec backend test -f /app/file.txt && echo "exists" || echo "not found"
```

---

### Manual Health Checks

**Backend health check:**
```bash
docker compose -f docker-compose.prod.yml exec backend wget -qO- http://localhost:8080/actuator/health
```

**Frontend health check:**
```bash
docker compose -f docker-compose.prod.yml exec frontend wget -qO- http://localhost:80
```

**Test with curl:**
```bash
docker compose -f docker-compose.prod.yml exec backend curl -f http://localhost:8080/api/items/health
```

---

### Network Testing

**DNS resolution in container:**
```bash
docker compose -f docker-compose.prod.yml exec frontend nslookup backend
```

**Ping between containers:**
```bash
docker compose -f docker-compose.prod.yml exec frontend ping backend -c 3
```

**Test port connectivity:**
```bash
docker compose -f docker-compose.prod.yml exec frontend nc -zv backend 8080
```

**Check which ports are listening:**
```bash
docker compose -f docker-compose.prod.yml exec backend netstat -tulpn
```

---

### Container Resources

**Real-time resource usage:**
```bash
docker stats
```

**Specific container stats:**
```bash
docker stats spring-backend
```

**One-time stats snapshot:**
```bash
docker stats --no-stream
```

---

## Database Commands

### PostgreSQL Operations

**Open PostgreSQL shell:**
```bash
docker compose -f docker-compose.prod.yml exec postgres psql -U appuser -d appdb
```

**Inside psql:**
```sql
\dt              -- List tables
\d items         -- Show table structure
\l               -- List databases
\du              -- List users
SELECT * FROM items;  -- Query data
\q               -- Quit
```

**Execute SQL directly:**
```bash
docker compose -f docker-compose.prod.yml exec postgres psql -U appuser -d appdb -c "SELECT * FROM items;"
```

**Count rows:**
```bash
docker compose -f docker-compose.prod.yml exec postgres psql -U appuser -d appdb -c "SELECT COUNT(*) FROM items;"
```

---

### Backup & Restore

**Create database backup:**
```bash
docker compose -f docker-compose.prod.yml exec postgres pg_dump -U appuser appdb > backup_$(date +%Y%m%d).sql
```

**Restore from backup:**
```bash
cat backup.sql | docker compose -f docker-compose.prod.yml exec -T postgres psql -U appuser -d appdb
```

**Backup all databases:**
```bash
docker compose -f docker-compose.prod.yml exec postgres pg_dumpall -U appuser > backup_all.sql
```

**Create compressed backup:**
```bash
docker compose -f docker-compose.prod.yml exec postgres pg_dump -U appuser appdb | gzip > backup.sql.gz
```

---

## Typical Workflows

### Complete Restart After Changes

```bash
# Stop everything
docker compose -f docker-compose.prod.yml down

# Rebuild images
docker compose -f docker-compose.prod.yml build

# Start with environment file
docker compose -f docker-compose.prod.yml --env-file .env up -d

# Follow logs
docker compose -f docker-compose.prod.yml logs -f
```

---

### Deploy Single Service

```bash
# Build only backend
docker compose -f docker-compose.prod.yml build backend

# Deploy backend
docker compose -f docker-compose.prod.yml up -d backend

# Check logs
docker compose -f docker-compose.prod.yml logs -f backend
```

---

### Debug Issues

**Step 1: Check status**
```bash
docker compose -f docker-compose.prod.yml ps
```

**Step 2: View logs of problematic service**
```bash
docker compose -f docker-compose.prod.yml logs backend --tail=100
```

**Step 3: Check environment**
```bash
docker compose -f docker-compose.prod.yml exec backend env
```

**Step 4: Enter container and test manually**
```bash
docker compose -f docker-compose.prod.yml exec backend sh
# Inside container:
curl http://localhost:8080/api/items/health
exit
```

---

### Update Application

**Method 1: Full rebuild**
```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d
```

**Method 2: Pull and restart (if using registry)**
```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

**Method 3: Rolling update**
```bash
# Update one service at a time
docker compose -f docker-compose.prod.yml build backend
docker compose -f docker-compose.prod.yml up -d --no-deps backend
```

---

### View Real-Time Activity

**Watch container status:**
```bash
watch -n 2 'docker compose -f docker-compose.prod.yml ps'
```

**Monitor logs in multiple terminals:**
```bash
# Terminal 1
docker compose -f docker-compose.prod.yml logs -f traefik

# Terminal 2
docker compose -f docker-compose.prod.yml logs -f backend

# Terminal 3
docker compose -f docker-compose.prod.yml logs -f frontend
```

---

## Shortcuts & Tips

### Using Default docker-compose.yml (Development)

If using `docker-compose.yml` (not prod):
```bash
docker compose up -d          # No -f flag needed
docker compose ps
docker compose logs -f
docker compose down
```

---

### Create Aliases (Optional)

Add to `~/.bashrc` or `~/.zshrc`:
```bash
# Production docker-compose shortcuts
alias dcp='docker compose -f docker-compose.prod.yml'
alias dcl='docker compose -f docker-compose.prod.yml logs -f'
alias dps='docker compose -f docker-compose.prod.yml ps'
alias dcb='docker compose -f docker-compose.prod.yml build'
alias dcu='docker compose -f docker-compose.prod.yml up -d'
alias dcd='docker compose -f docker-compose.prod.yml down'

# Then use:
dcp up -d
dcl backend
dps
```

Reload shell: `source ~/.bashrc`

---

### Quick Commands

**Restart everything:**
```bash
docker compose -f docker-compose.prod.yml restart
```

**View all container IPs:**
```bash
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
```

**Clean up stopped containers:**
```bash
docker container prune
```

**See which containers are using most resources:**
```bash
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

---

## Important Flags

| Flag | Meaning | Example |
|------|---------|---------|
| `-d` | Detached (background) | `up -d` |
| `-f` | Follow (live logs) | `logs -f` |
| `--tail` | Last N lines only | `logs --tail=50` |
| `-v` | Also remove volumes | `down -v` |
| `--no-cache` | Build without cache | `build --no-cache` |
| `--force-recreate` | Recreate containers | `up -d --force-recreate` |
| `--env-file` | Specific .env file | `--env-file .env` |
| `-T` | No TTY (for pipes) | `exec -T postgres` |
| `-it` | Interactive with TTY | `exec -it backend sh` |
| `--no-deps` | Don't restart dependencies | `up -d --no-deps backend` |
| `-a` | All (including stopped) | `ps -a` |
| `--timestamps` | Show log timestamps | `logs --timestamps` |
| `-q` | Quiet (IDs only) | `ps -q` |

---

## Advanced Usage

### Copy Files Between Host and Container

**From host to container:**
```bash
docker cp ./local-file.txt spring-backend:/app/file.txt
```

**From container to host:**
```bash
docker cp spring-backend:/app/logs/app.log ./app.log
```

---

### Save and Load Images

**Save image to tar:**
```bash
docker save spring-angular-app-backend:local > backend.tar
```

**Load image from tar:**
```bash
docker load < backend.tar
```

**Transfer between servers:**
```bash
# On source server
docker save spring-angular-app-backend:local | gzip > backend.tar.gz

# Copy to target server
scp backend.tar.gz user@target-server:/tmp/

# On target server
gunzip -c /tmp/backend.tar.gz | docker load
```

---

### Multi-Container Operations

**Stop specific containers:**
```bash
docker stop $(docker ps -q --filter "name=spring-")
```

**Remove containers by pattern:**
```bash
docker rm $(docker ps -a -q --filter "name=spring-")
```

**View logs of multiple containers:**
```bash
docker compose -f docker-compose.prod.yml logs -f backend frontend | grep ERROR
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check exit code
docker inspect spring-backend --format='{{.State.ExitCode}}'

# View last logs before crash
docker logs --tail=100 spring-backend
```

### Port Already in Use

```bash
# Find what's using port 8080
sudo netstat -tulpn | grep 8080
# or
sudo lsof -i :8080

# Kill process
sudo kill -9 PID
```

### Out of Disk Space

```bash
# Check Docker disk usage
docker system df

# Clean up
docker system prune -a --volumes

# Remove specific items
docker image prune -a
docker container prune
docker volume prune
docker network prune
```

### Container Stuck in "Unhealthy"

```bash
# Check health check command
docker inspect spring-backend --format='{{json .State.Health}}' | jq

# Test health check manually
docker compose -f docker-compose.prod.yml exec backend wget -qO- http://localhost:8080/actuator/health
```

---

## Performance Optimization

### Reduce Image Size

```bash
# Use multi-stage builds (in Dockerfile)
# Use alpine base images
# Clean up in same RUN command

# Check image layers
docker history spring-angular-app-backend:local

# Remove intermediate images
docker image prune
```

### Limit Container Resources

Add to `docker-compose.prod.yml`:
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

---

## Security Best Practices

### Scan Images for Vulnerabilities

```bash
# Using Docker Scout (built-in)
docker scout cves spring-angular-app-backend:local

# Or use Trivy
trivy image spring-angular-app-backend:local
```

### Run as Non-Root User

In Dockerfile:
```dockerfile
RUN addgroup -g 1001 -S appuser && adduser -u 1001 -S appuser -G appuser
USER appuser
```

### Use Secrets

```bash
# Create secret
echo "my_secret_password" | docker secret create db_password -

# Use in compose
services:
  backend:
    secrets:
      - db_password
```

---

## Useful One-Liners

```bash
# Kill all running containers
docker kill $(docker ps -q)

# Remove all containers
docker rm $(docker ps -a -q)

# Remove all images
docker rmi $(docker images -q)

# Get container IP
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' spring-backend

# Follow logs of all containers
docker compose -f docker-compose.prod.yml logs -f

# Restart only unhealthy containers
docker ps --filter health=unhealthy --format "{{.Names}}" | xargs docker restart

# Show which images are used by running containers
docker ps --format "{{.Image}}"
```

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

**💡 Tip:** Use `docker --help` or `docker compose --help` for quick reference anytime!
