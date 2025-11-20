resource "azurerm_resource_provider_registration" "comms" {
  count = var.enable_acs ? 1 : 0
  name  = "Microsoft.Communication"
}

resource "azurerm_communication_service" "comms" {
  count               = var.enable_acs ? 1 : 0
  name                = "acs-${local.namespace}"
  resource_group_name = azurerm_resource_group.resource_group.name
  data_location       = var.acs_data_location

  depends_on = [
    azurerm_resource_provider_registration.comms
  ]
}

resource "azurerm_email_communication_service" "email" {
  count               = var.enable_acs ? 1 : 0
  name                = "acs-email-${local.namespace}"
  resource_group_name = azurerm_resource_group.resource_group.name
  data_location       = var.acs_data_location

  depends_on = [
    azurerm_resource_provider_registration.comms
  ]
}

resource "azurerm_email_communication_service_domain" "email" {
  count             = var.enable_acs ? 1 : 0
  name              = "AzureManagedDomain"
  email_service_id  = azurerm_email_communication_service.email[count.index].id
  domain_management = "AzureManaged"
}

resource "azurerm_communication_service_email_domain_association" "association" {
  count                    = var.enable_acs ? 1 : 0
  email_service_domain_id  = azurerm_email_communication_service_domain.email[count.index].id
  communication_service_id = azurerm_communication_service.comms[count.index].id
}

resource "azurerm_email_communication_service_domain_sender_username" "email" {
  count                   = var.enable_acs ? 1 : 0
  name                    = "no-reply"
  email_service_domain_id = azurerm_email_communication_service_domain.email[count.index].id
}
