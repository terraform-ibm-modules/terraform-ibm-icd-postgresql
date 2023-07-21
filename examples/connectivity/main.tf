##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# ICD postgresql database
##############################################################################

module "postgresql_db" {
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-postgres"
  pg_version        = var.pg_version
  region            = var.region
  resource_tags     = var.resource_tags
  access_tags       = var.access_tags
}

resource "ibm_is_vpc" "example_vpc" {
  name           = "${var.prefix}-vpc"
  resource_group = module.resource_group.resource_group_id
  tags           = var.resource_tags
}

##############################################################################
# Create new SSH key
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
  image          = "r006-1366d3e6-bf5b-49a0-b69a-8efd93cc225f"
  profile        = "cx2-2x4"
  resource_group = module.resource_group.resource_group_id
  vpc            = ibm_is_vpc.example_vpc.id
  zone           = "us-south-1"
  keys           = [ibm_is_ssh_key.ssh_key.id]
  lifecycle {
    ignore_changes = [
      image
    ]
  }

  primary_network_interface {
    subnet               = ibm_is_vpc.example_vpc.subnets[0].id
    primary_ipv4_address = "10.240.0.6" # will be deprecated. Use primary_ip.[0].address
    allow_ip_spoofing    = true
  }

  boot_volume {
    encryption = "crn:v1:bluemix:public:kms:us-south:a/dffc98a0f1f0f95f6613b3b752286b87:e4a29d1a-2ef0-42a6-8fd2-350deb1c647e:key:5437653b-c4b1-447f-9646-b2a2a4cd6179"
  }

  network_interfaces {
    subnet            = ibm_is_vpc.example_vpc.subnets[0].id
    allow_ip_spoofing = false
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

resource "null_resource" "db_connection" {
  depends_on = [ibm_is_instance.vsi]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y postgresql-client",
      "psql -h ${module.postgresql_db.hostname} -p ${module.postgresql_db.port}"
    ]
    connection {
      type        = "ssh"
      host        = ibm_is_floating_ip.vsi_fip.address
      user        = "admin"
      private_key = tls_private_key.tls_key.private_key_pem
    }
  }
}
