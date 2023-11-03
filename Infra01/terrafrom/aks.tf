resource "azurerm_user_assigned_identity" "aks-identity" {
  location            = var.location
  name                = "${var.projectPrefix}-aks-identity"
  resource_group_name = azurerm_resource_group.baserg.name
}

resource "azurerm_role_assignment" "aks-ide-route" {
  scope                = azurerm_route_table.aks-routetable.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks-identity.principal_id
}

resource "azurerm_role_assignment" "aks-ide-subnet" {
  scope                = azurerm_subnet.subnet-aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks-identity.principal_id
}

resource "azurerm_kubernetes_cluster" "aks" {
  depends_on = [ azurerm_subnet_route_table_association.aks-routetable,
  azurerm_role_assignment.aks-ide-route ]
  name = "${var.projectPrefix}-aks-cluster"
  location = var.location
  resource_group_name = azurerm_resource_group.baserg.name

  
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks-identity.id ]
  }

  sku_tier = "Free"

  default_node_pool {
    name = "defaultpool"
    vm_size = "Standard_B2as_v2"
    enable_node_public_ip = "false"
    enable_auto_scaling = "false"
    node_count = 1
    vnet_subnet_id = azurerm_subnet.subnet-aks.id
  }

  dns_prefix = "myakscluster"


  linux_profile {
    admin_username = var.linuser
    ssh_key {
        key_data = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
        }
    
  }
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
    outbound_type = "userDefinedRouting"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "qa" {
  name                  = "qa"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_B2as_v2"
  enable_node_public_ip = "false"
  enable_auto_scaling = "false"
  node_count = 1
  vnet_subnet_id = azurerm_subnet.subnet-aks.id

  tags = {
    Environment = "QA"
  }
}