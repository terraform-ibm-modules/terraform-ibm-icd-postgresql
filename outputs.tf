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

output "service_credentials_json" {
  description = <<EOT
  Map of service credentials json exposed as
  service_credentials_json = map({
    \t service_credential_name_1 = string
    \t service_credential_name_2 = string
  })
  EOT
  value       = local.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = <<EOT
  Object of service credentials exposed as
  service_credentials_object = object({
    \t hostname = string
    \t certificate = string
    \t credentials = map({
      \t\t service_credential_name_1 = {
        \t\t\t username = string
        \t\t\t password = string
      \t\t }
      \t\t service_credential_name_2 = {
        \t\t\t username = string
        \t\t\t password = string
      \t\t }
    \t })
  })
  EOT
  value       = local.service_credentials_object
  sensitive   = true
}
