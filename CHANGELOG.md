# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2025-12-09

### Changed

#### Infrastructure
- **Server Type**: Updated default from `cx21` to `cx22` (new Hetzner generation)
  - Cost reduced: ~5.83 EUR/month → ~4.90 EUR/month
  - Same specs: 2 vCPU, 4GB RAM, 40GB SSD
- **Firewall**: Added Port 8080 rule for Backend API development/testing
  - ⚠️ Note: Close this port in production, route through Traefik on 80/443
- **Primary IP**: Resource commented out in `main.tf` (optional, saves ~1.19 EUR/month)

#### Backend
- **Hibernate DDL**: Changed from `validate` to `update` in production profile
  - Tables now created automatically on first run
  - For production with Flyway/Liquibase, change back to `validate`
- **Spring Profile**: Documented use of `dev` profile for easier setup
  - `dev` profile has `ddl-auto: create-drop` for automatic schema creation

#### Documentation
- Updated all server type references from cx21 → cx22
- Updated cost tables across README files
- Added note about Port 8080 security consideration
- Clarified frontend status (minimal placeholder, to be developed)
- Updated `terraform.tfvars.example` with new server types

### Technical Details

**Files Changed:**
- `terraform/main.tf` - Added Port 8080 firewall rule
- `terraform/variables.tf` - Changed default server_type to cx22
- `terraform/terraform.tfvars.example` - Updated examples
- `backend/src/main/resources/application.yml` - Changed ddl-auto to update
- `README.md` - Updated costs and status
- `terraform/README.md` - Updated server costs table
- `docs/SETUP.md` - Updated setup instructions

**Deployment Notes:**
- Existing deployments: Run `terraform apply` to update firewall
- New deployments: Will automatically use cx22 and have Port 8080 open
- Backend will create database tables automatically on first start

### Security Recommendations

For production deployments:
1. Close Port 8080 in firewall (remove rule from `main.tf`)
2. Route all traffic through Traefik on ports 80/443
3. Consider using Flyway/Liquibase for database migrations
4. Change `ddl-auto` back to `validate` in production profile
5. Restrict SSH access to specific IPs in `terraform.tfvars`

## [1.0.0] - 2025-12-08

### Added
- Initial release
- Terraform infrastructure for Hetzner Cloud
- Spring Boot 3 backend with PostgreSQL
- Angular 17 frontend structure
- Docker Compose setup
- GitHub Actions CI/CD pipeline
- Comprehensive documentation

### Infrastructure
- Ubuntu 24.04 server
- Docker & Docker Compose pre-installed
- Firewall with SSH, HTTP, HTTPS
- Automatic security updates
- fail2ban for SSH protection

### Backend
- Spring Boot 3.2.1 with Java 21
- PostgreSQL 16 database
- REST API with CRUD operations
- Health checks and monitoring
- Hibernate JPA

### DevOps
- Terraform for infrastructure as code
- Docker multi-stage builds
- GitHub Actions for CI/CD
- Automatic deployments on push to main

### Documentation
- Comprehensive README.md
- Detailed SETUP.md guide
- Terraform documentation
- API documentation
