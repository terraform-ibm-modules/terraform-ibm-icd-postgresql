locals {
  # Determine if gen2 plan is being used
  is_gen2 = can(regex("-gen2$", var.plan))

  gen2_host_flavor    = "bx3d.4x20"
  classic_host_flavor = "multitenant"

  gen2_service_credential_names = [
    {
      name     = "postgresql_manager"
      role     = "Manager"
      endpoint = var.service_endpoints
    },
    {
      name     = "postgresql_writer"
      role     = "Writer"
      endpoint = var.service_endpoints
    }
  ]
  classic_service_credential_names = [
    {
      name     = "postgresql_admin"
      role     = "Administrator"
      endpoint = var.service_endpoints
    },
    {
      name     = "postgresql_operator"
      role     = "Operator"
      endpoint = var.service_endpoints
    },
    {
      name     = "postgresql_viewer"
      role     = "Viewer"
      endpoint = var.service_endpoints
    },
    {
      name     = "postgresql_editor"
      role     = "Editor"
      endpoint = var.service_endpoints
    }
  ]
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Postgresql
##############################################################################

module "database" {
  source = "../.."
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source            = "terraform-ibm-modules/icd-postgresql/ibm"
  # version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  resource_group_id        = module.resource_group.resource_group_id
  name                     = "${var.prefix}-data-store"
  region                   = var.region
  plan                     = var.plan
  postgresql_version       = var.postgresql_version
  access_tags              = var.access_tags
  tags                     = var.resource_tags
  service_endpoints        = var.service_endpoints
  member_host_flavor       = local.is_gen2 ? local.gen2_host_flavor : local.classic_host_flavor
  disk_mb                  = "10240"
  deletion_protection      = false
  service_credential_names = local.is_gen2 ? local.gen2_service_credential_names : local.classic_service_credential_names
}

# On destroy, we are seeing that even though the replica has been returned as
# destroyed by terraform, the leader instance destroy can fail with: "You
# must delete all replicas before disabling the leader. Try again with valid
# values or contact support if the issue persists."
# The ICD team have recommended to wait for a period of time after the replica
# destroy completes before attempting to destroy the leader instance, so hence
# adding a time sleep here.

resource "time_sleep" "wait_time" {
  count      = local.is_gen2 ? 0 : 1
  depends_on = [module.database]

  destroy_duration = "5m"
}

############################################################################### ICD postgresql read-only-replica
##############################################################################
module "read_only_replica_postgresql_db" {
  count               = local.is_gen2 ? 0 : var.read_only_replicas_count
  source              = "../.."
  resource_group_id   = module.resource_group.resource_group_id
  name                = "${var.prefix}-read-only-replica-${count.index}"
  region              = var.region
  tags                = var.resource_tags
  access_tags         = var.access_tags
  postgresql_version  = var.postgresql_version
  remote_leader_crn   = module.database.crn
  deletion_protection = false
  member_host_flavor  = local.classic_host_flavor
  memory_mb           = 4096  # Must be an increment of 384 megabytes. The minimum size of a read-only replica is 2 GB RAM, new hosting model minimum is 4 GB RAM.
  disk_mb             = 10240 # Must be an increment of 512 megabytes. The minimum size of a read-only replica is 5 GB of disk
  depends_on          = [time_sleep.wait_time[0]]
}
