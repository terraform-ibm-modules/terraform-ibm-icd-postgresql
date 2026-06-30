provider "ibm" {
  ibmcloud_api_key      = var.ibmcloud_api_key
  region                = var.region
  visibility            = var.provider_visibility
  private_endpoint_type = (var.provider_visibility == "private" && var.region == "ca-mon") ? "vpe" : null
}

# Provider block for KMS (Key Protect or Key Protect Dedicated)
provider "ibm" {
  alias                 = "kms"
  ibmcloud_api_key      = var.ibmcloud_kms_api_key != null ? var.ibmcloud_kms_api_key : var.ibmcloud_api_key
  region                = var.region
  visibility            = var.provider_visibility
  private_endpoint_type = (var.provider_visibility == "private" && var.region == "ca-mon") ? "vpe" : null
}
