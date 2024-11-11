locals {
  # tflint-ignore: terraform_unused_declarations
  validate_kms_inputs = !var.use_ibm_owned_encryption_key && (var.kms_key_crn == null || var.existing_kms_instance_guid == null) ? tobool("Values for 'kms_key_crn' and 'existing_kms_instance_guid' must be passed if 'use_ibm_owned_encryption_key' it set to false.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_inputs_2 = var.use_ibm_owned_encryption_key && (var.kms_key_crn != null || var.backup_encryption_key_crn != null || var.existing_kms_instance_guid != null) ? tobool("'use_ibm_owned_encryption_key' is set to true, but values have been passed for either 'kms_key_crn', 'backup_encryption_key_crn' and/or 'existing_kms_instance_guid'. To use BYOK or KYOK encryption, ensure to set 'use_ibm_owned_encryption_key' to false, and pass values for 'kms_key_crn', 'backup_encryption_key_crn' (optional) and 'existing_kms_instance_guid'. Alternatively do not pass any values for 'kms_key_crn', 'backup_encryption_key_crn' and 'existing_kms_instance_guid' to use the IBM owned encryption keys.") : true
}

module "postgresql_db" {
  source                        = "../../"
  resource_group_id             = var.resource_group_id
  name                          = var.name
  region                        = var.region
  skip_iam_authorization_policy = var.skip_iam_authorization_policy
  service_endpoints             = "private"
  pg_version                    = var.pg_version
  kms_encryption_enabled        = !var.use_ibm_owned_encryption_key
  existing_kms_instance_guid    = var.existing_kms_instance_guid
  kms_key_crn                   = var.kms_key_crn
  backup_encryption_key_crn     = var.backup_encryption_key_crn
  resource_tags                 = var.resource_tags
  access_tags                   = var.access_tags
  cbr_rules                     = var.cbr_rules
  configuration                 = var.configuration
  member_memory_mb              = var.member_memory_mb
  member_disk_mb                = var.member_disk_mb
  member_cpu_count              = var.member_cpu_count
  member_host_flavor            = var.member_host_flavor
  members                       = var.members
  admin_pass                    = var.admin_pass
  users                         = var.users
  service_credential_names      = var.service_credential_names
  auto_scaling                  = var.auto_scaling
  backup_crn                    = var.backup_crn
}
