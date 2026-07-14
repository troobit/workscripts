vnet_config = {
  this = {
    vnet_cidr = "10.0.0.0/16"
    subnets = {
      "public-fe" = {
        address_prefixes   = ["10.0.0.0/24"]
        service_delegation = []
      }
      "private-capp" = {
        address_prefixes   = ["10.0.1.0/24"]
        service_delegation = []
      }
      "private-db" = {
        address_prefixes   = ["10.0.2.0/24"]
        service_delegation = []
      }
    }
  }
}

# =============================================================================
# Container Apps
# =============================================================================

container_apps = [{ name = "frontend"
  revision_mode = "Single"
  template = { container = { name = "api"
    image = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu   = 0.25
memory = "0.5Gi" } } }]
