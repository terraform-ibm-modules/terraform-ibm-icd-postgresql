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

output "crn" {
  description = "Postgresql instance crn"
  value       = module.postgresql_db.crn
}

output "hostname" {
  description = "Postgresql instance hostname"
  value       = module.postgresql_db.hostname
}

output "port" {
  description = "Postgresql instance port"
  value       = module.postgresql_db.port
}
