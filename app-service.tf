# Create App Service plan to define the capacity and resources to be shared among the app services that will be assigned to that plan
resource "azurerm_service_plan" "app_service_plan" {
  name                = local.app_service.name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  os_type             = "Linux"
  sku_name            = local.app_service.size

  tags = {
    app = var.project_slug
    env = var.env
  }

  depends_on = [
    azurerm_postgresql_flexible_server_database.db
  ]
}

resource "azurerm_linux_web_app" "app_service" {
  name                = local.app_service.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  service_plan_id     = azurerm_service_plan.app_service_plan.id
  https_only          = true

  site_config {
    application_stack {
      docker_image_name = "${local.app_service.docker_image}:${var.docker_tag}"
    }

    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 2

    http2_enabled = true
  }

  app_settings = {
    "APP_URL"                 = "https://${local.hostname}"
    "APP_DEBUG"               = var.debug_mode
    "APP_ENV"                 = var.env
    "APP_KEY"                 = random_password.app_key.result
    "WEBSITE_FACTORY_EDITION" = var.edition
    "DB_CONNECTION"           = "pgsql"
    "DB_HOST"                 = azurerm_private_dns_zone.dns_zone.name
    "DB_PORT"                 = "5432"
    "DB_DATABASE"             = azurerm_postgresql_flexible_server_database.db.name
    "DB_USERNAME"             = local.db_config.admin_db_user
    "DB_PASSWORD"             = local.db_config.admin_db_password
    "MAIL_MAILER"             = "smtp"
    "MAIL_HOST"               = var.mail_host
    "MAIL_PORT"               = var.mail_port
    "MAIL_USERNAME"           = var.mail_username
    "MAIL_PASSWORD"           = var.mail_password
    "MAIL_ENCRYPTION"         = var.mail_encryption
    "MAIL_FROM_ADDRESS"       = var.mail_from_address
    "FILESYSTEM_DRIVER"       = "azure"
    "FILESYSTEM_CLOUD"        = "azure"
    "AZURE_STORAGE_NAME"      = azurerm_storage_account.storage_account.name
    "AZURE_STORAGE_KEY"       = azurerm_storage_account.storage_account.primary_access_key
    "AZURE_STORAGE_CONTAINER" = azurerm_storage_container.storage_container.name
    "ADMIN_EMAIL"             = var.admin_email
    "ADMIN_PASSWORD"          = random_password.admin_password.result
    "SENTRY_DSN"              = var.sentry_dsn
    "SENTRY_ENVIRONMENT"      = coalesce(var.sentry_environment, var.project_slug)
  }

  connection_string {
    name  = "website-factory-db-connection"
    type  = "PostgreSQL"
    value = azurerm_private_dns_zone.dns_zone.name
  }

  tags = {
    app = var.project_slug
    env = var.env
  }
}

# root domain certificate
resource "azurerm_app_service_custom_hostname_binding" "root_hostname_binding" {
  count               = var.hostname == null ? 0 : 1
  hostname            = var.hostname
  app_service_name    = azurerm_linux_web_app.app_service.name
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_app_service_managed_certificate" "root_managed_certificate" {
  count                      = var.hostname == null ? 0 : 1
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.root_hostname_binding[count.index].id

  tags = {
    app = var.project_slug
    env = var.env
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_app_service_certificate_binding" "root_certificate_binding" {
  count               = var.hostname == null ? 0 : 1
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.root_hostname_binding[count.index].id
  certificate_id      = azurerm_app_service_managed_certificate.root_managed_certificate[count.index].id
  ssl_state           = "SniEnabled"
}

# www subdomain certificate
resource "azurerm_app_service_custom_hostname_binding" "www_hostname_binding" {
  count               = var.hostname == null ? 0 : 1
  hostname            = "www.${var.hostname}"
  app_service_name    = azurerm_linux_web_app.app_service.name
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_app_service_managed_certificate" "www_managed_certificate" {
  count                      = var.hostname == null ? 0 : 1
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.www_hostname_binding[count.index].id

  tags = {
    app = var.project_slug
    env = var.env
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_app_service_certificate_binding" "www_certificate_binding" {
  count               = var.hostname == null ? 0 : 1
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.www_hostname_binding[count.index].id
  certificate_id      = azurerm_app_service_managed_certificate.www_managed_certificate[count.index].id
  ssl_state           = "SniEnabled"
}
