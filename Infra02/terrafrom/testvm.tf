# NIC for the VM
locals {
    vmname = "${var.projectPrefix}testvm327"
    static-ip01 = "172.18.3.10"
}

resource "azurerm_network_interface" "testvm-01" {
  name                = "${local.vmname}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.baserg.name

  ip_configuration {
    name                          = "ipv4"
    subnet_id                     = azurerm_subnet.subnet-aks.id
    private_ip_address_allocation = "Static"
    private_ip_address = local.static-ip01
  }
}

resource "azurerm_linux_virtual_machine" "testvm" {
  name                  = local.vmname
  location              = var.location
  resource_group_name   = azurerm_resource_group.baserg.name
  network_interface_ids = [azurerm_network_interface.testvm-01.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = local.vmname
  admin_username = var.linuser

  admin_ssh_key {
    username   = var.linuser
    public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.common.primary_blob_endpoint
  }
}