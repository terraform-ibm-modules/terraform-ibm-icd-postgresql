##############################################################################
# Outputs
##############################################################################
output "id" {
  description = "Postgresql instance id"
  value       = var.existing_postgresql_db_backup_crn == null ? module.postgresql_db[0].id : null
}

output "restored_postgresql_db_id" {
  description = "Restored Postgresql instance id"
  value       = module.restored_postgresql_db.id
}

output "restored_postgresql_db_version" {
  description = "Restored Postgresql instance version"
  value       = module.restored_postgresql_db.version
}
