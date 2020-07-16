variable "algorithm" {
  description = "Private key algorithm"
  default = "RSA"
}
variable "ecdsa_curve" {
    description = "Elliptive curve to use for ECDS algorithm"
    default = "P521"
}
variable "rsa_bits" {
  description = "Size of RSA algorithm. 2048 by default."
  default = 2048
}

variable "ca_common_name" {
  default = "vault-ca.local"
}
variable "ca_organization" {
  default = "Hashi Vault"
}
variable "common_name" {
  default = "vault.local"
}
variable "vaulthost" {
  description = "Domain for the cert"
}
variable "compute_address" {
    description = "IP address. Can come "
}
variable "validity_period_hours" {
  default = 8760
}
variable "servers" {
  description = "Vault server nodes"
}





