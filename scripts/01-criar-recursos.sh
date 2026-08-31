#!/usr/bin/env bash
# Cria Resource Group, ACR e Storage (File Share do MySQL).
# RM do representante: 556460
# Uso no Cloud Shell:  bash scripts/01-criar-recursos.sh

rm=rm556460
resourceGroup="rg-dimdim"
location="eastus"
acrName="dimdimrm556460"
storageAccountName="volumedimdimrm556460"
file_share_name="mysql-dimdim-volume"

echo "==> Resource Group"
if ! az group show --name "$resourceGroup" &>/dev/null; then
  az group create --name "$resourceGroup" --location "$location"
else
  echo "Resource group '$resourceGroup' ja existe."
fi

echo "==> ACR"
az provider register --namespace Microsoft.ContainerRegistry
if ! az acr show --name "$acrName" --resource-group "$resourceGroup" &>/dev/null; then
  az acr create \
    --resource-group "$resourceGroup" \
    --name "$acrName" \
    --sku Basic \
    --admin-enabled true \
    --location "$location"
else
  echo "ACR '$acrName' ja existe."
fi

echo "==> Storage Account + File Share"
az provider register --namespace Microsoft.Storage
if ! az storage account show --name "$storageAccountName" --resource-group "$resourceGroup" &>/dev/null; then
  az storage account create \
    --resource-group "$resourceGroup" \
    --name "$storageAccountName" \
    --location "$location" \
    --sku Standard_LRS \
    --kind StorageV2
else
  echo "Storage '$storageAccountName' ja existe."
fi

connection_string=$(az storage account show-connection-string \
  --name "$storageAccountName" \
  --resource-group "$resourceGroup" \
  --query connectionString \
  --output tsv)

if ! az storage share exists --name "$file_share_name" --account-name "$storageAccountName" --connection-string "$connection_string" | grep true; then
  az storage share create \
    --name "$file_share_name" \
    --account-name "$storageAccountName" \
    --connection-string "$connection_string"
else
  echo "File share '$file_share_name' ja existe."
fi

echo "==> Login server do ACR:"
az acr show --name "$acrName" --query loginServer -o tsv
echo "Proximo: build/push das imagens, depois Key Vault e ACIs."