output "server_id" {
  description = "Hetzner Cloud server ID"
  value       = hcloud_server.app_server.id
}

output "server_name" {
  description = "Server name"
  value       = hcloud_server.app_server.name
}

output "server_ipv4" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.app_server.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 address of the server"
  value       = hcloud_server.app_server.ipv6_address
}

output "server_status" {
  description = "Server status"
  value       = hcloud_server.app_server.status
}

output "ssh_connection" {
  description = "SSH connection string"
  value       = "ssh root@${hcloud_server.app_server.ipv4_address}"
}

output "application_url" {
  description = "Application URL"
  value       = "http://${hcloud_server.app_server.ipv4_address}"
}

output "next_steps" {
  description = "Next steps after infrastructure is created"
  value = <<-EOT
    
    ✅ Infrastructure created successfully!
    
    Next steps:
    1. SSH into server: ssh root@${hcloud_server.app_server.ipv4_address}
    2. Wait for cloud-init to complete (~2-3 minutes): tail -f /var/log/cloud-init-output.log
    3. Verify Docker: docker --version && docker compose version
    4. Clone your application repository
    5. Run: docker compose up -d
    
    Server IP: ${hcloud_server.app_server.ipv4_address}
    Location: ${var.location}
    Type: ${var.server_type}
  EOT
}
