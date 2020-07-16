# # Creating the resource group for the vms
# resource "azurerm_resource_group" "rg" {
#     name = var.az_resource_group
#     location = var.az_region

#     tags = {
#         owner = var.owner
#         Team = "HashiSE"   
#     }
# }

# Create a virtual network
resource "azurerm_virtual_network" "vault-dc-net" {
    name = "vault-dc-network"
    address_space = ["10.0.0.0/16"]
    location = var.az_region
    # resource_group_name = azurerm_resource_group.rg.name
    resource_group_name         = var.az_resource_group

    tags = {
        owner = var.owner
        Team = "HashiSE"   
    }
}
# A subnet to create
resource "azurerm_subnet" "vault-dc-subnet" {
    name = "vault-dc-subnet"
    # resource_group_name = azurerm_resource_group.rg.name
    resource_group_name         = var.az_resource_group
    virtual_network_name = azurerm_virtual_network.vault-dc-net.name
    address_prefixes = ["10.0.1.0/24"]
}

# Creating a public IP
resource "azurerm_public_ip" "public-ip" {
    count = var.nodes
    name = "vault-ip-${count.index}"
    location = var.az_region
    # resource_group_name = azurerm_resource_group.rg.name
    resource_group_name = var.az_resource_group
    sku = "Standard"
    allocation_method = "Static"
    lifecycle {
        create_before_destroy = true
    }
}

# Create a Security Group
resource "azurerm_network_security_group" "vault-sg" {
    name  = "vault-dc-sg"
    location = var.az_region
    # resource_group_name = azurerm_resource_group.rg.name
    resource_group_name = var.az_resource_group

  tags = {
    owner     = var.owner
    Team = "HashiSE"
 }
# SSH
  security_rule {
    name                       = "vault-dc-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
# HTTP
  security_rule {
    name                       = "vault-dc-http"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

# HTTPS
  security_rule {
    name                       = "vault-dc-https"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

#LDAP
  security_rule {
    name                       = "vault-dc-LDAP"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "dc-vault-instance"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8200-8201"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Associate the security group to the Subnet
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.vault-dc-subnet.id
  network_security_group_id = azurerm_network_security_group.vault-sg.id
}