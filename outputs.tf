##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Postgresql instance id"
  value       = ibm_database.postgresql_db.id
}

output "version" {
  description = "Postgresql instance version"
  value       = ibm_database.postgresql_db.version
}

output "guid" {
  description = "Postgresql instance guid"
  value       = ibm_database.postgresql_db.guid
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

output "adminuser" {
  description = "Database admin user name"
  value       = ibm_database.postgresql_db.adminuser
}

output "hostname" {
  description = "Database connection hostname"
  value       = data.ibm_database_connection.database_connection.postgres[0].hosts[0].hostname
}

output "port" {
  description = "Database connection port"
  value       = data.ibm_database_connection.database_connection.postgres[0].hosts[0].port
}

output "certificate_base64" {
  description = "Database connection certificate"
  value       = data.ibm_database_connection.database_connection.postgres[0].certificate[0].certificate_base64
  sensitive   = true
}

output "pitr_time" {
  description = "Postgresql instance id"
  value       = var.pitr_time != "" ? var.pitr_time : data.ibm_database_point_in_time_recovery.source_db_earliest_pitr_time[0].earliest_point_in_time_recovery_time
}
