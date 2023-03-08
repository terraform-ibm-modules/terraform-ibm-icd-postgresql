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

output "restored_postgresql_db_id" {
  description = "Restored Postgresql instance id"
  value       = module.restored_postgresql_db.id
}
