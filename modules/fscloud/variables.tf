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

variable "pg_version" {
  type        = string
  description = "Version of the PostgreSQL instance. If no value is passed, the current preferred version of IBM Cloud Databases is used."
  default     = null
}

variable "region" {
  type        = string
  description = "The region where you want to deploy your instance. Must be the same region as the Hyper Protect Crypto Services instance."
  default     = "us-south"
}

##############################################################################
# ICD hosting model properties
##############################################################################

variable "members" {
  type        = number
  description = "Allocated number of members. Members can be scaled up but not down."
  default     = 2
}

variable "member_cpu_count" {
  type        = number
  description = "Allocated dedicated CPU per member. For shared CPU, set to 0. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)"
  default     = 3
}

variable "member_disk_mb" {
  type        = number
  description = "Allocated disk per member. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)"
  default     = 5120
}

variable "member_host_flavor" {
  type        = string
  description = "Allocated host flavor per member. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)"
  default     = null
}

variable "member_memory_mb" {
  type        = number
  description = "Allocated memory per member. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)"
  default     = 4096
}

variable "admin_pass" {
  type        = string
  description = "The password for the database administrator. If the admin password is null then the admin user ID cannot be accessed. More users can be specified in a user block."
  default     = null
  sensitive   = true
}

variable "users" {
  type = list(object({
    name     = string
    password = string # pragma: allowlist secret
    type     = optional(string)
    role     = optional(string)
  }))
  description = "A list of users that you want to create on the database. Multiple blocks are allowed. The user password must be in the range of 10-32 characters. Be warned that in most case using IAM service credentials (via the var.service_credential_names) is sufficient to control access to the Postgres instance. This blocks creates native postgres database users, more info on that can be found here https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-user-management&interface=ui"
  default     = []
  sensitive   = true
}

variable "service_credential_names" {
  type        = map(string)
  description = "Map of name, role for service credentials that you want to create for the database"
  default     = {}
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the PostgreSQL instance."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the PostgreSQL instance created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details"
  default     = []
}

variable "configuration" {
  type = object({
    shared_buffers  = optional(number)
    max_connections = optional(number)
    # below field gives error when sent to provider
    # tracking issue: https://github.com/IBM-Cloud/terraform-provider-ibm/issues/5403
    # max_locks_per_transaction  = optional(number)
    max_prepared_transactions  = optional(number)
    synchronous_commit         = optional(string)
    effective_io_concurrency   = optional(number)
    deadlock_timeout           = optional(number)
    log_connections            = optional(string)
    log_disconnections         = optional(string)
    log_min_duration_statement = optional(number)
    tcp_keepalives_idle        = optional(number)
    tcp_keepalives_interval    = optional(number)
    tcp_keepalives_count       = optional(number)
    archive_timeout            = optional(number)
    wal_level                  = optional(string)
    max_replication_slots      = optional(number)
    max_wal_senders            = optional(number)
  })
  description = "Database configuration parameters, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-changing-configuration&interface=api for more details."
  default     = null
}

##############################################################
# Auto Scaling
##############################################################

variable "auto_scaling" {
  type = object({
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
  description = "Optional rules to allow the database to increase resources in response to usage. Only a single autoscaling block is allowed. Make sure you understand the effects of autoscaling, especially for production environments. See https://ibm.biz/autoscaling-considerations in the IBM Cloud Docs."
  default     = null
}

##############################################################
# Encryption
##############################################################

variable "use_ibm_owned_encryption_key" {
  type        = string
  description = "Set to true to use the default IBM Cloud® Databases randomly generated keys for disk and backups encryption. To control the encryption keys, use the `kms_key_crn` and `backup_encryption_key_crn` inputs."
  default     = false
}

variable "kms_key_crn" {
  type        = string
  description = "The Hyper Protect Crypto Services (HPCS) or Key Protect root key CRN to use for disk encryption."
  default     = null
}

variable "backup_encryption_key_crn" {
  type        = string
  description = "The Hyper Protect Crypto Services (HPCS) or Key Protect root key CRN to use for encrypting the disk that holds deployment backups. There are region limitations for backup encryption. See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups (HPCS) and https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok (Key Protect)."
  default     = null
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all PostgreSQL database instances in the resource group to read the encryption key from the Hyper Protect Crypto Services or Key Protect instance. The instance is passed in through the var.existing_kms_instance_guid variable."
  default     = false
}

variable "existing_kms_instance_guid" {
  type        = string
  description = "The GUID of the Hyper Protect Crypto Services (HPCS) or Key Protect instance."
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

##############################################################
# Backup
##############################################################

variable "backup_crn" {
  type        = string
  description = "The CRN of a backup resource to restore from. The backup is created by a database deployment with the same service ID. The backup is loaded after provisioning and the new deployment starts up that uses that data. A backup CRN is in the format crn:v1:<…>:backup:. If omitted, the database is provisioned empty."
  default     = null
}
