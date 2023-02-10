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
<!-- BEGIN EXAMPLES HOOK -->
## Examples

- [ Autoscale example](examples/autoscale)
- [ Complete example with byok encryption, CBR rules and storing credentials in secrets manager](examples/complete)
- [ Default example](examples/default)
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
| <a name="module_cbr_rule"></a> [cbr\_rule](#module\_cbr\_rule) | git::https://github.com/terraform-ibm-modules/terraform-ibm-cbr//cbr-rule-module | v1.1.2 |

## Resources

| Name | Type |
|------|------|
| [ibm_database.postgresql_db](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/database) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowlist"></a> [allowlist](#input\_allowlist) | Set of IP address and description to allowlist in database | <pre>list(object({<br>    address     = optional(string)<br>    description = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_auto_scaling"></a> [auto\_scaling](#input\_auto\_scaling) | (Optional) Configure rules to allow your database to automatically increase its resources. Single block of autoscaling is allowed at once. | <pre>object({<br>    cpu = object({<br>      rate_increase_percent       = optional(number)<br>      rate_limit_count_per_member = optional(number)<br>      rate_period_seconds         = optional(number)<br>      rate_units                  = optional(string)<br>    })<br>    disk = object({<br>      capacity_enabled             = optional(bool)<br>      free_space_less_than_percent = optional(number)<br>      io_above_percent             = optional(number)<br>      io_enabled                   = optional(bool)<br>      io_over_period               = optional(string)<br>      rate_increase_percent        = optional(number)<br>      rate_limit_mb_per_member     = optional(number)<br>      rate_period_seconds          = optional(number)<br>      rate_units                   = optional(string)<br>    })<br>    memory = object({<br>      io_above_percent         = optional(number)<br>      io_enabled               = optional(bool)<br>      io_over_period           = optional(string)<br>      rate_increase_percent    = optional(number)<br>      rate_limit_mb_per_member = optional(number)<br>      rate_period_seconds      = optional(number)<br>      rate_units               = optional(string)<br>    })<br>  })</pre> | <pre>{<br>  "cpu": {},<br>  "disk": {},<br>  "memory": {}<br>}</pre> | no |
| <a name="input_backup_encryption_key_crn"></a> [backup\_encryption\_key\_crn](#input\_backup\_encryption\_key\_crn) | (Optional) The CRN of a key protect key, that you want to use for encrypting disk that holds deployment backups. If null, will use 'key\_protect\_key\_crn' as encryption key. If 'key\_protect\_key\_crn' is also null database is encrypted by using randomly generated keys. | `string` | `null` | no |
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | (Optional, list) List of CBR rules to create, if operations is not set it will default to api-type:data-plane | <pre>list(object({<br>    description = string<br>    account_id  = string<br>    rule_contexts = list(object({<br>      attributes = optional(list(object({<br>        name  = string<br>        value = string<br>    }))) }))<br>    enforcement_mode = string<br>    tags = optional(list(object({<br>      name  = string<br>      value = string<br>    })))<br>    operations = optional(list(object({<br>      api_types = list(object({<br>        api_type_id = string<br>      }))<br>    })))<br>  }))</pre> | `[]` | no |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | (Optional, Json String) Database Configuration in JSON format. | <pre>object({<br>    max_connections            = optional(number)<br>    max_prepared_transactions  = optional(number)<br>    deadlock_timeout           = optional(number)<br>    effective_io_concurrency   = optional(number)<br>    max_replication_slots      = optional(number)<br>    max_wal_senders            = optional(number)<br>    shared_buffers             = optional(number)<br>    synchronous_commit         = optional(string)<br>    wal_level                  = optional(string)<br>    archive_timeout            = optional(number)<br>    log_min_duration_statement = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_key_protect_key_crn"></a> [key\_protect\_key\_crn](#input\_key\_protect\_key\_crn) | (Optional) The root key CRN of a Key Management Service like Key Protect or Hyper Protect Crypto Service (HPCS) that you want to use for disk encryption. If `null`, database is encrypted by using randomly generated keys. See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok for current list of supported regions for BYOK | `string` | `null` | no |
| <a name="input_member_cpu_count"></a> [member\_cpu\_count](#input\_member\_cpu\_count) | CPU allocation required for postgresql database | `string` | `"3"` | no |
| <a name="input_member_disk_mb"></a> [member\_disk\_mb](#input\_member\_disk\_mb) | Disk allocation required for postgresql database | `string` | `"5120"` | no |
| <a name="input_member_memory_mb"></a> [member\_memory\_mb](#input\_member\_memory\_mb) | Memory allocation required for postgresql database | `string` | `"1024"` | no |
| <a name="input_members"></a> [members](#input\_members) | Number of members | `number` | `3` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Postgresql instance | `string` | n/a | yes |
| <a name="input_pg_version"></a> [pg\_version](#input\_pg\_version) | Version of the postgresql instance | `string` | `null` | no |
| <a name="input_plan_validation"></a> [plan\_validation](#input\_plan\_validation) | Enable or disable validating the database parameters for postgres during the plan phase | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | The region postgresql is to be created on. The region must support BYOK if key\_protect\_key\_crn is used | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the postgresql will be created | `string` | n/a | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | Optional list of tags to be added to created resources | `list(string)` | `[]` | no |
| <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints) | Sets the endpoint of the Postgresql instance, valid values are 'public', 'private', or 'public-and-private' | `string` | `"private"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | Postgresl instance id |
| <a name="output_version"></a> [version](#output\_version) | Postgresql instance version |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- BEGIN CONTRIBUTING HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
<!-- Source for this readme file: https://github.com/terraform-ibm-modules/common-dev-assets/tree/main/module-assets/ci/module-template-automation -->
<!-- END CONTRIBUTING HOOK -->
