data "azurerm_key_vault" "kv" {
  name = "kv-entproj-shared-01"
  resource_group_name = "rg-security-shared"
}

data "azurerm_key_vault_secret" "vm_password"{
    name = "linux-admin-password"
    key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_network_interface" "vm_nic" {
  name = "nic-${var.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.private_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
    name = var.vm_name
    location = var.location

    resource_group_name = var.resource_group_name

    admin_username = var.admin_username
    admin_password = data.azurerm_key_vault_secret.vm_password.value

    size = var.vm_size
    
    network_interface_ids = [azurerm_network_interface.vm_nic.id]
    
    disable_password_authentication = false

    os_disk {
      caching = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }

    source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.25" 
  auto_upgrade_minor_version = true
}