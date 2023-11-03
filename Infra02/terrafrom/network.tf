#VNET
resource "azurerm_virtual_network" "vnet" {
  name = "${var.projectPrefix}-vnet"
  resource_group_name = azurerm_resource_group.baserg.name
  location = var.location
  address_space = ["172.18.0.0/16"]
}

#Subnets
resource "azurerm_subnet" "subnet-aks" {
    name = "${var.projectPrefix}-snet-aks"
    resource_group_name = azurerm_resource_group.baserg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["172.18.3.0/27"]
}

resource "azurerm_subnet" "subnet-gw" {
    name = "${var.projectPrefix}-snet-gw"
    resource_group_name = azurerm_resource_group.baserg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["172.18.3.32/27"]
}

resource "azurerm_subnet" "subnet-gwout" {
    name = "${var.projectPrefix}-snet-gwout"
    resource_group_name = azurerm_resource_group.baserg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["172.18.3.64/27"]
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
  next_hop_in_ip_address = data.azurerm_public_ip.snatvm-pip.ip_address
  depends_on = [ azurerm_public_ip.snatvm-WAN ]
}

