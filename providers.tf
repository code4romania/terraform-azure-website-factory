terraform {
  required_version = "~> 1.10"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.48"
    }
  }

  cloud {
    organization = "onghub"

    workspaces {
      tags = [
        "website-factory",
        "azure"
      ]
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
