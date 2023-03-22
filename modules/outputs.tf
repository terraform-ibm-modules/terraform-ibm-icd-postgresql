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

