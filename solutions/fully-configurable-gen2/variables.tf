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
  default     = 10240
}

variable "member_host_flavor" {
  type        = string
  description = "The host flavor per member. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)."
  default     = "bx3d.4x20"
  # Prevent null or "", require a machine type
  validation {
    condition     = (length(var.member_host_flavor) > 0)
    error_message = "Member host flavor must be specified. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)."
  }
  validation {
    condition     = (length(var.member_host_flavor) > 0) && var.member_host_flavor != "multitenant"
    error_message = "Shared compute, `multitenant`, is not supported for Gen2. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor)."
  }
}

variable "service_credential_names" {
  description = "A list of service credential resource keys to be created for the PostgreSQL instance. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/blob/main/solutions/fully-configurable/DA-types.md#svc-credential-name)"
  type = list(object({
    name     = string
    role     = optional(string, "Viewer")
    endpoint = optional(string, "private")
  }))
  default = []
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

variable "kms_encryption_enabled" {
  type        = bool
  description = "Set to true to enable KMS encryption using customer-managed keys. When enabled, you must provide a value for at least one of the following: existing_kms_instance_crn or existing_kms_key_crn. If set to false, IBM-owned encryption is used (i.e., encryption keys managed and held by IBM)."
  default     = false

  validation {
    condition = (!var.kms_encryption_enabled ||
      var.existing_postgresql_instance_crn != null ||
      var.existing_kms_instance_crn != null ||
      var.existing_kms_key_crn != null
    )
    error_message = "When 'kms_encryption_enabled' is true, you must provide either 'existing_kms_instance_crn' (to create a new key) or 'existing_kms_key_crn' (to use an existing key)."
  }

  validation {
    condition     = (var.existing_kms_instance_crn == null && var.existing_kms_key_crn == null) || var.kms_encryption_enabled
    error_message = "When either 'existing_kms_instance_crn' or 'existing_kms_key_crn' is set then 'kms_encryption_enabled' must be set to true."
  }
}

variable "existing_kms_instance_crn" {
  type        = string
  description = "The CRN of a Key Protect or Hyper Protect Crypto Services instance. Required to create a new encryption key and key ring which will be used to encrypt both deployment data and backups. To use an existing key, pass a value for `existing_kms_key_crn`. Bare in mind that backups encryption is only available in certain regions. See [Bring your own key for backups](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok) and [Using the HPCS Key for Backup encryption](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups)."
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
  description = "The CRN of a Key Protect or Hyper Protect Crypto Services encryption key to encrypt your data. By default this key is used for deployment data. If no value is passed a new key will be created in the instance specified in the `existing_kms_instance_crn` input. Bare in mind that backups encryption is only available in certain regions. See [Bring your own key for backups](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok) and [Using the HPCS Key for Backup encryption](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups)."
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

variable "async_restore" {
  type        = bool
  description = "Set it to `true`, to initiate the restore as an asynchronous operation, which helps to reduce end-to-end restore time. This feature can only be used when the source and target PostgreSQL databases are running the same major version."
  default     = false
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
