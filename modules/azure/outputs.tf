output "vault-nodes" {
  value = azurerm_public_ip.public-ip.*.ip_address
}
# output "bastion" {
#   value = azurerm_bastion_host.bastion.dns_name
# }