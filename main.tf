terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" 
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-devops-shared"
    storage_account_name = "staccounttffstates01" 
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate" 
  }
}

provider "azurerm" {
  features {}
}



resource "azurerm_resource_group" "rg" {
  name = var.rg_name
  location = var.location
}


module "network" {
  source = "./modules/network"
  
  resource_group_name = var.rg_name
  location =  var.location

  vnet-Name = "vnet-${var.environment}-${var.location}-01"

  vnet-AddressSpace = [ "10.0.0.0/16" ]
  bastion-subnetPrefixes = ["10.0.1.0/24"]
  subnet-private-addressPrefixes = ["10.0.2.0/24"]
  
  subnet-private-name = "snet-${var.environment}-private-01"
  nsg_name = "nsg-${var.environment}-private-01"
}


module "bastion" {
  source = "./modules/bastion"
  
  location = var.location
  resource_group_name = var.rg_name 
  
  bastion-host-name = "bas-${var.environment}-${var.location}-01"
  subnet-bastion-id = module.network.bastion_subnet_id
  publicIp-name = "pip-${var.environment}-${var.location}-01"
  bastion-sku = var.bastion-sku

}

module "compute" {
  source = "./modules/compute"

  resource_group_name =  var.rg_name

  location = var.location

  vm_name = "vm-${var.environment}-${var.location}-01"
  admin_username = "linuxadmin"
  vm_size = var.vm-sku
  private_subnet_id = module.network.private_subnet_id
}


module "observability" {
  source = "./modules/observability"

  resource_group_name = var.rg_name
  location            = var.location
  environment         = var.environment
  workspace_name      = "law-${var.environment}-${var.location}-01"
  vm_id = module.compute.vm_id
}