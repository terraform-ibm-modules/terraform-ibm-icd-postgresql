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

variable "postgresql_version" {
  type        = string
  description = "Version of the PostgreSQL instance. If no value is passed, the current preferred version of IBM Cloud Databases is used."
  default     = null

  validation {
    condition = anytrue([
      var.postgresql_version == null,
      var.postgresql_version == "13",
      var.postgresql_version == "14",
      var.postgresql_version == "15",
      var.postgresql_version == "16",
      var.postgresql_version == "17",
      var.postgresql_version == "18"
    ])
    error_message = "Version must be 13, 14, 15, 16, 17, or 18. If no value passed, the current ICD preferred version is used."
  }
}

variable "region" {
  type        = string
  description = "The region where you want to deploy your instance."
  default     = "us-south"
}

variable "remote_leader_crn" {
  type        = string
  description = "A CRN of the leader database to make the replica(read-only) deployment. The leader database is created by a database deployment with the same service ID. A read-only replica is set up to replicate all of your data from the leader deployment to the replica deployment by using asynchronous replication. For more information, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-read-only-replicas"
  default     = null
}

##############################################################################
# ICD hosting model properties
##############################################################################

variable "members" {
  type        = number
  description = "Allocated number of members. Members can be scaled up but not down."
  default     = 2
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
}

variable "cpu_count" {
  type        = number
  description = "Allocated dedicated CPU per member. For shared CPU, set to 0. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)"
  default     = 0
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
}

variable "disk_mb" {
  type        = number
  description = "Allocated disk per member. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)"
  default     = 5120
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
}

variable "member_host_flavor" {
  type        = string
  description = "Allocated host flavor per member. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)."
  default     = null
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
}

variable "memory_mb" {
  type        = number
  description = "Allocated memory per member. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)"
  default     = 4096
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
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

  validation {
    condition     = alltrue([for name, role in var.service_credential_names : contains(["Administrator", "Operator", "Viewer", "Editor"], role)])
    error_message = "Valid values for service credential roles are 'Administrator', 'Operator', 'Viewer', and `Editor`"
  }
}

variable "service_endpoints" {
  type        = string
  description = "Specify whether you want to enable the public, private, or both service endpoints. Supported values are 'public', 'private', or 'public-and-private'."
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.service_endpoints)
    error_message = "Valid values for service_endpoints are 'public', 'public-and-private', and 'private'"
  }
}

variable "tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the PostgreSQL instance."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the PostgreSQL instance created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details"
  default     = []

  validation {
    condition = alltrue([
      for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\", see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits for more details"
  }
}

variable "version_upgrade_skip_backup" {
  type        = bool
  description = "Whether to skip taking a backup before upgrading the database version. Attention: Skipping a backup is not recommended. Skipping a backup before a version upgrade is dangerous and may result in data loss if the upgrade fails at any stage — there will be no immediate backup to restore from."
  default     = false
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection within terraform. This is not a property of the resource and does not prevent deletion outside of terraform. The database can not be deleted by terraform when this value is set to 'true'. In order to delete with terraform the value must be set to 'false' and a terraform apply performed before the destroy is performed. The default is 'true'."
  default     = true
}

variable "update_timeout" {
  type        = string
  description = "A database update may require a longer timeout for the update to complete. The default is 120 minutes. Set this variable to change the `update` value in the `timeouts` block. [Learn more](https://developer.hashicorp.com/terraform/language/resources/syntax#operation-timeouts)."
  default     = "120m"
}

variable "create_timeout" {
  type        = string
  description = "A database creation may require a longer timeout for the creation to complete. The default is 120 minutes. Set this variable to change the `create` value in the `timeouts` block. [Learn more](https://developer.hashicorp.com/terraform/language/resources/syntax#operation-timeouts)."
  default     = "120m"
}

variable "delete_timeout" {
  type        = string
  description = "A database deletion may require a longer timeout for the deletion to complete. The default is 15 minutes. Set this variable to change the `delete` value in the `timeouts` block. [Learn more](https://developer.hashicorp.com/terraform/language/resources/syntax#operation-timeouts)."
  default     = "15m"
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

  # uncomment below validation when max_locks_per_transaction provider bug is resolved
  # validation {
  #   condition     = var.configuration != null ? (var.configuration["max_locks_per_transaction"] != null ? var.configuration["max_locks_per_transaction"] >= 10 : true) : true
  #   error_message = "Value for `configuration[\"max_locks_per_transaction\"]` must be 10 or more, if specified."
  # }

  validation {
    condition     = var.configuration != null ? (var.configuration["synchronous_commit"] != null ? contains(["local", "on", "off"], var.configuration["synchronous_commit"]) : true) : true
    error_message = "Value for `configuration[\"synchronous_commit\"]` must be one of `local`, `on`, or `off`, if specified."
  }

  validation {
    condition     = var.configuration != null ? (var.configuration["deadlock_timeout"] != null ? var.configuration["deadlock_timeout"] >= 100 : true) : true
    error_message = "Value for `configuration[\"deadlock_timeout\"]` must be 100 or more, if specified."
  }

  validation {
    condition     = var.configuration != null ? (var.configuration["log_connections"] != null ? contains(["on", "off"], var.configuration["log_connections"]) : true) : true
    error_message = "Value for `configuration[\"log_connections\"]` must be either `on` or `off`, if specified."
  }

  validation {
    condition     = var.configuration != null ? (var.configuration["log_disconnections"] != null ? contains(["on", "off"], var.configuration["log_disconnections"]) : true) : true
    error_message = "Value for `configuration[\"log_disconnections\"]` must be either `on` or `off`, if specified."
  }

  validation {
    condition     = var.configuration != null ? (var.configuration["log_min_duration_statement"] != null ? var.configuration["log_min_duration_statement"] >= 100 : true) : true
    error_message = "Value for `configuration[\"log_min_duration_statement\"]` must be 100 or more, if specified."
  }

  validation {
    condition     = var.configuration != null ? (var.configuration["archive_timeout"] != null ? var.configuration["archive_timeout"] >= 300 : true) : true
    error_message = "Value for `configuration[\"archive_timeout\"]` must be 300 or more, if specified."
  }

  # skip validation for issue #508 and #512
  #validation {
  #  condition     = var.configuration != null ? (var.configuration["wal_level"] != null ? contains(["replica", "logical"], var.configuration["wal_level"]) : true) : true
  #  error_message = "Value for `configuration[\"wal_level\"]` must be either `replica` or `logical`, if specified."
  #}

  validation {
    condition     = var.configuration != null ? (var.configuration["max_replication_slots"] != null ? var.configuration["max_replication_slots"] >= 10 : true) : true
    error_message = "Value for `configuration[\"max_replication_slots\"]` must be 10 or more, if specified."
  }

  validation {
    condition     = var.configuration != null ? (var.configuration["max_wal_senders"] != null ? var.configuration["max_wal_senders"] >= 12 : true) : true
    error_message = "Value for `configuration[\"max_wal_senders\"]` must be 12 or more, if specified."
  }
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
  type        = bool
  description = "IBM Cloud Databases will secure your deployment's data at rest automatically with an encryption key that IBM hold. Alternatively, you may select your own Key Management System instance and encryption key (Key Protect or Hyper Protect Crypto Services) by setting this to false. If setting to false, a value must be passed for the `kms_key_crn` input."
  default     = true

  validation {
    condition = !(
      var.use_ibm_owned_encryption_key == true &&
      (var.kms_key_crn != null || var.backup_encryption_key_crn != null)
    )
    error_message = "When 'use_ibm_owned_encryption_key' is true, 'kms_key_crn' and 'backup_encryption_key_crn' must both be null."
  }

  validation {
    condition     = var.use_ibm_owned_encryption_key || var.kms_key_crn != null
    error_message = "When setting 'use_ibm_owned_encryption_key' to false, a value must be passed for 'kms_key_crn'."
  }

  validation {
    condition = (
      var.use_ibm_owned_encryption_key ||
      var.backup_encryption_key_crn == null ||
      (!var.use_default_backup_encryption_key && !var.use_same_kms_key_for_backups)
    )
    error_message = "When passing a value for 'backup_encryption_key_crn' you cannot set 'use_default_backup_encryption_key' to true or 'use_ibm_owned_encryption_key' to false."
  }

  validation {
    condition = (
      var.use_ibm_owned_encryption_key ||
      var.backup_encryption_key_crn != null ||
      var.use_same_kms_key_for_backups
    )
    error_message = "When 'use_same_kms_key_for_backups' is set to false, a value needs to be passed for 'backup_encryption_key_crn'."
  }
}

variable "use_default_backup_encryption_key" {
  type        = bool
  description = "When `use_ibm_owned_encryption_key` is set to false, backups will be encrypted with either the key specified in `kms_key_crn`, or in `backup_encryption_key_crn` if a value is passed. If you do not want to use your own key for backups encryption, you can set this to `true` to use the IBM Cloud Databases default encryption for backups. Alternatively set `use_ibm_owned_encryption_key` to true to use the default encryption for both backups and deployment data."
  default     = false
}

variable "kms_key_crn" {
  type        = string
  description = "The CRN of a Key Protect or Hyper Protect Crypto Services encryption key to encrypt your data. Applies only if `use_ibm_owned_encryption_key` is false. By default this key is used for both deployment data and backups, but this behaviour can be altered using the `use_same_kms_key_for_backups` and `backup_encryption_key_crn` inputs. Bare in mind that backups encryption is only available in certain regions. See [Bring your own key for backups](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok) and [Using the HPCS Key for Backup encryption](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups)."
  default     = null

  validation {
    condition = anytrue([
      var.kms_key_crn == null,
      can(regex(".*kms.*", var.kms_key_crn)),
      can(regex(".*hs-crypto.*", var.kms_key_crn)),
    ])
    error_message = "Value must be the KMS key CRN from a Key Protect or Hyper Protect Crypto Services instance."
  }
}

variable "use_same_kms_key_for_backups" {
  type        = bool
  description = "Set this to false if you wan't to use a different key that you own to encrypt backups. When set to false, a value is required for the `backup_encryption_key_crn` input. Alternatively set `use_default_backup_encryption_key` to true to use the IBM Cloud Databases default encryption. Applies only if `use_ibm_owned_encryption_key` is false. Bare in mind that backups encryption is only available in certain regions. See [Bring your own key for backups](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok) and [Using the HPCS Key for Backup encryption](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups)."
  default     = true
}

variable "backup_encryption_key_crn" {
  type        = string
  description = "The CRN of a Key Protect or Hyper Protect Crypto Services encryption key that you want to use for encrypting the disk that holds deployment backups. Applies only if `use_ibm_owned_encryption_key` is false and `use_same_kms_key_for_backups` is false. If no value is passed, and `use_same_kms_key_for_backups` is true, the value of `kms_key_crn` is used. Alternatively set `use_default_backup_encryption_key` to true to use the IBM Cloud Databases default encryption. Bare in mind that backups encryption is only available in certain regions. See [Bring your own key for backups](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok) and [Using the HPCS Key for Backup encryption](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups)."
  default     = null

  validation {
    condition = anytrue([
      var.backup_encryption_key_crn == null,
      can(regex(".*kms.*", var.backup_encryption_key_crn)),
      can(regex(".*hs-crypto.*", var.backup_encryption_key_crn)),
    ])
    error_message = "Value must be the KMS key CRN from a Key Protect or Hyper Protect Crypto Services instance in one of the supported backup regions."
  }
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of IAM authorization policies that permits all Databases for PostgreSQL instances in the given resource group 'Reader' access to the Key Protect or Hyper Protect Crypto Services key that was provided in the `kms_key_crn` and `backup_encryption_key_crn` inputs. This policy is required in order to enable KMS encryption, so only skip creation if there is one already present in your account. No policy is created if `use_ibm_owned_encryption_key` is true."
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
    tags = optional(list(object({
      name  = string
      value = string
    })))
  }))
  description = "The context-based restrictions rule to create. Only one rule is allowed."
  default     = []
  # Validation happens in the rule module
  validation {
    condition     = length(var.cbr_rules) <= 1
    error_message = "Only one CBR rule is allowed."
  }
}

##############################################################
# Backup
##############################################################

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

##############################################################
# Point-In-Time Recovery (PITR)
##############################################################

variable "pitr_id" {
  type        = string
  description = "(Optional) The ID of the source deployment PostgreSQL instance that you want to recover back to. The PostgreSQL instance is expected to be in an up and in running state."
  default     = null

  validation {
    condition     = var.pitr_id != null ? true : var.pitr_time == null
    error_message = "To use Point-In-Time Recovery (PITR), a value for var.pitr_id needs to be set when var.pitr_time is specified. Otherwise, unset var.pitr_time."
  }

  validation {
    condition     = var.pitr_id == null ? true : var.pitr_time != null
    error_message = "To use Point-In-Time Recovery (PITR), a value for var.pitr_time needs to be set when var.pitr_id is specified. Otherwise, unset var.pitr_id."
  }
}

variable "pitr_time" {
  type        = string
  description = "(Optional) The timestamp in UTC format (%Y-%m-%dT%H:%M:%SZ) for any time in the last 7 days that you want to restore to. If empty string (\"\") is passed, earliest_point_in_time_recovery_time will be used as pitr_time. To retrieve the timestamp, run the command (ibmcloud cdb postgresql earliest-pitr-timestamp <deployment name or CRN>). For more info on Point-in-time Recovery, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-pitr"
  default     = null
}
