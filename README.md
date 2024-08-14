# IBM Cloud Databases for Postgresql module

[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-icd-postgresql?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module implements an instance of the IBM Cloud Databases for PostgreSQL service.

:exclamation: The module does not support major version upgrades or updates to encryption and backup encryption keys. To upgrade the version, create another instance of Databases for PostgreSQL with the updated version and follow the steps in [Upgrading PostgreSQL docs](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-upgrading&interface=cli) in the IBM Cloud Docs.

:exclamation: The module only supports setting the disk encryption and backup encryption key CRNs on creation and no update support is available. The KMS manual or automatic key rotation may be used to change the key value and initiate the re-encryption of the deployment.

## Usage

IBM Cloud Databases supports:
- Key Protect encryption in `us-south`, `us-east`, and `eu-de` for backup encryption. For more information, see [Bring Your Own Key for Backups](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok) in the IBM Cloud Docs.
- Hyper Protect Crypto Services in all regions for backup encryption. For more information, see [Hyper Protect Crypto Services for Backup encryption](https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups) in the IBM Cloud Docs.

If you enable key management encryption and no value is passed for 'backup_encryption_key_crn', the value of 'kms_key_crn' is used

```hcl
provider "ibm" {
  ibmcloud_api_key = "XXXXXXXXXX"
  region           = "us-south"
}

module "postgresql_db" {
  source            = "terraform-ibm-modules/icd-postgresql/ibm"
  version           = "latest" # Replace "latest" with a release version to lock into a specific release
  resource_group_id = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
  name              = "my-instance"
  region            = "us-south"
}
```

## Required IAM access policies

You need the following permissions to run this module.

- Account Management
    - **Databases for PostgreSQL** service
        - `Editor` role access

To attach access management tags to resources in this module, you need the following permissions.

- IAM Services
    - **Tagging** service
        - `Administrator` platform access

<!-- BEGIN EXAMPLES HOOK -->
## Examples

- [ Restore from backup example](examples/backup)
- [ Basic with read-only replica example](examples/basic)
- [ Complete example with BYOK encryption, CBR rules and VPE creation](examples/complete)
- [ Financial Services Cloud profile example with autoscaling enabled](examples/fscloud)
- [ Point in time recovery example (PITR)](examples/pitr)
<!-- END EXAMPLES HOOK -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.68.1, <2.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cbr_rule"></a> [cbr\_rule](#module\_cbr\_rule) | terraform-ibm-modules/cbr/ibm//modules/cbr-rule-module | 1.23.5 |

### Resources

| Name | Type |
|------|------|
| [ibm_database.postgresql_db](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database) | resource |
| [ibm_iam_authorization_policy.kms_policy](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [ibm_resource_key.service_credentials](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_key) | resource |
| [ibm_resource_tag.postgresql_tag](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_tag) | resource |
| [time_sleep.wait_for_authorization_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [ibm_database_connection.database_connection](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/database_connection) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags) | A list of access tags to apply to the PostgreSQL instance created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details | `list(string)` | `[]` | no |
| <a name="input_admin_pass"></a> [admin\_pass](#input\_admin\_pass) | The password for the database administrator. If the admin password is null then the admin user ID cannot be accessed. More users can be specified in a user block. | `string` | `null` | no |
| <a name="input_auto_scaling"></a> [auto\_scaling](#input\_auto\_scaling) | Optional rules to allow the database to increase resources in response to usage. Only a single autoscaling block is allowed. Make sure you understand the effects of autoscaling, especially for production environments. See https://ibm.biz/autoscaling-considerations in the IBM Cloud Docs. | <pre>object({<br>    disk = object({<br>      capacity_enabled             = optional(bool, false)<br>      free_space_less_than_percent = optional(number, 10)<br>      io_above_percent             = optional(number, 90)<br>      io_enabled                   = optional(bool, false)<br>      io_over_period               = optional(string, "15m")<br>      rate_increase_percent        = optional(number, 10)<br>      rate_limit_mb_per_member     = optional(number, 3670016)<br>      rate_period_seconds          = optional(number, 900)<br>      rate_units                   = optional(string, "mb")<br>    })<br>    memory = object({<br>      io_above_percent         = optional(number, 90)<br>      io_enabled               = optional(bool, false)<br>      io_over_period           = optional(string, "15m")<br>      rate_increase_percent    = optional(number, 10)<br>      rate_limit_mb_per_member = optional(number, 114688)<br>      rate_period_seconds      = optional(number, 900)<br>      rate_units               = optional(string, "mb")<br>    })<br>  })</pre> | `null` | no |
| <a name="input_backup_crn"></a> [backup\_crn](#input\_backup\_crn) | The CRN of a backup resource to restore from. The backup is created by a database deployment with the same service ID. The backup is loaded after provisioning and the new deployment starts up that uses that data. A backup CRN is in the format crn:v1:<…>:backup:. If omitted, the database is provisioned empty. | `string` | `null` | no |
| <a name="input_backup_encryption_key_crn"></a> [backup\_encryption\_key\_crn](#input\_backup\_encryption\_key\_crn) | The CRN of a KMS (Key Protect or Hyper Protect Crypto Services) key to use for encrypting the disk that holds deployment backups. Only used if var.kms\_encryption\_enabled is set to true. There are limitation per region on the type of KMS service (Key Protect or Hyper Protect Crypto Services) and region for those services. See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok and https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs#use-hpcs-backups | `string` | `null` | no |
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | (Optional, list) List of CBR rules to create | <pre>list(object({<br>    description = string<br>    account_id  = string<br>    rule_contexts = list(object({<br>      attributes = optional(list(object({<br>        name  = string<br>        value = string<br>    }))) }))<br>    enforcement_mode = string<br>  }))</pre> | `[]` | no |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | Database configuration parameters, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-changing-configuration&interface=api for more details. | <pre>object({<br>    shared_buffers  = optional(number)<br>    max_connections = optional(number)<br>    # below field gives error when sent to provider<br>    # tracking issue: https://github.com/IBM-Cloud/terraform-provider-ibm/issues/5403<br>    # max_locks_per_transaction  = optional(number)<br>    max_prepared_transactions  = optional(number)<br>    synchronous_commit         = optional(string)<br>    effective_io_concurrency   = optional(number)<br>    deadlock_timeout           = optional(number)<br>    log_connections            = optional(string)<br>    log_disconnections         = optional(string)<br>    log_min_duration_statement = optional(number)<br>    tcp_keepalives_idle        = optional(number)<br>    tcp_keepalives_interval    = optional(number)<br>    tcp_keepalives_count       = optional(number)<br>    archive_timeout            = optional(number)<br>    wal_level                  = optional(string)<br>    max_replication_slots      = optional(number)<br>    max_wal_senders            = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_existing_kms_instance_guid"></a> [existing\_kms\_instance\_guid](#input\_existing\_kms\_instance\_guid) | The GUID of the Hyper Protect Crypto Services or Key Protect instance in which the key specified in var.kms\_key\_crn and var.backup\_encryption\_key\_crn is coming from. Required only if var.kms\_encryption\_enabled is set to true, var.skip\_iam\_authorization\_policy is set to false, and you pass a value for var.kms\_key\_crn, var.backup\_encryption\_key\_crn, or both. | `string` | `null` | no |
| <a name="input_kms_encryption_enabled"></a> [kms\_encryption\_enabled](#input\_kms\_encryption\_enabled) | Set this to true to control the encryption keys used to encrypt the data that you store in IBM Cloud Databases. If set to false, the data is encrypted by using randomly generated keys. For more info on Key Protect integration, see https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect. For more info on HPCS integration, see https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs | `bool` | `false` | no |
| <a name="input_kms_key_crn"></a> [kms\_key\_crn](#input\_kms\_key\_crn) | The root key CRN of a Key Management Services like Key Protect or Hyper Protect Crypto Services (HPCS) that you want to use for disk encryption. Only used if var.kms\_encryption\_enabled is set to true. | `string` | `null` | no |
| <a name="input_member_cpu_count"></a> [member\_cpu\_count](#input\_member\_cpu\_count) | Allocated dedicated CPU per member. For shared CPU, set to 0. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling) | `number` | `0` | no |
| <a name="input_member_disk_mb"></a> [member\_disk\_mb](#input\_member\_disk\_mb) | Allocated disk per member. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling) | `number` | `5120` | no |
| <a name="input_member_host_flavor"></a> [member\_host\_flavor](#input\_member\_host\_flavor) | Allocated host flavor per member. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database#host_flavor) | `string` | `null` | no |
| <a name="input_member_memory_mb"></a> [member\_memory\_mb](#input\_member\_memory\_mb) | Allocated memory per member. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling) | `number` | `4096` | no |
| <a name="input_members"></a> [members](#input\_members) | Allocated number of members. Members can be scaled up but not down. | `number` | `2` | no |
| <a name="input_name"></a> [name](#input\_name) | The name to give the Postgresql instance. | `string` | n/a | yes |
| <a name="input_pg_version"></a> [pg\_version](#input\_pg\_version) | Version of the PostgreSQL instance. If no value is passed, the current preferred version of IBM Cloud Databases is used. | `string` | `null` | no |
| <a name="input_pitr_id"></a> [pitr\_id](#input\_pitr\_id) | (Optional) The ID of the source deployment PostgreSQL instance that you want to recover back to. The PostgreSQL instance is expected to be in an up and in running state. | `string` | `null` | no |
| <a name="input_pitr_time"></a> [pitr\_time](#input\_pitr\_time) | (Optional) The timestamp in UTC format (%Y-%m-%dT%H:%M:%SZ) for any time in the last 7 days that you want to restore to. To retrieve the timestamp, run the command (ibmcloud cdb postgresql earliest-pitr-timestamp <deployment name or CRN>). For more info on Point-in-time Recovery, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-pitr | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where you want to deploy your instance. | `string` | `"us-south"` | no |
| <a name="input_remote_leader_crn"></a> [remote\_leader\_crn](#input\_remote\_leader\_crn) | A CRN of the leader database to make the replica(read-only) deployment. The leader database is created by a database deployment with the same service ID. A read-only replica is set up to replicate all of your data from the leader deployment to the replica deployment by using asynchronous replication. For more information, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-read-only-replicas | `string` | `null` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the PostgreSQL instance will be created. | `string` | n/a | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | Optional list of tags to be added to the PostgreSQL instance. | `list(string)` | `[]` | no |
| <a name="input_service_credential_names"></a> [service\_credential\_names](#input\_service\_credential\_names) | Map of name, role for service credentials that you want to create for the database | `map(string)` | `{}` | no |
| <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints) | Specify whether you want to enable the public, private, or both service endpoints. Supported values are 'public', 'private', or 'public-and-private'. | `string` | `"private"` | no |
| <a name="input_skip_iam_authorization_policy"></a> [skip\_iam\_authorization\_policy](#input\_skip\_iam\_authorization\_policy) | Set to true to skip the creation of an IAM authorization policy that permits all PostgreSQL database instances in the resource group to read the encryption key from the KMS instance. If set to false, pass in a value for the KMS instance in the existing\_kms\_instance\_guid variable. In addition, no policy is created if var.kms\_encryption\_enabled is set to false. | `bool` | `false` | no |
| <a name="input_use_default_backup_encryption_key"></a> [use\_default\_backup\_encryption\_key](#input\_use\_default\_backup\_encryption\_key) | Set to true to use default ICD randomly generated keys. | `bool` | `false` | no |
| <a name="input_users"></a> [users](#input\_users) | A list of users that you want to create on the database. Multiple blocks are allowed. The user password must be in the range of 10-32 characters. Be warned that in most case using IAM service credentials (via the var.service\_credential\_names) is sufficient to control access to the Postgres instance. This blocks creates native postgres database users, more info on that can be found here https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-user-management&interface=ui | <pre>list(object({<br>    name     = string<br>    password = string # pragma: allowlist secret<br>    type     = optional(string)<br>    role     = optional(string)<br>  }))</pre> | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_adminuser"></a> [adminuser](#output\_adminuser) | Database admin user name |
| <a name="output_cbr_rule_ids"></a> [cbr\_rule\_ids](#output\_cbr\_rule\_ids) | CBR rule ids created to restrict Postgresql |
| <a name="output_certificate_base64"></a> [certificate\_base64](#output\_certificate\_base64) | Database connection certificate |
| <a name="output_crn"></a> [crn](#output\_crn) | Postgresql instance crn |
| <a name="output_guid"></a> [guid](#output\_guid) | Postgresql instance guid |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | Database connection hostname |
| <a name="output_id"></a> [id](#output\_id) | Postgresql instance id |
| <a name="output_port"></a> [port](#output\_port) | Database connection port |
| <a name="output_service_credentials_json"></a> [service\_credentials\_json](#output\_service\_credentials\_json) | Service credentials json map |
| <a name="output_service_credentials_object"></a> [service\_credentials\_object](#output\_service\_credentials\_object) | Service credentials object |
| <a name="output_version"></a> [version](#output\_version) | Postgresql instance version |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- BEGIN CONTRIBUTING HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
<!-- Source for this readme file: https://github.com/terraform-ibm-modules/common-dev-assets/tree/main/module-assets/ci/module-template-automation -->
<!-- END CONTRIBUTING HOOK -->
