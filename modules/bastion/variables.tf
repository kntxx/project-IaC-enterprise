variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "bastion-host-name" {
 type = string 
 default = "bastion-easia-01"
}

variable "subnet-bastion-id" {
  type = string
}

variable "publicIp-name" {
  type = string
  default = "pip-bastion"
}

variable "bastion-sku" {
  type = string
  default = "Basic"
}