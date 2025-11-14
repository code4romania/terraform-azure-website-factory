locals {
  namespace_prefix = "wf-"
  namespace_suffix = var.env == "production" ? "" : "-${var.env}"
  namespace        = "${local.namespace_prefix}${var.project_slug}${local.namespace_suffix}"
  hostname         = var.hostname != null ? var.hostname : "${local.app_service.name}.azurewebsites.net"

  network = {
    vn_name          = "network-${local.namespace}"
    vn_address_space = ["10.0.0.0/16"]

    subnet_name             = "sn-${local.namespace}"
    subnet_address_prefixes = ["10.0.2.0/24"]
  }

  app_service = {
    name         = local.namespace
    docker_image = "code4romania/website-factory"
    size         = "B1" # Smallest tier but not free, F1 tier didn't allow to apply
  }

  storage_config = {
    name             = replace(local.namespace, "-", "")
    tier             = "Standard"
    replication_type = "LRS" # Locally Redundant Storage
    container_name   = "data"
  }

  db_config = {
    name              = local.namespace
    sku               = "B_Standard_B1ms"
    version           = "17"
    admin_db_user     = "psqladmin"
    admin_db_password = random_password.db_pass.result

    storage_mb                    = 32768
    backup_retention_days         = 7
    geo_redundant_backup_enabled  = false
    public_network_access_enabled = true
    zone                          = var.database_az_enabled ? var.database_az : null
  }

  mail = {
    mailer = var.enable_acs ? "azure" : "smtp"
    from   = var.enable_acs ? "${azurerm_email_communication_service_domain_sender_username.email[0].name}@${azurerm_communication_service.comms[0].hostname}" : var.mail_from_address

    smtp = {
      host       = var.enable_acs ? null : var.mail_host
      port       = var.enable_acs ? null : var.mail_port
      username   = var.enable_acs ? null : var.mail_username
      password   = var.enable_acs ? null : var.mail_password
      encryption = var.mail_encryption
    }

    azure = {
      resource_name = var.enable_acs ? azurerm_email_communication_service.email[0].name : null
      key           = var.enable_acs ? azurerm_communication_service.comms[0].primary_key : null
    }
  }
}
