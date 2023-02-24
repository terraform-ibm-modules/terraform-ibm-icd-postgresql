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
  default     = "pg"
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

variable "configuration" {
  description = "(Optional, Json String) Database Configuration in JSON format."
  type = object({
    max_connections            = optional(number)
    max_prepared_transactions  = optional(number)
    deadlock_timeout           = optional(number)
    effective_io_concurrency   = optional(number)
    max_replication_slots      = optional(number)
    max_wal_senders            = optional(number)
    shared_buffers             = optional(number)
    synchronous_commit         = optional(string)
    wal_level                  = optional(string)
    archive_timeout            = optional(number)
    log_min_duration_statement = optional(number)
  })
  default = null
}

variable "auto_scaling" {
  type = object({
    cpu = object({
      rate_increase_percent       = optional(number)
      rate_limit_count_per_member = optional(number)
      rate_period_seconds         = optional(number)
      rate_units                  = optional(string)
    })
    disk = object({
      capacity_enabled             = optional(bool)
      free_space_less_than_percent = optional(number)
      io_above_percent             = optional(number)
      io_enabled                   = optional(bool)
      io_over_period               = optional(string)
      rate_increase_percent        = optional(number)
      rate_limit_mb_per_member     = optional(number)
      rate_period_seconds          = optional(number)
      rate_units                   = optional(string)
    })
    memory = object({
      io_above_percent         = optional(number)
      io_enabled               = optional(bool)
      io_over_period           = optional(string)
      rate_increase_percent    = optional(number)
      rate_limit_mb_per_member = optional(number)
      rate_period_seconds      = optional(number)
      rate_units               = optional(string)
    })
  })
  description = "(Optional) Configure rules to allow your database to automatically increase its resources. Single block of autoscaling is allowed at once."
  default = {
    cpu    = {}
    disk   = {}
    memory = {}
  }
}
