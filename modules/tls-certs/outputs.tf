output "vault_crt" {
  value = tls_locally_signed_cert.server.*.cert_pem
}
output "vault_ca" {
    value = tls_self_signed_cert.ca.cert_pem
}
output "vault_key" {
    value = tls_private_key.server.*.private_key_pem
}
