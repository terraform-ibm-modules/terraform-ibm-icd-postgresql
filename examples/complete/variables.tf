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

variable "service_credential_names" {
  description = "Map of name, role for service credentials that you want to create for the database"
  type        = map(string)
  default = {
    "postgressql_credential_microservices" : "Administrator",
    "postgressql_credential_dev_1" : "Administrator",
    "postgressql_credential_dev_2" : "Administrator"
  }
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
      capacity_enabled : true,
      io_enabled : true
    }
    memory = {
      io_enabled : true,
    }
  }
}

variable "read_only_replicas_count" {
  type        = number
  description = "No of read-only replicas per leader"
  default     = 1
  validation {
    condition = alltrue([
      var.read_only_replicas_count >= 1,
      var.read_only_replicas_count <= 5
    ])
    error_message = "There is a limit of five read-only replicas per leader"
  }

}

variable "replica_member_memory_mb" {
  type        = string
  description = "Memory allocation required for postgresql read-only replica database"
  default     = "3072"
  validation {
    condition = alltrue([
      var.replica_member_memory_mb >= 3072,
      var.replica_member_memory_mb <= 114688
    ])
    error_message = "member group memory must be >= 3072 and <= 114688 in increments of 384"
  }
}

variable "replica_member_disk_mb" {
  type        = string
  description = "Disk allocation required for postgresql read-only replica database"
  default     = "15360"
  validation {
    condition = alltrue([
      var.replica_member_disk_mb >= 15360,
      var.replica_member_disk_mb <= 4194304
    ])
    error_message = "member group disk must be >= 15360 and <= 4194304 in increments of 1536"
  }
}

variable "replica_member_cpu_count" {
  type        = string
  description = "CPU allocation required for the postgresql read-only replica database"
  default     = "9"
  validation {
    condition = alltrue([
      var.replica_member_cpu_count >= 9,
      var.replica_member_cpu_count <= 28
    ])
    error_message = "member group cpu must be >= 9 and <= 28 in increments of 1"
  }
}
