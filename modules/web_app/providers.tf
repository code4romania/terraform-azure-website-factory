terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.23"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
