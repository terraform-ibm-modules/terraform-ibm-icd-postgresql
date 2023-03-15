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

# TBD: Remove this - Created output just to validate results
output "testing_attribs" {
  value = module.postgresql_db.local_attribs
}