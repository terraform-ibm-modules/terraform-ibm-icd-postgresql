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
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-postgres"
  region            = var.region
  resource_tags     = var.resource_tags
  configuration     = var.configuration
}

data "ibm_database_backups" "backup_database" {
  deployment_id = module.postgresql_db.id
}

# New postgresql instance pointing to the restored instance
module "restored_postgresql_db" {
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-postgres-restored"
  region            = var.region
  resource_tags     = var.resource_tags
  configuration     = var.configuration
  backup_crn        = data.ibm_database_backups.backup_database.backups[0].backup_id
}
