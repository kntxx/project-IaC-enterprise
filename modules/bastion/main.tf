resource "azurerm_public_ip" "bastion_ip" {
  name = var.publicIp-name
  location = var.location
  resource_group_name = var.resource_group_name
  allocation_method = "Static"
  sku = "Standard"
}

resource  "azurerm_bastion_host" "bastion"{
  name = var.bastion-host-name
  location = var.location
  resource_group_name = var.resource_group_name
  sku = var.bastion-sku
  ip_configuration {
    name                 = "bastion-ipConfiguration"
    subnet_id            = var.subnet-bastion-id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}