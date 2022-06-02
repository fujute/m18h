provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "1TL-${var.prefix}-resources-rg"
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
  name                = "${var.prefix}-nic11"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  ip_configuration {
    name                          = "first-subnet2"
    subnet_id                     = azurerm_subnet.first-subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm1"
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

// -- public IP for second VM----

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Dynamic"
}


resource "azurerm_network_interface" "second-internal" {
  name                      = "${var.prefix}-nic21"
  resource_group_name       = azurerm_resource_group.example.name
  location                  = azurerm_resource_group.example.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.second-subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "second-pip" {
  name                = "${var.prefix}-nic22"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.second-subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_security_group" "webserver" {
  name                = "tls_webserver"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "tls"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "443"
    destination_address_prefix = azurerm_network_interface.second-internal.private_ip_address
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.second-internal.id
  network_security_group_id = azurerm_network_security_group.webserver.id
}

// -- deploy second VM in second vnet ----

resource "azurerm_linux_virtual_machine" "linuxvm2" {
  name                            = "${var.prefix}-vm2"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = "${var.password}"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.second-pip.id,
    azurerm_network_interface.second-internal.id,
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

// End of File
