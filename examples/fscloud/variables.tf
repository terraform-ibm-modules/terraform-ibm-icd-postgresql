variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Region to provision all resources created by this example."
  default     = "us-south"
}

variable "prefix" {
  type        = string
  description = "Prefix to append to all resources created by this example"
  default     = "fs-cloud"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "pg_version" {
  description = "Version of the postgresql instance"
  type        = string
  default     = null
}

variable "existing_kms_instance_guid" {
  description = "The GUID of the Hyper Protect Crypto service in which the key specified in var.kms_key_crn is coming from"
  type        = string
}

variable "kms_key_crn" {
  type        = string
  description = "The root key CRN of a Hyper Protect Crypto Service (HPCS) that you want to use for disk encryption. If `null`, database is encrypted by using randomly generated keys. See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs&interface=ui for more information on integrating HPCS with PostgreSQL database."
}
