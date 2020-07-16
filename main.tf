terraform {
    required_version = "~> 0.12"
    backend "remote"{ 
    }
}

provider "azurerm" {
    # 2.18.0 has an issue with availability set definition and lb rules: https://github.com/terraform-providers/terraform-provider-azurerm/issues/7691
    # We are using 2.17.0 in the meantime. If using 2.18.0 just remove the avset definition and its reference on the vm creation
    version = "=2.17.0"
    features {}
    use_msi = true
    # subscription_id = var.az_subscription
    # tenant_id       = var.az_tenantid
    # client_id           = var.az_client_id
    # client_secret       = var.az_client_secret
}

# Creating the resource group for the vms
resource "azurerm_resource_group" "rg" {
    name = var.resource_group
    location = var.region

    tags = {
        owner = var.owner
        Team = "HashiSE" 
        DoNotDelete = "True"  
    }
}

resource "azurerm_public_ip" "lb-ip" {
    name = "loadbalancer-ip"
    location = var.region
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Static"
    # Standard SKU is needed if we want HTTPS health probe from the Load Balancer
    sku = "Standard"
    tags = {
      lbtype = "vault-cluster"
      owner = var.owner
    }
}

module "tls-cert" {
  source = "./modules/tls-certs"

  algorithm = "RSA"
  ca_common_name = "vault-ca.local"
  ca_organization = "HashiCA"
  common_name = var.common_name
  vaulthost = var.domains
  compute_address = azurerm_public_ip.lb-ip.ip_address
  servers = var.numnodes
}

module "azure" {
  source = "./modules/azure"
  
  cluster = var.cluster_name
  az_resource_group = azurerm_resource_group.rg.name
  az_region = var.region
  az_machine = var.size
  owner = var.owner
  nodes = var.numnodes
  client_secret = var.arm_client_secret
  custom_image = var.az_image
  image_rg = var.image_resource
  lb_ip = azurerm_public_ip.lb-ip.id
  tls = var.enable_tls
  vault_cert = var.own_certs ? var.cert : module.tls-cert.vault_crt
  vault_key = var.own_certs ? var.cert_key : module.tls-cert.vault_key
  ca_cert = var.own_certs ? var.ca_cert : module.tls-cert.vault_ca
  vm_passwd = var.vmpasswd
}
