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

output "cbr_rule_ids" {
  description = "CBR rule ids created to restrict Postgresql"
  value       = module.postgresql_db.cbr_rule_ids
}

output "hostname" {
  description = "Postgresql instance hostname"
  value       = module.postgresql_db.hostname
}

output "port" {
  description = "Postgresql instance port"
  value       = module.postgresql_db.port
}

output "vpc_id" {
  description = "ID of VPC created"
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  description = "list of subnet IDs"
  value = module.vpc.subnet_ids
}

output "resource_group_id" {
  description = "ID of resource_group created"
  value = module.resource_group.resource_group_id
}
