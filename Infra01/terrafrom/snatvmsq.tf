# NIC for the VM
locals {
    snatsgvmname = "${var.projectPrefix}snatvmsg327"
    static-ip-LANsg = "172.19.1.11"
    static-ip-WANsg = "172.19.2.11"
}

data "template_file" "cloud-init-sg" {
  template = "${file("${path.module}/cloud-init-snat.yml")}"
  vars = {
    snat-ip-WAN = local.static-ip-WANsg
    snat-ip-LAN = "172.19.1.1"
    aks-subnet = local.aks-subnet
  }
}


# Create public IPs
resource "azurerm_public_ip" "snatsgvm-WAN" {
  name                = "${local.snatsgvmname}-pip-WAN"
  location            = var.location
  resource_group_name = azurerm_resource_group.baserg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "snatsgvm-WAN-nsg" {
  name                = "snatvmsg-WAN-nsg"
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

resource "azurerm_network_interface" "snatsgvm-LAN" {
  name                = "${local.snatsgvmname}-nic-LAN"
  location            = var.location
  resource_group_name = azurerm_resource_group.baserg.name
  enable_ip_forwarding = "true"
  ip_configuration {
    name                          = "ipv4"
    subnet_id                     = azurerm_subnet.subnet-gw.id
    private_ip_address_allocation = "Static"
    private_ip_address = local.static-ip-LANsg
  }
}

resource "azurerm_network_interface" "snatsgvm-WAN" {
  name                = "${local.snatsgvmname}-nic-WAN"
  location            = var.location
  resource_group_name = azurerm_resource_group.baserg.name

  ip_configuration {
    name                          = "ipv4"
    subnet_id                     = azurerm_subnet.subnet-gwout.id
    private_ip_address_allocation = "Static"
    private_ip_address = local.static-ip-WANsg
    public_ip_address_id = azurerm_public_ip.snatsgvm-WAN.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsgwasg" {
  network_interface_id      = azurerm_network_interface.snatsgvm-WAN.id
  network_security_group_id = azurerm_network_security_group.snatsgvm-WAN-nsg.id
}

resource "azurerm_linux_virtual_machine" "snatsgvm" {
  name                  = local.snatsgvmname
  location              = var.location
  resource_group_name   = azurerm_resource_group.baserg.name
  network_interface_ids = [azurerm_network_interface.snatsgvm-WAN.id, azurerm_network_interface.snatsgvm-LAN.id]
  size                  = "Standard_B2ats_v2"

  os_disk {
    name                 = "${local.snatsgvmname}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  user_data = base64encode(data.template_file.cloud-init-sg.rendered)
  
  computer_name  = local.snatsgvmname
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


data "azurerm_public_ip" "snatsgvm-pip" {
  name                = azurerm_public_ip.snatsgvm-WAN.name
  resource_group_name = azurerm_resource_group.baserg.name
  depends_on = [ azurerm_linux_virtual_machine.snatsgvm ]
}