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

output "hostname" {
  description = "Postgresql instance hostname"
  value       = module.postgresql.hostname
}

output "port" {
  description = "Postgresql instance port"
  value       = module.postgresql.port
}
