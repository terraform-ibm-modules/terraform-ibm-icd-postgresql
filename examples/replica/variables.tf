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

# variable "postgres_replica_count" {
#   type        = string
#   description = "value"
#   default     = null
# }

variable "postgresql_db_remote_leader_crn" {
  type        = string
  description = "The CRN of the leader database to make the replica(read-only) deployment."
  default     = null
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
    error_message = "member group memory must be >= 2048 and <= 114688 in increments of 128"
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
    error_message = "member group disk must be >= 7680 and <= 4193280 in increments of 1024"
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
    error_message = "member group cpu must be >= 3 and <= 28 in increments of 1"
  }
}
