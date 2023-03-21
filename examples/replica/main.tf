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
  count             = var.postgresql_db_remote_leader_crn != null ? 0 : 1
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-postgres"
  region            = var.region
  resource_tags     = var.resource_tags
}

##############################################################################
# ICD postgresql read-only-replica
##############################################################################

module "replicate_postgresql_db" {
  source = "../.."
  # count             = var.postgres_replica_count == null ? 1 : var.postgres_replica_count
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-read-only-replica"
  region            = var.region
  resource_tags     = var.resource_tags
  remote_leader_crn = var.postgresql_db_remote_leader_crn == null ? module.postgresql_db[0].id : var.postgresql_db_remote_leader_crn
  member_memory_mb  = var.member_memory_mb
  member_disk_mb    = var.member_disk_mb
  member_cpu_count  = var.member_cpu_count
}
