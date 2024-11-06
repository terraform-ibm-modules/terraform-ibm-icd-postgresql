##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "PostgreSQL instance id"
  value       = module.postgresql_db.id
}

output "guid" {
  description = "PostgreSQL instance guid"
  value       = module.postgresql_db.guid
}

output "version" {
  description = "PostgreSQL instance version"
  value       = module.postgresql_db.version
}

output "crn" {
  description = "PostgreSQL instance crn"
  value       = module.postgresql_db.crn
}

output "cbr_rule_ids" {
  description = "CBR rule ids created to restrict PostgreSQL"
  value       = module.postgresql_db.cbr_rule_ids
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = module.postgresql_db.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = module.postgresql_db.service_credentials_object
  sensitive   = true
}

output "hostname" {
  description = "PostgreSQL instance hostname"
  value       = module.postgresql_db.hostname
}

output "port" {
  description = "PostgreSQL instance port"
  value       = module.postgresql_db.port
}

output "test" {
  value = nonsensitive(local.create_cross_account_auth_policy)
  # sensitive = true
}
