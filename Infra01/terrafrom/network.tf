#VNETs
resource "azurerm_virtual_network" "vnet-aks" {
  name = "${var.projectPrefix}-vnet-aks"
  resource_group_name = azurerm_resource_group.baserg.name
  location = var.location
  address_space = ["172.18.0.0/16"]
}

resource "azurerm_virtual_network" "vnet-hub" {
  name = "${var.projectPrefix}-vnet-hub"
  resource_group_name = azurerm_resource_group.baserg.name
  location = var.location
  address_space = ["172.19.0.0/16"]
}

#Subnets
resource "azurerm_subnet" "subnet-aks" {
    name = "${var.projectPrefix}-snet-aks"
    resource_group_name = azurerm_resource_group.baserg.name
    virtual_network_name = azurerm_virtual_network.vnet-aks.name
    address_prefixes = ["172.18.1.0/24"]
    
}

resource "azurerm_subnet" "subnet-apim" {
    name = "${var.projectPrefix}-snet-apim"
    resource_group_name = azurerm_resource_group.baserg.name
    virtual_network_name = azurerm_virtual_network.vnet-aks.name
    address_prefixes = ["172.18.2.0/24"]
}

resource "azurerm_subnet" "subnet-gw" {
    name = "${var.projectPrefix}-snet-gw"
    resource_group_name = azurerm_resource_group.baserg.name
    virtual_network_name = azurerm_virtual_network.vnet-hub.name
    address_prefixes = ["172.19.1.0/24"]
}

resource "azurerm_subnet" "subnet-gwout" {
    name = "${var.projectPrefix}-snet-gwout"
    resource_group_name = azurerm_resource_group.baserg.name
    virtual_network_name = azurerm_virtual_network.vnet-hub.name
    address_prefixes = ["172.19.2.0/24"]
}

#VNET peering
resource "azurerm_virtual_network_peering" "hub-aks" {
  name                      = "${azurerm_virtual_network.vnet-hub.name}-to-${azurerm_virtual_network.vnet-aks.name}"
  resource_group_name       = var.rgName
  virtual_network_name      = azurerm_virtual_network.vnet-hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-aks.id
}

resource "azurerm_virtual_network_peering" "aks-hub" {
  name                      = "${azurerm_virtual_network.vnet-aks.name}-to-${azurerm_virtual_network.vnet-hub.name}"
  resource_group_name       = var.rgName
  virtual_network_name      = azurerm_virtual_network.vnet-aks.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-hub.id
}

#Route
resource "azurerm_route_table" "aks-routetable" {
  name                = "${var.projectPrefix}-snet-aks-routetable"
  location            = var.location
  resource_group_name = azurerm_resource_group.baserg.name
}

resource "azurerm_route" "aks-rotue-default" {
  name                = "default"
  resource_group_name = azurerm_resource_group.baserg.name
  route_table_name    = azurerm_route_table.aks-routetable.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = local.static-ip-LAN
  depends_on = [ azurerm_public_ip.snatvm-WAN ]
}

resource "azurerm_subnet_route_table_association" "aks-routetable" {
  subnet_id      = azurerm_subnet.subnet-aks.id
  route_table_id = azurerm_route_table.aks-routetable.id
}

