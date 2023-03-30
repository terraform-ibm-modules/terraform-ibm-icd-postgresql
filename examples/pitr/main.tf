##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}
locals {
  permanent_resources = yamldecode(file("../../common-dev-assets/common-go-assets/common-permanent-resources.yaml"))
}

data "ibm_database_point_in_time_recovery" "database_pitr" {
  deployment_id = local.permanent_resources["postgresqlCrn"]
}

# New ICD postgresql database instance pointing to a PITR time
module "postgresql_db_pitr" {
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-postgres-pitr"
  region            = var.region
  resource_tags     = var.resource_tags
  configuration     = var.configuration
  pitr_time         = data.ibm_database_point_in_time_recovery.database_pitr.earliest_point_in_time_recovery_time
  pitr_id           = local.permanent_resources["postgresqlCrn"]
}
