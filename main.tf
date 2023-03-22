provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = "us-south"
}

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # Pin to the lowest provider version of the range defined in the main module's version.tf to ensure lowest version still works
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.49.0"
    }
  }
}

output "id" {
  description = "Postgresql read-only replica instance id"
  value       = module.replicate_postgresql_db.id
}

output "version" {
  description = "Postgresql read-only replica instance version"
  value       = module.replicate_postgresql_db.version
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key"
  sensitive   = true
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  resource_group_name          = var.resource_group == null ? "create-ror-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# ICD postgresql database
##############################################################################

module "postgresql_db" {
  source            = "./modules"
  resource_group_id = module.resource_group.resource_group_id
  name              = "create-ror-postgres"
  region            = "us-south"
}

##############################################################################
# ICD postgresql read-only-replica
##############################################################################

module "replicate_postgresql_db" {
  source = "./modules"
  resource_group_id = module.resource_group.resource_group_id
  name              = "create-ror-read-only-replica"
  region            = "us-south"
  remote_leader_crn = module.postgresql_db.id
  member_memory_mb  = "3072"
  member_disk_mb    = "15360"
  member_cpu_count  = "9"
}
