##############################################################################
# Outputs
##############################################################################
output "restored_icd_postgresql_id" {
  description = "Restored Postgresql instance id"
  value       = module.restored_icd_postgresql.id
}

output "restored_icd_postgresql_version" {
  description = "Restored Postgresql instance version"
  value       = module.restored_icd_postgresql.version
}
