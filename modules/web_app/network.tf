# Create a virtual network within the resource group
resource "azurerm_virtual_network" "vn_network" {
  name                = local.network.vn_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  address_space       = local.network.vn_address_space

  tags = {
    app = var.project_slug
    env = var.env
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = local.network.subnet_name
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vn_network.name
  address_prefixes     = local.network.subnet_address_prefixes
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Create DNS name for postgress
resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "${local.db_config.name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.resource_group.name

  tags = {
    app = var.project_slug
    env = var.env
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_vnet_link" {
  name                  = "${var.project_slug}-link"
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vn_network.id
  resource_group_name   = azurerm_resource_group.resource_group.name

  tags = {
    app = var.project_slug
    env = var.env
  }
}
