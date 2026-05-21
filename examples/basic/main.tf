##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Postgresql
##############################################################################

module "database" {
  source = "../.."
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source            = "terraform-ibm-modules/icd-postgresql/ibm"
  # version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  resource_group_id   = module.resource_group.resource_group_id
  name                = "${var.prefix}-data-store"
  region              = var.region
  plan                = "standard-gen2"
  postgresql_version  = var.postgresql_version
  access_tags         = var.access_tags
  tags                = var.resource_tags
  service_endpoints   = var.service_endpoints
  member_host_flavor  = var.member_host_flavor
  disk_mb             = "10240"
  deletion_protection = false
  #  configuration = {
  #    shared_buffers             = 32000
  #    max_connections            = 250
  #    max_locks_per_transaction  = 64
  #    max_prepared_transactions  = 0
  #    synchronous_commit         = "local"
  #    effective_io_concurrency   = 12
  #    deadlock_timeout           = 10000
  #    log_connections            = "off"
  #    log_disconnections         = "off"
  #    log_min_duration_statement = 100
  #    tcp_keepalives_idle        = 200
  #    tcp_keepalives_interval    = 50
  #    tcp_keepalives_count       = 6
  #    archive_timeout            = 1000
  #    max_replication_slots      = 10
  #    max_wal_senders            = 20
  #  }
  service_credential_names = [
    {
      name     = "postgresql_admin"
      role     = "Administrator"
      endpoint = "private"
    },
    {
      name     = "postgresql_operator"
      role     = "Operator"
      endpoint = "private"
    },
    {
      name     = "postgresql_viewer"
      role     = "Viewer"
      endpoint = "private"
    },
    {
      name     = "postgresql_editor"
      role     = "Editor"
      endpoint = "private"
    }
  ]
  # users = [
  #   {
  #     name     = "nonexistent"
  #     password = "notreal"
  #   }
  # ]
}
