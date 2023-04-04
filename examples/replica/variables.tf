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

variable "read_only_replicas" {
  type        = string
  description = "No of read-only replicas per leader"
  default     = "1"
  validation {
    condition = alltrue([
      var.read_only_replicas >= 1,
      var.read_only_replicas <= 5
    ])
    error_message = "There is a limit of five read-only replicas per leader"
  }

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
