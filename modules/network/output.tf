output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion-subnet.id
}

output "private_subnet_id" {
  value = azurerm_subnet.private-subnet.id
}