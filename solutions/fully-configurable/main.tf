#######################################################################################################################
# Resource Group
#######################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.2.0"
  existing_resource_group_name = var.existing_resource_group_name
}

#######################################################################################################################
# KMS encryption key
#######################################################################################################################

locals {
  create_new_kms_key     = var.existing_postgresql_instance_crn == null && !var.use_ibm_owned_encryption_key && var.existing_kms_key_crn == null ? true : false # no need to create any KMS resources if passing an existing key, or using IBM owned keys
  postgres_key_name      = (var.prefix != null && var.prefix != "") ? "${var.prefix}-${var.key_name}" : var.key_name
  postgres_key_ring_name = (var.prefix != null && var.prefix != "") ? "${var.prefix}-${var.key_ring_name}" : var.key_ring_name
}

module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = local.create_new_kms_key ? 1 : 0
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "5.1.7"
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
  create_cross_account_kms_auth_policy        = var.existing_postgresql_instance_crn == null && !var.skip_postgresql_kms_auth_policy && var.ibmcloud_kms_api_key != null && !var.use_ibm_owned_encryption_key
  create_cross_account_backup_kms_auth_policy = var.existing_postgresql_instance_crn == null && !var.skip_postgresql_kms_auth_policy && var.ibmcloud_kms_api_key != null && !var.use_ibm_owned_encryption_key && var.existing_backup_kms_key_crn != null

  # If KMS encryption enabled (and existing ES instance is not being passed), parse details from the existing key if being passed, otherwise get it from the key that the DA creates
  kms_account_id    = var.existing_postgresql_instance_crn != null || var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? module.kms_key_crn_parser[0].account_id : module.kms_instance_crn_parser[0].account_id
  kms_service       = var.existing_postgresql_instance_crn != null || var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? module.kms_key_crn_parser[0].service_name : module.kms_instance_crn_parser[0].service_name
  kms_instance_guid = var.existing_postgresql_instance_crn != null || var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? module.kms_key_crn_parser[0].service_instance : module.kms_instance_crn_parser[0].service_instance
  kms_key_crn       = var.existing_postgresql_instance_crn != null || var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? var.existing_kms_key_crn : module.kms[0].keys[format("%s.%s", local.postgres_key_ring_name, local.postgres_key_name)].crn
  kms_key_id        = var.existing_postgresql_instance_crn != null || var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? module.kms_key_crn_parser[0].resource : module.kms[0].keys[format("%s.%s", local.postgres_key_ring_name, local.postgres_key_name)].key_id
  kms_region        = var.existing_postgresql_instance_crn != null || var.use_ibm_owned_encryption_key ? null : var.existing_kms_key_crn != null ? module.kms_key_crn_parser[0].region : module.kms_instance_crn_parser[0].region

  # If creating KMS cross account policy for backups, parse backup key details from passed in key CRN
  backup_kms_account_id    = local.create_cross_account_backup_kms_auth_policy ? module.kms_backup_key_crn_parser[0].account_id : local.kms_account_id
  backup_kms_service       = local.create_cross_account_backup_kms_auth_policy ? module.kms_backup_key_crn_parser[0].service_name : local.kms_service
  backup_kms_instance_guid = local.create_cross_account_backup_kms_auth_policy ? module.kms_backup_key_crn_parser[0].service_instance : local.kms_instance_guid
  backup_kms_key_id        = local.create_cross_account_backup_kms_auth_policy ? module.kms_backup_key_crn_parser[0].resource : local.kms_key_id

  backup_kms_key_crn = var.existing_postgresql_instance_crn != null || var.use_ibm_owned_encryption_key ? null : var.existing_backup_kms_key_crn
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
  # admin password to use
  admin_pass = var.admin_pass == null ? (startswith(random_password.admin_password[0].result, "-") ? "J${substr(random_password.admin_password[0].result, 1, -1)}" : startswith(random_password.admin_password[0].result, "_") ? "K${substr(random_password.admin_password[0].result, 1, -1)}" : random_password.admin_password[0].result) : var.admin_pass
}

#######################################################################################################################
# Postgresql
#######################################################################################################################

# Look up existing instance details if user passes one
module "postgresql_instance_crn_parser" {
  count   = var.existing_postgresql_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_postgresql_instance_crn
}

# Existing instance local vars
locals {
  existing_postgresql_guid   = var.existing_postgresql_instance_crn != null ? module.postgresql_instance_crn_parser[0].service_instance : null
  existing_postgresql_region = var.existing_postgresql_instance_crn != null ? module.postgresql_instance_crn_parser[0].region : null
}

# Do a data lookup on the resource GUID to get more info that is needed for the 'ibm_database' data lookup below
data "ibm_resource_instance" "existing_instance_resource" {
  count      = var.existing_postgresql_instance_crn != null ? 1 : 0
  identifier = local.existing_postgresql_guid
}

# Lookup details of existing instance
data "ibm_database" "existing_db_instance" {
  count             = var.existing_postgresql_instance_crn != null ? 1 : 0
  name              = data.ibm_resource_instance.existing_instance_resource[0].name
  resource_group_id = data.ibm_resource_instance.existing_instance_resource[0].resource_group_id
  location          = var.region
  service           = "databases-for-postgresql"
}

# Lookup existing instance connection details
data "ibm_database_connection" "existing_connection" {
  count         = var.existing_postgresql_instance_crn != null ? 1 : 0
  endpoint_type = "private"
  deployment_id = data.ibm_database.existing_db_instance[0].id
  user_id       = data.ibm_database.existing_db_instance[0].adminuser
  user_type     = "database"
}

# Create new instance
module "postgresql_db" {
  count                             = var.existing_postgresql_instance_crn != null ? 0 : 1
  source                            = "../../"
  depends_on                        = [time_sleep.wait_for_authorization_policy, time_sleep.wait_for_backup_kms_authorization_policy]
  resource_group_id                 = module.resource_group.resource_group_id
  name                              = (var.prefix != null && var.prefix != "") ? "${var.prefix}-${var.postgresql_name}" : var.postgresql_name
  region                            = var.region
  remote_leader_crn                 = var.remote_leader_crn
  skip_iam_authorization_policy     = var.skip_postgresql_kms_auth_policy
  pg_version                        = var.postgresql_version
  use_ibm_owned_encryption_key      = var.use_ibm_owned_encryption_key
  kms_key_crn                       = local.kms_key_crn
  backup_encryption_key_crn         = local.backup_kms_key_crn
  use_same_kms_key_for_backups      = local.use_same_kms_key_for_backups
  use_default_backup_encryption_key = var.use_default_backup_encryption_key
  access_tags                       = var.postgresql_access_tags
  tags                              = var.postgresql_resource_tags
  # workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/6141
  admin_pass               = var.remote_leader_crn == null ? local.admin_pass : null
  users                    = var.users
  members                  = var.members
  member_host_flavor       = var.member_host_flavor
  member_memory_mb         = var.member_memory_mb
  member_disk_mb           = var.member_disk_mb
  member_cpu_count         = var.member_cpu_count
  auto_scaling             = var.auto_scaling
  configuration            = var.configuration
  service_credential_names = var.service_credential_names
  backup_crn               = var.backup_crn
  service_endpoints        = var.service_endpoints
}

locals {
  postgresql_guid     = var.existing_postgresql_instance_crn != null ? data.ibm_database.existing_db_instance[0].guid : module.postgresql_db[0].guid
  postgresql_id       = var.existing_postgresql_instance_crn != null ? data.ibm_database.existing_db_instance[0].id : module.postgresql_db[0].id
  postgresql_version  = var.existing_postgresql_instance_crn != null ? data.ibm_database.existing_db_instance[0].version : module.postgresql_db[0].version
  postgresql_crn      = var.existing_postgresql_instance_crn != null ? var.existing_postgresql_instance_crn : module.postgresql_db[0].crn
  postgresql_hostname = var.existing_postgresql_instance_crn != null ? data.ibm_database_connection.existing_connection[0].postgres[0].hosts[0].hostname : module.postgresql_db[0].hostname
  postgresql_port     = var.existing_postgresql_instance_crn != null ? data.ibm_database_connection.existing_connection[0].postgres[0].hosts[0].port : module.postgresql_db[0].port
}
