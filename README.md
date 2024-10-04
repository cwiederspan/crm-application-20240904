# CRM Sample Application

A sample application for building and deploying a simple CRM application.

## Getting Started and Setup

```bash

source .env

az login -t $ARM_TENANT_ID

```

## Layer 0: Global Library

> NOTE: Nothing to do on this step, it is a library that is used by other layers.

## Layer 1: Global Infrastructure

This layer is used to create resources like hub VNETs, DNS Zones, observability tools and other global resources.

```bash

cd infra/layer1-global_infrastructure/

# Uses local storage for state
terraform init

# Apply the Terraform
terraform apply \
-var "base_name=crm-v1-l1-globalcore" \
-var "location=$LOCATION"

# Log output variables
app_outbound_subnet_id

```

## Layer 2: Product Platform

This layer is used to create shared application or platform resources like spoke VNETs, storage accounts, key vaults, databases and other resources.

```bash

cd infra/layer2-product_platform/

# Uses local storage for state
terraform init

# Apply the Terraform
terraform apply \
-var "base_name=crm-v1-l2-appcore" \
-var "location=$LOCATION"

# Log output variables
key_vault_uri
afd_default_origin_group_id
afd_endpoint_id
user_managed_identity_id

```

## Layer 3: Application

This layer is used to create specific application resources like VMs, app plans and services, storage accounts, etc.

### Sample Application 001

```bash

cd infra/layer3-application/app001/

# Uses local storage for state
terraform init

# Check the variables from the previous runs
SUBNET_ID=$(terraform output -state=../../layer1-global_infrastructure/terraform.tfstate -json | jq -r '.app_outbound_subnet_id.value')
KV_URI=$(terraform output -state=../../layer2-product_platform/terraform.tfstate -json | jq -r '.key_vault_uri.value')
AFD_DOG_ID=$(terraform output -state=../../layer2-product_platform/terraform.tfstate -json | jq -r '.afd_default_origin_group_id.value')
AFD_ENDPOINT_ID=$(terraform output -state=../../layer2-product_platform/terraform.tfstate -json | jq -r '.afd_endpoint_id.value')
USER_ID=$(terraform output -state=../../layer2-product_platform/terraform.tfstate -json | jq -r '.user_managed_identity_id.value')

# Apply the Terraform
terraform apply \
-var "base_name=crm-v1-l3-app001" \
-var "location=$LOCATION" \
-var "outbound_subnet_id=$SUBNET_ID" \
-var "user_managed_identity=$USER_ID" \
-var "key_vault_uri=$KV_URI" \
-var "afd_endpoint_id=$AFD_ENDPOINT_ID" \
-var "afd_default_origin_group_id=$AFD_DOG_ID"

```

## Application Deployment

This will allow you to deploy the sample application to the app service created above.

```bash

cd app/WebApplication1

dotnet publish -c Release

# Now use the VS Code App Service extension to deploy the app

```