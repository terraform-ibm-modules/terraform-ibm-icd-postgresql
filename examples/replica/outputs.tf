##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Postgresql instance id"
  value       = module.postgresql_db.id
}

output "replica_id" {
  description = "Postgresql read-only replica instance id"
  value       = module.replicate_postgresql_db.id
}

output "version" {
  description = "Postgresql instance version"
  value       = module.postgresql_db.version
}

output "replica_version" {
  description = "Postgresql read-only replica instance version"
  value       = module.replicate_postgresql_db.version
}
