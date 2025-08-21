# Configuring complex inputs in Databases for PostgreSQL

Several optional input variables in the IBM Cloud [Databases for PostgreSQL deployable architecture](https://cloud.ibm.com/catalog#deployable_architecture) use complex object types. You specify these inputs when you configure deployable architecture.

- [Service credentials](#svc-credential-name) (`service_credential_names`)
- [Users](#users) (`users`)
- [Autoscaling](#autoscaling) (`auto_scaling`)
- [Configuration](#configuration) (`configuration`)

## Service credentials <a name="svc-credential-name"></a>

You can specify a set of IAM credentials to connect to the database with the `service_credential_names` input variable. Include a credential name and IAM service role for each key-value pair. Each role provides a specific level of access to the database. For more information, see [Adding and viewing credentials](https://cloud.ibm.com/docs/account?topic=account-service_credentials&interface=ui).

- Variable name: `service_credential_names`.
- Type: A map. The key is the name of the service credential. The value is the role that is assigned to that credential.
- Default value: An empty map (`{}`).

### Options for service_credential_names

- Key (required): The name of the service credential.
- Value (required): The IAM service role that is assigned to the credential. For more information, see [IBM Cloud IAM roles](https://cloud.ibm.com/docs/account?topic=account-userroles).

### Example service credential

```hcl
  {
      "postgres_admin" : "Administrator",
      "postgres_reader" : "Operator",
      "postgres_viewer" : "Viewer",
      "postgres_editor" : "Editor"
  }
```

## Service credential secrets <a name="service-credential-secrets"></a>

When you add an IBM Database for PostgreSQL deployable architecture from the IBM Cloud catalog to IBM Cloud Project , you can configure service credentials. In edit mode for the projects configuration, from the configure panel click the optional tab.

To enter a custom value, use the edit action to open the "Edit Array" panel. Add the service credential secrets configurations to the array here.

In the configuration, specify the secret group name, whether it already exists or will be created and include all the necessary service credential secrets that need to be created within that secret group.

 [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/sm_service_credentials_secret) about service credential secrets.

- Variable name: `service_credential_secrets`.
- Type: A list of objects that represent a service credential secret groups and secrets
- Default value: An empty list (`[]`)

### Options for service_credential_secrets

- `secret_group_name` (required): A unique human-readable name that identifies this service credential secret group.
- `secret_group_description` (optional, default = `null`): A human-readable description for this secret group.
- `existing_secret_group`: (optional, default = `false`): Set to true, if secret group name provided in the variable `secret_group_name` already exists.
- `service_credentials`: (optional, default = `[]`): A list of object that represents a service credential secret.

#### Options for service_credentials

- `secret_name`: (required): A unique human-readable name of the secret to create.
- `service_credentials_source_service_role_crn`: (required): The CRN of the role to give the service credential in the IBM Cloud Database service. Service credentials role CRNs can be found at https://cloud.ibm.com/iam/roles, select the IBM Cloud Database and select the role.
- `secret_labels`: (optional, default = `[]`): Labels of the secret to create. Up to 30 labels can be created. Labels can be 2 - 30 characters, including spaces. Special characters that are not permitted include the angled brackets (<>), comma (,), colon (:), ampersand (&), and vertical pipe character (|).
- `secret_auto_rotation`: (optional, default = `true`): Whether to configure automatic rotation of service credential.
- `secret_auto_rotation_unit`: (optional, default = `day`): Specifies the unit of time for rotation of a secret. Acceptable values are `day` or `month`.
- `secret_auto_rotation_interval`: (optional, default = `89`): Specifies the rotation interval for the rotation unit.
- `service_credentials_ttl`: (optional, default = `7776000`): The time-to-live (TTL) to assign to generated service credentials (in seconds).
- `service_credential_secret_description`: (optional, default = `null`): Description of the secret to create.

The following example includes all the configuration options for four service credentials and two secret groups.
```hcl
[
  {
    "secret_group_name": "sg-1"
    "existing_secret_group": true
    "service_credentials": [                                              # pragma: allowlist secret
      {
        "secret_name": "cred-1"
        "service_credentials_source_service_role_crn":  "crn:v1:bluemix:public:iam::::role:Editor"
        "secret_labels": ["test-editor-1", "test-editor-2"]
        "secret_auto_rotation": true
        "secret_auto_rotation_unit": "day"
        "secret_auto_rotation_interval": 89
        "service_credentials_ttl": 7776000
        "service_credential_secret_description": "sample description"
      },
      {
        "secret_name": "cred-2"
        "service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Viewer"
      }
    ]
  },
  {
    "secret_group_name": "sg-2"
    "service_credentials": [                                              # pragma: allowlist secret
      {
        "secret_name": "cred-3"
        "service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Viewer"
      }
    ]
  }
]
```

## Users <a name="users"></a>

If you can't use the IAM-enabled `service_credential_names` input variable for access, you can create users and roles directly in the database. For more information, see [Managing users and roles](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-user-management&interface=ui).

:exclamation: **Important:** The `users` input contains sensitive information (the user's password).

- Variable name: `users`.
- Type: A list of objects that represent a user
- Default value: An empty list (`[]`)

### Options for users

- `name` (required): The username for the user account.
- `password` (required): The password for the user account in the range of 10-32 characters.
- `type` (required): The user type. The "type" field is required to generate the connection string for the outputs.
- `role`: The user role. The role determines the user's access level and permissions.

### Example users

```hcl
[
  {
    "name": "pg_admin",
    "password": "securepassword123",
    "type": "database",
  },
  {
    "name": "pg_reader",
    "password": "readpassword123",
    "type": "ops_manager"
  }
]
```

## Autoscaling <a name="autoscaling"></a>

The Autoscaling variable sets the rules for how database increase resources in response to usage. Make sure you understand the effects of autoscaling, especially for production environments. For more information, see [Autoscaling](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-autoscaling&interface=ui#autoscaling-consider).

- Variable name: `auto_scaling`
- Type: An object with `disk` and `memory` configurations

### Disk options for auto_scaling

Disk autoscaling specifies thresholds when scaling can occur based on disk usage, disk I/O utilization, or both.

The disk object in the `auto_scaling` input contains the following options. All options are optional.

- `capacity_enabled`: Whether disk capacity autoscaling is enabled (default: `false`).
- `free_space_less_than_percent`: The percentage of free disk space that triggers autoscaling (default: `10`).
- `io_above_percent`: The percentage of I/O (input/output) disk usage that triggers autoscaling (default: `90`).
- `io_enabled`: Indicates whether IO-based autoscaling is enabled (default: `false`).
- `io_over_period`: How long I/O usage is evaluated for autoscaling (default: `"15m"` (15 minutes)).
- `rate_increase_percent`: The percentage increase in disk capacity when autoscaling is triggered (default: `10`).
- `rate_limit_mb_per_member`: The limit in megabytes for the rate of disk increase per member (default: `3670016`).
- `rate_period_seconds`: How long (in seconds) the rate limit is applied for disk (default: `900` (15 minutes)).
- `rate_units`: The units to use for the rate increase (default: `"mb"` (megabytes)).

### Memory options for auto_scaling

The memory object within auto_scaling contains the following options. All options are optional.

- `io_above_percent`: The percentage of I/O memory usage that triggers autoscaling (default: `90`).
- `io_enabled`: Whether IO-based autoscaling for memory is enabled (default: `false`).
- `io_over_period`: How long I/O usage is evaluated for memory autoscaling (default: `"15m"` (15 minutes)).
- `rate_increase_percent`: The percentage increase in memory capacity that triggers autoscaling (default: `10`).
- `rate_limit_mb_per_member`: The limit in megabytes for the rate of memory increase per member (default: `114688`).
- `rate_period_seconds`: How long (in seconds) the rate limit is applied for memory (default: `900` (15 minutes)).
- `rate_units`: The memory size units to use for the rate increase (default: `"mb"` (megabytes)).

### Example autoscaling

The following example shows values for both disk and memory for the `auto_scaling` input.

```hcl
{
  "disk": {
      "capacity_enabled": true,
      "free_space_less_than_percent": 15,
      "io_above_percent": 85,
      "io_enabled": true,
      "io_over_period": "15m",
      "rate_increase_percent": 15,
      "rate_limit_mb_per_member": 3670016,
      "rate_period_seconds": 900,
      "rate_units": "mb"
  },
  "memory": {
      "io_above_percent": 90,
      "io_enabled": true,
      "io_over_period": "15m",
      "rate_increase_percent": 10,
      "rate_limit_mb_per_member": 114688,
      "rate_period_seconds": 900,
      "rate_units": "mb"
  }
}
```

## Configuration  <a name="configuration"></a>

The Configuration variable tunes the PostgreSQL database to suit different use case. For more information, see [Configuration](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-changing-configuration&interface=cli).

- Variable name: `configuration`
- Type: An object with multiple attributes i.e.  `shared_buffers`, `max_connections`, `max_prepared_transactions`, `synchronous_commit` , `effective_io_concurrency` , `deadlock_timeout`, `log_connections`, `log_disconnections`, `log_min_duration_statement`, `tcp_keepalives_idle`, `tcp_keepalives_interval`, `tcp_keepalives_count`, `archive_timeout`, `wal_level`, `max_replication_slots` and `max_wal_senders`

### Options for configuration

The configuration object in the input contains the following options categorized under three sections. All options are optional.

**1. Memory Settings. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-changing-configuration&interface=cli#mem-settings).**

- `shared_buffers`: Determines the amount of memory the database server uses for shared memory buffers. Larger values can improve performance by reducing disk I/O. (default: `32000`).

**2. General Settings. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-changing-configuration&interface=cli#gen-settings).**

- `max_connections`: Sets the maximum number of concurrent connections to the database. Increasing this value allows more users to connect simultaneously but requires more memory. (default: `115`)
- `max_prepared_transactions`: Specifies the maximum number of transactions that can be in the prepared state simultaneously. This is important for applications using two-phase commit. (default: `0`)
- `synchronous_commit`: Determines whether the server commits are synchronous or asynchronous. Setting to off can improve performance but at the risk of losing recent transactions in the event of a crash. (default: `local`)
- `effective_io_concurrency`: Configures the number of concurrent disk I/O operations PostgreSQL can handle, improving performance for SSDs and RAID arrays. (default: `12`)
- `deadlock_timeout`: Specifies the amount of time to wait on a lock before checking for a deadlock condition. Shorter times can help detect deadlocks faster. (default: `10000`)
- `log_connections`: When enabled, logs each successful connection to the server. Useful for monitoring and debugging. (default: `off`)
- `log_disconnections`: When enabled, logs the end of each session, including the duration. Helpful for tracking user activity. (default: `off`)
- `log_min_duration_statement`: Logs the execution time of each statement that exceeds the specified duration. Useful for identifying slow queries. (default: `100`)
- `tcp_keepalives_idle`: Sets the amount of time between TCP keep-alive messages when no data has been sent. Helps to detect dead TCP connections. (default: `111`)
- `tcp_keepalives_interval`: Specifies the interval between TCP keep-alive messages. Important for maintaining long-lived idle connections. (default: `15`)
- `tcp_keepalives_count`: Determines the number of TCP keep-alive messages sent before the server decides the connection is dead. (default: `6`)

**3. WAL Settings. [Learn more](https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-changing-configuration&interface=cli#wal-settings).**

- `archive_timeout`: Forces a switch to the next WAL file if no new file has been generated within the specified time. Useful for ensuring regular WAL archiving. (default: `1800`)
- `wal_level`: Sets the level of information written to the WAL. Higher levels, like replica or logical, are required for replication and logical decoding. (default: `replica`)
- `max_replication_slots`: Specifies the maximum number of replication slots, which are used for streaming replication and logical decoding. (default: `10`)
- `max_wal_senders`: Determines the maximum number of concurrent WAL sender processes for streaming replication. Increasing this allows more standby servers to connect. (default: `12`)

### Example configuration

The following example shows values for the `configuration` input.

```hcl
{
    "shared_buffers": 32000,
    "max_connections": 115,
    "max_prepared_transactions": 0,
    "synchronous_commit": "local",
    "effective_io_concurrency": 12,
    "deadlock_timeout": 10000,
    "log_connections": "on",
    "log_disconnections": "on",
    "log_min_duration_statement": 100,
    "tcp_keepalives_idle": 111,
    "tcp_keepalives_interval": 15,
    "tcp_keepalives_count": 6,
    "archive_timeout": 1800,
    "max_replication_slots": 10,
    "max_wal_senders": 12
}
```
