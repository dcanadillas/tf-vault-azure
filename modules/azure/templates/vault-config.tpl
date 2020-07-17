#!/bin/bash

VAULT_DIR="/etc/vault.d"

# ---- Preparing certificates ----
echo "==> Adding trusted root CA"
sudo tee /usr/local/share/ca-certificates/01-me.crt > /dev/null <<EOF
${me_ca}
EOF
sudo update-ca-certificates &>/dev/null

echo "==> Adding my certificates"
sudo tee /etc/ssl/certs/me.crt > /dev/null <<EOF
${me_cert}
EOF
sudo tee /etc/ssl/certs/me.key > /dev/null <<EOF
${me_key}
EOF
# ----------------------------------

echo "==> Vault (server)"
# Vault expects the key to be concatenated with the CA
sudo mkdir -p $VAULT_DIR/tls/
sudo tee $VAULT_DIR/tls/vault.crt > /dev/null <<EOF
$(cat /etc/ssl/certs/me.crt)
$(cat /usr/local/share/ca-certificates/01-me.crt)
EOF


echo "==> Generating Vault config"
if [ -d "$VAULT_DIR" ]; then
    sudo tee $VAULT_DIR/config.hcl > /dev/null <<EOF
    cluster_name = "${clustername}-demo"

    storage "raft" {
        path = "/vault/data"
        node_id = "${node_name}"
%{ for leader_host in hosts ~}
%{ if node_name != leader_host ~}
        retry_join {
            leader_api_addr = "${http}://${leader_host}:8200"
            # leader_ca_cer_file = "/path/to/ca1"
            # leader_client_cert_file = "/etc/vault.d/tls/vault.crt"
            # leader_client_key_file = "/etc/ssl/certs/me.key"
        }
%{ endif ~}
%{ endfor ~}
    }

    listener "tcp" {
        address       = "0.0.0.0:8200"
        cluster_address = "0.0.0.0:8201"
        tls_disable = ${tls_disable}
        tls_cert_file = "/etc/vault.d/tls/vault.crt"
        tls_key_file  = "/etc/ssl/certs/me.key"
    }


    seal "azurekeyvault" {
        tenant_id      = "${tenant_id}"
        client_id      = "${client_id}"
        client_secret  = "${client_secret}"
        vault_name     = "${kmsvaultname}"
        key_name       = "${kmskeyname}"
        enviroment    = "AzurePublicCloud"
    }
    replication {
        resolver_discover_servers = false
    }
    api_addr = "${http}://${public_ip}:8200"
    cluster_addr = "${http}://${private_ip}:8201"
    disable_mlock = true

    ui = true
EOF
else
    echo "$VAULT_DIR does not exist" >> /tmp/tf-vault.log
fi

echo "==> Starting Vault server..."
sudo systemctl start vault