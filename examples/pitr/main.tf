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
  name              = "${var.prefix}-pitr-postgres"
  region            = var.region
  resource_tags     = var.resource_tags
  configuration     = var.configuration
}

resource "null_resource" "wait_for_postgresql_db_pitr_creation" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [module.postgresql_db]
}

data "ibm_database_point_in_time_recovery" "database_pitr" {
  deployment_id = module.postgresql_db.id

  depends_on = [null_resource.wait_for_postgresql_db_pitr_creation]
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
  pitr_id           = module.postgresql_db.id
}