# ## We are creating a bastion in case we don't make public subnet for the nodes
# resource "azurerm_public_ip" "bastion-ip" {
#     name = "bastion-ip"
#     location = var.az_region
#     # resource_group_name = azurerm_resource_group.rg.name
#     resource_group_name = var.az_resource_group
#     sku = "Standard"
#     allocation_method = "Static"
#     lifecycle {
#         create_before_destroy = true
#     }
# }

# resource "azurerm_subnet" "bastion-subnet" {
#     name = "AzureBastionSubnet"
#     # resource_group_name = azurerm_resource_group.rg.name
#     resource_group_name         = var.az_resource_group
#     virtual_network_name = azurerm_virtual_network.vault-dc-net.name
#     address_prefixes = ["10.0.2.0/24"]
# }

# resource "azurerm_bastion_host" "bastion" {
#   name = "bastion-host"
#   location = var.az_region
#   resource_group_name = var.az_resource_group

#   ip_configuration {
#     name                 = "bastion-conf"
#     subnet_id            = azurerm_subnet.bastion-subnet.id
#     public_ip_address_id = azurerm_public_ip.bastion-ip.id
#   }
# }