# # variable "az_subscription" {
# # }
# # variable "az_tenantid" {

# # }

variable "cluster" {
  default = "vault-dc-cluster"
}
variable "az_resource_group" {
  default = "dcanadillas-rg"
}

variable "az_region" {
  default = "westeurope"
}
variable "az_zone" {
    default = "westeurope1"
}
variable "owner" {
  
}
variable "az_machine" {
  default = "Standard_DS1_v2"
}
variable "nodes" {
  default = 1
}
variable "client_secret" {
  default = ""
  description = "The client secret of the client ID used in ARM_CLIENT_SECRET env variable"
}
variable "custom_image" {
  description = "Custom image to use for Vault VM"
  default = "Ubuntu-Vault-1_4_2"
}
variable "image_rg" {
  description = "Resource group name for the custom image to use"
  default = "dcanadillas-images"
}
variable "lb_ip" {
  description = "Load Balancer IP"
}
variable "vault_cert" {
  description = "Certificates for Vault nodes"
}
variable "vault_key" {
  description = "Vault servers private keys"
}
variable "ca_cert" {
  description = "CA certificate"
}
variable "vm_passwd" {
  description = "Password for the vm nodes to access by ssh"
}
variable "tls" {
  description = "Enable TLS termination at nodes with certificate if value is true"
  default = true
}







