##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key to deploy resources."
  sensitive   = true
}

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the resources. [Learn more](https://cloud.ibm.com/docs/account?topic=account-rgs&interface=ui#create_rgs) about how to create a resource group."
  default     = "Default"
}

variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to `null` or an empty string. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    # must not exceed 16 characters in length
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "name" {
  type        = string
  description = "The name of the Databases for PostgreSQL instance. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  default     = "postgresql"
}

variable "region" {
  description = "The region where you want to deploy your instance."
  type        = string
  default     = "us-south"
}

variable "existing_postgresql_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing Databases for Postgresql instance. If no value is specified, a new instance is created."

  validation {
    condition = anytrue([
      var.existing_postgresql_instance_crn == null,
      can(regex("^crn:v\\d:(.*:){2}databases-for-postgresql:(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.existing_postgresql_instance_crn))
    ])
    error_message = "The value provided for 'existing_postgresql_instance_crn' is not valid."
  }
}

variable "postgresql_version" {
  description = "The version of the Databases for Redis instance."
  type        = string
  default     = null
}

variable "remote_leader_crn" {
  type        = string
  description = "A CRN of the leader database to make the replica(read-only) deployment. The leader database is created by a database deployment with the same service ID. A read-only replica is set up to replicate all of your data from the leader deployment to the replica deployment by using asynchronous replication. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-read-only-replicas)."
  default     = null

  validation {
    condition = anytrue([
      var.remote_leader_crn == null,
      can(regex("^crn:v\\d:(.*:){2}databases-for-postgresql:(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.remote_leader_crn))
    ])
    error_message = "The value provided for 'remote_leader_crn' is not valid."
  }
}

##############################################################################
# ICD hosting model properties
##############################################################################

variable "members" {
  type        = number
  description = "The number of members that are allocated. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)."
  default     = 2
}

variable "member_memory_mb" {
  type        = number
  description = "The memory per member that is allocated. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling)"
  default     = 4096
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

variable "configuration" {
  description = "Database Configuration for PostgreSQL instance. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/solutions/fully-configurable/DA-types.md)"
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

variable "service_credential_names" {
  description = "Map of name, role for service credentials that you want to create for the database. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/blob/main/solutions/fully-configurable/DA-types.md#svc-credential-name)"
  type        = map(string)
  default     = {}
}

variable "admin_pass" {
  type        = string
  description = "The password for the database administrator. If no admin password is provided (i.e., it is null), one will be generated automatically. Additional users can be added using a user block."
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
  description = "A list of users that you want to create on the database. Multiple blocks are allowed. The user password must be in the range of 10-32 characters. Be warned that in most case using IAM service credentials (via the var.service_credential_names) is sufficient to control access to the PostgreSQL instance. This blocks creates native postgres database users. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/solutions/fully-configurable/DA-types.md#users)"
}

variable "resource_tags" {
  type        = list(string)
  description = "The list of resource tags to be added to the Databases for PostgreSQL instance."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Databases for PostgreSQL instance created by the solution. [Learn more](https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial)."
  default     = []
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

##############################################################
# Encryption
##############################################################

variable "existing_kms_instance_crn" {
  type        = string
  description = "The CRN of a Key Protect or Hyper Protect Crypto Services instance. Required to create a new encryption key and key ring which will be used to encrypt both deployment data and backups. To use an existing key, pass values for `existing_kms_key_crn` and/or `existing_backup_kms_key_crn`. Bare in mind that backups encryption is only available in certain regions. See [Bring your own key for backups](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok) and [Using the HPCS Key for Backup encryption](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups)."
  default     = null

  validation {
    condition = anytrue([
      var.existing_kms_instance_crn == null,
      can(regex("^crn:v\\d:(.*:){2}(kms|hs-crypto):(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.existing_kms_instance_crn))
    ])
    error_message = "The value provided for 'existing_kms_instance_crn' is not valid."
  }
}

variable "existing_kms_key_crn" {
  type        = string
  description = "The CRN of a Key Protect or Hyper Protect Crypto Services encryption key to encrypt your data. By default this key is used for both deployment data and backups, but this behaviour can be altered using the optional `existing_backup_kms_key_crn` input. If no value is passed a new key will be created in the instance specified in the `existing_kms_instance_crn` input. Bare in mind that backups encryption is only available in certain regions. See [Bring your own key for backups](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok) and [Using the HPCS Key for Backup encryption](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups)."
  default     = null

  validation {
    condition = (
      (var.existing_kms_key_crn != null && var.existing_kms_instance_crn == null) ||
      (var.existing_kms_key_crn == null && var.existing_kms_instance_crn != null)
    )
    error_message = "Either existing_kms_key_crn or existing_kms_instance_crn must be set, but not both."
  }

  validation {
    condition = anytrue([
      var.existing_kms_key_crn == null,
      can(regex("^crn:v\\d:(.*:){2}(kms|hs-crypto):(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}:key:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.existing_kms_key_crn))
    ])
    error_message = "The value provided for 'existing_kms_key_crn’ is not valid."
  }
}

variable "skip_postgresql_kms_auth_policy" {
  type        = bool
  description = "Whether to create an IAM authorization policy that permits all Databases for PostgreSQL instances in the resource group to read the encryption key from the Hyper Protect Crypto Services instance specified in the `existing_kms_instance_crn` variable."
  default     = false
}

variable "ibmcloud_kms_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create a root key and key ring in the key management service (KMS) instance. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the instance in `existing_kms_instance_crn` is in an account that's different from the PostgreSQL instance. Leave this input empty if the same account owns both instances."
  sensitive   = true
  default     = null
}

variable "key_ring_name" {
  type        = string
  default     = "postgresql-key-ring"
  description = "The name for the key ring created for the Databases for PostgreSQL key. Applies only if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "key_name" {
  type        = string
  default     = "postgresql-key"
  description = "The name for the key created for the Databases for PostgreSQL key. Applies only if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "existing_backup_kms_key_crn" {
  type        = string
  description = "The CRN of a Key Protect or Hyper Protect Crypto Services encryption key that you want to use for encrypting the disk that holds deployment backups. If no value is passed, the value of `existing_kms_key_crn` is used. If no value is passed for `existing_kms_key_crn`, a new key will be created in the instance specified in the `existing_kms_instance_crn` input."
  default     = null

  validation {
    condition = anytrue([
      var.existing_backup_kms_key_crn == null,
      can(regex("^crn:v\\d:(.*:){2}(kms|hs-crypto):(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}:key:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.existing_backup_kms_key_crn))
    ])
    error_message = "The value provided for 'existing_backup_kms_key_crn' is not valid."
  }
}

variable "backup_crn" {
  type        = string
  description = "The CRN of a backup resource to restore from. The backup is created by a database deployment with the same service ID. The backup is loaded after provisioning and the new deployment starts up that uses that data. A backup CRN is in the format crn:v1:<…>:backup:. If omitted, the database is provisioned empty."
  default     = null

  validation {
    condition = anytrue([
      var.backup_crn == null,
      can(regex("^crn:v\\d:(.*:){2}databases-for-postgresql:(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}:backup:[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", var.backup_crn))
    ])
    error_message = "backup_crn must be null OR starts with 'crn:' and contains ':backup:'"
  }
}

variable "async_restore" {
  type        = bool
  description = "Set it to `true`, to initiate the restore as an asynchronous operation, which helps to reduce end-to-end restore time. This feature can only be used when the source and target PostgreSQL databases are running the same major version."
  default     = false
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
  description = "Optional rules to allow the database to increase resources in response to usage. Only a single autoscaling block is allowed. Make sure you understand the effects of autoscaling, especially for production environments. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/solutions/fully-configurable/DA-types.md)"
  default = {
    disk = {
      capacity_enabled             = false
      free_space_less_than_percent = 10
      io_above_percent             = 90
      io_enabled                   = false
      io_over_period               = "15m"
      rate_increase_percent        = 10
      rate_limit_mb_per_member     = 3670016
      rate_period_seconds          = 900
      rate_units                   = "mb"
    }
    memory = {
      io_above_percent         = 90
      io_enabled               = false
      io_over_period           = "15m"
      rate_increase_percent    = 10
      rate_limit_mb_per_member = 114688
      rate_period_seconds      = 900
      rate_units               = "mb"
    }
  }
}

#############################################################################
# Secrets Manager Service Credentials
#############################################################################

variable "existing_secrets_manager_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of existing secrets manager to use to create service credential secrets for Databases for PostgreSQL instance."

  validation {
    condition = anytrue([
      var.existing_secrets_manager_instance_crn == null,
      can(regex("^crn:v\\d:(.*:){2}secrets-manager:(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.existing_secrets_manager_instance_crn))
    ])
    error_message = "The value provided for 'existing_secrets_manager_instance_crn' is not valid."
  }
}

variable "service_credential_secrets" {
  type = list(object({
    secret_group_name        = string
    secret_group_description = optional(string)
    existing_secret_group    = optional(bool)
    service_credentials = list(object({
      secret_name                                 = string
      service_credentials_source_service_role_crn = string
      secret_labels                               = optional(list(string))
      secret_auto_rotation                        = optional(bool)
      secret_auto_rotation_unit                   = optional(string)
      secret_auto_rotation_interval               = optional(number)
      service_credentials_ttl                     = optional(string)
      service_credential_secret_description       = optional(string)

    }))
  }))
  default     = []
  description = "Service credential secrets configuration for Databases for PostgreSQL. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/tree/main/solutions/fully-configurable/DA-types.md#service-credential-secrets)."

  validation {
    # Service roles CRNs can be found at https://cloud.ibm.com/iam/roles, select the IBM Cloud Database and select the role
    condition = alltrue([
      for group in var.service_credential_secrets : alltrue([
        # crn:v?:bluemix; two non-empty segments; three possibly empty segments; :serviceRole or role: non-empty segment
        for credential in group.service_credentials : can(regex("^crn:v[0-9]:bluemix(:..*){2}(:.*){3}:(serviceRole|role):..*$", credential.service_credentials_source_service_role_crn))
      ])
    ])
    error_message = "service_credentials_source_service_role_crn must be a serviceRole CRN. See https://cloud.ibm.com/iam/roles"
  }

  validation {
    condition = (
      length(var.service_credential_secrets) == 0 ||
      var.existing_secrets_manager_instance_crn != null
    )
    error_message = "`existing_secrets_manager_instance_crn` is required when adding service credentials to a secrets manager secret."
  }
}

variable "skip_postgresql_secrets_manager_auth_policy" {
  type        = bool
  default     = false
  description = "Whether an IAM authorization policy is created for Secrets Manager instance to create a service credential secrets for Databases for PostgreSQL. If set to false, the Secrets Manager instance passed by the user is granted the Key Manager access to the PostgreSQL instance created by the Deployable Architecture. Set to `true` to use an existing policy. The value of this is ignored if any value for 'existing_secrets_manager_instance_crn' is not passed."
}

variable "admin_pass_secrets_manager_secret_group" {
  type        = string
  description = "The name of a new or existing secrets manager secret group for admin password. To use existing secret group, `use_existing_admin_pass_secrets_manager_secret_group` must be set to `true`. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  default     = "postgresql-secrets"

  validation {
    condition = (
      var.existing_secrets_manager_instance_crn == null ||
      var.admin_pass_secrets_manager_secret_group != null
    )
    error_message = "`admin_pass_secrets_manager_secret_group` is required when `existing_secrets_manager_instance_crn` is set."
  }
}

variable "use_existing_admin_pass_secrets_manager_secret_group" {
  type        = bool
  description = "Whether to use an existing secrets manager secret group for admin password."
  default     = false
}

variable "admin_pass_secrets_manager_secret_name" {
  type        = string
  description = "The name of a new PostgreSQL administrator secret. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  default     = "postgresql-admin-password"

  validation {
    condition = (
      var.existing_secrets_manager_instance_crn == null ||
      var.admin_pass_secrets_manager_secret_name != null
    )
    error_message = "`admin_pass_secrets_manager_secret_name` is required when `existing_secrets_manager_instance_crn` is set."
  }
}
