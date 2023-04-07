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

variable "existing_kms_instance_guid" {
  description = "The GUID of the Hyper Protect Crypto service."
  type        = string
}

variable "pg_version" {
  description = "Version of the postgresql instance"
  # Version must be 11 or 12 or 13 or 14. If null, the current default ICD postgresql version is used
  type    = string
  default = null
}

variable "region" {
  description = "The region postgresql is to be created on. The region must support KYOK."
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
  description = "Optional list of tags to be applied to the PostgreSQL database instance."
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

variable "kms_key_crn" {
  type        = string
  description = "The root key CRN of a Hyper Protect Crypto Service (HPCS) that you want to use for disk encryption. See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs&interface=ui for more information on integrating HPCS with PostgreSQL database."
}

variable "backup_encryption_key_crn" {
  type        = string
  description = "The CRN of a Key Protect Key to use for encrypting backups. Take note that Hyper Protect Crypto Services for IBM Cloud® Databases backups is not currently supported."
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all PostgreSQL database instances in the provided resource group reader access to the instance specified in the existing_kms_instance_guid variable."
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
