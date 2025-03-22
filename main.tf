terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azuread" {}

provider "azurerm" {
  alias           = "cli"
  features {}
  subscription_id = var.subscription_id
  use_msi         = false
}

module "azuread" {
  source = "./modules/azuread"
}



resource "azurerm_role_assignment" "example" {
  provider =             azurerm.cli
  scope                = "/subscriptions/xxx"
  role_definition_name = "Contributor"
  principal_id         = "yyy"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = module.azuread.client_id
  client_secret   = module.azuread.client_secret
  tenant_id       = var.tenant_id
}


module "network" {
  source              = "./modules/network"
  resource_group_name = var.resource_group_name
  location            = var.location
  depends_on          = [module.azuread,
                        azurerm_role_assignment.example
                        ]
}

module "vm" {
  source              = "./modules/vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = module.network.subnet_id
  public_ip_id        = module.network.public_ip_id
  nsg_id              = module.network.nsg_id
  admin_username      = var.admin_username
  ssh_public_key      = tls_private_key.ssh_key.public_key_openssh
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/id_rsa"
}
