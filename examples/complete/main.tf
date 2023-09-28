##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.0.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Key Protect All Inclusive
##############################################################################

module "key_protect_all_inclusive" {
  source            = "terraform-ibm-modules/key-protect-all-inclusive/ibm"
  version           = "4.2.0"
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
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-zone-module"
  version          = "1.12.0"
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
  source                     = "../../"
  resource_group_id          = module.resource_group.resource_group_id
  name                       = "${var.prefix}-postgres"
  region                     = var.region
  pg_version                 = var.pg_version
  admin_pass                 = var.admin_pass
  users                      = var.users
  kms_encryption_enabled     = true
  kms_key_crn                = module.key_protect_all_inclusive.keys["icd-pg.${var.prefix}-pg"].crn
  existing_kms_instance_guid = module.key_protect_all_inclusive.key_protect_guid
  resource_tags              = var.resource_tags
  service_credential_names   = var.service_credential_names
  access_tags                = var.access_tags
  configuration = {
    max_connections = 250
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

# wait 30 secs after security group is destroyed before destroying VPE to workaround race condition
resource "time_sleep" "wait_30_seconds" {
  depends_on       = [ibm_is_security_group.sg1]
  destroy_duration = "30s"
}


resource "tls_private_key" "tls_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "ssh_key" {
  name       = "${var.prefix}-ssh-key"
  public_key = tls_private_key.tls_key.public_key_openssh
}


resource "ibm_is_instance" "vsi" {
  name           = "${var.prefix}-vsi"
  image          = "r006-fedc50ed-8ea3-4a66-9559-c482c4e6ed88"
  profile        = "cx2-2x4"
  resource_group = module.resource_group.resource_group_id
  vpc            = ibm_is_vpc.example_vpc.id
  zone           = var.region
  keys           = [ibm_is_ssh_key.ssh_key.id]
  lifecycle {
    ignore_changes = [
      image
    ]
  }

  primary_network_interface {
    subnet = ibm_is_vpc.example_vpc.subnets[0].id
  }


  # User can configure timeouts
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

resource "ibm_is_floating_ip" "vsi_fip" {
  name        = "${var.prefix}-fip"
  target      = ibm_is_instance.vsi.primary_network_interface[0].id
  access_tags = var.access_tags
}

locals {
  # https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-connecting-psql
  composed = replace(module.postgresql_db.service_credentials_object.credentials["postgressql_viewer"]["composed"], "sslmode=verify-full", "sslmode=require")
}
resource "null_resource" "db_connection" {
  depends_on = [ibm_is_instance.vsi]

  provisioner "remote-exec" {

    inline = [
      "sudo apt-get update",
      "sudo apt-get install postgresql-client",

      "${local.composed} -c 'CREATE TABLE test (id serial PRIMARY KEY, marks serial);'",
      "${local.composed} -c 'INSERT INTO test (id, marks) VALUES (1, 100);'",
      "${local.composed} -c 'INSERT INTO test (id, marks) VALUES (2, 200);'",
      "${local.composed} -c 'INSERT INTO test (id, marks) VALUES (3, 300);'",
      "${local.composed} -c 'INSERT INTO test (id, marks) VALUES (4, 400);'",
    ]
    connection {
      type        = "ssh"
      host        = ibm_is_floating_ip.vsi_fip.address
      user        = "root"
      private_key = tls_private_key.tls_key.private_key_pem
    }
  }
}
