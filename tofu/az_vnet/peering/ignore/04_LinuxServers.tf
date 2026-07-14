# ====================================================================================
# Variables
# ====================================================================================

variable "username" {
  type    = string
  default = "osadmin"
}

variable "publisher" {
  type    = string
  default = "Canonical"
}

variable "marketplace_offer" {
  default = "UbuntuServer"
}

variable "sku" {
  default = "16.04-LTS"
}

variable "linux_vm_count" {
  default = 1
}

resource "random_string" "password" {
  length  = 10
  special = true
  upper   = true
  numeric = true
}

# ====================================================================================
# NICs
# ====================================================================================

resource "azurerm_network_interface" "nic" {
  count               = var.linux_vm_count
  name                = "linux-nic-${count.index}"
  location            = var.location_primary
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "nic-config-${count.index}"
    subnet_id                     = azurerm_subnet.spoke-subnet-01.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ====================================================================================
# VMs
# ====================================================================================

resource "azurerm_linux_virtual_machine" "linux" {
  count                           = var.linux_vm_count
  name                            = "linux-vm-${count.index}"
  location                        = var.location_primary
  resource_group_name             = var.rg_name
  network_interface_ids           = [azurerm_network_interface.nic[count.index].id]
  size                            = "Standard_DS1_v2"
  admin_username                  = var.username
  admin_password                  = random_string.password.result
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.username
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmMVirIqN/z7tDJnT+sgWIP3M9oJtUNLw7eJ23ezOM50JLjqQA4QzJ/LgROX1wOJBtcZxv5959U7Kwy1NrHJwQY/ok7bRJ8eCjQT00Kjqvi31Axm1VeF/Wkak8ETqwW51SUVDIo6GqkNAEcY9YWH+Y3xictF8miblICNX6G04nnbJ04Cjbg1G8qYmXHOYZ0sKwl2QjJ7IhNPNJ6thjBHYdrd8j4K02py+mQ9yuCvSyXf3NEQKLEshon2xW+oE4a406RpLZFS+HeF6jHSA6M50kHMCx+dPlosH1WBgBg+8Qbc1+Url1nv1ixxG4kl82CcG/t81h5sFO6hdwxn3REFuP+phSbs/dUWT5pno5g5fY6gI+6F5farXsgqtEdQW/CR6NtOm5dCkXmBmW/ytq9RbU/VzeqSibz5IOSQQKnKYns3HRbfQZnFZltj7S9UYCIc9oVT9cH4x5UPvT+wMi+ZD4r/Go17NoXUrlKpix5iUUxHjHP4cV7n6bZ3jKRtppzQ0="
  }

  source_image_reference {
    publisher = var.publisher
    offer     = var.marketplace_offer
    sku       = var.sku
    version   = "latest"
  }

  os_disk {
    name    = "linux-osdisk-${count.index}"
    caching = "ReadWrite"
    #create_option     = "FromImage"
    storage_account_type = "Standard_LRS"
  }

  tags = merge(
    var.common_tags,
    { "ResourceType" = "LinuxVM" },
    { "BackupTier" = "${count.index + 1}" }
  )
}
