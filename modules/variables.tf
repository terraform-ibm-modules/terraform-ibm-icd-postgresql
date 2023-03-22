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

variable "plan_validation" {
  type        = bool
  description = "Enable or disable validating the database parameters for postgres during the plan phase"
  default     = true
}

variable "remote_leader_crn" {
  type        = string
  description = "The CRN of the leader database to make the replica(read-only) deployment."
  default     = null
}

variable "region" {
  description = "The region postgresql is to be created on. The region must support BYOK if key_protect_key_crn is used"
  type        = string
  default     = "us-south"
}

variable "member_memory_mb" {
  type        = string
  description = "Memory allocation required for postgresql database"
  default     = "1024"
  validation {
    condition = alltrue([
      var.member_memory_mb >= 1024,
      var.member_memory_mb <= 114688
    ])
    error_message = "member group memory must be >= 1024 and <= 114688 in increments of 128"
  }
}

variable "backup_crn" {
  type        = string
  description = "The CRN of a backup resource to restore from. The backup is created by a database deployment with the same service ID. The backup is loaded after provisioning and the new deployment starts up that uses that data. A backup CRN is in the format crn:v1:<…>:backup:. If omitted, the database is provisioned empty."
  default     = null
  validation {
    condition = anytrue([
      var.backup_crn == null,
      can(regex("^crn:.*:backup:", var.backup_crn))
    ])
    error_message = "backup_crn must be null OR starts with 'crn:' and contains ':backup:'"
  }
}

variable "member_disk_mb" {
  type        = string
  description = "Disk allocation required for postgresql database"
  default     = "5120"
  validation {
    condition = alltrue([
      var.member_disk_mb >= 5120,
      var.member_disk_mb <= 4194304
    ])
    error_message = "member group disk must be >= 5120 and <= 4194304 in increments of 1024"
  }
}

variable "member_cpu_count" {
  type        = string
  description = "CPU allocation required for postgresql database"
  default     = "3"
  validation {
    condition = alltrue([
      var.member_cpu_count >= 3,
      var.member_cpu_count <= 28
    ])
    error_message = "member group cpu must be >= 3 and <= 28 in increments of 1"
  }
}

# actual scaling of the resources could take some time to apply
# Members can be scaled up but not down
variable "members" {
  type        = number
  description = "Number of members"
  default     = 3
  validation {
    condition = alltrue([
      var.members >= 3,
      var.members <= 20
    ])
    error_message = "member group members must be >= 3 and <= 20 in increments of 1"
  }
}

variable "service_endpoints" {
  type        = string
  description = "Sets the endpoint of the Postgresql instance, valid values are 'public', 'private', or 'public-and-private'"
  default     = "private"
  validation {
    condition     = contains(["public", "private", "public-and-private"], var.service_endpoints)
    error_message = "Valid values for service_endpoints are 'public', 'public-and-private', and 'private'"
  }
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

variable "auto_scaling" {
  type = object({
    cpu = object({
      rate_increase_percent       = optional(number, 10)
      rate_limit_count_per_member = optional(number, 20)
      rate_period_seconds         = optional(number, 900)
      rate_units                  = optional(string, "count")
    })
    disk = object({
      capacity_enabled             = optional(bool, false)
      free_space_less_than_percent = optional(number, 10)
      io_above_percent             = optional(number, 90)
      io_enabled                   = optional(bool, false)
      io_over_period               = optional(string, "15m")
      rate_increase_percent        = optional(number, 10)
      rate_limit_mb_per_member     = optional(number, 3670016)
      rate_period_seconds          = optional(number, 900)
      rate_units                   = optional(string, "mb")
    })
    memory = object({
      io_above_percent         = optional(number, 90)
      io_enabled               = optional(bool, false)
      io_over_period           = optional(string, "15m")
      rate_increase_percent    = optional(number, 10)
      rate_limit_mb_per_member = optional(number, 114688)
      rate_period_seconds      = optional(number, 900)
      rate_units               = optional(string, "mb")
    })
  })
  description = "(Optional) Configure rules to allow your database to automatically increase its resources. Single block of autoscaling is allowed at once."
  default     = null
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
