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

variable "service_credential" {
  type        = string
  description = "Database service credential"
}

variable "resource_group_id" {
  type        = string
  description = "Id of existing resource_group"
}

variable "vpc_id" {
  type        = string
  description = "Id of existing vpc"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet ids"
}

variable "vsi_reserved_ip" {
  type        = string
  description = "Reserved IP for vsi"
}
