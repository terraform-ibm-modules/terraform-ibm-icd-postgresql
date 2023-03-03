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
  providers = {
    restapi = restapi.kp
  }
  source            = "git::https://github.com/terraform-ibm-modules/terraform-ibm-key-protect-all-inclusive.git?ref=v3.1.2"
  resource_group_id = module.resource_group.resource_group_id
  # Note: Database instance and Key Protect must be created in the same region when using BYOK
  # See https://cloud.ibm.com/docs/cloud-databases?topic=cloud-databases-key-protect&interface=ui#key-byok
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  key_map                   = { "icd-pg" = ["${var.prefix}-pg"] }
}

# Create IAM Access Policy to allow Key protect to access Postgres instance
resource "ibm_iam_authorization_policy" "policy" {
  source_service_name         = "databases-for-postgresql"
  source_resource_group_id    = module.resource_group.resource_group_id
  target_service_name         = "kms"
  target_resource_instance_id = module.key_protect_all_inclusive.key_protect_guid
  roles                       = ["Reader"]
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
# VSI
##############################################################################
data "ibm_is_image" "ubuntu" {
  name = "ibm-ubuntu-18-04-6-minimal-amd64-7"
}

resource "ibm_is_security_group" "sg1" {
  name = "${var.prefix}-sg1"
  vpc  = ibm_is_vpc.example_vpc.id
}

locals {
  security_group_rules_map = {
    "rule1" = {
      "direction" : "inbound",
      "name" : "allow-all-inbound",
      "source" : "0.0.0.0/0"
    },
    "rule2" = {
      "direction" : "outbound",
      "name" : "allow-all-outbound",
      "source" : "0.0.0.0/0"
    }
  }
}

resource "ibm_is_security_group_rule" "security_group_rules" {
  for_each  = local.security_group_rules_map
  group     = ibm_is_security_group.sg1.id
  direction = each.value.direction
  remote    = each.value.source
}

resource "ibm_is_ssh_key" "sshkey" {
  name       = "ssh1"
  public_key = var.ssh_key
}

resource "ibm_is_instance" "vsi1" {
  name    = "${var.prefix}-vpc-vsi"
  vpc     = ibm_is_vpc.example_vpc.id
  zone    = "${var.region}-1"
  keys    = [ibm_is_ssh_key.sshkey.id]
  image   = data.ibm_is_image.ubuntu.id
  profile = "bx2-2x8"

  primary_network_interface {
    subnet          = ibm_is_subnet.testacc_subnet.id
    security_groups = [ibm_is_security_group.sg1.id]
  }
}

resource "ibm_is_floating_ip" "fip1" {
  name   = "${var.prefix}-fip1"
  target = ibm_is_instance.vsi1.primary_network_interface[0].id
}

##############################################################################
# Create CBR Zone
##############################################################################
module "cbr_zone" {
  source           = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cbr//cbr-zone-module?ref=v1.1.2"
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
  source              = "../../"
  resource_group_id   = module.resource_group.resource_group_id
  name                = "${var.prefix}-postgres"
  region              = var.region
  service_endpoints   = "public-and-private"
  pg_version          = var.pg_version
  key_protect_key_crn = module.key_protect_all_inclusive.keys["icd-pg.${var.prefix}-pg"].crn
  resource_tags       = var.resource_tags
  cbr_rules = [
    {
      description      = "${var.prefix}-postgres access only from vpc"
      enforcement_mode = "enabled" #Postgresql does not support report mode
      account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
      rule_contexts = [{
        attributes = [
          {
            "name" : "endpointType",
            "value" : "private,public"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_zone.zone_id
        }]
      }]
    }
  ]
}

##############################################################################
# Service Credentials
##############################################################################

resource "ibm_resource_key" "service_credentials" {
  count                = length(var.service_credentials)
  name                 = var.service_credentials[count.index]
  resource_instance_id = module.postgresql_db.id
  tags                 = var.resource_tags
}
