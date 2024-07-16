##############################################################################
# Outputs
##############################################################################

output "id" {
  description = "Postgresql instance id"
  value       = module.postgresql.id
}

output "guid" {
  description = "Postgresql instance guid"
  value       = module.postgresql.guid
}

output "version" {
  description = "Postgresql instance version"
  value       = module.postgresql.version
}

output "crn" {
  description = "Postgresql instance crn"
  value       = module.postgresql.crn
}

output "cbr_rule_ids" {
  description = "CBR rule ids created to restrict Postgresql"
  value       = module.postgresql.cbr_rule_ids
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = module.postgresql.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = module.postgresql.service_credentials_object
  sensitive   = true
}

output "hostname" {
  description = "Postgresql instance hostname"
  value       = module.postgresql.hostname
}

output "port" {
  description = "Postgresql instance port"
  value       = module.postgresql.port
}
