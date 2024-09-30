resource "azurerm_virtual_network" "vnet-sample" {
  name                = "vnet-sample"
  resource_group_name = "rg-tenant-1"
  location            = "West Europe"
  address_space       = ["10.0.0.0/16"]
}