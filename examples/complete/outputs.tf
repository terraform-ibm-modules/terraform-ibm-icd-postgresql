##############################################################################
# Outputs
##############################################################################
output "id" {
  description = "Postgresql instance id"
  value       = module.postgresql_db.id
}

output "guid" {
  description = "Postgresql instance guid"
  value       = module.postgresql_db.guid
}

output "version" {
  description = "Postgresql instance version"
  value       = module.postgresql_db.version
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = module.postgresql_db.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = module.postgresql_db.service_credentials_object
  sensitive   = true
}

output "cbrruleid" {
  description = "CBR created to restrict Postgresql"
  value       = module.postgresql_db.cbrruleid
}
