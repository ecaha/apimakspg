terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
    }
    azapi = {
      source  = "azure/azapi"
    }
    docker ={
      source = "kreuzwerker/docker"
    }
  }
}

provider "azurerm" {
    features {
    }
    subscription_id = var.subscriptionid
    tenant_id = var.tennantid
}

provider "azapi" {
    subscription_id = var.subscriptionid
    tenant_id = var.tennantid
}

resource "azurerm_resource_group" "baserg" {
  name = var.rgName
  location = var.location
}

resource "azurerm_storage_account" "common" {
  name = "${var.projectPrefix}store007"
  location = var.location
  resource_group_name = azurerm_resource_group.baserg.name
  account_tier = "Standard"
  account_kind = "StorageV2"
  account_replication_type = "LRS"
}
