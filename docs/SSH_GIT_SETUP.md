# SSH & Git Setup Guide

Complete guide for setting up passwordless SSH access to your server and passwordless Git operations.

## Table of Contents

- [Overview](#overview)
- [SSH Keys Without Passphrase](#ssh-keys-without-passphrase)
- [Git with SSH (No Password)](#git-with-ssh-no-password)
- [SSH Config File](#ssh-config-file)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Goals

After completing this guide, you will have:

- ✅ SSH to server without entering passphrase
- ✅ Git push/pull without entering password
- ✅ Secure key-based authentication
- ✅ Convenient aliases for quick access

### Security Note

**Keys without passphrase are less secure than keys with passphrase.**

However, for development workflows and automation (CI/CD), passphrase-free keys are practical. Ensure:

- Keep private keys secure (`chmod 600`)
- Don't share private keys
- Use different keys for different purposes
- Regularly rotate keys
- Consider SSH agent for passphrase-protected keys in interactive use

---

## SSH Keys Without Passphrase

### 1. Create SSH Key for Server Access

**On your local machine:**

```bash
# Create new key without passphrase
ssh-keygen -t ed25519 -f ~/.ssh/hetzner_nopass -C "your-email@example.com"

# When prompted for passphrase: Press ENTER (leave empty)
# Press ENTER again to confirm
```

**Key files created:**
- `~/.ssh/hetzner_nopass` - Private key (keep secret!)
- `~/.ssh/hetzner_nopass.pub` - Public key (safe to share)

---

### 2. Copy Public Key to Server

**Method 1: Using ssh-copy-id (easiest)**

```bash
ssh-copy-id -i ~/.ssh/hetzner_nopass user@your-server-ip

# Enter server password when prompted
```

**Method 2: Manual copy**

```bash
# Display public key
cat ~/.ssh/hetzner_nopass.pub

# Copy the output
```

Then on the server:

```bash
# SSH to server (using old method)
ssh user@your-server-ip

# Add public key
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys

# Paste the public key at the end
# Save: Ctrl+O, Enter, Ctrl+X

# Set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Exit server
exit
```

**Method 3: Direct pipe (if you have existing access)**

```bash
cat ~/.ssh/hetzner_nopass.pub | ssh user@your-server-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

---

### 3. Test SSH Connection

```bash
# Test with new key
ssh -i ~/.ssh/hetzner_nopass user@your-server-ip

# Should login WITHOUT asking for passphrase!
```

---

### 4. Configure SSH Config (Optional but Recommended)

Create/edit SSH config file:

```bash
nano ~/.ssh/config
```

Add:

```
Host hetzner
    HostName your-server-ip
    User root
    IdentityFile ~/.ssh/hetzner_nopass
    IdentitiesOnly yes
```

**Explanation:**
- `Host hetzner` - Alias you'll use (e.g., `ssh hetzner`)
- `HostName` - Actual server IP or domain
- `User` - Username on server (usually `root`)
- `IdentityFile` - Path to private key
- `IdentitiesOnly yes` - Use ONLY this key (ignore other keys)

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

**Test:**

```bash
# Now you can simply use:
ssh hetzner

# Instead of:
ssh -i ~/.ssh/hetzner_nopass user@your-server-ip
```

---

## Git with SSH (No Password)

### Why SSH Instead of HTTPS?

**HTTPS:** `https://github.com/username/repo.git`
- Requires username + password/token for each push
- Or storing credentials (less secure)

**SSH:** `git@github.com:username/repo.git`
- Uses SSH keys (no password needed)
- More secure and convenient

---

### 1. Create SSH Key for GitHub

**On your local machine:**

```bash
# Create new key for GitHub
ssh-keygen -t ed25519 -f ~/.ssh/github_nopass -C "your-email@example.com"

# When prompted for passphrase: Press ENTER (leave empty)
# Press ENTER again
```

**Display public key:**

```bash
cat ~/.ssh/github_nopass.pub
```

Copy the entire output (starts with `ssh-ed25519 AAAA...`)

---

### 2. Add SSH Key to GitHub

**In browser:**

1. Go to https://github.com/settings/keys
2. Click **New SSH key**
3. **Title:** `Linux Workstation` (or any descriptive name)
4. **Key type:** Authentication Key
5. **Key:** Paste your public key
6. Click **Add SSH key**
7. Confirm with your GitHub password if prompted

---

### 3. Configure SSH for GitHub

Edit SSH config:

```bash
nano ~/.ssh/config
```

Add (in addition to server config):

```
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_nopass
    IdentitiesOnly yes
```

**Complete example with both:**

```
Host hetzner
    HostName 91.98.127.79
    User root
    IdentityFile ~/.ssh/hetzner_nopass
    IdentitiesOnly yes

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_nopass
    IdentitiesOnly yes
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

---

### 4. Test GitHub SSH Connection

```bash
ssh -T git@github.com

# First time will ask to verify fingerprint:
# "Are you sure you want to continue connecting (yes/no)?"
# Type: yes

# Should show:
# Hi YourUsername! You've successfully authenticated, but GitHub does not provide shell access.
```

---

### 5. Convert Existing Repository to SSH

**Check current remote:**

```bash
cd ~/path/to/your/repo

git remote -v

# If shows HTTPS:
# origin  https://github.com/username/repo.git (fetch)
# origin  https://github.com/username/repo.git (push)
```

**Convert to SSH:**

```bash
git remote set-url origin git@github.com:username/repo.git

# Verify:
git remote -v

# Should now show:
# origin  git@github.com:username/repo.git (fetch)
# origin  git@github.com:username/repo.git (push)
```

---

### 6. Test Git Operations

```bash
# Should work without password:
git pull
git push origin main

# No username/password prompt!
```

---

## SSH Config File

### Complete Example

**Location:** `~/.ssh/config`

```
# Hetzner Production Server
Host hetzner
    HostName 91.98.127.79
    User root
    IdentityFile ~/.ssh/hetzner_nopass
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_nopass
    IdentitiesOnly yes

# Multiple servers example
Host staging
    HostName staging.example.com
    User deploy
    IdentityFile ~/.ssh/staging_key
    Port 2222
    IdentitiesOnly yes

# Wildcard for all servers
Host *.example.com
    User admin
    IdentityFile ~/.ssh/company_key
```

### Common SSH Config Options

| Option | Description | Example |
|--------|-------------|---------|
| `Host` | Alias name | `Host myserver` |
| `HostName` | Actual server address | `HostName 1.2.3.4` |
| `User` | Username | `User root` |
| `IdentityFile` | SSH key path | `IdentityFile ~/.ssh/key` |
| `IdentitiesOnly` | Use only specified key | `IdentitiesOnly yes` |
| `Port` | SSH port (default 22) | `Port 2222` |
| `ServerAliveInterval` | Keep connection alive | `ServerAliveInterval 60` |
| `ServerAliveCountMax` | Max keepalive tries | `ServerAliveCountMax 3` |
| `Compression` | Enable compression | `Compression yes` |
| `ForwardAgent` | SSH agent forwarding | `ForwardAgent yes` |

---

## Server Git Setup (Optional)

If you also want passwordless git on the server:

### 1. Create SSH Key on Server

```bash
# SSH to server
ssh hetzner

# Create key for GitHub
ssh-keygen -t ed25519 -f ~/.ssh/github_server -C "server@hetzner"

# Press ENTER for no passphrase

# Display public key
cat ~/.ssh/github_server.pub
```

### 2. Add to GitHub

Copy the public key and add to GitHub:
- https://github.com/settings/keys
- **New SSH key**
- Title: `Hetzner Production Server`
- Paste key
- **Add SSH key**

### 3. Configure SSH on Server

```bash
# On server
nano ~/.ssh/config
```

Add:

```
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_server
    IdentitiesOnly yes
```

### 4. Convert Repository to SSH

```bash
cd /opt/spring-angular-app

git remote set-url origin git@github.com:username/repo.git

# Test
ssh -T git@github.com
git pull
```

---

## Troubleshooting

### SSH Still Asks for Passphrase

**Problem:** Using wrong key or key has passphrase

**Solution:**

```bash
# Check which key SSH is trying to use
ssh -v user@server 2>&1 | grep "Offering public key"

# Force specific key
ssh -i ~/.ssh/hetzner_nopass user@server

# Check SSH config
cat ~/.ssh/config

# Ensure IdentitiesOnly yes is set
```

---

### Permission Denied (publickey)

**Problem:** Public key not on server or wrong permissions

**Check on server:**

```bash
# Check authorized_keys exists and has your key
cat ~/.ssh/authorized_keys

# Check permissions
ls -la ~/.ssh
# Should show: drwx------ (700)

ls -la ~/.ssh/authorized_keys
# Should show: -rw------- (600)

# Fix permissions if wrong
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

### Git Still Asks for Password

**Problem:** Repository still using HTTPS

**Check and fix:**

```bash
git remote -v

# If shows https://, convert to SSH:
git remote set-url origin git@github.com:username/repo.git

# Verify GitHub SSH works
ssh -T git@github.com
```

---

### Multiple Keys Conflict

**Problem:** SSH tries all keys before the right one

**Solution:** Use `IdentitiesOnly yes` in SSH config

```bash
nano ~/.ssh/config
```

Ensure each Host has:

```
Host example
    IdentityFile ~/.ssh/specific_key
    IdentitiesOnly yes
```

This prevents SSH from trying all keys in `~/.ssh/`.

---

### SSH Config Not Working

**Problem:** SSH ignoring config file

**Check:**

```bash
# Test if config is read
ssh -vvv hetzner 2>&1 | grep config

# Check file permissions
ls -la ~/.ssh/config
# Should be: -rw------- (600) or -rw-r--r-- (644)

# Fix if wrong
chmod 600 ~/.ssh/config

# Verify syntax
ssh -G hetzner
# Shows parsed config for this host
```

---

### GitHub Authentication Failed

**Problem:** Key not added to GitHub or wrong key used

**Verify:**

```bash
# Test GitHub authentication
ssh -T git@github.com

# If fails, check which key is being offered
ssh -vT git@github.com 2>&1 | grep "Offering public key"

# Ensure correct key is in GitHub settings
cat ~/.ssh/github_nopass.pub
# Copy and verify at: https://github.com/settings/keys
```

---

### Can't Find Private Key

**Problem:** Key moved or renamed

**Solution:**

```bash
# List all SSH keys
ls -la ~/.ssh/*.pub

# If key is missing, create new one
ssh-keygen -t ed25519 -f ~/.ssh/new_key_name

# Update SSH config and GitHub with new key
```

---

## Best Practices

### Security

1. **Different keys for different purposes:**
   - One key for servers
   - One key for GitHub
   - One key per server if managing multiple

2. **Regular key rotation:**
   ```bash
   # Generate new key
   ssh-keygen -t ed25519 -f ~/.ssh/new_key
   
   # Add to server/GitHub
   # Update SSH config
   # Remove old key from server/GitHub
   ```

3. **Backup private keys securely:**
   ```bash
   # Encrypted backup
   tar czf - ~/.ssh | gpg -c > ssh_backup_$(date +%F).tar.gz.gpg
   ```

4. **Monitor authorized_keys:**
   ```bash
   # On server, check who has access
   cat ~/.ssh/authorized_keys
   ```

---

### Convenience

1. **Use SSH agent for interactive work:**
   ```bash
   # Start SSH agent
   eval "$(ssh-agent -s)"
   
   # Add key (with passphrase)
   ssh-add ~/.ssh/secure_key
   
   # Key remains unlocked in memory
   ```

2. **Create aliases:**
   ```bash
   # In ~/.bashrc or ~/.zshrc
   alias sshh='ssh hetzner'
   alias gsync='git pull && git push'
   ```

3. **Use ProxyJump for bastion hosts:**
   ```ssh
   Host internal-server
       HostName 10.0.1.100
       User admin
       ProxyJump bastion-host
   ```

---

## Summary

### Quick Reference

**Server SSH:**
```bash
ssh hetzner
```

**Git operations:**
```bash
git push origin main
git pull
```

**Check SSH config:**
```bash
cat ~/.ssh/config
```

**Test GitHub SSH:**
```bash
ssh -T git@github.com
```

**List SSH keys:**
```bash
ls -la ~/.ssh/*.pub
```

---

### Files Overview

| File | Purpose | Permissions |
|------|---------|-------------|
| `~/.ssh/config` | SSH configuration | 600 or 644 |
| `~/.ssh/id_ed25519` | Default private key | 600 |
| `~/.ssh/id_ed25519.pub` | Default public key | 644 |
| `~/.ssh/hetzner_nopass` | Server private key | 600 |
| `~/.ssh/github_nopass` | GitHub private key | 600 |
| `~/.ssh/authorized_keys` | Server: allowed keys | 600 |
| `~/.ssh/known_hosts` | Verified host fingerprints | 644 |

---

## Additional Resources

- [GitHub SSH Documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [OpenSSH Config Documentation](https://man.openbsd.org/ssh_config)
- [SSH Key Best Practices](https://www.ssh.com/academy/ssh/keygen)
- [GitHub SSH Troubleshooting](https://docs.github.com/en/authentication/troubleshooting-ssh)

---

**🔑 You now have passwordless SSH and Git access configured!**
