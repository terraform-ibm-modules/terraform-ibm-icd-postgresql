
module "create_sgr_rule_vsi" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "v2.0.0"
  add_ibm_cloud_internal_rules = false
  security_group_name          = "${var.prefix}-security-group-vsi"
  resource_group               = var.resource_group_id
  vpc_id                       = var.vpc_id
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
# Floating IP
##############################################################################

resource "ibm_is_floating_ip" "vsi_fip" {
  name        = "${var.prefix}-fip"
  target      = ibm_is_instance.vsi.primary_network_interface[0].id
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
  resource_group = var.resource_group_id
  vpc            = var.vpc_id
  zone           = "${var.region}-1"
  keys           = [ibm_is_ssh_key.ssh_key.id]

  lifecycle {
    ignore_changes = [
      image
    ]
  }

  primary_network_interface {
    subnet = var.subnet_ids[0]
    name   = "${var.prefix}-eth"
    primary_ip {
      address     = var.vsi_reserved_ip
      auto_delete = true
    }
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
locals {
  composed_string = replace(jsondecode(var.service_credential).connection.cli.composed[0], "sslmode=verify-full", "sslmode=require")
}

resource "null_resource" "db_connection" {
  depends_on = [
    ibm_is_instance.vsi,
    module.create_sgr_rule_vsi,
]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install postgresql-client -y",

      "${local.composed_string} -c 'CREATE TABLE test (id serial PRIMARY KEY, marks serial);'",
      "${local.composed_string} -c 'INSERT INTO test (id, marks) VALUES (101, 100);'",
      "${local.composed_string} -c 'INSERT INTO test (id, marks) VALUES (102, 200);'",
      "${local.composed_string} -c 'INSERT INTO test (id, marks) VALUES (103, 300);'",
      "${local.composed_string} -c 'INSERT INTO test (id, marks) VALUES (104, 400);'",
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