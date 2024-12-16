##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Key Protect All Inclusive
##############################################################################

locals {
  data_key_name    = "${var.prefix}-pg"
  backups_key_name = "${var.prefix}-pg-backups"
}

module "key_protect_all_inclusive" {
  source            = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version           = "4.18.1"
  resource_group_id = module.resource_group.resource_group_id
  # Note: Database instance and Key Protect must be created in the same region when using BYOK
  # See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  keys = [
    {
      key_ring_name = "icd-pg"
      keys = [
        {
          key_name     = local.data_key_name
          force_delete = true
        },
        {
          key_name     = local.backups_key_name
          force_delete = true
        }
      ]
    }
  ]
}

##############################################################################
# Get Cloud Account ID
##############################################################################

data "ibm_iam_account_settings" "iam_account_settings" {
}

##############################################################################
# VPC
##############################################################################

module "vpc" {
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "7.19.1"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  name              = "vpc"
  tags              = var.resource_tags
}

##############################################################################
# Security group
##############################################################################

resource "ibm_is_security_group" "sg1" {
  name = "${var.prefix}-sg1"
  vpc  = module.vpc.vpc_id
}

# wait 30 secs after security group is destroyed before destroying VPE to workaround race condition
resource "time_sleep" "wait_30_seconds" {
  depends_on       = [ibm_is_security_group.sg1]
  destroy_duration = "30s"
}

##############################################################################
# Create CBR Zone
##############################################################################

module "cbr_zone" {
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-zone-module"
  version          = "1.29.0"
  name             = "${var.prefix}-VPC-network-zone"
  zone_description = "CBR Network zone representing VPC"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type  = "vpc", # to bind a specific vpc to the zone
    value = module.vpc.vpc_crn,
  }]
}

##############################################################################
# Postgres Instance
##############################################################################

module "postgresql_db" {
  source            = "../../"
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-postgres"
  region            = var.region
  pg_version        = var.pg_version
  admin_pass        = var.admin_pass
  users             = var.users
  # Example of how to use different KMS keys for data and backups
  use_ibm_owned_encryption_key = false
  use_same_kms_key_for_backups = false
  kms_key_crn                  = module.key_protect_all_inclusive.keys["icd-pg.${var.prefix}-pg"].crn
  backup_encryption_key_crn    = module.key_protect_all_inclusive.keys["icd-pg.${local.data_key_name}"].crn
  existing_kms_instance_guid   = module.key_protect_all_inclusive.kms_guid
  resource_tags                = var.resource_tags
  service_credential_names = {
    "postgressql_admin" : "Administrator",
    "postgressql_operator" : "Operator",
    "postgressql_viewer" : "Viewer",
    "postgressql_editor" : "Editor",
  }
  access_tags        = var.access_tags
  member_host_flavor = "multitenant"
  # Example of setting configuration - none of the below is mandatory - those settings are set in this example for illustation purpose and ensure path is exercised in automated test using this example.
  configuration = {
    shared_buffers             = 32000
    max_connections            = 250
    max_locks_per_transaction  = 64
    max_prepared_transactions  = 0
    synchronous_commit         = "local"
    effective_io_concurrency   = 12
    deadlock_timeout           = 10000
    log_connections            = "off"
    log_disconnections         = "off"
    log_min_duration_statement = 100
    tcp_keepalives_idle        = 200
    tcp_keepalives_interval    = 50
    tcp_keepalives_count       = 6
    archive_timeout            = 1000
    max_replication_slots      = 10
    max_wal_senders            = 20
  }
  cbr_rules = [
    {
      description      = "${var.prefix}-postgres access only from vpc"
      enforcement_mode = "enabled" #Postgresql does not support report mode
      account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
      rule_contexts = [{
        attributes = [
          {
            "name" : "endpointType",
            "value" : "private"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_zone.zone_id
        }]
      }]
    }
  ]
}

# VPE provisioning should wait for the database provisioning
resource "time_sleep" "wait_120_seconds" {
  depends_on      = [module.postgresql_db]
  create_duration = "120s"
}

##############################################################################
# VPE
##############################################################################

module "vpe" {
  source  = "terraform-ibm-modules/vpe-gateway/ibm"
  version = "4.3.0"
  prefix  = "vpe-to-pg"
  cloud_service_by_crn = [
    {
      service_name = "${var.prefix}-postgres"
      crn          = module.postgresql_db.crn
    },
  ]
  vpc_id             = module.vpc.vpc_id
  subnet_zone_list   = module.vpc.subnet_zone_list
  resource_group_id  = module.resource_group.resource_group_id
  security_group_ids = [ibm_is_security_group.sg1.id]
  depends_on = [
    time_sleep.wait_120_seconds,
    time_sleep.wait_30_seconds
  ]
}
