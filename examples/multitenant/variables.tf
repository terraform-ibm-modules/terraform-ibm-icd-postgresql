variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Region to provision all resources created by this example."
}

variable "prefix" {
  type        = string
  description = "Prefix to append to all resources created by this example"
}

variable "pg_version" {
  description = "Version of the postgresql instance. If no value passed, the current ICD preferred version is used."
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

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the PostgreSQL instance created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details"
  default     = []
}

variable "read_only_replicas_count" {
  type        = number
  description = "Number of read-only replicas per leader"
  default     = 1
  validation {
    condition = alltrue([
      var.read_only_replicas_count >= 1,
      var.read_only_replicas_count <= 5
    ])
    error_message = "There is a limit of five read-only replicas per leader"
  }
}
