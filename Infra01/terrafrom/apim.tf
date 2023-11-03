resource "azurerm_api_management" "apim" {
  name                = "${var.projectPrefix}-apim"
  location            = var.location
  resource_group_name = azurerm_resource_group.baserg.name
  publisher_email     = "erik@nowhere.com"
  publisher_name      = "erik"
  sku_name            = "Developer_1"
  identity {
    type = "SystemAssigned"
  }
  virtual_network_type = "External"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.subnet-apim.id
  }
}