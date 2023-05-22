# Profile for IBM Cloud Framework for Financial Services

This code is a version of the [parent root module](../../) that includes a default configuration that complies with the relevant controls from the [IBM Cloud Framework for Financial Services](https://cloud.ibm.com/docs/framework-financial-services?topic=framework-financial-services-about). See the [Example for IBM Cloud Framework for Financial Services](/examples/fscloud/) for logic that uses this module.

The default values in this profile were scanned by [IBM Code Risk Analyzer (CRA)](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin?topic=code-risk-analyzer-cli-plugin-cra-cli-plugin#terraform-command) for compliance with the IBM Cloud Framework for Financial Services profile that is specified by the IBM Security and Compliance Center. The scan passed for all applicable goals with one exception:

> rule-beb7b289-706b-4dc0-b01d-b1d15d4331e3: Check whether Databases for PostgreSQL network access is restricted to a specific IP range.

The IBM Cloud Framework for Financial Services mandates the application of an inbound network-based allowlist in front of the IBM Cloud Databases for (ICD) PostgreSQL instance. You can comply with this requirement by using the `cbr_rules` variable in the module, which can be used to create a narrow context-based restriction rule that is scoped to the PostgreSQL instance. CRA does not currently support checking for context-based restrictions, so you can ignore the failing rule after you set the context-based restriction.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.49.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_postgresql_db"></a> [postgresql\_db](#module\_postgresql\_db) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_scaling"></a> [auto\_scaling](#input\_auto\_scaling) | Optional rules to allow the database to increase resources in response to usage. Only a single autoscaling block is allowed. Make sure you understand the effects of autoscaling, especially for production environments. See https://ibm.biz/autoscaling-considerations in the IBM Cloud Docs. | <pre>object({<br>    disk = object({<br>      capacity_enabled             = optional(bool, false)<br>      free_space_less_than_percent = optional(number, 10)<br>      io_above_percent             = optional(number, 90)<br>      io_enabled                   = optional(bool, false)<br>      io_over_period               = optional(string, "15m")<br>      rate_increase_percent        = optional(number, 10)<br>      rate_limit_mb_per_member     = optional(number, 3670016)<br>      rate_period_seconds          = optional(number, 900)<br>      rate_units                   = optional(string, "mb")<br>    })<br>    memory = object({<br>      io_above_percent         = optional(number, 90)<br>      io_enabled               = optional(bool, false)<br>      io_over_period           = optional(string, "15m")<br>      rate_increase_percent    = optional(number, 10)<br>      rate_limit_mb_per_member = optional(number, 114688)<br>      rate_period_seconds      = optional(number, 900)<br>      rate_units               = optional(string, "mb")<br>    })<br>  })</pre> | `null` | no |
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | (Optional, list) List of CBR rules to create | <pre>list(object({<br>    description = string<br>    account_id  = string<br>    rule_contexts = list(object({<br>      attributes = optional(list(object({<br>        name  = string<br>        value = string<br>    }))) }))<br>    enforcement_mode = string<br>  }))</pre> | `[]` | no |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | Database configuration. | <pre>object({<br>    max_connections            = optional(number)<br>    max_prepared_transactions  = optional(number)<br>    deadlock_timeout           = optional(number)<br>    effective_io_concurrency   = optional(number)<br>    max_replication_slots      = optional(number)<br>    max_wal_senders            = optional(number)<br>    shared_buffers             = optional(number)<br>    synchronous_commit         = optional(string)<br>    wal_level                  = optional(string)<br>    archive_timeout            = optional(number)<br>    log_min_duration_statement = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_existing_kms_instance_guid"></a> [existing\_kms\_instance\_guid](#input\_existing\_kms\_instance\_guid) | The GUID of the Hyper Protect Crypto Services instance. | `string` | n/a | yes |
| <a name="input_kms_key_crn"></a> [kms\_key\_crn](#input\_kms\_key\_crn) | The root key CRN of the Hyper Protect Crypto Service (HPCS) to use for disk encryption. | `string` | n/a | yes |
| <a name="input_member_cpu_count"></a> [member\_cpu\_count](#input\_member\_cpu\_count) | Allocated dedicated CPU per member. For shared CPU, set to 0. For more information, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling | `number` | `3` | no |
| <a name="input_member_disk_mb"></a> [member\_disk\_mb](#input\_member\_disk\_mb) | Allocated disk per member. For more information, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling | `number` | `5120` | no |
| <a name="input_member_memory_mb"></a> [member\_memory\_mb](#input\_member\_memory\_mb) | Allocated memory per member. For more information, see https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-resources-scaling | `number` | `1024` | no |
| <a name="input_members"></a> [members](#input\_members) | Allocated number of members. Members can be scaled up but not down. | `number` | `2` | no |
| <a name="input_name"></a> [name](#input\_name) | The name to give the Postgresql instance. | `string` | n/a | yes |
| <a name="input_pg_version"></a> [pg\_version](#input\_pg\_version) | Version of the PostgreSQL instance. If no value is passed, the current preferred version of IBM Cloud Databases is used. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where you want to deploy your instance. Must be the same region as the Hyper Protect Crypto Services instance. | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the PostgreSQL instance will be created. | `string` | n/a | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | Optional list of tags to be added to the PostgreSQL instance. | `list(string)` | `[]` | no |
| <a name="input_service_credential_names"></a> [service\_credential\_names](#input\_service\_credential\_names) | Map of name, role for service credentials that you want to create for the database | `map(string)` | `{}` | no |
| <a name="input_skip_iam_authorization_policy"></a> [skip\_iam\_authorization\_policy](#input\_skip\_iam\_authorization\_policy) | Set to true to skip the creation of an IAM authorization policy that permits all PostgreSQL database instances in the resource group to read the encryption key from the Hyper Protect Crypto Services instance. The HPCS instance is passed in through the var.existing\_kms\_instance\_guid variable. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crn"></a> [crn](#output\_crn) | Postgresql instance crn |
| <a name="output_guid"></a> [guid](#output\_guid) | Postgresql instance guid |
| <a name="output_id"></a> [id](#output\_id) | Postgresql instance id |
| <a name="output_version"></a> [version](#output\_version) | Postgresql instance version |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
