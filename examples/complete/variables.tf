variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Region to provision all resources created by this example."
  default     = "us-south"
}

variable "prefix" {
  type        = string
  description = "Prefix to append to all resources created by this example"
  default     = "postgres"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the PostgreSQL instance created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details"
  default     = []
}

variable "pg_version" {
  description = "Version of the PostgreSQL instance. If no value is passed, the current preferred version of IBM Cloud Databases is used."
  type        = string
  default     = null
}

variable "admin_pass" {
  type        = string
  default     = null
  sensitive   = true
  description = "The password for the database administrator. If the admin password is null then the admin user ID cannot be accessed. More users can be specified in a user block. The admin password must be in the range of 10-32 characters and cannot start with a special character."
}

variable "users" {
  type = list(object({
    name     = string
    password = string
    type     = string
    role     = optional(string)
  }))
  default     = []
  sensitive   = true
  description = "A list of users that you want to create on the database. Multiple blocks are allowed. The user password must be in the range of 10-32 characters."
}

variable "service_credential_names" {
  description = "Map of name, role for service credentials that you want to create for the database"
  type        = map(string)
  default = {
    "postgressql_admin" : "Administrator",
    "postgressql_operator" : "Operator",
    "postgressql_viewer" : "Viewer",
    "postgressql_editor" : "Editor",
  }
}


variable "vpc_network_acls" {
  description = "The list of ACLs to create. Provide at least one rule for each ACL."
  type = list(
    object({
      name                         = string
      add_ibm_cloud_internal_rules = optional(bool)
      add_vpc_connectivity_rules   = optional(bool)
      prepend_ibm_rules            = optional(bool)
      rules = list(
        object({
          name        = string
          action      = string
          destination = string
          direction   = string
          source      = string
          tcp = optional(
            object({
              port_max        = optional(number)
              port_min        = optional(number)
              source_port_max = optional(number)
              source_port_min = optional(number)
            })
          )
          udp = optional(
            object({
              port_max        = optional(number)
              port_min        = optional(number)
              source_port_max = optional(number)
              source_port_min = optional(number)
            })
          )
          icmp = optional(
            object({
              type = optional(number)
              code = optional(number)
            })
          )
        })
      )
    })
  )
  default = [
    {
      name                         = "vpc-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      rules                        = []
    }
  ]
}
