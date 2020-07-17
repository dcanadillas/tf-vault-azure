output "nodes" {
  value = module.azure.vault-nodes
}
output "load-balancer" {
  value = azurerm_public_ip.lb-ip.ip_address
}
output "TLS" {
    value = var.enable_tls
}
# output "bastion_host" {
#   value = module.azure.bastion
# }
output "vault_ca" {
    value = var.own_certs ? var.ca_cert : module.tls-cert.vault_ca
}