##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Postgresql instance id"
  value       = can(ibm_database.postgresql_db[0].id) ? ibm_database.postgresql_db[0].id : null
}

output "version" {
  description = "Postgresql instance version"
  value       = can(ibm_database.postgresql_db[0].version) ? ibm_database.postgresql_db[0].version : null
}

output "guid" {
  description = "Postgresql instance guid"
  value       = can(ibm_database.postgresql_db[0].guid) ? ibm_database.postgresql_db[0].guid : null
}

output "crn" {
  description = "Postgresql instance crn"
  value       = can(ibm_database.postgresql_db[0].resource_crn) ? ibm_database.postgresql_db[0].resource_crn : null
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

output "adminuser" {
  description = "Database admin user name"
  value       = can(ibm_database.postgresql_db[0].adminuser) ? ibm_database.postgresql_db[0].adminuser : null
}

output "hostname" {
  description = "Database connection hostname"
  value       = can(data.ibm_database_connection.database_connection[0].postgres[0].hosts[0].hostname) ? data.ibm_database_connection.database_connection[0].postgres[0].hosts[0].hostname : null
}

output "port" {
  description = "Database connection port"
  value       = can(data.ibm_database_connection.database_connection[0].postgres[0].hosts[0].port) ? data.ibm_database_connection.database_connection[0].postgres[0].hosts[0].port : null
}

output "certificate_base64" {
  description = "Database connection certificate"
  value       = can(data.ibm_database_connection.database_connection[0].postgres[0].certificate[0].certificate_base64) ? data.ibm_database_connection.database_connection[0].postgres[0].certificate[0].certificate_base64 : null
  sensitive   = true
}

output "pitr_time" {
  description = "Postgresql instance id"
  value       = var.pitr_time != "" ? var.pitr_time : data.ibm_database_point_in_time_recovery.source_db_earliest_pitr_time[0].earliest_point_in_time_recovery_time
}
