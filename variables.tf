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

variable "plan_validation" {
  type        = bool
  description = "Enable or disable validating the database parameters for PostgreSQL during the plan phase."
  default     = true
}

variable "remote_leader_crn" {
  type        = string
  description = "A CRN of the leader database to make the replica(read-only) deployment. The leader database is created by a database deployment with the same service ID. A read-only replica is set up to replicate all of your data from the leader deployment to the replica deployment by using asynchronous replication. For more information, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-read-only-replicas"
  default     = null
}

variable "pg_version" {
  description = "Version of the PostgreSQL instance to provision. If no value is passed, the current preferred version of IBM Cloud Databases is used."
  type        = string
  default     = null
  validation {
    condition = anytrue([
      var.pg_version == null,
      var.pg_version == "14",
      var.pg_version == "13",
      var.pg_version == "12",
      var.pg_version == "11"
    ])
    error_message = "Version must be 11 or 12 or 13 or 14. If no value passed, the current ICD preferred version is used."
  }
}

variable "region" {
  description = "The region where you want to deploy your instance."
  type        = string
  default     = "us-south"
}

variable "member_memory_mb" {
  type        = number
  description = "Allocated memory per-member. See the following doc for supported values: https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling"
  default     = 1024
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
}

variable "member_disk_mb" {
  type        = number
  description = "Allocated disk per member. For more information, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling"
  default     = 5120
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
}

variable "member_cpu_count" {
  type        = number
  description = "Allocated dedicated CPU per member. For shared CPU, set to 0. For more information, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling"
  default     = 0
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
}

variable "service_credential_names" {
  description = "Map of name, role for service credentials that you want to create for the database"
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for name, role in var.service_credential_names : contains(["Administrator", "Operator", "Viewer", "Editor"], role)])
    error_message = "Valid values for service credential roles are 'Administrator', 'Operator', 'Viewer', and `Editor`"
  }
}

variable "members" {
  type        = number
  description = "Allocated number of members. Members can be scaled up but not down."
  default     = 2
  # Validation is done in the Terraform plan phase by the IBM provider, so no need to add extra validation here.
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

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the PostgreSQL instance and the associated service credentials (if creating)."
  default     = []
}

variable "configuration" {
  description = "Database configuration"
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

##############################################################
# Auto Scaling
##############################################################

variable "auto_scaling" {
  type = object({
    cpu = object({
      rate_increase_percent       = optional(number, 10)
      rate_limit_count_per_member = optional(number, 30)
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
  description = "Optional rules to allow the database to increase resources in response to usage. Only a single autoscaling block is allowed. Make sure you understand the effects of autoscaling, especially for production environments. See https://ibm.biz/autoscaling-considerations in the IBM Cloud Docs."
  default     = null
}

##############################################################
# Encryption
##############################################################

variable "kms_encryption_enabled" {
  type        = bool
  description = "Set this to true to control the encryption keys used to encrypt the data that you store in IBM Cloud® Databases. If set to false, the data is encrypted by using randomly generated keys. For more info on Key Protect integration, see https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect. For more info on HPCS integration, see https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs"
  default     = false
}

variable "kms_key_crn" {
  type        = string
  description = "The root key CRN of a Key Management Services like Key Protect or Hyper Protect Crypto Services (HPCS) that you want to use for disk encryption. Only used if var.kms_encryption_enabled is set to true."
  default     = null
  validation {
    condition = anytrue([
      var.kms_key_crn == null,
      can(regex(".*kms.*", var.kms_key_crn)),
      can(regex(".*hs-crypto.*", var.kms_key_crn)),
    ])
    error_message = "Value must be the root key CRN from either the Key Protect or Hyper Protect Crypto Service (HPCS)"
  }
}

variable "backup_encryption_key_crn" {
  type        = string
  description = "The CRN of a Key Protect key that you want to use for encrypting the disk that holds deployment backups. Only used if var.kms_encryption_enabled is set to true. BYOK for backups is available only in US regions us-south and us-east, and in eu-de. Only keys in the us-south and eu-de are durable to region failures. To ensure that your backups are available even if a region failure occurs, use a key from us-south or eu-de. Hyper Protect Crypto Services for IBM Cloud Databases backups is not currently supported. If no value is passed here, the value passed for the 'kms_key_crn' variable is used. And if a HPCS value is passed for var.kms_key_crn, the database backup encryption uses the default encryption keys."
  default     = null
  validation {
    condition     = var.backup_encryption_key_crn == null ? true : length(regexall("^crn:v1:bluemix:public:kms:(us-south|us-east|eu-de):a/[[:xdigit:]]{32}:[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}:key:[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$", var.backup_encryption_key_crn)) > 0
    error_message = "Valid values for backup_encryption_key_crn is null or a Key Protect key CRN from us-south, us-east or eu-de"
  }
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all PostgreSQL database instances in the resource group to read the encryption key from the Hyper Protect Crypto Services (HPCS) instance. If set to false, pass in a value for the HPCS instance in the  var.existing_kms_instance_guid variable. In addition, no policy is created if var.kms_encryption_enabled is set to false."
  default     = false
}

variable "existing_kms_instance_guid" {
  description = "The GUID of the Hyper Protect Crypto Services or Key Protect instance in which the key specified in var.kms_key_crn and var.backup_encryption_key_crn is coming from. Required only if var.kms_encryption_enabled is set to true, var.skip_iam_authorization_policy is set to false, and you pass a value for var.kms_key_crn, var.backup_encryption_key_crn, or both."
  type        = string
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
}

variable "pitr_time" {
  type        = string
  description = "(Optional) The timestamp in UTC format (%Y-%m-%dT%H:%M:%SZ) that you want to restore to. To retrieve the timestamp, run the command (ibmcloud cdb postgresql earliest-pitr-timestamp <deployment name or CRN>). For more info on Point-in-time Recovery, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-pitr"
  default     = null
}
