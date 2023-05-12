##############################################################################
# Input Variables
##############################################################################

variable "resource_group_id" {
  type        = string
  description = "The resource group ID where the PostgreSQL instance will be created."
}

variable "name" {
  type        = string
  description = "The name to give the Postgresql instance."
}

variable "existing_kms_instance_guid" {
  description = "The GUID of the Hyper Protect Crypto Service."
  type        = string
}

variable "pg_version" {
  description = "Version of the PostgreSQL instance to provision."
  type        = string
  default     = null
}

variable "region" {
  description = "The region where you want to deploy your instance. Must be the same region as the Hyper Protect Crypto Service."
  type        = string
  default     = "us-south"
}

variable "member_memory_mb" {
  type        = number
  description = "Allocated memory per-member. See the following doc for supported values: https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling"
  default     = "1024"
}

variable "member_disk_mb" {
  type        = number
  description = "Allocated disk per-member. See the following doc for supported values: https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling"
  default     = "5120"
}

variable "member_cpu_count" {
  type        = number
  description = "Allocated dedicated CPU per-member. For shared CPU, set to 0."
  default     = "3"
}

variable "members" {
  type        = number
  description = "Allocated number of members. Members can be scaled up but not down."
  default     = 3
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the PostgreSQL instance."
  default     = []
}

variable "configuration" {
  description = "Database configuration."
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

variable "kms_key_crn" {
  type        = string
  description = "The root key CRN of the Hyper Protect Crypto Service (HPCS) to use for disk encryption."
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all PostgreSQL database instances in the given resource group to read the encryption key from the Hyper Protect instance passed in var.existing_kms_instance_guid."
  default     = false
}

##############################################################
# Context-based restriction (CBR)
##############################################################

variable "cbr_rules" {
  type = list(object({
    description = string
    account_id  = string
    rule_contexts = list(object({
      attributes = optional(list(object({
        name  = string
        value = string
    }))) }))
    enforcement_mode = string
  }))
  description = "(Optional, list) List of CBR rules to create"
  default     = []
  # Validation happens in the rule module
}
