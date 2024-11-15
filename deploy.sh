#!/bin/bash

# Variables
read -p "Enter your initials: " INITIALS
RANDOM_SUFFIX=$(date +%Y%m%d)
RESOURCE_GROUP=$INITIALS"-aks-rg"
CLUSTER_NAME=$INITIALS"-aks-cluster"
LOCATION="centralus"
SYSTEM_NODE_POOL="systempool"
USER_NODE_POOL="userpool"
USER_NODE_COUNT=1
ACR_NAME=$INITIALS"acr"$RANDOM_SUFFIX
KV_NAME=$INITIALS"-aks-kv"
APP_INSIGHTS_CONNECTION_STRING_NAME="app-insights-connection-string"
LOG_ANALYTICS_WORKSPACE=$INITIALS"-aks-law"
APP_INSIGHTS=$INITIALS"-aks-appinsights"
IDENTITY_NAME=$INITIALS"-aks-identity"
TAGS="Environment=Development Owner=$INITIALS"

# Check if the user is already logged in to Azure
if ! az account show > /dev/null 2>&1; then
  echo "You are not logged in to Azure. Please log in."
  az login
else
  echo "You are already logged in to Azure."
fi

# get tenant id
TENANT_ID=$(az account show --query tenantId --output tsv)

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION --tags $TAGS

# Create AKS cluster with system node pool
az aks create \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --name $CLUSTER_NAME \
    --nodepool-name $SYSTEM_NODE_POOL \
    --node-count 1 \
    --enable-managed-identity \
    --generate-ssh-keys \
    --tags $TAGS

# Create user node pool
az aks nodepool add \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --name $USER_NODE_POOL \
    --node-count $USER_NODE_COUNT \
    --os-type Linux \
    --mode User

# Create user managed identity
az identity create --name $IDENTITY_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --tags $TAGS

# Get the identity resource ID
IDENTITY_ID=$(az identity show --name $IDENTITY_NAME --resource-group $RESOURCE_GROUP --query principalId --output tsv)

# Attach Azure Container Registry to AKS cluster
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --tags $TAGS
az aks update -n $CLUSTER_NAME -g $RESOURCE_GROUP --attach-acr $ACR_NAME

# create azure key vault and disable soft delete
az keyvault create --name $KV_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --tags $TAGS --enable-rbac-authorization true

# Get the Key Vault resource ID
KV_ID=$(az keyvault show --name $KV_NAME --resource-group $RESOURCE_GROUP --query id --output tsv)

# Get the signed-in user's object ID
USER_OBJECT_ID=$(az ad signed-in-user show --query id --output tsv)

# Assign KeyVaultSecretsOfficer role to the managed identity
az role assignment create --role "Key Vault Secrets Officer" --assignee-object-id $USER_OBJECT_ID --scope $KV_ID

# Create Log Analytics workspace
az monitor log-analytics workspace create --resource-group $RESOURCE_GROUP --workspace-name $LOG_ANALYTICS_WORKSPACE --location $LOCATION --tags $TAGS

# Get the Log Analytics workspace resource ID
LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP --workspace-name $LOG_ANALYTICS_WORKSPACE --query id --output tsv)

# Enable monitoring for AKS cluster
az aks enable-addons -a monitoring -n $CLUSTER_NAME -g $RESOURCE_GROUP --workspace-resource-id $LOG_ANALYTICS_WORKSPACE_ID

# Enable azure key vault secrets provider for AKS
az aks enable-addons -a azure-keyvault-secrets-provider -n $CLUSTER_NAME -g $RESOURCE_GROUP

# get add on azure key vault secrets provider identity object id
AKVSP_CLIENT_ID=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)

# get add on azure key vault secrets provider identity client id
AKVSP_OBJECT_ID=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.objectId -o tsv) 

# Assign KeyVaultSecretsUser role to the key vault managed identity client id
az role assignment create --role "Key Vault Secrets User" --assignee-object-id $AKVSP_OBJECT_ID --scope $KV_ID

# Create Application Insights
az monitor app-insights component create \
  --app $APP_INSIGHTS \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --kind web \
  --application-type web \
  --workspace $LOG_ANALYTICS_WORKSPACE_ID \
  --tags $TAGS

# Get the Application Insights connection string
APP_INSIGHTS_CONNECTION_STRING=$(az monitor app-insights component show --app $APP_INSIGHTS --resource-group $RESOURCE_GROUP --query connectionString --output tsv)

# Create a secret in Key Vault for the Application Insights connection string
az keyvault secret set --vault-name $KV_NAME --name $APP_INSIGHTS_CONNECTION_STRING_NAME --value $APP_INSIGHTS_CONNECTION_STRING

# verify the secret in Key Vault
az keyvault secret show --name $APP_INSIGHTS_CONNECTION_STRING_NAME --vault-name $KV_NAME

# Build Docker image
docker build -t $ACR_NAME.azurecr.io/weather-app:latest .

# Push Docker image to Azure Container Registry``
az acr login --name $ACR_NAME
docker push $ACR_NAME.azurecr.io/weather-app:latest

# Get AKS cluster credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# generate SecretsProviderClass.yaml
cat <<EOF > k8s/SecretsProviderClass.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname
spec: 
  provider: azure
  parameters: 
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: $AKVSP_CLIENT_ID
    keyvaultName: $KV_NAME
    cloudName: ""
    objects:  |
      array:
        - |
          objectName: $APP_INSIGHTS_CONNECTION_STRING_NAME
          objectType: secret
          objectVersion: ""
    tenantId: $TENANT_ID
  secretObjects:
    - data:
        - key: $APP_INSIGHTS_CONNECTION_STRING_NAME
          objectName: $APP_INSIGHTS_CONNECTION_STRING_NAME
      secretName: "aiconnectionstring"
      type: Opaque
EOF

