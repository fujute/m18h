provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "first" {
  name                = "${var.prefix}-network1"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
  }
}
resource "azurerm_subnet" "first-subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.first.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_virtual_network" "second" {
  name                = "${var.prefix}-network2"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["192.168.0.0/16"]

  subnet {
    name           = "subnet1"
    address_prefix = "192.168.1.0/24"
  }
  
}

resource "azurerm_subnet" "second-subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.second.name
  address_prefixes     = ["192.168.2.0/24"]
}

// vnet peering 

resource "azurerm_virtual_network_peering" "first-to-second" {
  name                         = "first-to-second"
  resource_group_name          = azurerm_resource_group.example.name
  virtual_network_name         = azurerm_virtual_network.first.name
  remote_virtual_network_id    = azurerm_virtual_network.second.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "second-to-first" {
  name                         = "second-to-first"
  resource_group_name          = azurerm_resource_group.example.name
  virtual_network_name         = azurerm_virtual_network.second.name
  remote_virtual_network_id    = azurerm_virtual_network.first.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

// Azure VM in first/first-subnet2
resource "azurerm_network_interface" "first" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  ip_configuration {
    name                          = "first-subnet2"
    subnet_id                     = azurerm_subnet.first-subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "${var.username}"
  admin_password                  = "${var.password}"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.first.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

//---
