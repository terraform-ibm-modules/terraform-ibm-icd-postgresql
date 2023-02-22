##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Postgresl instance id"
  value       = ibm_database.postgresql_db.id
}

output "version" {
  description = "Postgresql instance version"
  value       = ibm_database.postgresql_db.version
}

output "service_credentials_json" {
  description = "List of service credentials json"
  value       = local.service_credentials_json
}

output "service_credentials_object" {
  description = "Object of service credentials with username, password, certificate and hostname"
  value       = local.service_credentials_object
}
