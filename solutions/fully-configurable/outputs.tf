##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "PostgreSQL instance id"
  value       = local.postgresql_id
}

output "version" {
  description = "PostgreSQL instance version"
  value       = local.postgresql_version
}

output "guid" {
  description = "PostgreSQL instance guid"
  value       = local.postgresql_guid
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

output "next_steps_text" {
  value       = "Your Database for PostgreSQL instance is ready. You can now take advantage of a fully managed service enabling you to efficiently create sophisticated, high-performance applications with enhanced JSON support and improved query parallelism."
  description = "Next steps text"
}

output "next_step_primary_label" {
  value       = "Deployment Details"
  description = "Primary label"
}

output "next_step_primary_url" {
  value       = "https://cloud.ibm.com/services/databases-for-postgresql/${local.postgresql_crn}"
  description = "Primary URL"
}

output "next_step_secondary_label" {
  value       = "Learn more about Databases for PostgreSQL"
  description = "Secondary label"
}

output "next_step_secondary_url" {
  value       = "https://cloud.ibm.com/docs/databases-for-postgresql"
  description = "Secondary URL"
}
