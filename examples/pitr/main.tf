##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

# New ICD postgresql database instance pointing to a PITR time
module "postgresql_db_pitr" {
  source             = "../.."
  resource_group_id  = module.resource_group.resource_group_id
  name               = "${var.prefix}-postgres-pitr"
  region             = var.region
  resource_tags      = var.resource_tags
  access_tags        = var.access_tags
  member_memory_mb   = 4096
  member_disk_mb     = 5120
  member_cpu_count   = 0
  member_host_flavor = "multitenant"
  members            = var.members
  pg_version         = var.pg_version
  pitr_id            = var.pitr_id
  pitr_time          = var.pitr_time

}
