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
  default     = "pg-pitr"
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
  description = "Optional list of access management tags to be added to created resources"
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

variable "pitr_id" {
  type        = string
  description = "The ID of the postgresql instance that you want to recover back to. Here ID of the postgresql instance is expected to be up and in running state."
}

variable "member_memory_mb" {
  type        = string
  description = "Memory allocation required for postgresql read-only replica database"
  default     = "3072"
  validation {
    condition = alltrue([
      var.member_memory_mb >= 3072,
      var.member_memory_mb <= 114688
    ])
    error_message = "member group memory must be >= 3072 and <= 114688 in increments of 384"
  }
}

variable "member_disk_mb" {
  type        = string
  description = "Disk allocation required for postgresql read-only replica database"
  default     = "15360"
  validation {
    condition = alltrue([
      var.member_disk_mb >= 15360,
      var.member_disk_mb <= 4194304
    ])
    error_message = "member group disk must be >= 15360 and <= 4194304 in increments of 1536"
  }
}

variable "member_cpu_count" {
  type        = string
  description = "CPU allocation required for the postgresql read-only replica database"
  default     = "9"
  validation {
    condition = alltrue([
      var.member_cpu_count >= 9,
      var.member_cpu_count <= 28
    ])
    error_message = "member group cpu must be >= 9 and <= 28 in increments of 1"
  }
}
