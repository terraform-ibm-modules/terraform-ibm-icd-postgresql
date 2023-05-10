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
  default     = "pg-res"
}

variable "pg_version" {
  description = "Version of the postgresql instance"
  type        = string
  default     = null
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

variable "postgresql_db_backup_crn" {
  type        = string
  description = "The existing CRN of a backup resource to restore from. If null then it will create a new instance first and then create another instance pointing to the backup of the first instance."
  default     = null
}
