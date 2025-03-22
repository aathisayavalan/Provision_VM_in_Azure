"Modular terraform code from last article."

Title: “Automating Azure Infrastructure with Terraform: A Real-World Example” | by Arokia Athisayavalan B | Mar, 2025 | Medium

Prerequisites
Before we begin, ensure you have the following:

	1. An Azure account with an active subscription.
	2. Terraform installed on your local machine.
	3. Azure CLI installed and configured (az login).

Step 1: Setting Up Terraform Configuration
We'll start by creating a modular Terraform configuration to provision an Azure VM. Here's the directory structure:

Provision_VM_in_Azure/
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│   ├── azuread/
│   ├── network/
│   └── vm/

Replace xxx with subscription id and yyy with service principal id.
To get service principal use below command.
az ad sp show --id <client-id> --query id -o tsv
Client id is same as application id

Step 2: Defining the Azure AD Module
The azuread module creates an Azure AD application and service principal, which are required for authenticating Terraform with Azure.

# modules/azuread/main.tf
resource "azuread_application" "first_project" {
  display_name = "first_project"
}

resource "azuread_service_principal" "user_1" {
  client_id = azuread_application.first_project.client_id
}

resource "azuread_service_principal_password" "password" {
  service_principal_id = azuread_service_principal.user_1.id
  end_date             = "2025-06-30T23:59:59Z"
}

output "client_id" {
  value = azuread_application.first_project.client_id
}

output "client_secret" {
  value     = azuread_service_principal_password.password.value
  sensitive = true
}

Step 3: Creating the Network Module
The network module provisions the foundational networking components, such as a resource group, virtual network, subnet, and network security group (NSG).

# modules/network/main.tf
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "myPublicIP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "myNSG"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

output "subnet_id" {
  value = azurerm_subnet.subnet.id
}

output "public_ip_id" {
  value = azurerm_public_ip.public_ip.id
}

output "nsg_id" {
  value = azurerm_network_security_group.nsg.id
}


Step 4: Provisioning the VM
The vm module creates an Azure Linux VM using the networking components from the network module.

# modules/vm/main.tf
resource "azurerm_network_interface" "nic" {
  name                = "myNIC"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = var.nsg_id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "myRedHatVM"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = "Standard_B1s"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8.1"
    version   = "latest"
  }
}

output "vm_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}


Step 5: Running Terraform
	1. Initialize Terraform:
terraform init
	2. Plan the infrastructure:
terraform plan
	3. Apply the configuration:
terraform apply

Conclusion
By following this guide, you've learned how to automate the provisioning of an Azure VM using Terraform. This modular approach makes your infrastructure code reusable, maintainable, and scalable. Whether you're managing a single VM or an entire cloud environment, Terraform is a powerful tool to add to your DevOps toolkit.

Next Steps
	• Explore advanced Terraform features like workspaces and remote state management.
	• Integrate Terraform with CI/CD pipelines for automated deployments.
	• Learn how to use Terraform Cloud for collaborative infrastructure management.





















![image](https://github.com/user-attachments/assets/3618f653-2c3d-4777-abc3-7c160dbb0288)
