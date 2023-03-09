# Financial Services Controls - IBM Cloud Databases for ICD PostgreSQL module

This module is a version of the [parent root module](../../) that comes with pre-defined defaults that meet the relevant controls from the [IBM Cloud Framework for Financial Services](https://cloud.ibm.com/docs/framework-financial-services?topic=framework-financial-services-about).

See the accompanying [fscloud example](../../examples/fscloud/) leveraging this module.

The defaults coming with this module have been scanned by [IBM Code Risk Analyzer (CRA)](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin?topic=code-risk-analyzer-cli-plugin-cra-cli-plugin#terraform-command) and the Financial Cloud profile for [Security and Compliance Center](https://cloud.ibm.com/docs/security-compliance?topic=security-compliance-getting-started). They meet all applicable goals.

:exclamation: The financial services framework mandates the application of an inbound network-based allow-list in front of the ICD PostGresql instance. This can be achieved in multiple ways:
- By using the `allowlist` (legacy method) input in the module.
- By using the `cbr_rules` input in the module, which creates a narrow [context-based restriction](https://cloud.ibm.com/docs/account?topic=account-context-restrictions-whatis) rule scoped to the ICD PostGresql instance
- By creating coarse-grained context-based restriction rules (for instance, covering all ICD PostGresql instance in the account) through the [https://github.com/terraform-ibm-modules/terraform-ibm-cbr](terraform-ibm-cbr) module.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_postgresql_db"></a> [postgresql\_db](#module\_postgresql\_db) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowlist"></a> [allowlist](#input\_allowlist) | Set of IP address and description to allowlist in database | <pre>list(object({<br>    address     = optional(string)<br>    description = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_auto_scaling"></a> [auto\_scaling](#input\_auto\_scaling) | (Optional) Configure rules to allow your database to automatically increase its resources. Single block of autoscaling is allowed at once. | <pre>object({<br>    cpu = object({<br>      rate_increase_percent       = optional(number)<br>      rate_limit_count_per_member = optional(number)<br>      rate_period_seconds         = optional(number)<br>      rate_units                  = optional(string)<br>    })<br>    disk = object({<br>      capacity_enabled             = optional(bool)<br>      free_space_less_than_percent = optional(number)<br>      io_above_percent             = optional(number)<br>      io_enabled                   = optional(bool)<br>      io_over_period               = optional(string)<br>      rate_increase_percent        = optional(number)<br>      rate_limit_mb_per_member     = optional(number)<br>      rate_period_seconds          = optional(number)<br>      rate_units                   = optional(string)<br>    })<br>    memory = object({<br>      io_above_percent         = optional(number)<br>      io_enabled               = optional(bool)<br>      io_over_period           = optional(string)<br>      rate_increase_percent    = optional(number)<br>      rate_limit_mb_per_member = optional(number)<br>      rate_period_seconds      = optional(number)<br>      rate_units               = optional(string)<br>    })<br>  })</pre> | <pre>{<br>  "cpu": {},<br>  "disk": {},<br>  "memory": {}<br>}</pre> | no |
| <a name="input_backup_encryption_key_crn"></a> [backup\_encryption\_key\_crn](#input\_backup\_encryption\_key\_crn) | (Optional) The CRN of a key protect key, that you want to use for encrypting disk that holds deployment backups. If null, will use 'key\_protect\_key\_crn' as encryption key. If 'key\_protect\_key\_crn' is also null database is encrypted by using randomly generated keys. | `string` | `null` | no |
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | (Optional, list) List of CBR rules to create | <pre>list(object({<br>    description = string<br>    account_id  = string<br>    rule_contexts = list(object({<br>      attributes = optional(list(object({<br>        name  = string<br>        value = string<br>    }))) }))<br>    enforcement_mode = string<br>  }))</pre> | `[]` | no |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | (Optional, Json String) Database Configuration in JSON format. | <pre>object({<br>    max_connections            = optional(number)<br>    max_prepared_transactions  = optional(number)<br>    deadlock_timeout           = optional(number)<br>    effective_io_concurrency   = optional(number)<br>    max_replication_slots      = optional(number)<br>    max_wal_senders            = optional(number)<br>    shared_buffers             = optional(number)<br>    synchronous_commit         = optional(string)<br>    wal_level                  = optional(string)<br>    archive_timeout            = optional(number)<br>    log_min_duration_statement = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_key_protect_key_crn"></a> [key\_protect\_key\_crn](#input\_key\_protect\_key\_crn) | (Optional) The root key CRN of a Key Management Service like Key Protect or Hyper Protect Crypto Service (HPCS) that you want to use for disk encryption. If `null`, database is encrypted by using randomly generated keys. See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok for current list of supported regions for BYOK | `string` | `null` | no |
| <a name="input_member_cpu_count"></a> [member\_cpu\_count](#input\_member\_cpu\_count) | CPU allocation required for postgresql database | `string` | `"3"` | no |
| <a name="input_member_disk_mb"></a> [member\_disk\_mb](#input\_member\_disk\_mb) | Disk allocation required for postgresql database | `string` | `"5120"` | no |
| <a name="input_member_memory_mb"></a> [member\_memory\_mb](#input\_member\_memory\_mb) | Memory allocation required for postgresql database | `string` | `"1024"` | no |
| <a name="input_members"></a> [members](#input\_members) | Number of members | `number` | `3` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Postgresql instance | `string` | n/a | yes |
| <a name="input_pg_version"></a> [pg\_version](#input\_pg\_version) | Version of the postgresql instance | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The region postgresql is to be created on. The region must support BYOK if key\_protect\_key\_crn is used | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the postgresql will be created | `string` | n/a | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | Optional list of tags to be added to created resources | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_guid"></a> [guid](#output\_guid) | Postgresql instance guid |
| <a name="output_id"></a> [id](#output\_id) | Postgresql instance id |
| <a name="output_version"></a> [version](#output\_version) | Postgresql instance version |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
