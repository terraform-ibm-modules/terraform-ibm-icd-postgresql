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
    service_credential_name_1 = string
    service_credential_name_2 = string
  })
  EOT
  value       = local.service_credentials_json
  sensitive   = true
}

output "service_credentials_object" {
  description = <<EOT
  Object of service credentials exposed as
  service_credentials_object = object({
    hostname = string
    certificate = string
    credentials = map({
      service_credential_name_1 = {
        username = string
        password = string
      }
      service_credential_name_2 = {
        username = string
        password = string
      }
    })
  })
  EOT
  value       = local.service_credentials_object
  sensitive   = true
}
