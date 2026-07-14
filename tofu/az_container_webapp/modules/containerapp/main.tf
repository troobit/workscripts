# =============================================================================
# Locals
# =============================================================================
locals {
  env_vars_list = [
    for key, value in var.env_vars : {
      name  = key
      value = value
    }
  ]
}

# =============================================================================
# Container App(s)
# =============================================================================

resource "azurerm_container_app" "this" {
  name                         = "ca-${var.name}"
  container_app_environment_id = var.container_app_env_id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.app_config.revision_mode

  # Reference the managed identity to allow authentication to KV
  secret {
    name  = "azure-client-id"
    value = var.user_managed_client_ids[0]
  }

  secret {
    name                = "cr-password"
    identity            = var.user_managed_resource_ids[0]
    key_vault_secret_id = var.cr-password-secret-id
  }

  # Key vault to authenticate to
  secret {
    name  = "keyvault-uri"
    value = var.key_vault_uri
  }

  dynamic "secret" {
    for_each = local.env_vars_list
    content {
      name  = replace(lower(secret.value.name), "_", "-")
      value = secret.value.value
    }
  }

  template {
    container {
      name   = "ca-${var.app_config.template.container.name}"
      image  = var.app_config.template.container.image
      cpu    = var.app_config.template.container.cpu
      memory = var.app_config.template.container.memory

      dynamic "env" {
        for_each = local.env_vars_list
        content {
          name        = env.value.name
          secret_name = replace(lower(env.value.name), "_", "-")
        }
      }
      env {
        name        = "KeyVaultUri"
        secret_name = "keyvault-uri"
      }
    }

  }

  identity {
    type         = "UserAssigned"
    identity_ids = var.user_managed_resource_ids
  }

  tags = merge(var.common_tags, {
    "repository" = "troobit/this" # For using in the Azure DevOps pipeline when different repos deploy to the same RG
    }
  )
  lifecycle {
    ignore_changes = [
      ingress,
      registry,
      template[0].min_replicas,
      template[0].max_replicas,
      template[0].container[0].image,
      template[0].container[0].cpu,
      template[0].container[0].name,
      template[0].container[0].memory
    ]
  }
}

# =============================================================================
# Custom Domain - using Azure Managed Certificate
# =============================================================================

resource "azurerm_container_app_custom_domain" "this" {
  count           = var.custom_domain != null ? 1 : 0
  name             = var.custom_domain
  container_app_id = azurerm_container_app.this.id

  lifecycle {
    // When using an Azure created Managed Certificate these values must be added to ignore_changes to prevent resource recreation.
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }
}
