
locals {
  # tflint-ignore: terraform_unused_declarations
  validate_restrictions_set = (length(var.allowlist) == 0 && length(var.cbr_rules) == 0) ? tobool("Allow list and/or CBR Rules must be set") : true
}

module "postgresql_db" {
  source                    = "../../"
  resource_group_id         = var.resource_group_id
  name                      = var.name
  region                    = var.region
  service_endpoints         = "private"
  pg_version                = var.pg_version
  key_protect_key_crn       = var.key_protect_key_crn
  backup_encryption_key_crn = var.backup_encryption_key_crn
  resource_tags             = var.resource_tags
  allowlist                 = var.allowlist
  cbr_rules                 = var.cbr_rules
  configuration             = var.configuration
  member_memory_mb          = var.member_memory_mb
  member_disk_mb            = var.member_disk_mb
  member_cpu_count          = var.member_cpu_count
  members                   = var.members
}

# Create IAM Authorization Policies to allow COS to access kms for the encryption key
resource "ibm_iam_authorization_policy" "primary_kms_policy" {
  source_service_name         = "databases-for-postgresql"
  source_resource_instance_id = module.postgresql_db.guid
  target_service_name         = "hs-crypto"
  target_resource_instance_id = var.existing_hpcs_instance_guid
  roles                       = ["Reader"]
}
