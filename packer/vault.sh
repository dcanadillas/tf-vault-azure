#!/bin/bash

# VERSION_NUMBER="1.4.2"
VERSION_NUMBER="$1"

# VAULT_VERSION="$VERSION_NUMBER+ent"
VAULT_VERSION="$VERSION_NUMBER"
VAULT_ZIP="/tmp/vault.zip"
VAULT_DEST="/tmp"
VAULT_CONFIG="config.hcl"
VAULT_DATA="/vault/data"

# Update and install needed packages
sudo apt update && sudo apt install -y unzip


curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip

unzip -d $VAULT_DEST $VAULT_ZIP

sudo mv $VAULT_DEST/vault /usr/local/bin/vault
sudo chmod 0755 /usr/local/bin/vault
sudo mkdir -pm 0755 /etc/vault.d
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
sudo useradd --system --home /etc/vault.d --shell /bin/false vault
sudo chown vault:vault /usr/local/bin/vault


echo "--> Creating data Raft storage dir at $VAULT_DATA"
sudo mkdir -p $VAULT_DATA
sudo chown vault:vault $VAULT_DATA


echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/vault.service > /dev/null <<EOF
[Unit]
Description=Vault
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
User=vault
Group=vault
Restart=on-failure
ExecStart=/usr/local/bin/vault server -config="/etc/vault.d/$VAULT_CONFIG"
ExecReload=/bin/kill -HUP \$MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

