# Financial Services Cloud Profile

This is a profile for PostgreSQL that meets FS Cloud requirements.
It has been scanned by [IBM Code Risk Analyzer (CRA)](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin?topic=code-risk-analyzer-cli-plugin-cra-cli-plugin#terraform-command) and meets all applicable goals with the following exception:
- rule-9b2d8054-bc93-44fd-901b-91f677287e84: Check whether Databases for PostgreSQL network access is restricted to a specific IP range.
  - This is ignored because the CBR locks this down and CRA does not check this

## Note: If no Context Based Restriction(CBR) rules are passed, you must configure Context Based Restrictions externally to be compliant.

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
| <a name="input_backup_encryption_key_crn"></a> [backup\_encryption\_key\_crn](#input\_backup\_encryption\_key\_crn) | The CRN of a Key Protect Key to use for encrypting backups. Take note that Hyper Protect Crypto Services for IBM Cloud® Databases backups is not currently supported. | `string` | n/a | yes |
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | (Optional, list) List of CBR rules to create | <pre>list(object({<br>    description = string<br>    account_id  = string<br>    rule_contexts = list(object({<br>      attributes = optional(list(object({<br>        name  = string<br>        value = string<br>    }))) }))<br>    enforcement_mode = string<br>  }))</pre> | `[]` | no |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | (Optional, Json String) Database Configuration in JSON format. | <pre>object({<br>    max_connections            = optional(number)<br>    max_prepared_transactions  = optional(number)<br>    deadlock_timeout           = optional(number)<br>    effective_io_concurrency   = optional(number)<br>    max_replication_slots      = optional(number)<br>    max_wal_senders            = optional(number)<br>    shared_buffers             = optional(number)<br>    synchronous_commit         = optional(string)<br>    wal_level                  = optional(string)<br>    archive_timeout            = optional(number)<br>    log_min_duration_statement = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_existing_kms_instance_guid"></a> [existing\_kms\_instance\_guid](#input\_existing\_kms\_instance\_guid) | The GUID of the Hyper Protect Crypto service. | `string` | n/a | yes |
| <a name="input_kms_key_crn"></a> [kms\_key\_crn](#input\_kms\_key\_crn) | The root key CRN of a Hyper Protect Crypto Service (HPCS) that you want to use for disk encryption. See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-hpcs&interface=ui for more information on integrating HPCS with PostgreSQL database. | `string` | n/a | yes |
| <a name="input_member_cpu_count"></a> [member\_cpu\_count](#input\_member\_cpu\_count) | CPU allocation required for postgresql database | `string` | `"3"` | no |
| <a name="input_member_disk_mb"></a> [member\_disk\_mb](#input\_member\_disk\_mb) | Disk allocation required for postgresql database | `string` | `"5120"` | no |
| <a name="input_member_memory_mb"></a> [member\_memory\_mb](#input\_member\_memory\_mb) | Memory allocation required for postgresql database | `string` | `"1024"` | no |
| <a name="input_members"></a> [members](#input\_members) | Number of members | `number` | `3` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Postgresql instance | `string` | n/a | yes |
| <a name="input_pg_version"></a> [pg\_version](#input\_pg\_version) | Version of the postgresql instance | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The region postgresql is to be created on. The region must support KYOK. | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the postgresql will be created | `string` | n/a | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | Optional list of tags to be applied to the PostgreSQL database instance. | `list(string)` | `[]` | no |
| <a name="input_skip_iam_authorization_policy"></a> [skip\_iam\_authorization\_policy](#input\_skip\_iam\_authorization\_policy) | Set to true to skip the creation of an IAM authorization policy that permits all PostgreSQL database instances in the provided resource group reader access to the instance specified in the existing\_kms\_instance\_guid variable. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_guid"></a> [guid](#output\_guid) | Postgresql instance guid |
| <a name="output_id"></a> [id](#output\_id) | Postgresql instance id |
| <a name="output_version"></a> [version](#output\_version) | Postgresql instance version |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
