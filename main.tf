##############################################################################
# ICD PostgreSQL module
##############################################################################

locals {
  # Validation (approach based on https://github.com/hashicorp/terraform/issues/25609#issuecomment-1057614400)
  # tflint-ignore: terraform_unused_declarations
  validate_kms_values = !var.kms_encryption_enabled && (var.kms_key_crn != null || var.backup_encryption_key_crn != null) ? tobool("When passing values for var.backup_encryption_key_crn or var.kms_key_crn, you must set var.kms_encryption_enabled to true. Otherwise unset them to use default encryption") : true
  # tflint-ignore: terraform_unused_declarations
  validate_pitr_vars = (var.pitr_id != null && var.pitr_time == null) || (var.pitr_time != null && var.pitr_id == null) ? tobool("To use Point-In-Time Recovery (PITR), values for both var.pitr_id and var.pitr_time need to be set. Otherwise, unset both of these.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_vars = var.kms_encryption_enabled && var.kms_key_crn == null && var.backup_encryption_key_crn == null ? tobool("When setting var.kms_encryption_enabled to true, a value must be passed for var.kms_key_crn and/or var.backup_encryption_key_crn") : true
  # tflint-ignore: terraform_unused_declarations
  validate_auth_policy = var.kms_encryption_enabled && var.skip_iam_authorization_policy == false && var.existing_kms_instance_guid == null ? tobool("When var.skip_iam_authorization_policy is set to false, and var.kms_encryption_enabled to true, a value must be passed for var.existing_kms_instance_guid in order to create the auth policy.") : true

  # If no value passed for 'backup_encryption_key_crn' use the value of 'kms_key_crn'. If this is a HPCS key (which is not currently supported for backup encryption), default to 'null' meaning encryption is done using randomly generated keys
  # More info https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs
  backup_encryption_key_crn = var.backup_encryption_key_crn != null ? var.backup_encryption_key_crn : (can(regex(".*kms.*", var.kms_key_crn)) ? var.kms_key_crn : null)

  # Determine if auto scaling is enabled
  auto_scaling_enabled = var.auto_scaling == null ? [] : [1]

  # Determine what KMS service is being used for database encryption
  kms_service = var.kms_key_crn != null ? (
    can(regex(".*kms.*", var.kms_key_crn)) ? "kms" : (
      can(regex(".*hs-crypto.*", var.kms_key_crn)) ? "hs-crypto" : null
    )
  ) : null
}

# Create IAM Authorization Policies to allow PostgreSQL to access KMS for the encryption key
resource "ibm_iam_authorization_policy" "kms_policy" {
  count                       = var.kms_encryption_enabled == false || var.skip_iam_authorization_policy ? 0 : 1
  source_service_name         = "databases-for-postgresql"
  source_resource_group_id    = var.resource_group_id
  target_service_name         = local.kms_service
  target_resource_instance_id = var.existing_kms_instance_guid
  roles                       = ["Reader"]
}

# Create postgresql database
resource "ibm_database" "postgresql_db" {
  depends_on                           = [ibm_iam_authorization_policy.kms_policy]
  resource_group_id                    = var.resource_group_id
  name                                 = var.name
  service                              = "databases-for-postgresql"
  location                             = var.region
  plan                                 = "standard" # Only standard plan is available for postgres
  backup_id                            = var.backup_crn
  plan_validation                      = var.plan_validation
  remote_leader_id                     = var.remote_leader_crn
  version                              = var.pg_version
  tags                                 = var.resource_tags
  service_endpoints                    = var.service_endpoints
  configuration                        = var.configuration != null ? jsonencode(var.configuration) : null
  key_protect_key                      = var.kms_key_crn
  backup_encryption_key_crn            = local.backup_encryption_key_crn
  point_in_time_recovery_deployment_id = var.pitr_id
  point_in_time_recovery_time          = var.pitr_time

  group {
    group_id = "member" # Only member type is allowed for postgresql
    memory {
      allocation_mb = var.member_memory_mb
    }
    disk {
      allocation_mb = var.member_disk_mb
    }
    cpu {
      allocation_count = var.member_cpu_count
    }
    dynamic "members" {
      for_each = var.remote_leader_crn == null ? [1] : []
      content {
        allocation_count = var.members
      }
    }
  }

  ## This for_each block is NOT a loop to attach to multiple auto_scaling blocks.
  ## This block is only used to conditionally add auto_scaling block depending on var.auto_scaling
  dynamic "auto_scaling" {
    for_each = local.auto_scaling_enabled
    content {
      disk {
        capacity_enabled             = var.auto_scaling.disk.capacity_enabled
        free_space_less_than_percent = var.auto_scaling.disk.free_space_less_than_percent
        io_above_percent             = var.auto_scaling.disk.io_above_percent
        io_enabled                   = var.auto_scaling.disk.io_enabled
        io_over_period               = var.auto_scaling.disk.io_over_period
        rate_increase_percent        = var.auto_scaling.disk.rate_increase_percent
        rate_limit_mb_per_member     = var.auto_scaling.disk.rate_limit_mb_per_member
        rate_period_seconds          = var.auto_scaling.disk.rate_period_seconds
        rate_units                   = var.auto_scaling.disk.rate_units
      }
      memory {
        io_above_percent         = var.auto_scaling.memory.io_above_percent
        io_enabled               = var.auto_scaling.memory.io_enabled
        io_over_period           = var.auto_scaling.memory.io_over_period
        rate_increase_percent    = var.auto_scaling.memory.rate_increase_percent
        rate_limit_mb_per_member = var.auto_scaling.memory.rate_limit_mb_per_member
        rate_period_seconds      = var.auto_scaling.memory.rate_period_seconds
        rate_units               = var.auto_scaling.memory.rate_units
      }
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to these because a change will destroy and recreate the instance
      version,
      key_protect_key,
      backup_encryption_key_crn,
    ]
  }

  timeouts {
    create = "120m" # Extending provisioning time to 120 minutes
  }
}

##############################################################################
# Context Based Restrictions
##############################################################################
module "cbr_rule" {
  count            = length(var.cbr_rules) > 0 ? length(var.cbr_rules) : 0
  source           = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cbr//cbr-rule-module?ref=v1.2.0"
  rule_description = var.cbr_rules[count.index].description
  enforcement_mode = var.cbr_rules[count.index].enforcement_mode
  rule_contexts    = var.cbr_rules[count.index].rule_contexts
  resources = [{
    attributes = [
      {
        name     = "accountId"
        value    = var.cbr_rules[count.index].account_id
        operator = "stringEquals"
      },
      {
        name     = "serviceInstance"
        value    = ibm_database.postgresql_db.guid
        operator = "stringEquals"
      },
      {
        name     = "serviceName"
        value    = "databases-for-postgresql"
        operator = "stringEquals"
      }
    ]
  }]
  operations = [{
    api_types = [
      {
        api_type_id = "crn:v1:bluemix:public:context-based-restrictions::::api-type:data-plane"
      }
    ]
  }]
}

##############################################################################
# Service Credentials
##############################################################################

resource "ibm_resource_key" "service_credentials" {
  for_each             = var.service_credential_names
  name                 = each.key
  role                 = each.value
  resource_instance_id = ibm_database.postgresql_db.id
  tags                 = var.resource_tags
}

locals {
  # used for output only
  service_credentials_json = length(var.service_credential_names) > 0 ? {
    for service_credential in ibm_resource_key.service_credentials :
    service_credential["name"] => service_credential["credentials_json"]
  } : null

  service_credentials_object = length(var.service_credential_names) > 0 ? {
    hostname    = ibm_resource_key.service_credentials[keys(var.service_credential_names)[0]].credentials["connection.postgres.hosts.0.hostname"]
    certificate = ibm_resource_key.service_credentials[keys(var.service_credential_names)[0]].credentials["connection.postgres.certificate.certificate_base64"]
    credentials = {
      for service_credential in ibm_resource_key.service_credentials :
      service_credential["name"] => {
        username = service_credential.credentials["connection.postgres.authentication.username"]
        password = service_credential.credentials["connection.postgres.authentication.password"]
      }
    }
  } : null
}
