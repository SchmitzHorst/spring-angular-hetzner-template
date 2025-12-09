variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for server access"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "spring-angular-app"
}

variable "server_type" {
  description = "Hetzner Cloud server type"
  type        = string
  default     = "cx22" # 2 vCPU, 4 GB RAM, 40 GB SSD - ~4.90 EUR/month
  
  validation {
    condition     = can(regex("^(cx[0-9]{2}|cpx[0-9]{2}|ccx[0-9]{2})$", var.server_type))
    error_message = "Server type must be a valid Hetzner Cloud type (e.g., cx22, cx32, cpx11)"
  }
}

variable "location" {
  description = "Hetzner Cloud datacenter location"
  type        = string
  default     = "nbg1" # Nuremberg, Germany
  
  validation {
    condition     = contains(["nbg1", "fsn1", "hel1", "ash", "hil"], var.location)
    error_message = "Location must be one of: nbg1 (Nuremberg), fsn1 (Falkenstein), hel1 (Helsinki), ash (Ashburn), hil (Hillsboro)"
  }
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH into the server"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Default: allow from anywhere (change for production!)
}

variable "docker_compose_version" {
  description = "Docker Compose version to install"
  type        = string
  default     = "2.24.5"
}

variable "domain_name" {
  description = "Domain name for the application (optional, for SSL setup)"
  type        = string
  default     = ""
}
