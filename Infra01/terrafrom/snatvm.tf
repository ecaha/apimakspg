# NIC for the VM
locals {
    snatvmname = "${var.projectPrefix}snatvm327"
    static-ip-LAN = "172.19.1.10"
    static-ip-WAN = "172.19.2.10"
    aks-subnet = "172.18.1.0/24"
}

data "template_file" "cloud-init" {
  template = "${file("${path.module}/cloud-init-snat.yml")}"
  vars = {
    snat-ip-WAN = local.static-ip-WAN
    snat-ip-LAN = "172.19.1.1"
    aks-subnet = local.aks-subnet
  }
}


# Create public IPs
resource "azurerm_public_ip" "snatvm-WAN" {
  name                = "${local.snatvmname}-pip-WAN"
  location            = var.location
  resource_group_name = azurerm_resource_group.baserg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "snatvm-WAN-nsg" {
  name                = "snatvm-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.baserg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "snatvm-LAN" {
  name                = "${local.snatvmname}-nic-LAN"
  location            = var.location
  resource_group_name = azurerm_resource_group.baserg.name
  enable_ip_forwarding = "true"
  ip_configuration {
    name                          = "ipv4"
    subnet_id                     = azurerm_subnet.subnet-gw.id
    private_ip_address_allocation = "Static"
    private_ip_address = local.static-ip-LAN
  }
}

resource "azurerm_network_interface" "snatvm-WAN" {
  name                = "${local.snatvmname}-nic-WAN"
  location            = var.location
  resource_group_name = azurerm_resource_group.baserg.name

  ip_configuration {
    name                          = "ipv4"
    subnet_id                     = azurerm_subnet.subnet-gwout.id
    private_ip_address_allocation = "Static"
    private_ip_address = local.static-ip-WAN
    public_ip_address_id = azurerm_public_ip.snatvm-WAN.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsgwan" {
  network_interface_id      = azurerm_network_interface.snatvm-WAN.id
  network_security_group_id = azurerm_network_security_group.snatvm-WAN-nsg.id
}

resource "azurerm_linux_virtual_machine" "snatvm" {
  name                  = local.snatvmname
  location              = var.location
  resource_group_name   = azurerm_resource_group.baserg.name
  network_interface_ids = [azurerm_network_interface.snatvm-WAN.id, azurerm_network_interface.snatvm-LAN.id]
  size                  = "Standard_B2ats_v2"

  os_disk {
    name                 = "${local.snatvmname}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  user_data = base64encode(data.template_file.cloud-init.rendered)
  
  computer_name  = local.snatvmname
  admin_username = var.linuser

  disable_password_authentication = false
  admin_password = var.linpasswd
  # admin_ssh_key {
  #   username   = var.linuser
  #   public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  # }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.common.primary_blob_endpoint
  }
}


data "azurerm_public_ip" "snatvm-pip" {
  name                = azurerm_public_ip.snatvm-WAN.name
  resource_group_name = azurerm_resource_group.baserg.name
  depends_on = [ azurerm_linux_virtual_machine.snatvm ]
}