# ====================================================================================
# Variables
# ====================================================================================

variable "admin_username" {
  type    = string
  default = "osadmin"
}

variable "vm_image" {
  type = map(any)
  default = {
    publisher         = "bitnami"
    marketplace_offer = "nginxstack"
    version           = "latest"
    sku               = "1-9"
  }
}

# ====================================================================================
# Create SSH certs
# ====================================================================================

resource "tls_private_key" "endpointsvc" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}
output "tls_private_key" {
  sensitive = true
  value     = tls_private_key.endpointsvc.private_key_pem
}

variable "app_server_count" {
  description = "Number of app servers to stick behind the LB"
  default     = 2
}

# ====================================================================================
# NIC
# ====================================================================================

resource "azurerm_network_interface" "appserver_nic" {
  count               = var.app_server_count
  name                = "endpoint-vm-nic-${format("%02d", count.index + 1)}"
  location            = var.location
  resource_group_name = var.endpointsvc_rg_name

  ip_configuration {
    name                          = "endpointsvc-ipconfig"
    subnet_id                     = azurerm_subnet.endpointsvc_default_sn.id
    private_ip_address_allocation = "Dynamic"
    #private_ip_address           = var.private_ip
    #public_ip_address_id         = azurerm_public_ip.pip.id
  }
}


# ====================================================================================
# Primary Location
# ====================================================================================

resource "azurerm_linux_virtual_machine" "appserver" {
  count                           = var.app_server_count
  name                            = "vm-${format("%02d", count.index + 1)}"
  admin_username                  = var.admin_username
  location                        = var.location
  resource_group_name             = var.endpointsvc_rg_name
  network_interface_ids           = [azurerm_network_interface.endpointvm_nic[count.index].id]
  size                            = "Standard_B2s"
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.endpointsvc.public_key_openssh
  }

  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.marketplace_offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }

  plan {
    name      = "1-9"
    publisher = var.vm_image.publisher
    product   = var.vm_image.marketplace_offer
  }

  os_disk {
    name                 = "appserver-os-disk-${format("%02d", count.index + 1)}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags       = var.common_tags
  depends_on = [azurerm_resource_group.endpointsvc_rg, azurerm_network_interface.endpointvm_nic]
}
