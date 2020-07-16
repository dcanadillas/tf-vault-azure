# Vault deployment with Raft Integrated Storage in Azure
> DISCLOSURE: This repo is not an official HashiCorp repository and **is a work in progress**

The repository is structured to deploy HashiCorp Vault in Azure with the following workflow:
- Publish a Packer customized image with Vault binary installed and required packages
- Provision Vault infrastructure with Terraform to deploy a Vault cluster using Raft integrated storage
- Starting Vault operations manually (`vault operator` commands)

The workflow is represented in the following diagram:

![Terraform Azure Deploy](Terraform-VaultDeploy(Azure).png)

## Requirements
You will need to do the following in order to execute the Terraform configuration and build the image with Packer:

* Download Packer
* Download Terraform
* Configure access and Azure permissions as a contributor at least to be able to create and manage:
  * Network and load balancing resources
  * Compute resources and VMs
  * Resource groups
  * Azure Key Vault
* Create or get permissions on an Azure `resource group` where storing custom images (for Packer image building)

### Configure Azure Service Principal credentials as environment variables
Execute the following shellscript commands (Bash/Zsh tested):
```bash
export ARM_SUBSCRIPTION_ID="<your_subscription_id>"
export ARM_CLIENT_ID="<your_client_id>"
export ARM_CLIENT_SECRET="<your_client_secret>"
export ARM_TENANT_ID="<your_tenant_id>" 
```

### Define an Azure resource group for you Packer images
You can do this in Azure Portal or use `az` CLI:

```bash
az group create --name <your_custom_image_resource_group> --location <azure_region>
```

## Building Vault Packer image
In the `packer` directory you will find the resources to build the image with Packer. So, to build it, just execute:

```bash
$ cd packer
$ packer build -var resource_group="<your_custom_images_resource_group>" \
-var version="1_4_2Ent" \
-var vault_version="1.4.2+ent" \
vault.json
```
Yoy can change them, depending on version and name of your image, but previous Packer variables are defined as:
* `version`: This is just a version number to identify you custom image name (name it as you want, but recommended to align the name with the Vault version)
* `vault_version`: Specific Vault version that you can find [here](https://releases.hashicorp.com/vault/) (remove "vault" word. For example, vault_1.4.2 would be `packer ... -var vault_version="1.4.2" ...`)


## Remote or local backend for Terraform

You can use either your local execution of Terraform or using Terraform Cloud/Terraform Enterprise (TFC/TFE) as backends.

### If you use TFE o TFC
This repo is designed to use TFC/TFE as a remote backend if you want. In that case, please comment out the following lines in [`main.tf`](./main.tf):

```
terraform {
    backend "remote"{ 
    }
}
```

Edit the file [`backend_template.hcl`](./backend_template.hcl) with your TFC/TFE organization and workspace:
```
workspaces { name = "<my_workspace>" }
hostname     = "app.terraform.io"
organization = "<my_org>"
```

Rename the file for simplicity:
```bash
mv backend_template.hcl backend.hcl
```

Initialize your Terraform with the backend configuration (remember to be on the root path of this repo):

```bash
terraform init -backend-config=backend.hcl
```

And last, and very important, configure your [workspace variables](https://www.terraform.io/docs/cloud/workspaces/variables.html) (you can use [my own Python wrapper](https://github.com/dcanadillas/tfc-python) where you can upload them *in a batch way*. Or using a `*.auto.tfvars` file from local for the Terraform type ones ):
- Environment variables:
    * `ARM_SUBSCRIPTION_ID`
    * `ARM_CLIENT_ID` (as sensitive)
    * `ARM_CLIENT_SECRET` (as sensitive)
    * `ARM_TENANT_ID` (as sensitive)
- Terraform variables:
    * `resource_group`	
    * `arm_client_secret` (as sensitive value)
    * `owner`
    * `numnodes`
    * `region`
    * `cluster_name`
    * `az_image`
    * `image_resource`
    * `size`
    * `vmpasswd` (as sensitive value)
    * `enable_tls` (true or false)
    * `domains`
    * `common_name`

### Using local Terraform backend

If you use a common Terraform OSS local backend:
1. Edit the `terraform.tfvars.example` with your desired values and rename it:
   ```bash
   mv terraform.tfvars.example terraform.tfvars
   ```
2. Initialize your Terraform locally (remote backend lines are commented by default in `main.tf`, but if not you need to comment them):
   ```bash
   terraform init
   ```

## Deploying Vault infra with Terraform

Once you have your custom image in Azure with the required environment and Terraform backend configured you can execute the Terraform configuration to deploy the infra:

```bash
terraform apply
```

Check that the resources to be created in the Plan are the right ones and type `yes`.

## Operate your Vault

Once the Terraform is applied, the status of the Vault cluster nodes is about a `vault service` running, but the Vault nodes are still [sealed](). So, it is required to initialize one of the nodes of the cluster to start operating Vault. Once that node is initialized, the other servers (nodes) will join as followers of the Raft cluster.

Connect then to one of the nodes through ssh (be aware that ssh credentials are configured with `owner` Terraform variable as user and `vm_password` as password). You can see the nodes external IPs from the Terraform output:

```
...
Apply complete! Resources: 39 added, 0 changed, 0 destroyed.

Outputs:

TLS = true
load-balancer = 40.119.153.162
nodes = [
  "40.119.155.74",
  "40.119.154.18",
  "40.119.154.160",
]
...
```

To initialize Vault, first check that the service is running: 

```
$ sudo systemctl status vault
● vault.service - Vault
   Loaded: loaded (/etc/systemd/system/vault.service; disabled; vendor preset: enabled)
   Active: active (running) since Thu 2020-07-16 13:32:45 UTC; 2min 12s ago
     Docs: https://www.vaultproject.io/docs/
 Main PID: 2868 (vault)
    Tasks: 14 (limit: 19141)
   CGroup: /system.slice/vault.service
           └─2868 /usr/local/bin/vault server -config=/etc/vault.d/config.hcl
```

And initialize with the vault `operator` command:

```
$ vault operator init --recovery-shares=1 --recovery-threshold=1
Recovery Key 1: cblu3M+huuSNL/9zfGpFN19H4EI3rXAoSqLa18vi0/c=

Initial Root Token: s.obosXhIYkomNjSUQUMw4T9qo

Success! Vault is initialized

Recovery key initialized with 1 key shares and a key threshold of 1. Please
securely distribute the key shares printed above.
```

> Don't forget to save the output of this command and store the `Recovery Key` in a safe place. You can output the command to a file (`vault operator init --recovery-shares=1 --recovery-threshold=1 > vault-init.log`) and store that file in a safe place:
> ```
> $ az storage blob upload \
> --account-name <existing_storage-account> \
> --container <existing_blob_container> \
> --name <blob_name> 
> --file vault-init.log
> ```