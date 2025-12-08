# Terraform Infrastructure Setup

This directory contains Terraform configuration for deploying the infrastructure on Hetzner Cloud.

## Prerequisites

1. **Terraform installed** (>= 1.0)
   ```bash
   # Check version
   terraform --version
   
   # Install on macOS
   brew install terraform
   
   # Install on Linux
   wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
   unzip terraform_1.7.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Hetzner Cloud Account**
   - Sign up at https://console.hetzner.cloud
   - Create a new project
   - Generate API Token: Project → Security → API Tokens

3. **SSH Key Pair**
   ```bash
   # Generate if you don't have one
   ssh-keygen -t ed25519 -C "your-email@example.com"
   
   # View your public key
   cat ~/.ssh/id_ed25519.pub
   ```

## Setup

1. **Configure Variables**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review Infrastructure Plan**
   ```bash
   terraform plan
   ```

4. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

5. **Get Connection Info**
   ```bash
   terraform output
   ```

## What Gets Created

- **Hetzner Cloud Server** (Ubuntu 24.04)
  - Docker & Docker Compose pre-installed
  - Firewall configured (SSH, HTTP, HTTPS)
  - Automatic security updates enabled
  - fail2ban for SSH protection

- **Firewall Rules**
  - Port 22 (SSH) - restricted to your IP
  - Port 80 (HTTP) - open to all
  - Port 443 (HTTPS) - open to all

- **SSH Key** - for secure server access

## Server Costs

| Server Type | vCPU | RAM  | Storage | Price/Month |
|-------------|------|------|---------|-------------|
| cx21        | 2    | 4GB  | 40GB    | ~5.83 EUR   |
| cx31        | 2    | 8GB  | 80GB    | ~9.72 EUR   |
| cx41        | 4    | 16GB | 160GB   | ~18.54 EUR  |

## Post-Deployment

After `terraform apply`:

1. **SSH into server**
   ```bash
   ssh root@<server-ip>
   ```

2. **Wait for cloud-init** (~2-3 minutes)
   ```bash
   tail -f /var/log/cloud-init-output.log
   ```

3. **Verify Docker**
   ```bash
   docker --version
   docker compose version
   ```

4. **Deploy application**
   ```bash
   cd /opt/spring-angular-app
   # Clone your repo or copy docker-compose.yml
   docker compose up -d
   ```

## Useful Commands

```bash
# Show outputs again
terraform output

# SSH connection string
terraform output ssh_connection

# Destroy infrastructure (careful!)
terraform destroy

# Update infrastructure
terraform apply

# Show current state
terraform show
```

## Security Notes

⚠️ **Important for Production:**

1. Change `allowed_ssh_ips` in `terraform.tfvars` to your IP only
2. Keep `terraform.tfvars` secret (it's in .gitignore)
3. Enable a domain and SSL certificates
4. Configure backup strategy
5. Monitor server resources

## Troubleshooting

**Server not reachable?**
- Check firewall rules: `terraform show | grep firewall`
- Verify cloud-init completed: `ssh root@<ip> "tail /var/log/cloud-init-output.log"`

**Can't SSH?**
- Verify your SSH key is correct in terraform.tfvars
- Check if your IP is in allowed_ssh_ips

**Docker not installed?**
- Cloud-init may still be running, wait 2-3 minutes
- Check logs: `ssh root@<ip> "tail -f /var/log/cloud-init-output.log"`

## Cost Management

```bash
# Check current costs in Hetzner Console
# Monitor: console.hetzner.cloud → Billing

# Destroy when not needed
terraform destroy
```
