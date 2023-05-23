##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# ICD postgresql database
##############################################################################

module "postgresql_db" {
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-postgres"
  pg_version        = var.pg_version
  region            = var.region
  resource_tags     = var.resource_tags
  access_tags       = var.access_tags
}

##############################################################################
# ICD postgresql read-only-replica
##############################################################################

module "read_only_replica_postgresql_db" {
  count             = var.read_only_replicas_count
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-read-only-replica-${count.index}"
  region            = var.region
  resource_tags     = var.resource_tags
  access_tags       = var.access_tags
  pg_version        = var.pg_version
  remote_leader_crn = module.postgresql_db.crn
  member_memory_mb  = 2304  # Must be an increment of 384 megabytes. The minimum size of a read-only replica is 2 GB RAM
  member_disk_mb    = 15872 # Must be an increment of 512 megabytes. The minimum size of a read-only replica is 15.36 GB of disk
}
