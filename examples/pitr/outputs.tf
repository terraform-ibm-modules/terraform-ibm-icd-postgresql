##############################################################################
# Outputs
##############################################################################

output "pitr_postgresql_db_id" {
  description = "PITR Postgresql instance id"
  value       = module.postgresql_db_pitr.id
}

output "pitr_postgresql_db_version" {
  description = "PITR Postgresql instance version"
  value       = module.postgresql_db_pitr.version
}

output "pitr_time" {
  description = "PITR timestamp in UTC format (%Y-%m-%dT%H:%M:%SZ) used to create PITR instance"
  value       = var.pitr_time
}
