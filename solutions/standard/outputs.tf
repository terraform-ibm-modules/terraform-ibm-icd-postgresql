# ##############################################################################
# # Outputs
# ##############################################################################

# output "id" {
#   description = "PostgreSQL instance id"
#   value       = module.postgresql_db.id
# }

# output "guid" {
#   description = "PostgreSQL instance guid"
#   value       = module.postgresql_db.guid
# }

# output "version" {
#   description = "PostgreSQL instance version"
#   value       = module.postgresql_db.version
# }

# output "crn" {
#   description = "PostgreSQL instance crn"
#   value       = module.postgresql_db.crn
# }

# output "cbr_rule_ids" {
#   description = "CBR rule ids created to restrict PostgreSQL"
#   value       = module.postgresql_db.cbr_rule_ids
# }

# output "service_credentials_json" {
#   description = "Service credentials json map"
#   value       = module.postgresql_db.service_credentials_json
#   sensitive   = true
# }

# output "service_credentials_object" {
#   description = "Service credentials object"
#   value       = module.postgresql_db.service_credentials_object
#   sensitive   = true
# }

# output "hostname" {
#   description = "PostgreSQL instance hostname"
#   value       = module.postgresql_db.hostname
# }

# output "port" {
#   description = "PostgreSQL instance port"
#   value       = module.postgresql_db.port
# }
output "kms_keys_debug" {
  value = module.postgresql_db.kms_keys_debug
}
output "validate_backup_kms_key" {
  value = module.postgresql_db.validate_backup_kms_key
}

output "kms_key" {
  value = module.postgresql_db.kms_key
}
output "backup_encryption_key" {
  value = module.postgresql_db.backup_encryption_key
}
