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
  default     = "postgres"
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

variable "service_credentials" {
  description = "A list of service credentials that you want to create for the database"
  type        = list(string)
  default     = ["postgressql_credential_microservices", "postgressql_credential_dev_1", "postgressql_credential_dev_2"]
}

variable "auto_scaling" {
  type = object({
    cpu = object({
      rate_increase_percent       = number
      rate_limit_count_per_member = number
      rate_period_seconds         = number
      rate_units                  = string
    })
    disk = object({
      capacity_enabled             = bool
      free_space_less_than_percent = number
      io_above_percent             = number
      io_enabled                   = bool
      io_over_period               = string
      rate_increase_percent        = number
      rate_limit_mb_per_member     = number
      rate_period_seconds          = number
      rate_units                   = string
    })
    memory = object({
      io_above_percent         = number
      io_enabled               = bool
      io_over_period           = string
      rate_increase_percent    = number
      rate_limit_mb_per_member = number
      rate_period_seconds      = number
      rate_units               = string
    })
  })
  description = "(Optional) Configure rules to allow your database to automatically increase its resources. Single block of autoscaling is allowed at once."
  default     = null
}
