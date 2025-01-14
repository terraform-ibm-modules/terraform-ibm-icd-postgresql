##############################################################################
# Outputs
##############################################################################
output "id" {
  description = "Database instance id"
  value       = module.database.id
}

output "version" {
  description = "Database instance version"
  value       = module.database.version
}

output "adminuser" {
  description = "Database admin user name"
  value       = module.database.adminuser
}

output "hostname" {
  description = "Database connection hostname"
  value       = module.database.hostname
}

output "port" {
  description = "Database connection port"
  value       = module.database.port
}

output "certificate_base64" {
  description = "Database connection certificate"
  value       = module.database.certificate_base64
  sensitive   = true
}
