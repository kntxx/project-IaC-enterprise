variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "workspace_name" {
  type = string
}

variable "retention_in_days" {
  type    = number
  default = 30
}

variable "vm_id" {
  type = string
}