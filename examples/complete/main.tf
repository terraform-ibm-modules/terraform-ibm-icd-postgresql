##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Key Protect All Inclusive
##############################################################################

module "key_protect_all_inclusive" {
  source            = "git::https://github.com/terraform-ibm-modules/terraform-ibm-key-protect-all-inclusive.git?ref=v4.0.0"
  resource_group_id = module.resource_group.resource_group_id
  # Note: Database instance and Key Protect must be created in the same region when using BYOK
  # See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  key_map                   = { "icd-pg" = ["${var.prefix}-pg"] }
}

##############################################################################
# Get Cloud Account ID
##############################################################################

data "ibm_iam_account_settings" "iam_account_settings" {
}

##############################################################################
# VPC
##############################################################################
resource "ibm_is_vpc" "example_vpc" {
  name           = "${var.prefix}-vpc"
  resource_group = module.resource_group.resource_group_id
  tags           = var.resource_tags
}

resource "ibm_is_subnet" "testacc_subnet" {
  name                     = "${var.prefix}-subnet"
  vpc                      = ibm_is_vpc.example_vpc.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  resource_group           = module.resource_group.resource_group_id
}

##############################################################################
# Create CBR Zone
##############################################################################
module "cbr_zone" {
  source           = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cbr//cbr-zone-module?ref=v1.2.0"
  name             = "${var.prefix}-VPC-network-zone"
  zone_description = "CBR Network zone representing VPC"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type  = "vpc", # to bind a specific vpc to the zone
    value = ibm_is_vpc.example_vpc.crn,
  }]
}

##############################################################################
# Postgres Instance
##############################################################################

module "postgresql_db" {
  source                   = "../../"
  resource_group_id        = module.resource_group.resource_group_id
  name                     = "${var.prefix}-postgres"
  region                   = var.region
  service_endpoints        = "private"
  pg_version               = var.pg_version
  kms_key_crn              = module.key_protect_all_inclusive.keys["icd-pg.${var.prefix}-pg"].crn
  resource_tags            = var.resource_tags
  service_credential_names = var.service_credential_names
  auto_scaling             = var.auto_scaling
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

resource "ibm_is_security_group" "sg1" {
  name = "${var.prefix}-sg1"
  vpc  = ibm_is_vpc.example_vpc.id
}

resource "ibm_is_virtual_endpoint_gateway" "pgvpe" {
  name = "${var.prefix}-vpe-to-pg"
  target {
    crn           = module.postgresql_db.crn
    resource_type = "provider_cloud_service"
  }
  vpc = ibm_is_vpc.example_vpc.id
  ips {
    subnet = ibm_is_subnet.testacc_subnet.id
    name   = "${var.prefix}-pg-access-reserved-ip"
  }
  resource_group  = module.resource_group.resource_group_id
  security_groups = [ibm_is_security_group.sg1.id]
  depends_on = [
    time_sleep.wait_120_seconds,
    time_sleep.wait_30_seconds
  ]
}

resource "time_sleep" "wait_30_seconds" {
  depends_on       = [ibm_is_security_group.sg1]
  destroy_duration = "30s"
}

##############################################################################
# ICD postgresql read-only-replica
##############################################################################

module "read_only_replica_postgresql_db" {
  count             = var.read_only_replicas_count
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-read-only-replica-${count.index}"
  region            = var.region
  resource_tags     = var.resource_tags
  pg_version        = var.pg_version
  remote_leader_crn = module.postgresql_db.crn
  member_memory_mb  = var.replica_member_memory_mb
  member_disk_mb    = var.replica_member_disk_mb
  member_cpu_count  = var.replica_member_cpu_count
}
