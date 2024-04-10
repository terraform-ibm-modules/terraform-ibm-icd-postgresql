##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Postgresql instance id"
  value       = module.postgresql_db.id
}

output "guid" {
  description = "Postgresql instance guid"
  value       = module.postgresql_db.guid
}

output "version" {
  description = "Postgresql instance version"
  value       = module.postgresql_db.version
}

output "crn" {
  description = "Postgresql instance crn"
  value       = module.postgresql_db.crn
}

output "adminuser" {
  description = "Database admin user name"
  value       = module.postgresql_db.adminuser
}

output "hostname" {
  description = "Database connection hostname"
  value       = module.postgresql_db.hostname
}

output "port" {
  description = "Database connection port"
  value       = module.postgresql_db.port
}

output "certificate_base64" {
  description = "Database connection certificate"
  value       = module.postgresql_db.certificate_base64
  sensitive   = true
}
