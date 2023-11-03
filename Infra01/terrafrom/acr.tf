
resource "azurerm_container_registry" "acr" {
  name                = "${var.projectPrefix}acr327"
  resource_group_name = azurerm_resource_group.baserg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled = true
}

resource "azurerm_role_assignment" "aks-acr-role" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

output "acr-username" {
  value = azurerm_container_registry.acr.admin_username
  sensitive = true
}
output "acr-password" {
  value = azurerm_container_registry.acr.admin_password
  sensitive = true
}