##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

module "postgresql_db" {
  count             = var.postgresql_db_backup_crn != null ? 0 : 1
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-postgres"
  pg_version        = var.pg_version
  region            = var.region
  resource_tags     = var.resource_tags
  access_tags       = var.access_tags
}

data "ibm_database_backups" "backup_database" {
  count         = var.postgresql_db_backup_crn != null ? 0 : 1
  deployment_id = module.postgresql_db[0].id
}

# New postgresql instance pointing to the backup instance
module "restored_postgresql_db" {
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-postgres-restored"
  pg_version        = var.pg_version
  region            = var.region
  resource_tags     = var.resource_tags
  access_tags       = var.access_tags
  backup_crn        = var.postgresql_db_backup_crn == null ? data.ibm_database_backups.backup_database[0].backups[0].backup_id : var.postgresql_db_backup_crn
}
