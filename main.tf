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
  # tflint-ignore: terraform_unused_declarations
  validate_backup_key = var.backup_encryption_key_crn != null && var.use_default_backup_encryption_key == true ? tobool("When passing a value for 'backup_encryption_key_crn' you cannot set 'use_default_backup_encryption_key' to 'true'") : true

  # If no value passed for 'backup_encryption_key_crn' use the value of 'kms_key_crn' and perform validation of 'kms_key_crn' to check if region is supported by backup encryption key.
  # For more info, see https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok and https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups"
  backup_encryption_key_crn = var.use_default_backup_encryption_key == true ? null : (var.backup_encryption_key_crn != null ? var.backup_encryption_key_crn : var.kms_key_crn)

  # Determine if auto scaling is enabled
  auto_scaling_enabled = var.auto_scaling == null ? [] : [1]

  # Determine if host_flavor is used
  host_flavor_set = var.member_host_flavor != null ? true : false

  # Determine if restore, from backup or point in time recovery
  recovery_mode                     = var.backup_crn != null || var.pitr_id != null
  parsed_kms_key_crn                = var.kms_key_crn != null ? split(":", var.kms_key_crn) : []
  parsed_kms_backup_key_crn         = var.backup_encryption_key_crn != null ? split(":", var.backup_encryption_key_crn) : []
  existing_backup_kms_instance_guid = var.backup_encryption_key_crn != null ? local.parsed_kms_backup_key_crn[7] : null
  kms_keys = {
    "key1" = {

      kms_service    = length(local.parsed_kms_key_crn) > 0 ? local.parsed_kms_key_crn[4] : null,
      kms_scope      = length(local.parsed_kms_key_crn) > 0 ? local.parsed_kms_key_crn[6] : null,
      kms_account_id = length(local.parsed_kms_key_crn) > 0 ? split("/", local.parsed_kms_key_crn[6])[1] : null,
      kms_key_id     = length(local.parsed_kms_key_crn) > 0 ? local.parsed_kms_key_crn[9] : null,
      instance       = var.existing_kms_instance_guid,
      resource_type  = length(local.parsed_kms_key_crn) > 0 ? local.parsed_kms_key_crn[8] : null
    },
    "key2" = {
      kms_service    = length(local.parsed_kms_backup_key_crn) > 0 ? local.parsed_kms_backup_key_crn[4] : null,
      kms_scope      = length(local.parsed_kms_backup_key_crn) > 0 ? local.parsed_kms_backup_key_crn[6] : null,
      kms_account_id = length(local.parsed_kms_backup_key_crn) > 0 ? split("/", local.parsed_kms_backup_key_crn[6])[1] : null,
      kms_key_id     = length(local.parsed_kms_backup_key_crn) > 0 ? local.parsed_kms_backup_key_crn[9] : null,
      instance       = var.existing_backup_kms_instance_guid != null ? var.existing_backup_kms_instance_guid : var.existing_kms_instance_guid
      resource_type  = length(local.parsed_kms_backup_key_crn) > 0 ? local.parsed_kms_backup_key_crn[8] : null
    },
  }
  keys = var.kms_encryption_enabled == false || var.skip_iam_authorization_policy ? {} : tomap({
  for i, key in local.kms_keys : i => key })
}

# Create IAM Authorization Policies to allow PostgreSQL to access KMS for the encryption key
resource "ibm_iam_authorization_policy" "kms_policy" {
  for_each                 = local.keys
  source_service_name      = "databases-for-postgresql"
  source_resource_group_id = var.resource_group_id
  roles                    = ["Reader"]
  description              = "Allow all ICD Postgres instances in the resource group ${var.resource_group_id} to read from the ${each.value.kms_service} instance GUID ${each.value.instance}"

  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = each.value.kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = each.value.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = each.value.instance
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = each.value.resource_type
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = each.value.kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  depends_on = [ibm_iam_authorization_policy.kms_policy]

  create_duration = "30s"
}

# Create postgresql database
resource "ibm_database" "postgresql_db" {
  depends_on        = [time_sleep.wait_for_authorization_policy]
  resource_group_id = var.resource_group_id
  name              = var.name
  service           = "databases-for-postgresql"
  location          = var.region
  plan              = "standard" # Only standard plan is available for postgres
  backup_id         = var.backup_crn
  remote_leader_id  = var.remote_leader_crn
  version           = var.pg_version
  tags              = var.resource_tags
  adminpassword     = var.admin_pass
  service_endpoints = var.service_endpoints
  # remove elements with null values: see https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/issues/273
  configuration                        = var.configuration != null ? jsonencode({ for k, v in var.configuration : k => v if v != null }) : null
  key_protect_key                      = var.kms_key_crn
  backup_encryption_key_crn            = local.backup_encryption_key_crn
  point_in_time_recovery_deployment_id = var.pitr_id
  point_in_time_recovery_time          = var.pitr_time

  dynamic "users" {
    for_each = nonsensitive(var.users != null ? var.users : [])
    content {
      name     = users.value.name
      password = users.value.password
      type     = users.value.type
      role     = (users.value.role != "" ? users.value.role : null)
    }
  }

  # Workaround for https://github.ibm.com/GoldenEye/issues/issues/11359
  # means that no `group` block is added when restoring from backup
  # or point in time recovery

  ## This for_each block is NOT a loop to attach to multiple group blocks.
  ## This is used to conditionally add one, OR, the other group block depending on var.local.host_flavor_set
  ## This block is for if host_flavor IS set to specific pre-defined host sizes and not set to "multitenant"
  dynamic "group" {
    for_each = local.host_flavor_set && var.member_host_flavor != "multitenant" && !local.recovery_mode ? [1] : []
    content {
      group_id = "member" # Only member type is allowed for IBM Cloud Databases
      host_flavor {
        id = var.member_host_flavor
      }
      disk {
        allocation_mb = var.member_disk_mb
      }
      dynamic "members" {
        for_each = var.remote_leader_crn == null ? [1] : []
        content {
          allocation_count = var.members
        }
      }
    }
  }

  ## This block is for if host_flavor IS set to "multitenant"
  dynamic "group" {
    for_each = local.host_flavor_set && var.member_host_flavor == "multitenant" && !local.recovery_mode ? [1] : []
    content {
      group_id = "member" # Only member type is allowed for IBM Cloud Databases
      host_flavor {
        id = var.member_host_flavor
      }
      disk {
        allocation_mb = var.member_disk_mb
      }
      memory {
        allocation_mb = var.member_memory_mb
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
  }

  ## This block is for if host_flavor IS NOT set
  dynamic "group" {
    for_each = local.host_flavor_set == false && !local.recovery_mode ? [1] : []
    content {
      group_id = "member" # Only member type is allowed for IBM Cloud Databases
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
    update = "120m"
    delete = "15m"
  }
}

resource "ibm_resource_tag" "postgresql_tag" {
  count       = length(var.access_tags) == 0 ? 0 : 1
  resource_id = ibm_database.postgresql_db.resource_crn
  tags        = var.access_tags
  tag_type    = "access"
}

##############################################################################
# Context Based Restrictions
##############################################################################
module "cbr_rule" {
  count            = length(var.cbr_rules) > 0 ? length(var.cbr_rules) : 0
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-rule-module"
  version          = "1.29.0"
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
    port        = ibm_resource_key.service_credentials[keys(var.service_credential_names)[0]].credentials["connection.postgres.hosts.0.port"]
    credentials = {
      for service_credential in ibm_resource_key.service_credentials :
      service_credential["name"] => {
        username = service_credential.credentials["connection.postgres.authentication.username"]
        password = service_credential.credentials["connection.postgres.authentication.password"]
      }
    }
  } : null
}

data "ibm_database_connection" "database_connection" {
  endpoint_type = var.service_endpoints == "public-and-private" ? "public" : var.service_endpoints
  deployment_id = ibm_database.postgresql_db.id
  user_id       = ibm_database.postgresql_db.adminuser
  user_type     = "database"
}

data "ibm_database_point_in_time_recovery" "source_db_earliest_pitr_time" {
  count         = var.pitr_time != "" ? 0 : 1
  deployment_id = var.pitr_id
}
