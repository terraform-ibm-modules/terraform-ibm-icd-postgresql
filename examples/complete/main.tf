locals {
  # reserved IP that will be assigned to VSI
  vsi_reserved_ip = "10.10.10.10"

  # Change this local variable accordingly if default value of `service_credential_names` is changed in complete example
  service_credential_name = "postgressql_viewer"
  service_credential      = jsondecode(module.postgresql_db.service_credentials_json[local.service_credential_name])
  # https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-connecting-psql
  composed_string = replace(local.service_credential.connection.cli.composed[0], "sslmode=verify-full", "sslmode=require")

}


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
  version           = "4.3.0"
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

module "vpc" {
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "7.3.1"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  name              = "vpc"
  tags              = var.resource_tags
  network_acls = [
    {
      name                         = "vpc-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      rules = [
        # Allow all traffic from and to VSI
        {
          name        = "allow-all-inbound"
          action      = "allow"
          direction   = "inbound"
          destination = "${local.vsi_reserved_ip}/32"
          source      = "0.0.0.0/0"
        },
        {
          name        = "allow-all-outbound"
          action      = "allow"
          direction   = "outbound"
          destination = "0.0.0.0/0"
          source      = "${local.vsi_reserved_ip}/32"
        }
      ]
    }
  ]
}


##############################################################################
# Security group
##############################################################################

module "create_sgr_rule_pg" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "v2.0.0"
  add_ibm_cloud_internal_rules = false
  security_group_name          = "${var.prefix}-security-group-pg"
  resource_group               = module.resource_group.resource_group_id
  vpc_id                       = module.vpc.vpc_id
  target_ids                   = [for crn in module.vpe.crn : element(split(":", crn), length(split(":", crn)) - 1)]
}

module "create_sgr_rule_vsi" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "v2.0.0"
  add_ibm_cloud_internal_rules = false
  security_group_name          = "${var.prefix}-security-group-vsi"
  resource_group               = module.resource_group.resource_group_id
  vpc_id                       = module.vpc.vpc_id
  security_group_rules = [{
    name      = "allow-ssh-inbound"
    direction = "inbound"
    remote    = "0.0.0.0/0"
    tcp = {
      port_min = 22
      port_max = 22
    }
    }, {
    name      = "allow-http-inbound"
    direction = "inbound"
    remote    = "0.0.0.0/0"
    tcp = {
      port_min = 80
      port_max = 80
    }
    }, {
    name      = "allow-https-inbound"
    direction = "inbound"
    remote    = "0.0.0.0/0"
    tcp = {
      port_min = 443
      port_max = 443
    }
    }, {
    name      = "allow-ping-inbound"
    direction = "inbound"
    remote    = "0.0.0.0/0"
    icmp = {
      type = 8
    }
  }]
  target_ids = [ibm_is_instance.vsi.primary_network_interface[0].id]
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
    value = module.vpc.vpc_crn,
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

module "vpe" {
  source  = "terraform-ibm-modules/vpe-module/ibm"
  version = "2.4.0"
  prefix  = "vpe-to-pg"
  cloud_service_by_crn = [
    {
      name = "${var.prefix}-postgres"
      crn  = module.postgresql_db.crn
    },
  ]
  vpc_id            = module.vpc.vpc_id
  subnet_zone_list  = module.vpc.subnet_zone_list
  resource_group_id = module.resource_group.resource_group_id
  depends_on = [
    time_sleep.wait_120_seconds,
  ]
}


##############################################################################
# Floating IP
##############################################################################

resource "ibm_is_floating_ip" "vsi_fip" {
  name        = "${var.prefix}-fip"
  target      = ibm_is_instance.vsi.primary_network_interface[0].id
  access_tags = var.access_tags
}

##############################################################################
# SSH Key
##############################################################################

resource "tls_private_key" "tls_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "ssh_key" {
  name       = "${var.prefix}-ssh-key"
  public_key = tls_private_key.tls_key.public_key_openssh
}

##############################################################################
# VSI
##############################################################################

resource "ibm_is_instance" "vsi" {
  name           = "${var.prefix}-vsi"
  image          = "r006-fedc50ed-8ea3-4a66-9559-c482c4e6ed88"
  profile        = "cx2-2x4"
  resource_group = module.resource_group.resource_group_id
  vpc            = module.vpc.vpc_id
  zone           = "${var.region}-1"
  keys           = [ibm_is_ssh_key.ssh_key.id]

  lifecycle {
    ignore_changes = [
      image
    ]
  }

  primary_network_interface {
    subnet = module.vpc.subnet_ids[0]
    name   = "${var.prefix}-eth"
    primary_ip {
      address     = local.vsi_reserved_ip
      auto_delete = true
    }
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

resource "null_resource" "db_connection" {
  depends_on = [ibm_is_instance.vsi, module.create_sgr_rule_vsi, module.vpe]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install postgresql-client -y",

      "${local.composed_string} -c 'CREATE TABLE test (id serial PRIMARY KEY, marks serial);'",
      "${local.composed_string} -c 'INSERT INTO test (id, marks) VALUES (11, 100);'",
      "${local.composed_string} -c 'INSERT INTO test (id, marks) VALUES (12, 200);'",
      "${local.composed_string} -c 'INSERT INTO test (id, marks) VALUES (13, 300);'",
      "${local.composed_string} -c 'INSERT INTO test (id, marks) VALUES (14, 400);'",
      "${local.composed_string} -c 'SELECT * FROM test;'",
    ]
    connection {
      type        = "ssh"
      host        = ibm_is_floating_ip.vsi_fip.address
      user        = "root"
      private_key = tls_private_key.tls_key.private_key_pem
    }
    on_failure = fail
  }
}
