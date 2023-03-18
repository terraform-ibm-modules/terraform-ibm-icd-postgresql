variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Region to provision all resources created by this example"
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

variable "member_memory_mb" {
  type        = string
  description = "Memory allocation required for postgresql database"
  default     = "1024"
}

variable "member_disk_mb" {
  type        = string
  description = "Disk allocation required for postgresql database"
  default     = "5120"
}

variable "member_cpu_count" {
  type        = string
  description = "CPU allocation required for postgresql database"
  default     = "3"
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
    cpu = {}
    disk = {
      "capacity_enabled" : true,
      "io_enabled" : true
    }
    memory = {
      "io_enabled" : true,
    }
  }
}
