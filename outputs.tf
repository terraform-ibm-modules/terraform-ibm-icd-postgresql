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
