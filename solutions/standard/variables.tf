##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key to deploy resources."
  sensitive   = true
}

variable "ibmcloud_kms_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create a root key and key ring in the key management service (KMS) instance. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the instance in `existing_kms_instance_crn` is in an account that's different from the PostgreSQL instance. Leave this input empty if the same account owns both instances."
  sensitive   = true
  default     = null
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of a new or an existing resource group to provision the Databases for PostgreSQL in. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "prefix" {
  type        = string
  description = "Prefix to add to all resources created by this solution."
  default     = null
}

variable "name" {
  type        = string
  description = "The name of the PostgreSQL instance. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  default     = "postgresql"
}

variable "region" {
  description = "The region where you want to deploy your instance."
  type        = string
  default     = "us-south"
}

variable "pg_version" {
  description = "The version of the PostgreSQL instance. If no value is specified, the current preferred version of PostgreSQL is used."
  type        = string
  default     = null
}

variable "backup_crn" {
  type        = string
  description = "The CRN of a backup resource to restore from. The backup is created by a database deployment with the same service ID. The backup is loaded after provisioning and the new deployment starts up that uses that data. A backup CRN is in the format crn:v1:<…>:backup:. If omitted, the database is provisioned empty."
  default     = null
}

##############################################################################
# ICD hosting model properties
##############################################################################
variable "members" {
  type        = number
  description = "The number of members that are allocated. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)."
  default     = 3
}

variable "member_cpu_count" {
  type        = number
  description = "The dedicated CPU per member that is allocated. For shared CPU, set to 0. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)."
  default     = 0
}

variable "member_disk_mb" {
  type        = number
  description = "The disk that is allocated per member. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)."
  default     = 5120
}

variable "member_host_flavor" {
  type        = string
  description = "The host flavor per member. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)."
  default     = "multitenant"
  # Prevent null or "", require multitenant or a machine type
  validation {
    condition     = (length(var.member_host_flavor) > 0)
    error_message = "Member host flavor must be specified. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)."
  }
}

variable "member_memory_mb" {
  type        = number
  description = "The memory per member that is allocated. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)"
  default     = 4096
}

variable "admin_pass" {
  type        = string
  description = "The password for the database administrator. If the admin password is null, the admin user ID cannot be accessed. More users can be specified in a user block."
  default     = null
  sensitive   = true
}

variable "users" {
  type = list(object({
    name     = string
    password = string # pragma: allowlist secret
    type     = string # "type" is required to generate the connection string for the outputs.
    role     = optional(string)
  }))
  default     = []
  sensitive   = true
  description = "A list of users that you want to create on the database. Multiple blocks are allowed. The user password must be in the range of 10-32 characters. Be warned that in most case using IAM service credentials (via the var.service_credential_names) is sufficient to control access to the PostgreSQL instance. This blocks creates native postgres database users. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/solutions/standard/DA-types.md)."
}

variable "service_credential_names" {
  description = "The map of name and role for service credentials that you want to create for the database. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/solutions/standard/DA-types.md)."
  type        = map(string)
  default     = {}
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the PostgreSQL instance."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the PostgreSQL instance created by the solution. [Learn more](https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial)."
  default     = []
}

variable "configuration" {
  description = "Database Configuration for PostgreSQL instance. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/solutions/standard/DA-types.md)"
  type = object({
    shared_buffers             = optional(number)
    max_connections            = optional(number)
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
  default = {
    shared_buffers             = 32000
    max_connections            = 115
    max_prepared_transactions  = 0
    synchronous_commit         = "local"
    effective_io_concurrency   = 12
    deadlock_timeout           = 10000
    log_connections            = "on"
    log_disconnections         = "on"
    log_min_duration_statement = 100
    tcp_keepalives_idle        = 111
    tcp_keepalives_interval    = 15
    tcp_keepalives_count       = 6
    archive_timeout            = 1800
    max_replication_slots      = 10
    max_wal_senders            = 12
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
  description = "The rules to allow the database to increase resources in response to usage. Only a single autoscaling block is allowed. Make sure you understand the effects of autoscaling, especially for production environments. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/solutions/standard/DA-types.md)"
  default     = null
}

##############################################################
# Encryption
##############################################################

variable "use_ibm_owned_encryption_key" {
  type        = string
  description = "Set to true to use the default IBM Cloud® Databases randomly generated keys for disk and backups encryption."
  default     = false
}

variable "key_name" {
  type        = string
  default     = "postgresql-key"
  description = "The name for the key created for the PostgreSQL key. Applies only if not specifying an existing key or using IBM owned keys. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "key_ring_name" {
  type        = string
  default     = "postgresql-key-ring"
  description = "The name for the key ring created for the PostgreSQL key. Applies only if not specifying an existing key or using IBM owned keys. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "kms_endpoint_type" {
  type        = string
  description = "The type of endpoint to use for communicating with the Key Protect or Hyper Protect Crypto Services instance. Possible values: `public`, `private`."
  default     = "private"
  validation {
    condition     = can(regex("public|private", var.kms_endpoint_type))
    error_message = "The kms_endpoint_type value must be 'public' or 'private'."
  }
}

variable "existing_kms_key_crn" {
  type        = string
  description = "The CRN of an Hyper Protect Crypto Services or Key Protect encryption key that you want to use to use for both disk and backup encryption. If no value is passed, a new key ring and key will be created in the instance provided in the `existing_kms_instance_crn` input. Backup encryption is only supported is some regions ([learn more](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok)), so if you need to use a key from a different region for backup encryption, use the `existing_backup_kms_key_crn` input."
  default     = null
}

variable "existing_kms_instance_crn" {
  description = "The CRN of an Hyper Protect Crypto Services or Key Protect instance that you want to use for both disk and backup encryption. Backup encryption is only supported is some regions ([learn more](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok)), so if you need to use a different instance for backup encryption from a supported region, use the `existing_backup_kms_instance_crn` input."
  type        = string
  default     = null
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Whether to create an IAM authorization policy that permits all PostgreSQL instances in the resource group to read the encryption key from the Hyper Protect Crypto Services instance specified in the `existing_kms_instance_crn` variable."
  default     = false
}

##############################################################
# Backup Encryption
##############################################################
variable "existing_backup_kms_key_crn" {
  type        = string
  description = "The CRN of an Hyper Protect Crypto Services or Key Protect encryption key that you want to use to encrypt database backups. If no value is passed, the value of `existing_kms_key_crn` is used. If no value is passed for that, a new key will be created in the provided KMS instance and used for both disk encryption, and backup encryption."
  default     = null
}

variable "existing_backup_kms_instance_crn" {
  description = "The CRN of an Hyper Protect Crypto Services or Key Protect instance that you want to use to encrypt database backups. If no value is passed, the value of the `existing_kms_instance_crn` input will be used, however backup encryption is only supported in certain regions so you need to ensure the KMS for backup is coming from one of the supported regions. [Learn more](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok)"
  type        = string
  default     = null
}
