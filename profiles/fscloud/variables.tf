##############################################################################
# Input Variables
##############################################################################

variable "resource_group_id" {
  type        = string
  description = "The resource group ID where the postgresql will be created"
}

variable "name" {
  type        = string
  description = "Name of the Postgresql instance"
}

variable "existing_hpcs_instance_guid" {
  description = "The GUID of the Hyper Protect Crypto service."
  type        = string
  default     = null
}

variable "pg_version" {
  description = "Version of the postgresql instance"
  # Version must be 11 or 12 or 13 or 14. If null, the current default ICD postgresql version is used
  type    = string
  default = null
}

variable "region" {
  description = "The region postgresql is to be created on. The region must support BYOK if key_protect_key_crn is used"
  type        = string
  default     = "us-south"
}

variable "member_memory_mb" {
  type        = string
  description = "Memory allocation required for postgresql database" # member group memory must be >= 1024 and <= 114688
  default     = "1024"
}

variable "member_disk_mb" {
  type        = string
  description = "Disk allocation required for postgresql database" # member group disk must be >= 5120 and <= 4194304
  default     = "5120"
}

variable "member_cpu_count" {
  type        = string
  description = "CPU allocation required for postgresql database" # member group cpu must be >= 3 and <= 28
  default     = "3"
}

# actual scaling of the resources could take some time to apply
# Members can be scaled up but not down
variable "members" {
  type        = number
  description = "Number of members" # member group members must be >= 3 and <= 20
  default     = 3
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "allowlist" {
  type = list(object({
    address     = optional(string)
    description = optional(string)
  }))
  default     = []
  description = "Set of IP address and description to allowlist in database"
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

variable "key_protect_key_crn" {
  type        = string
  description = "(Optional) The root key CRN of a Key Management Service like Key Protect or Hyper Protect Crypto Service (HPCS) that you want to use for disk encryption. If `null`, database is encrypted by using randomly generated keys. See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok for current list of supported regions for BYOK"
  default     = null
}

variable "backup_encryption_key_crn" {
  type        = string
  description = "(Optional) The CRN of a key protect key, that you want to use for encrypting disk that holds deployment backups. If null, will use 'key_protect_key_crn' as encryption key. If 'key_protect_key_crn' is also null database is encrypted by using randomly generated keys."
  default     = null
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
