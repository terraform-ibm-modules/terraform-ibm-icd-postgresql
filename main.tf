##############################################################################
# ICD Postgresql modules
#
# Creates ICD Postgresql instance
##############################################################################

locals {
  kp_backup_crn = var.backup_encryption_key_crn != null ? var.backup_encryption_key_crn : var.key_protect_key_crn
}

# Create postgresql database
resource "ibm_database" "postgresql_db" {
  resource_group_id = var.resource_group_id
  name              = var.name
  service           = "databases-for-postgresql"
  location          = var.region
  plan              = "standard" # Only standard plan is available for postgres
  plan_validation   = var.plan_validation
  version           = var.pg_version
  tags              = var.resource_tags
  service_endpoints = var.service_endpoints
  configuration     = var.configuration != null ? jsonencode(var.configuration) : null

  key_protect_key           = var.key_protect_key_crn
  backup_encryption_key_crn = local.kp_backup_crn

  dynamic "allowlist" {
    for_each = (var.allowlist != null ? var.allowlist : [])
    content {
      address     = (allowlist.value.address != "" ? allowlist.value.address : null)
      description = (allowlist.value.description != "" ? allowlist.value.description : null)
    }
  }
  group {
    group_id = "member" #Only member type is allowed for postgresql
    memory {
      allocation_mb = var.member_memory_mb
    }
    disk {
      allocation_mb = var.member_disk_mb
    }
    cpu {
      allocation_count = var.member_cpu_count
    }

    members {
      allocation_count = var.members
    }
  }
  auto_scaling {
    cpu {
      rate_increase_percent       = var.auto_scaling.cpu.rate_increase_percent
      rate_limit_count_per_member = var.auto_scaling.cpu.rate_limit_count_per_member
      rate_period_seconds         = var.auto_scaling.cpu.rate_period_seconds
      rate_units                  = var.auto_scaling.cpu.rate_units
    }
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
  source           = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cbr//cbr-rule-module?ref=v1.1.2"
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
    ],
    tags = var.cbr_rules[count.index].tags
  }]
  operations = [{
    api_types = [
      {
        api_type_id = "crn:v1:bluemix:public:context-based-restrictions::::api-type:data-plane"
      }
    ]
  }]
}
