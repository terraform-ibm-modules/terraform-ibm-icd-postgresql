##############################################################################
# ICD Postgresql modules
#
# Creates ICD Postgresql instance
##############################################################################

locals {
  kp_backup_crn        = var.backup_encryption_key_crn != null ? var.backup_encryption_key_crn : var.key_protect_key_crn
  auto_scaling_enabled = var.auto_scaling == null ? [] : [1]
}

# Create postgresql database
resource "ibm_database" "postgresql_db" {
  resource_group_id = var.resource_group_id
  name              = var.name
  service           = "databases-for-postgresql"
  location          = "us-south"
  plan              = "standard" # Only standard plan is available for postgres
  backup_id         = var.backup_crn
  plan_validation   = var.plan_validation
  remote_leader_id  = var.remote_leader_crn
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

  ## This for_each block is NOT a loop to attach to multiple auto_scaling blocks.
  ## This block is only used to conditionally add auto_scaling block depending on var.auto_scaling
  dynamic "auto_scaling" {
    for_each = local.auto_scaling_enabled
    content {
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

