##############################################################################
# Outputs
##############################################################################
output "id" {
  description = "Postgresql instance id"
  value       = module.postgresql_db.id
}

output "version" {
  description = "Postgresql instance version"
  value       = module.postgresql_db.version
}

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
  value       = data.ibm_database_point_in_time_recovery.database_pitr.earliest_point_in_time_recovery_time
}




