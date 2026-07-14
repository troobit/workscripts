# =============================================================================
# Variables
# =============================================================================

variable "username" {
  type    = string
  default = "ws-admin"
}

variable "password" {
  type    = string
  default = "ChangeMe!" #Or use an az keyvault...
}

variable "publisher" {
  type    = string
  default = "cognosys"
}

variable "marketplace_offer" {
  default = "nginx-with-ubuntu-server-1804-lts-free"
}

# =============================================================================
# Create SSH certs
# =============================================================================

resource "tls_private_key" "ws" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}
output "tls_private_key" {
  sensitive = true # so TF allows you to output it
  value     = tls_private_key.ws.private_key_pem
}

# =============================================================================
# Primary Location
# =============================================================================

resource "azurerm_marketplace_agreement" "ws-agreement" {
  publisher = var.publisher
  offer     = var.marketplace_offer
  plan      = "hourly"
}

resource "azurerm_linux_virtual_machine" "ws" {
  name                            = "ws-01"
  admin_username                  = var.username
  admin_password                  = var.password
  location                        = var.location
  resource_group_name             = var.rg_name
  network_interface_ids           = azurerm_network_interface.nic.*.id
  size                            = "Standard_B2s"
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.username
    public_key = tls_private_key.ws.public_key_openssh
  }

  source_image_reference {
    publisher = var.publisher
    offer     = var.marketplace_offer
    sku       = var.marketplace_offer
    version   = "1.2019.1008"
  }

  plan {
    name      = var.marketplace_offer
    publisher = var.publisher
    product   = var.marketplace_offer
  }

  os_disk {
    name                 = "ws-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags       = var.common_tags
  depends_on = [azurerm_resource_group.rg, azurerm_network_interface.nic]
}