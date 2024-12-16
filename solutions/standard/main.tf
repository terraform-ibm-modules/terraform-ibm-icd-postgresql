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
# KMS related variable validation
# (approach based on https://github.com/hashicorp/terraform/issues/25609#issuecomment-1057614400)
#
# TODO: Replace with terraform cross variable validation: https://github.ibm.com/GoldenEye/issues/issues/10836
#######################################################################################################################

locals {
  # tflint-ignore: terraform_unused_declarations
  validate_kms_1 = var.use_ibm_owned_encryption_key && (var.existing_kms_instance_crn != null || var.existing_kms_key_crn != null || var.existing_backup_kms_key_crn != null) ? tobool("When setting values for 'existing_kms_instance_crn', 'existing_kms_key_crn' or 'existing_backup_kms_key_crn', the 'use_ibm_owned_encryption_key' input must be set to false.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_2 = !var.use_ibm_owned_encryption_key && (var.existing_kms_instance_crn == null && var.existing_kms_key_crn == null) ? tobool("When 'use_ibm_owned_encryption_key' is false, a value is required for either 'existing_kms_instance_crn' (to create a new key), or 'existing_kms_key_crn' to use an existing key.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_3 = local.create_new_kms_key && var.existing_kms_instance_crn == null ? tobool("If a value is not provided for 'existing_kms_key_crn', and 'use_ibm_owned_encryption_key' is not set to true, you must provide a value for 'existing_kms_instance_crn'.") : true
}

#######################################################################################################################
# KMS encryption key
#######################################################################################################################

locals {
  create_new_kms_key     = !var.use_ibm_owned_encryption_key && var.existing_kms_key_crn == null ? 1 : 0 # no need to create any KMS resources if passing an existing key, or using IBM owned keys
  postgres_key_name      = var.prefix != null ? "${var.prefix}-${var.key_name}" : var.key_name
  postgres_key_ring_name = var.prefix != null ? "${var.prefix}-${var.key_ring_name}" : var.key_ring_name
}

module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = local.create_new_kms_key
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.18.1"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name     = local.postgres_key_ring_name
      existing_key_ring = false
      keys = [
        {
          key_name                 = local.postgres_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    }
  ]
}

########################################################################################################################
# Parse KMS info from given CRNs
########################################################################################################################

module "kms_instance_crn_parser" {
  count   = var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_instance_crn
}

module "kms_key_crn_parser" {
  count   = var.existing_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_key_crn
}

module "kms_backup_key_crn_parser" {
  count   = var.existing_backup_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_backup_kms_key_crn
}

#######################################################################################################################
# KMS IAM Authorization Policies
#   - only created if user passes a value for 'ibmcloud_kms_api_key' (used when KMS is in different account to PostgreSQL)
#   - if no value passed for 'ibmcloud_kms_api_key', the auth policy is created by the PostgreSQL module
#######################################################################################################################

# Lookup account ID
data "ibm_iam_account_settings" "iam_account_settings" {
}

locals {
  account_id                                  = data.ibm_iam_account_settings.iam_account_settings.account_id
  create_cross_account_kms_auth_policy        = !var.skip_pg_kms_auth_policy && var.ibmcloud_kms_api_key != null && !var.use_ibm_owned_encryption_key
  create_cross_account_backup_kms_auth_policy = !var.skip_pg_kms_auth_policy && var.ibmcloud_kms_api_key != null && !var.use_ibm_owned_encryption_key && var.existing_backup_kms_key_crn != null

  # If KMS encryption enabled (and existing ES instance is not being passed), parse details from the existing key if being passed, otherwise get it from the key that the DA creates
  kms_account_id    = var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? module.kms_key_crn_parser[0].account_id : module.kms_instance_crn_parser[0].account_id
  kms_service       = var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? module.kms_key_crn_parser[0].service_name : module.kms_instance_crn_parser[0].service_name
  kms_instance_guid = var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? module.kms_key_crn_parser[0].service_instance : module.kms_instance_crn_parser[0].service_instance
  kms_key_crn       = var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? var.existing_kms_key_crn : module.kms[0].keys[format("%s.%s", local.postgres_key_ring_name, local.postgres_key_name)].crn
  kms_key_id        = var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? module.kms_key_crn_parser[0].resource : module.kms[0].keys[format("%s.%s", local.postgres_key_ring_name, local.postgres_key_name)].key_id
  kms_region        = var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? module.kms_key_crn_parser[0].region : module.kms_instance_crn_parser[0].region

  # If creating KMS cross account policy for backups, parse backup key details from passed in key CRN
  backup_kms_account_id    = local.create_cross_account_backup_kms_auth_policy ? module.kms_backup_key_crn_parser[0].account_id : local.kms_account_id
  backup_kms_service       = local.create_cross_account_backup_kms_auth_policy ? module.kms_backup_key_crn_parser[0].service_name : local.kms_service
  backup_kms_instance_guid = local.create_cross_account_backup_kms_auth_policy ? module.kms_backup_key_crn_parser[0].service_instance : local.kms_instance_guid
  backup_kms_key_id        = local.create_cross_account_backup_kms_auth_policy ? module.kms_backup_key_crn_parser[0].resource : local.kms_key_id

  backup_kms_key_crn = var.use_ibm_owned_encryption_key ? null : var.existing_backup_kms_key_crn
  # Always use same key for backups unless user explicially passed a value for 'existing_backup_kms_key_crn'
  use_same_kms_key_for_backups = var.existing_backup_kms_key_crn == null ? true : false
}

# Create auth policy (scoped to exact KMS key)
resource "ibm_iam_authorization_policy" "kms_policy" {
  count                    = local.create_cross_account_kms_auth_policy ? 1 : 0
  provider                 = ibm.kms
  source_service_account   = local.account_id
  source_service_name      = "databases-for-postgresql"
  source_resource_group_id = module.resource_group.resource_group_id
  roles                    = ["Reader"]
  description              = "Allow all PostgreSQL instances in the resource group ${module.resource_group.resource_group_id} in the account ${local.account_id} to read the ${local.kms_service} key ${local.kms_key_id} from the instance GUID ${local.kms_instance_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.kms_instance_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  count           = local.create_cross_account_kms_auth_policy ? 1 : 0
  depends_on      = [ibm_iam_authorization_policy.kms_policy]
  create_duration = "30s"
}

# Create auth policy (scoped to exact KMS key for backups)
resource "ibm_iam_authorization_policy" "backup_kms_policy" {
  count                    = local.create_cross_account_backup_kms_auth_policy ? 1 : 0
  provider                 = ibm.kms
  source_service_account   = local.account_id
  source_service_name      = "databases-for-postgresql"
  source_resource_group_id = module.resource_group.resource_group_id
  roles                    = ["Reader"]
  description              = "Allow all PostgreSQL instances in the resource group ${module.resource_group.resource_group_id} in the account ${local.account_id} to read the ${local.backup_kms_service} key ${local.backup_kms_key_id} from the instance GUID ${local.backup_kms_instance_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.backup_kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.backup_kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.backup_kms_instance_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.backup_kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_backup_kms_authorization_policy" {
  count           = local.create_cross_account_backup_kms_auth_policy ? 1 : 0
  depends_on      = [ibm_iam_authorization_policy.backup_kms_policy]
  create_duration = "30s"
}

#######################################################################################################################
# PostgreSQL admin password
#######################################################################################################################

resource "random_password" "admin_password" {
  count            = var.admin_pass == null ? 1 : 0
  length           = 32
  special          = true
  override_special = "-_"
  min_numeric      = 1
}

locals {
  # _- are invalid first characters
  # if - replace first char with J
  # elseif _ replace first char with K
  # else use asis
  generated_admin_password = startswith(random_password.admin_password[0].result, "-") ? "J${substr(random_password.admin_password[0].result, 1, -1)}" : startswith(random_password.admin_password[0].result, "_") ? "K${substr(random_password.admin_password[0].result, 1, -1)}" : random_password.admin_password[0].result

  # admin password to use
  admin_pass = var.admin_pass == null ? local.generated_admin_password : var.admin_pass
}

#######################################################################################################################
# Postgresql
#######################################################################################################################

# Create new instance
module "postgresql_db" {
  source                            = "../../modules/fscloud"
  depends_on                        = [time_sleep.wait_for_authorization_policy, time_sleep.wait_for_backup_kms_authorization_policy]
  resource_group_id                 = module.resource_group.resource_group_id
  name                              = var.prefix != null ? "${var.prefix}-${var.name}" : var.name
  region                            = var.region
  skip_iam_authorization_policy     = var.skip_pg_kms_auth_policy
  pg_version                        = var.pg_version
  use_ibm_owned_encryption_key      = var.use_ibm_owned_encryption_key
  kms_key_crn                       = local.kms_key_crn
  backup_encryption_key_crn         = local.backup_kms_key_crn
  use_same_kms_key_for_backups      = local.use_same_kms_key_for_backups
  use_default_backup_encryption_key = var.use_default_backup_encryption_key
  access_tags                       = var.access_tags
  resource_tags                     = var.resource_tags
  admin_pass                        = local.admin_pass
  users                             = var.users
  members                           = var.members
  member_host_flavor                = var.member_host_flavor
  member_memory_mb                  = var.member_memory_mb
  member_disk_mb                    = var.member_disk_mb
  member_cpu_count                  = var.member_cpu_count
  auto_scaling                      = var.auto_scaling
  configuration                     = var.configuration
  service_credential_names          = var.service_credential_names
  backup_crn                        = var.backup_crn
}
