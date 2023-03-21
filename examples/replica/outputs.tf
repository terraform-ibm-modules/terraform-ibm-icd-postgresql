##############################################################################
# Outputs
##############################################################################
output "id" {
  description = "Postgresql read-only replica instance id"
  value       = module.replicate_postgresql_db.id
}

output "version" {
  description = "Postgresql read-only replica instance version"
  value       = module.replicate_postgresql_db.version
}
