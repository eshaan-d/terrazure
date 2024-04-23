/*

The following links provide the documentation for the new blocks used
in this terraform configuration file

1.azurerm_storage_account - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account

*/

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.97.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

resource "azurerm_resource_group" "esh-dev-test" {
  name     = "test-res"
  location = "West Europe"
}

locals {
  virtual_network = {
    name          = "app-network"
    address_space = "10.0.0.0/16"
  }

  subnets = [
    {
      name           = "subnetA"
      address_prefix = "10.0.0.0/24"
    },
    {
      name           = "subnetB"
      address_prefix = "10.0.1.0/24"
    }
  ]
}

#resource "azurerm_storage_account" "esh-test-strg"{ 
#  name                     = "teststrgesh03"
#  resource_group_name      = azurerm_resource_group.esh-dev-test.name
#  location                 = azurerm_resource_group.esh-dev-test.location
#  account_tier             = "Standard"
#  account_replication_type = "LRS"
#  account_kind             = "StorageV2"
#  depends_on = [
#    azurerm_resource_group.esh-dev-test
#  ]
#
#
#  tags = {
#    environment = "staging"
#  }
#}

#resource "azurerm_storage_container" "esh-test-cont" {
#  name                  = "test-cont"
#  storage_account_name  = azurerm_storage_account.esh-test-strg.name
#  container_access_type = "blob"
#  depends_on = [
#    azurerm_storage_account.esh-test-strg
#  ]
#}

#resource "azurerm_storage_blob" "esh-test-blob" {
#  name                   = "main.tf"
#  storage_account_name   = azurerm_storage_account.esh-test-strg.name
#  storage_container_name = azurerm_storage_container.esh-test-cont.name
#  type                   = "Block"
#  source                 = "main.tf"
#  depends_on = [
#    azurerm_storage_container.esh-test-cont
#  ]
#}
#

resource "azurerm_virtual_network" "esh-test-net" {
  name                = local.virtual_network.name
  location            = azurerm_resource_group.esh-dev-test.location
  resource_group_name = azurerm_resource_group.esh-dev-test.name
  address_space       = [local.virtual_network.address_space]
  #dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = local.subnets[0].name
  resource_group_name  = azurerm_resource_group.esh-dev-test.name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[0].address_prefix]
  depends_on = [
    azurerm_virtual_network.esh-test-net
  ]

}

resource "azurerm_subnet" "SubnetB" {
  name                 = local.subnets[1].name
  resource_group_name  = azurerm_resource_group.esh-dev-test.name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[1].address_prefix]
  depends_on = [
    azurerm_virtual_network.esh-test-net
  ]

}

resource "azurerm_network_interface" "esh-test-nic" {
  name                = "test-nic"
  location            = azurerm_resource_group.esh-dev-test.location
  resource_group_name = azurerm_resource_group.esh-dev-test.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.esh-test-pip.id
  }
  depends_on = [
    azurerm_subnet.SubnetA
  ]
}

output "subnetA-id" {
  value = azurerm_subnet.SubnetA.id
}

resource "azurerm_public_ip" "esh-test-pip" {
  name                = "test-pub-ip"
  resource_group_name = azurerm_resource_group.esh-dev-test.name
  location            = azurerm_resource_group.esh-dev-test.location
  allocation_method   = "Static"
  depends_on = [
    azurerm_resource_group.esh-dev-test
  ]

  tags = {
    environment = "Production"
  }
}