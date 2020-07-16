# Creating an external IP for the Load Balancer
# resource "azurerm_public_ip" "lb-ip" {
#     name = "loadbalancer-ip"
#     location = var.az_region
#     resource_group_name = azurerm_resource_group.rg.name
#     allocation_method = "Static"
#     tags = {
#       lbtype = "vault-cluster"
#     }
# }

# Creating a Load Balancer backend pool
resource "azurerm_lb_backend_address_pool" "backend-pool" {
#   resource_group_name = azurerm_resource_group.rg.name
  resource_group_name         = var.az_resource_group
  loadbalancer_id     = azurerm_lb.vault-lb.id
  name                = "vault-address-pool"
}

# Creating the Load Balancer
resource "azurerm_lb" "vault-lb" {
  name                = "vault-dc-loadbalancer"
  location            = var.az_region
#   resource_group_name = azurerm_resource_group.rg.name
  resource_group_name         = var.az_resource_group
  # Need to define a Standard SKU if we want a HTTPS LB Probe
  sku = "Standard"

  frontend_ip_configuration {
    name                 = "VaultFrontEnd"
    # public_ip_address_id = azurerm_public_ip.lb-ip.id
    public_ip_address_id = var.lb_ip
  }
}

# Creating a Load Balancer probe to monitor /v1/sys/health
resource "azurerm_lb_probe" "vault-lb-probe" {
#   resource_group_name = azurerm_resource_group.rg.name
  resource_group_name         = var.az_resource_group
  loadbalancer_id     = azurerm_lb.vault-lb.id
  name                = "vault-probe"
  port                = 8200
  protocol = "${var.tls}" == "true" ? "Https" : "Http"
  request_path = "/v1/sys/health"
}

# Time to create the Load Balancer rule to redirect traffic
# Let's define ports to redirect in LB. The API port needs to be accessible, but
# also the cluster_addr port if doing replication between clusters
locals {
  lb_ports = [ 8200, 8201 ]
}
resource "azurerm_lb_rule" "lb-rule" {
  count = length(local.lb_ports)
#   resource_group_name            = azurerm_resource_group.rg.name
  resource_group_name         = var.az_resource_group
  loadbalancer_id                = azurerm_lb.vault-lb.id
  name                           = "${var.cluster}-rule-${count.index}"
  protocol                       = "Tcp"
  # frontend_port                  = 8200
  # backend_port                   = 8200
  frontend_port                  = local.lb_ports[count.index]
  backend_port                   = local.lb_ports[count.index]
  # frontend_ip_configuration_name = "VaultFrontEnd"
  frontend_ip_configuration_name = azurerm_lb.vault-lb.frontend_ip_configuration.0.name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend-pool.id
  probe_id = azurerm_lb_probe.vault-lb-probe.id
  # depends_on = [
  #   azurerm_lb_probe.vault-lb-probe,
  #   azurerm_lb_backend_address_pool.backend-pool
  # ]
}

# resource "azurerm_lb_rule" "lb-rule" {
# #   resource_group_name            = azurerm_resource_group.rg.name
#   resource_group_name         = var.az_resource_group
#   loadbalancer_id                = azurerm_lb.vault-lb.id
#   name                           = "${var.cluster}-rule-0"
#   protocol                       = "Tcp"
#   frontend_port                  = 8200
#   backend_port                   = 8200
#   frontend_ip_configuration_name = "VaultFrontEnd"
#   probe_id = azurerm_lb_probe.vault-lb-probe.id
# }

# --------------------------------------
