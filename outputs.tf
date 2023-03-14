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

output "crn" {
  description = "Postgresql instance crn"
  value       = ibm_database.postgresql_db.resource_crn
}

output "version" {
  description = "Postgresql instance version"
  value       = ibm_database.postgresql_db.version
}

output "cbrruleid" {
  description = "CBR created to restrict Postgresql"
  value       = module.cbr_rule[*].rule_id
}
