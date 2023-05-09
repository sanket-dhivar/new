terraform {
 backend "azurerm" {
 resource_group_name = "KE-DevOps-LandingZone"
 storage_account_name = "testwesteurope123"
 container_name = "test-dev"
 key = "RgvUgw78ISrE3tzFSvPRqmtfUEfbnR7d6nRXnIhgw6GbEK92616z93NkyL9OcHxqWIbrSzGNZoda+ASthYh2KQ=="
 }
}

provider "azurerm"{
    features {
    }
}

data "azurerm_resource_group" "test" {
  name = "KE-DevOps-LandingZone"
}


resource "azurerm_virtual_network" "Vnet" {
  name = "vnet-test-eastus"
  address_space = ["10.1.0.0/16"]
  location                     = "${data.azurerm_resource_group.test.location}"
    resource_group_name          = "${data.azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "snet" {
  name = "snet-test-eastus"
  
    resource_group_name          = "${data.azurerm_resource_group.test.name}"
  virtual_network_name = azurerm_virtual_network.Vnet.name
  address_prefixes = ["10.1.0.0/24"]
}
resource "azurerm_subnet" "bastion" {
  name = "AzureBastionSubnet"
  resource_group_name          = "${data.azurerm_resource_group.test.name}"
  virtual_network_name = azurerm_virtual_network.Vnet.name
  address_prefixes = ["10.1.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name = "nic-test"
  location                     = "${data.azurerm_resource_group.test.location}"
    resource_group_name          = "${data.azurerm_resource_group.test.name}"

  ip_configuration {
    name = "nic-config"
    subnet_id = azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  
  name                = "vm-test-eastus"
  location                     = "${data.azurerm_resource_group.test.location}"
    resource_group_name          = "${data.azurerm_resource_group.test.name}"
  size                = "Standard_B1s"
  
  admin_username      = "SanketVM1"
  admin_password      = "Sanket@VM1"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  for_each = local.zones
  
  zone = each.value
}
locals {
  zones = toset(["1"])
}


resource "azurerm_public_ip" "ip" {
  name                = "bastionip"
  location                     = "${data.azurerm_resource_group.test.location}"
    resource_group_name          = "${data.azurerm_resource_group.test.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name = "vnet-test-eastus-bastion"
  location                     = "${data.azurerm_resource_group.test.location}"
    resource_group_name          = "${data.azurerm_resource_group.test.name}"

  ip_configuration {
    name                 = "ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.ip.id
  }
}