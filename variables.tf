variable "resource_group" {
  description = "Azure resource group to use for the cluster"
}
variable "owner" {
  description = "Owner of the cluster"
}
variable "numnodes" {
  description = "Number of nodes of Vault cluster"
}
variable "region" {
  description = "Cloud region to deploy Vault cluster"
}
variable "cluster_name" {
  description = "The name of the cluster to use"
}
variable "arm_client_secret" {
  description = "Secret used by ARM_CLIENT_SECRET env variable"
}
variable "az_image" {
  description = "Custom Vault image name"
}
variable "image_resource" {
  description = "Azure resource group of the Vault custom image"
}
variable "size" {
  description = "Machine size to use for nodes"
}
variable "domains" {
    description = "Domains for the nodes."
    default = "*.example.com"
}
variable "vmpasswd" {
  description = "Password for the vms of nodes like ssh access"
  default = "P4sswdS3cr3t!"
}
variable "enable_tls" {
  description = "If you want to enable TLS nodes certificates set this to true"
  default = "true"
}
variable "common_name" {
  description = "Common name to issue certificate"
  default = "example.com"
}
variable "own_certs" {
  description = "Set to true if putting certs as variables"
  default = false
}
variable "cert" {
  description = "Certificate for server node"
}
variable "ca_cert" {
  description = "CA Root certificate for servers node"
}
variable "cert_key" {
  description = "Certificate key for node"
}










