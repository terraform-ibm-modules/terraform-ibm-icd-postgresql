provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  ibmcloud_timeout = 60
}

provider "ibm" {
  alias            = "kms"
  ibmcloud_api_key = var.ibmcloud_kms_api_key != null ? var.ibmcloud_kms_api_key : var.ibmcloud_api_key
  region           = local.existing_kms_instance_region
}

provider "ibm" {
  alias            = "backup-kms"
  ibmcloud_api_key = var.ibmcloud_backup_kms_api_key != null ? var.ibmcloud_backup_kms_api_key : var.ibmcloud_api_key
  region           = local.existing_kms_instance_region
}
