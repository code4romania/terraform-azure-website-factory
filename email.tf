resource "azurerm_communication_service" "email" {
  name                = "acs-email-${local.namespace}"
  resource_group_name = azurerm_resource_group.resource_group.name
  data_location       = var.acs_data_location
}

resource "azurerm_email_communication_service_domain" "email" {
  name              = "AzureManagedDomain"
  email_service_id  = azurerm_email_communication_service.email.id
  domain_management = "AzureManaged"
}

resource "azurerm_email_communication_service_domain_sender_username" "email" {
  name                    = "acs-email-sender-${local.namespace}"
  email_service_domain_id = azurerm_email_communication_service_domain.email.id
}
