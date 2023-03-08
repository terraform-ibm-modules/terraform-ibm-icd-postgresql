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

output "backup_crn" {
  description = "Postgresql backup id"
  value       = data.ibm_database_backups.backup_database.backups[0].backup_id
}
