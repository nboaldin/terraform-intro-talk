# Terraform blocks take fields to configure terraform itself
# We are specifying the provider needed and where to get the provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configuration for the overarching azure provider
# Here we are telling the provider to use our 'Dev' subscription in Azure
provider "azurerm" {
  features {}
  subscription_id = "put a subsciption id here"
}

# This how you instantiate variables in Terraform
# You can configure them in a more detailed manner: description, typing, etc.
variable "prefix" {
  default = "nathantest"
}

#Declaring the creation/sustaining of an azure resource group called nathantest
resource "azurerm_resource_group" "nathantest" {
  name     = "${var.prefix}-resources"
  location = "centralus"
}

#Declaring the creation/sustaining of an azure virtual network called nathantest
resource "azurerm_virtual_network" "nathantest" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.nathantest.location
  resource_group_name = azurerm_resource_group.nathantest.name
}

#Declaring the creation/sustaining of an azure subnet called internal
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.nathantest.name
  virtual_network_name = azurerm_virtual_network.nathantest.name
  address_prefixes     = ["10.0.2.0/24"]
}

#Declaring the creation/sustaining of an azure network interface called nathantest
resource "azurerm_network_interface" "nathantest" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.nathantest.location
  resource_group_name = azurerm_resource_group.nathantest.name

  ip_configuration {
    name                          = "nathantest"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "nathantest" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.nathantest.location
  resource_group_name   = azurerm_resource_group.nathantest.name
  network_interface_ids = [azurerm_network_interface.nathantest.id]
  vm_size               = "Standard_A1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # change the username and password
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
