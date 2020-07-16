data "azurerm_client_config" "current" {
}

resource "random_id" "keyvault" {
  byte_length = 4
}

resource "random_id" "keyvaultkey" {
  byte_length = 4
}

resource "azurerm_key_vault" "dc-vault" {
  name                        = "demo-dc-${random_id.keyvault.hex}"
  location = var.az_region
#   location                    = azurerm_resource_group.rg.location
#   resource_group_name         = azurerm_resource_group.rg.name
  resource_group_name         = var.az_resource_group
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id

  sku_name  = "standard"
  

  tags = {
    owner     = var.owner
    environment = var.cluster
 }
 access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id

    #object_id = "${var.object_id}"
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get",
      "list",
      "create",
      "delete",
      "update",
      "wrapKey",
      "unwrapKey",
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

# resource "azurerm_user_assigned_identity" "dc-vault" {
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location

#   name = "${var.cluster}-demo-vm"
# }

# resource "azurerm_key_vault_access_policy" "dc-vault_vm" {
#   key_vault_id          = azurerm_key_vault.dc-vault.id
#   tenant_id = data.azurerm_client_config.current.tenant_id
#   object_id = data.azurerm_client_config.current.object_id
#   certificate_permissions = [
#     "get",
#     "list",
#     "create",
#   ]
#   key_permissions = [
#     "backup",
#     "create",
#     "decrypt",
#     "delete",
#     "encrypt",
#     "get",
#     "import",
#     "list",
#     "purge",
#     "recover",
#     "restore",
#     "sign",
#     "unwrapKey",
#     "update",
#     "verify",
#     "wrapKey",
#   ]
#   secret_permissions = [
#     "get",
#     "list",
#     "set",
#   ]
# }

resource "azurerm_key_vault_key" "dc-vault" {
  name      = "demo-dc-${random_id.keyvaultkey.hex}"
  key_vault_id = azurerm_key_vault.dc-vault.id
  key_type  = "RSA"
  key_size  = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  tags = {
    owner     = var.owner
    environment = var.cluster
  }
}