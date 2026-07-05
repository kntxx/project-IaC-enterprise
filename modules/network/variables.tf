variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet-Name" {
  type = string
  default = "vnet-enterprise-infra"
}

variable "vnet-AddressSpace" {
  type = list(string)
}

variable "bastion-subnetPrefixes" {
  type = list(string)
}

variable "subnet-private-name" {
  type = string
}

variable "subnet-private-addressPrefixes" {
  type = list(string)
}

variable "nsg_name" {
  type = string
  default = "nsg"
}