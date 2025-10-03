##############################################################################
# Outputs
##############################################################################
output "id" {
  description = "Postgresql instance id"
  value       = module.database.id
}

output "postgresql_crn" {
  description = "Postgresql CRN"
  value       = module.database.crn
}

output "version" {
  description = "Postgresql instance version"
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

output "read_replica_ids" {
  description = "Read-only replica Postgresql instance IDs"
  value       = module.read_only_replica_postgresql_db[*].id
}

output "read_replica_crns" {
  description = "Read-only replica Postgresql CRNs"
  value       = module.read_only_replica_postgresql_db[*].crn
}
