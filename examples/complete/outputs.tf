##############################################################################
# Outputs
##############################################################################
output "id" {
  description = "Postgresql instance id"
  value       = module.icd_postgresql.id
}

output "guid" {
  description = "Postgresql instance guid"
  value       = module.icd_postgresql.guid
}

output "version" {
  description = "Postgresql instance version"
  value       = module.icd_postgresql.version
}

output "service_credentials_json" {
  description = "Service credentials json map"
  value       = module.icd_postgresql.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = "Service credentials object"
  value       = module.icd_postgresql.service_credentials_object
  sensitive   = true
}

output "cbr_rule_ids" {
  description = "CBR rule ids created to restrict Postgresql"
  value       = module.icd_postgresql.cbr_rule_ids
}

output "hostname" {
  description = "Postgresql instance hostname"
  value       = module.icd_postgresql.hostname
}

output "port" {
  description = "Postgresql instance port"
  value       = module.icd_postgresql.port
}
