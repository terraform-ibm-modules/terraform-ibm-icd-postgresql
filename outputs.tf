##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Postgresql instance id"
  value       = ibm_database.postgresql_db.id
}

output "guid" {
  description = "Postgresql instance guid"
  value       = ibm_database.postgresql_db.guid
}

output "version" {
  description = "Postgresql instance version"
  value       = ibm_database.postgresql_db.version
}

output "crn" {
  description = "Postgresql instance crn"
  value       = ibm_database.postgresql_db.resource_crn
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = local.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = local.service_credentials_object
  sensitive   = true
}

output "cbr_rule_ids" {
  description = "CBR rule ids created to restrict Postgresql"
  value       = module.cbr_rule[*].rule_id
}

output "hostname" {
  description = "Database hostname. Only contains value when var.service_credential_names or var.users are set."
  value       = length(var.service_credential_names) > 0 ? nonsensitive(ibm_resource_key.service_credentials[keys(var.service_credential_names)[0]].credentials["connection.postgres.hosts.0.hostname"]) : length(var.users) > 0 ? data.ibm_database_connection.database_connection[0].postgres[0].hosts[0].hostname : null
}

output "port" {
  description = "Database port. Only contains value when var.service_credential_names or var.users are set."
  value       = length(var.service_credential_names) > 0 ? nonsensitive(ibm_resource_key.service_credentials[keys(var.service_credential_names)[0]].credentials["connection.postgres.hosts.0.port"]) : length(var.users) > 0 ? data.ibm_database_connection.database_connection[0].postgres[0].hosts[0].port : null
}
