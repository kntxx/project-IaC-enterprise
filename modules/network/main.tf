resource "azurerm_virtual_network" "this" {
  name                = var.vnet-Name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space = var.vnet-AddressSpace
}

resource "azurerm_subnet" "bastion-subnet" {
  name = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name = var.resource_group_name
  address_prefixes = var.bastion-subnetPrefixes
}

resource "azurerm_subnet" "private-subnet" {
  name = var.subnet-private-name
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name = var.resource_group_name
  address_prefixes = var.subnet-private-addressPrefixes
}

resource "azurerm_network_security_group" "private-Nsg" {
  name = var.nsg_name
  location = var.location
  resource_group_name = var.resource_group_name

  security_rule  {
    name  = "allow-http"
    priority = 200
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_rule" "allow_ssh_bastion" {
    name                       = "allow-ssh-bastion"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = var.bastion-subnetPrefixes[0]
    destination_address_prefix = "*"
    network_security_group_name = azurerm_network_security_group.private-Nsg.name
    resource_group_name = var.resource_group_name
}
resource "azurerm_subnet_network_security_group_association" "private-assoc" {
  network_security_group_id = azurerm_network_security_group.private-Nsg.id
  subnet_id = azurerm_subnet.private-subnet.id
}
resource "azurerm_public_ip" "nat_pip" {
  name                = var.pipName
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard" 
}

resource "azurerm_nat_gateway" "nat_gw" {
  name                    = var.natName
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4

}
resource "azurerm_subnet_nat_gateway_association" "subnet_assoc" {
  subnet_id = azurerm_subnet.private-subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}
