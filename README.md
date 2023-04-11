<!-- BEGIN MODULE HOOK -->

<!-- Update the title to match the module name and add a description -->
# IBM Cloud Databases for ICD Postgresql module
<!-- UPDATE BADGE: Update the link for the following badge-->
[![Stable (With quality checks)](https://img.shields.io/badge/Status-Stable%20(With%20quality%20checks)-green?style=plastic)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![Build status](https://github.com/terraform-ibm-modules/terraform-ibm-module-template/actions/workflows/ci.yml/badge.svg)](https://github.com/terraform-ibm-modules/terraform-ibm-module-template/actions/workflows/ci.yml)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-icd-postgresql?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)


## Usage

> WARNING: **This module does not support major version upgrade or updates to encryption and backup encryption keys**: To upgrade version create a new postgresql instance with the updated version and follow the [Upgrading PostgreSQL docs](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-upgrading&interface=cli)

> NOTE: The database encryption for backups supports only Key Protect keys, not the Hyper Protect Crypto Key at the moment. More info: https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs&interface=cli

```hcl
module "postgresql_db" {
  # replace main with version
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-icd-postgresql?ref=main"
  admin_password    = var.admin_password
  resource_group_id = module.resource_group.resource_group_id
  name              = var.name
}
```

## Required IAM access policies

You need the following permissions to run this module.

- Account Management
    - **Databases for PostgreSQL** service
        - `Editor` role access
<!-- END MODULE HOOK -->

## Read-only Replica considerations

- **There are additional considerations when setting the variables in the read-only-replica example.** Refer [configuring read-only replicas](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-read-only-replicas). For load balancing multiple read only replicas are suggested/required.

| Variable | Description | Type | Default |
|------|---------|---------|:--------:|
| <a name="input_pg_version"></a> [pg_version](#input\_pg\_version)| A read-only replica must be the same major version as its leader.|`string` | `null` |
|  <a name="input_region"></a> [region](#input\_region)| The read-only replica can exist in the same region as the source formation or in different one, enabling your data to be replicated across regions. | `string` | `"us-south"` |
| <a name="input_read_only_replicas"></a> [read_only_replicas](#input\_read\_only\_replicas)| There is a limit of five read-only replicas per leader.|`number` | `1` |
| <a name="input_member_memory_mb"></a> [member\_memory\_mb](#input\_member\_memory\_mb) | The minimum RAM size of a read-only replica is 3 GB |`string` | `"3072"` |
| <a name="input_member_disk_mb"></a> [member\_disk\_mb](#input\_member\_disk\_mb)  | The minimum disk size of a read-only replica is 15 GB |`string` | `"15360"` |
| <a name="input_member_cpu_count"></a> [member\_cpu\_count](#input\_member\_cpu\_count) | The minimum CPU allocation required for read-only replica is 9 | `string` | `"9"` |
| <a name="input_members"></a> [members](#input\_members)| A read-only replica is a deployment with single data member and does not have any internal high availability.|`number` | `1` |

<!-- BEGIN EXAMPLES HOOK -->
## Examples

- [ Autoscale example](examples/autoscale)
- [ Restore from backup example](examples/backup)
- [ Complete example with byok encryption, CBR rules and storing credentials in secrets manager](examples/complete)
- [ Default example](examples/default)
- [ Financial Services Cloud profile example](examples/fscloud)
- [ Point in time recovery example (PITR)](examples/pitr)
- [ Replica example](examples/replica)
<!-- END EXAMPLES HOOK -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.49.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cbr_rule"></a> [cbr\_rule](#module\_cbr\_rule) | git::https://github.com/terraform-ibm-modules/terraform-ibm-cbr//cbr-rule-module | v1.2.0 |

## Resources

| Name | Type |
|------|------|
| [ibm_database.postgresql_db](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database) | resource |
| [ibm_iam_authorization_policy.kms_policy](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [ibm_resource_key.service_credentials](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowlist"></a> [allowlist](#input\_allowlist) | Set of IP address and description to allowlist in database | <pre>list(object({<br>    address     = optional(string)<br>    description = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_auto_scaling"></a> [auto\_scaling](#input\_auto\_scaling) | (Optional) Configure rules to allow your database to automatically increase its resources. Single block of autoscaling is allowed at once. | <pre>object({<br>    cpu = object({<br>      rate_increase_percent       = optional(number, 10)<br>      rate_limit_count_per_member = optional(number, 20)<br>      rate_period_seconds         = optional(number, 900)<br>      rate_units                  = optional(string, "count")<br>    })<br>    disk = object({<br>      capacity_enabled             = optional(bool, false)<br>      free_space_less_than_percent = optional(number, 10)<br>      io_above_percent             = optional(number, 90)<br>      io_enabled                   = optional(bool, false)<br>      io_over_period               = optional(string, "15m")<br>      rate_increase_percent        = optional(number, 10)<br>      rate_limit_mb_per_member     = optional(number, 3670016)<br>      rate_period_seconds          = optional(number, 900)<br>      rate_units                   = optional(string, "mb")<br>    })<br>    memory = object({<br>      io_above_percent         = optional(number, 90)<br>      io_enabled               = optional(bool, false)<br>      io_over_period           = optional(string, "15m")<br>      rate_increase_percent    = optional(number, 10)<br>      rate_limit_mb_per_member = optional(number, 114688)<br>      rate_period_seconds      = optional(number, 900)<br>      rate_units               = optional(string, "mb")<br>    })<br>  })</pre> | `null` | no |
| <a name="input_backup_crn"></a> [backup\_crn](#input\_backup\_crn) | The CRN of a backup resource to restore from. The backup is created by a database deployment with the same service ID. The backup is loaded after provisioning and the new deployment starts up that uses that data. A backup CRN is in the format crn:v1:<…>:backup:. If omitted, the database is provisioned empty. | `string` | `null` | no |
| <a name="input_backup_encryption_key_crn"></a> [backup\_encryption\_key\_crn](#input\_backup\_encryption\_key\_crn) | (Optional) The CRN of a Key Protect Key to use for encrypting backups. If left null, the value passed for the 'kms\_key\_crn' variable will be used. Take note that Hyper Protect Crypto Services for IBM Cloud® Databases backups is not currently supported. | `string` | `null` | no |
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | (Optional, list) List of CBR rules to create | <pre>list(object({<br>    description = string<br>    account_id  = string<br>    rule_contexts = list(object({<br>      attributes = optional(list(object({<br>        name  = string<br>        value = string<br>    }))) }))<br>    enforcement_mode = string<br>  }))</pre> | `[]` | no |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | (Optional, Json String) Database Configuration in JSON format. | <pre>object({<br>    max_connections            = optional(number)<br>    max_prepared_transactions  = optional(number)<br>    deadlock_timeout           = optional(number)<br>    effective_io_concurrency   = optional(number)<br>    max_replication_slots      = optional(number)<br>    max_wal_senders            = optional(number)<br>    shared_buffers             = optional(number)<br>    synchronous_commit         = optional(string)<br>    wal_level                  = optional(string)<br>    archive_timeout            = optional(number)<br>    log_min_duration_statement = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_existing_kms_instance_guid"></a> [existing\_kms\_instance\_guid](#input\_existing\_kms\_instance\_guid) | The GUID of the Hyper Protect or Key Protect instance in which the key specified in var.kms\_key\_crn is coming from. Only required if skip\_iam\_authorization\_policy is false | `string` | `null` | no |
| <a name="input_kms_key_crn"></a> [kms\_key\_crn](#input\_kms\_key\_crn) | (Optional) The root key CRN of a Key Management Service like Key Protect or Hyper Protect Crypto Service (HPCS) that you want to use for disk encryption. If `null`, database is encrypted by using randomly generated keys. See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok for current list of supported regions for BYOK | `string` | `null` | no |
| <a name="input_member_cpu_count"></a> [member\_cpu\_count](#input\_member\_cpu\_count) | CPU allocation required for postgresql database | `string` | `"3"` | no |
| <a name="input_member_disk_mb"></a> [member\_disk\_mb](#input\_member\_disk\_mb) | Disk allocation required for postgresql database | `string` | `"5120"` | no |
| <a name="input_member_memory_mb"></a> [member\_memory\_mb](#input\_member\_memory\_mb) | Memory allocation required for postgresql database | `string` | `"1024"` | no |
| <a name="input_members"></a> [members](#input\_members) | Number of members | `number` | `3` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Postgresql instance | `string` | n/a | yes |
| <a name="input_pg_version"></a> [pg\_version](#input\_pg\_version) | Version of the postgresql instance | `string` | `null` | no |
| <a name="input_pitr_id"></a> [pitr\_id](#input\_pitr\_id) | (Optional) The ID of the postgresql instance that you want to recover back to. Here ID of the postgresql instance is expected to be up and in running state. | `string` | `null` | no |
| <a name="input_pitr_time"></a> [pitr\_time](#input\_pitr\_time) | (Optional) The timestamp in UTC format (%Y-%m-%dT%H:%M:%SZ) that you want to restore to. To retrieve the timestamp, run the command (ibmcloud cdb postgresql earliest-pitr-timestamp <deployment name or CRN>) | `string` | `null` | no |
| <a name="input_plan_validation"></a> [plan\_validation](#input\_plan\_validation) | Enable or disable validating the database parameters for postgres during the plan phase | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | The region postgresql is to be created on. The region must support BYOK region if Key Protect Key is used or KYOK region if Hyper Protect Crypto Service (HPCS) is used. | `string` | `"us-south"` | no |
| <a name="input_remote_leader_crn"></a> [remote\_leader\_crn](#input\_remote\_leader\_crn) | The CRN of the leader database to make the replica(read-only) deployment. | `string` | `null` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the postgresql will be created | `string` | n/a | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | Optional list of tags to be added to created resources | `list(string)` | `[]` | no |
| <a name="input_service_credential_names"></a> [service\_credential\_names](#input\_service\_credential\_names) | Map of name, role for service credentials that you want to create for the database | `map(string)` | `{}` | no |
| <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints) | Sets the endpoint of the Postgresql instance, valid values are 'public', 'private', or 'public-and-private' | `string` | `"private"` | no |
| <a name="input_skip_iam_authorization_policy"></a> [skip\_iam\_authorization\_policy](#input\_skip\_iam\_authorization\_policy) | Set to true to skip the creation of an IAM authorization policy that permits all PostgreSQL database instances in the given Resource group to read the encryption key from the Hyper Protect or Key Protect instance in `existing_kms_instance_guid`. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cbr_rule_ids"></a> [cbr\_rule\_ids](#output\_cbr\_rule\_ids) | CBR rule ids created to restrict Postgresql |
| <a name="output_crn"></a> [crn](#output\_crn) | Postgresql instance crn |
| <a name="output_guid"></a> [guid](#output\_guid) | Postgresql instance guid |
| <a name="output_id"></a> [id](#output\_id) | Postgresql instance id |
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
