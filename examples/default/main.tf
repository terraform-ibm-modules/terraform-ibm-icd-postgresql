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
  region            = var.region
  resource_tags     = var.resource_tags
  configuration     = var.configuration
  auto_scaling = {
    cpu = {
      rate_limit_count_per_member = 30
    }
    disk = {

    }
    memory = {

    }
  }
}
