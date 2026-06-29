provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  visibility       = var.provider_visibility
}

# Provider block for KMS (Key Protect or Key Protect Dedicated)
provider "ibm" {
  alias            = "kms"
  ibmcloud_api_key = var.ibmcloud_kms_api_key != null ? var.ibmcloud_kms_api_key : var.ibmcloud_api_key
  region           = var.region
  visibility       = var.provider_visibility
}
