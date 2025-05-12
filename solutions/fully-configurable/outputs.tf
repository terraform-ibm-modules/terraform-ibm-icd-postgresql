##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "PostgreSQL instance id"
  value       = local.postgresql_id
}

output "guid" {
  description = "PostgreSQL instance guid"
  value       = local.postgresql_guid
}

output "version" {
  description = "PostgreSQL instance version"
  value       = local.postgresql_version
}

output "crn" {
  description = "PostgreSQL instance crn"
  value       = local.postgresql_crn
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = var.existing_postgresql_instance_crn != null ? null : module.postgresql_db[0].service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = var.existing_postgresql_instance_crn != null ? null : module.postgresql_db[0].service_credentials_object
  sensitive   = true
}

output "hostname" {
  description = "PostgreSQL instance hostname"
  value       = local.postgresql_hostname
}

output "port" {
  description = "PostgreSQL instance port"
  value       = local.postgresql_port
}
