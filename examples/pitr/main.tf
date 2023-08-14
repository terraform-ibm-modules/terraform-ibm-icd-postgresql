##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.0.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

data "ibm_database_point_in_time_recovery" "database_pitr" {
  deployment_id = var.pitr_id
}

# New ICD postgresql database instance pointing to a PITR time
module "postgresql_db_pitr" {
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-postgres-pitr"
  region            = var.region
  resource_tags     = var.resource_tags
  access_tags       = var.access_tags
  member_memory_mb  = 3072
  member_disk_mb    = 15360
  member_cpu_count  = 9
  members           = var.members
  pg_version        = var.pg_version
  pitr_id           = var.pitr_id
  pitr_time         = var.pitr_time == "" ? data.ibm_database_point_in_time_recovery.database_pitr.earliest_point_in_time_recovery_time : var.pitr_time
}
