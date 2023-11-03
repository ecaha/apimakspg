output "resource_group_name" {
  value = azurerm_resource_group.baserg.name
}

output "key_data" {
  value = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
}