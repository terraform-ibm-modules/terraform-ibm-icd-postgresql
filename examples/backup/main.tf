##############################################################################
# Resource Group
##############################################################################

locals {
  is_gen2             = can(regex("-gen2$", var.plan))
  gen2_host_flavor    = "bx3d.4x20"
  classic_host_flavor = "multitenant"
}

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

module "postgresql_db" {
  count               = var.postgresql_db_backup_crn != null || var.existing_database_crn != null ? 0 : 1
  source              = "../.."
  resource_group_id   = module.resource_group.resource_group_id
  name                = "${var.prefix}-postgres"
  postgresql_version  = var.postgresql_version
  region              = var.region
  resource_tags       = var.resource_tags
  access_tags         = var.access_tags
  deletion_protection = false
  member_host_flavor  = "multitenant"
}

data "ibm_database_backups" "backup_database" {
  count         = var.postgresql_db_backup_crn == null ? 1 : 0
  deployment_id = var.existing_database_crn == null ? module.postgresql_db[0].id : var.existing_database_crn
}

# New postgresql instance pointing to the backup instance
module "restored_icd_postgresql" {
  source = "../.."
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source            = "terraform-ibm-modules/icd-postgresql/ibm"
  # version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  resource_group_id   = module.resource_group.resource_group_id
  name                = "${var.prefix}-postgres-restored"
  plan                = var.plan
  postgresql_version  = var.postgresql_version
  region              = var.region
  resource_tags       = var.resource_tags
  access_tags         = var.access_tags
  deletion_protection = false
  member_host_flavor  = local.is_gen2 ? local.gen2_host_flavor : local.classic_host_flavor
  disk_mb             = var.disk_mb
  backup_crn          = var.postgresql_db_backup_crn == null ? data.ibm_database_backups.backup_database[0].backups[0].backup_id : var.postgresql_db_backup_crn
  async_restore       = true
}
