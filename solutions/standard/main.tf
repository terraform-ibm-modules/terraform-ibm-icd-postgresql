#######################################################################################################################
# Local Variables
#######################################################################################################################

locals {
  existing_kms_instance_guid   = var.existing_kms_instance_crn != null ? module.kms_instance_crn_parser[0].service_instance : null
  existing_kms_instance_region = var.existing_kms_instance_crn != null ? module.kms_instance_crn_parser[0].region : null

  key_name      = var.prefix != null ? "${var.prefix}-${var.key_name}" : var.key_name
  key_ring_name = var.prefix != null ? "${var.prefix}-${var.key_ring_name}" : var.key_ring_name

  kms_key_crn = !var.use_ibm_owned_encryption_key ? var.existing_kms_key_crn != null ? var.existing_kms_key_crn : module.kms[0].keys[format("%s.%s", local.key_ring_name, local.key_name)].crn : null

  create_cross_account_auth_policy = !var.skip_iam_authorization_policy && var.ibmcloud_kms_api_key != null && !var.use_ibm_owned_encryption_key

  kms_service_name = var.existing_kms_instance_crn != null ? module.kms_instance_crn_parser[0].service_name : null
}

#######################################################################################################################
# Resource Group
#######################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.use_existing_resource_group == false ? (var.prefix != null ? "${var.prefix}-${var.resource_group_name}" : var.resource_group_name) : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
}

#######################################################################################################################
# KMS root key for Postgresql
#######################################################################################################################
data "ibm_iam_account_settings" "iam_account_settings" {
  count = local.create_cross_account_auth_policy ? 1 : 0
}

# If existing KMS intance CRN passed, parse details from it
module "kms_instance_crn_parser" {
  count   = var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_instance_crn
}

resource "ibm_iam_authorization_policy" "kms_policy" {
  count                       = local.create_cross_account_auth_policy ? 1 : 0
  provider                    = ibm.kms
  source_service_account      = data.ibm_iam_account_settings.iam_account_settings[0].account_id
  source_service_name         = "databases-for-postgresql"
  source_resource_group_id    = module.resource_group.resource_group_id
  target_service_name         = local.kms_service_name
  target_resource_instance_id = local.existing_kms_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow all Postgresql instances in the resource group ${module.resource_group.resource_group_id} in the account ${data.ibm_iam_account_settings.iam_account_settings[0].account_id} to read from the ${local.kms_service_name} instance GUID ${local.existing_kms_instance_guid}"
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.kms_policy]
  create_duration = "30s"
}

module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = var.existing_kms_key_crn != null || var.use_ibm_owned_encryption_key ? 0 : 1 # no need to create any KMS resources if passing an existing key or using IBM owned keys
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.17.0"
  create_key_protect_instance = false
  region                      = local.existing_kms_instance_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name     = local.key_ring_name
      existing_key_ring = false
      keys = [
        {
          key_name                 = local.key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    }
  ]
}

#######################################################################################################################
# KMS backup encryption key for Postgresql
#######################################################################################################################

locals {
  existing_backup_kms_instance_guid   = var.existing_backup_kms_instance_crn != null ? module.backup_kms_instance_crn_parser[0].service_instance : null
  existing_backup_kms_instance_region = var.existing_backup_kms_instance_crn != null ? module.backup_kms_instance_crn_parser[0].region : null

  backup_key_name         = var.prefix != null ? "${var.prefix}-backup-encryption-${var.key_name}" : "backup-encryption-${var.key_name}"
  backup_key_ring_name    = var.prefix != null ? "${var.prefix}-backup-encryption-${var.key_ring_name}" : "backup-encryption-${var.key_ring_name}"
  backup_kms_key_crn      = var.existing_backup_kms_key_crn != null ? var.existing_backup_kms_key_crn : var.existing_backup_kms_instance_crn != null ? module.backup_kms[0].keys[format("%s.%s", local.backup_key_ring_name, local.backup_key_name)].crn : null
  backup_kms_service_name = var.existing_backup_kms_instance_crn != null ? module.backup_kms_instance_crn_parser[0].service_name : null
}

# If existing KMS intance CRN passed, parse details from it
module "backup_kms_instance_crn_parser" {
  count   = var.existing_backup_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_backup_kms_instance_crn
}

resource "ibm_iam_authorization_policy" "backup_kms_policy" {
  count                       = local.existing_backup_kms_instance_guid == local.existing_kms_instance_guid ? 0 : var.existing_backup_kms_key_crn != null ? 0 : var.existing_backup_kms_instance_crn != null ? !var.skip_iam_authorization_policy ? 1 : 0 : 0
  provider                    = ibm.kms
  source_service_account      = local.create_cross_account_auth_policy ? data.ibm_iam_account_settings.iam_account_settings[0].account_id : null
  source_service_name         = "databases-for-postgresql"
  source_resource_group_id    = module.resource_group.resource_group_id
  target_service_name         = local.backup_kms_service_name
  target_resource_instance_id = local.existing_backup_kms_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow all Postgresql instances in the resource group ${module.resource_group.resource_group_id} to read from the ${local.backup_kms_service_name} instance GUID ${local.existing_backup_kms_instance_guid}"
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_backup_kms_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.backup_kms_policy]
  create_duration = "30s"
}

module "backup_kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = var.use_ibm_owned_encryption_key ? 0 : var.existing_backup_kms_key_crn != null ? 0 : var.existing_backup_kms_instance_crn != null ? 1 : 0
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.17.0"
  create_key_protect_instance = false
  region                      = local.existing_backup_kms_instance_region
  existing_kms_instance_crn   = var.existing_backup_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name         = local.backup_key_ring_name
      existing_key_ring     = false
      force_delete_key_ring = true
      keys = [
        {
          key_name                 = local.backup_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    }
  ]
}

#######################################################################################################################
# Postgresql
#######################################################################################################################

module "postgresql_db" {
  source                        = "../../modules/fscloud"
  depends_on                    = [time_sleep.wait_for_authorization_policy, time_sleep.wait_for_backup_kms_authorization_policy]
  resource_group_id             = module.resource_group.resource_group_id
  name                          = var.prefix != null ? "${var.prefix}-${var.name}" : var.name
  region                        = var.region
  skip_iam_authorization_policy = local.create_cross_account_auth_policy ? true : var.skip_iam_authorization_policy
  pg_version                    = var.pg_version
  existing_kms_instance_guid    = local.existing_kms_instance_guid
  use_ibm_owned_encryption_key  = var.use_ibm_owned_encryption_key
  kms_key_crn                   = local.kms_key_crn
  access_tags                   = var.access_tags
  resource_tags                 = var.resource_tags
  admin_pass                    = var.admin_pass
  users                         = var.users
  members                       = var.members
  member_host_flavor            = var.member_host_flavor
  member_memory_mb              = var.member_memory_mb
  member_disk_mb                = var.member_disk_mb
  member_cpu_count              = var.member_cpu_count
  auto_scaling                  = var.auto_scaling
  configuration                 = var.configuration
  service_credential_names      = var.service_credential_names
  backup_encryption_key_crn     = local.backup_kms_key_crn
  backup_crn                    = var.backup_crn
}
