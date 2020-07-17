
# Let's create an availability set
resource "azurerm_availability_set" "vault-avset" {
  name                = "vault-avset"
  location = var.az_region
  # location            = azurerm_resource_group.rg.location
  # resource_group_name = azurerm_resource_group.rg.name
  resource_group_name = var.az_resource_group
  platform_update_domain_count = 2
  platform_fault_domain_count = 2

  tags = {
    environment = "Staging"
  }
}

# Creating dynamically a hostname list to use later on template
data "null_data_source" "hostnames" {
  count = var.nodes
  inputs = {
      hostnames = "vault-server-${count.index}"
  }
}
locals {
  hostnames = data.null_data_source.hostnames.*.inputs.hostnames
}

# Create network interface
resource "azurerm_network_interface" "vault-dc-nic" {
  count = var.nodes
  name                      = "vault-dc-nic-${count.index}"
  location                  = var.az_region
  # resource_group_name       = azurerm_resource_group.rg.name
  resource_group_name = var.az_resource_group

  ip_configuration {
    name                          = "vault-nic-config-${count.index}"
    subnet_id                     = azurerm_subnet.vault-dc-subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = element(azurerm_public_ip.public-ip.*.id, count.index)
  }
}

# Let's gather the image we want to use for vault VM
data "azurerm_image" "vmimage" {
  name = var.custom_image
  resource_group_name = var.image_rg
}

# # Create a Linux virtual machine
resource "azurerm_virtual_machine" "vault-vm" {
  count = var.nodes
  name                  = "vault-vm-${count.index}"
  location              = var.az_region
  # resource_group_name   = azurerm_resource_group.rg.name
  resource_group_name = var.az_resource_group
  network_interface_ids = ["${element(azurerm_network_interface.vault-dc-nic.*.id, count.index)}"]
  # network_interface_ids = ["${azurerm_network_interface.vault-dc-nic[count.index].id}"]
  vm_size               = var.az_machine
  availability_set_id = azurerm_availability_set.vault-avset.id

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "myOsDisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb = 100
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    id = data.azurerm_image.vmimage.id
  }

  os_profile {
    computer_name  = "vault-server-${count.index}"
    admin_username = var.owner
    admin_password = var.vm_passwd
    # custom_data    = base64encode("${data.template_file.server[count.index].rendered}")
    custom_data = templatefile("${path.module}/templates/vault-config.tpl",{ 
      clustername = var.cluster,
      location      = var.az_region,
      #hostname      = azurerm_virtual_machine.vault-vm[count.index].os_profile.computer_name
      private_ip    = azurerm_network_interface.vault-dc-nic[count.index].private_ip_address,
      public_ip     = azurerm_public_ip.public-ip[count.index].ip_address,
      kmsvaultname  = azurerm_key_vault.dc-vault.name,
      kmskeyname    = azurerm_key_vault_key.dc-vault.name,
      # subscription_id = var.subscription_id
      tenant_id     = data.azurerm_client_config.current.tenant_id,
      client_id     = data.azurerm_client_config.current.client_id,
      client_secret = var.client_secret,
      object_id     = data.azurerm_client_config.current.object_id,
      # fqdn          = azurerm_public_ip.servers-pip[count.index].fqdn
      hosts = local.hostnames
      node_name     = local.hostnames[count.index],
      tls_disable = var.tls == "true" ? 0 : 1,
      me_ca         = var.ca_cert,
      me_cert       = element(var.vault_cert,count.index),
      me_key        = element(var.vault_key,count.index),
      http = var.tls ==  "true" ? "https" : "http",
      vault_servers    = var.nodes
    }) 
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  identity {
    type = "SystemAssigned"
  }

  # lifecycle {
  #   create_before_destroy = true
  # }
}

# Let's associate every VM to the Backend Pool of the Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "vault" {
  count                   = var.nodes
  network_interface_id    = azurerm_network_interface.vault-dc-nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.vault-dc-nic[count.index].ip_configuration.0.name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend-pool.id
}


# data "cloudinit_config" "foo" {
#   gzip = false
#   base64_encode = false

#   part {
#     content_type = "text/x-shellscript"
#     filename = templatefile()"${path.module}/templates/vault-config.tpl",...)
#   }
# }


# ------- Template file for Vault installation -----
# # DEPRECATED
# data "template_file" "server" {
#   # depends_on = [azurerm_public_ip.servers-pip]
#   count      = var.nodes

#   template = "${file("${path.module}/templates/vault.tpl")}"

#   vars = {
#     clustername = var.cluster
#     location      = var.az_region
#     #hostname      = azurerm_virtual_machine.vault-vm[count.index].os_profile.computer_name
#     private_ip    = azurerm_network_interface.vault-dc-nic[count.index].private_ip_address
#     public_ip     = azurerm_public_ip.public-ip[count.index].ip_address
#     # enterprise    = var.enterprise
#     # vaultlicense  = var.vaultlicense
#     kmsvaultname  = azurerm_key_vault.dc-vault.name
#     kmskeyname    = azurerm_key_vault_key.dc-vault.name
#     # subscription_id = var.subscription_id
#     tenant_id     = data.azurerm_client_config.current.tenant_id
#     # client_id     = azurerm_user_assigned_identity.dc-vault.client_id
#     client_id     = data.azurerm_client_config.current.client_id
#     client_secret = var.client_secret
#     # object_id     = azurerm_user_assigned_identity.dc-vault.principal_id
#     object_id     = data.azurerm_client_config.current.object_id
#     # fqdn          = azurerm_public_ip.servers-pip[count.index].fqdn
#     node_name     = "vault-server-${count.index}"
#     tls_disable = var.tls == "true" ? 0 : 1
#     me_ca         = var.ca_cert
#     me_cert       = var.vault_cert[count.index]
#     me_key        = var.vault_key[count.index]
#     vault_servers    = var.nodes
#  }
# }

