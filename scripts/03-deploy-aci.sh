#!/usr/bin/env bash
# Sobe dois ACIs a partir das imagens do ACR.
# MySQL com volume Azure Files. App sem privilegio root (USER no Dockerfile).
set -euo pipefail

rm=rm556460
resourceGroup="rg-dimdim"
location="northcentralus"
acrName="dimdimrm556460"
storageAccountName="volumedimdimrm556460"
file_share_name="mysql-dimdim-volume"
tag="v1"
MYSQL_ROOT_PASSWORD=senha-dimdim
MYSQL_DATABASE=dimdim
MYSQL_USER=dimdim
MYSQL_PASSWORD=senha-dimdim

LOGIN_SERVER=$(az acr show --name "$acrName" --query loginServer -o tsv)
ACR_USER=$(az acr credential show --name "$acrName" --query username -o tsv)
ACR_PASS=$(az acr credential show --name "$acrName" --query "passwords[0].value" -o tsv)
STORAGE_KEY=$(az storage account keys list --resource-group "$resourceGroup" --account-name "$storageAccountName" --query "[0].value" -o tsv)

MYSQL_ACI="${rm}-mysql"
APP_ACI="${rm}-app"
MYSQL_DNS="mysql-container-${rm}"
APP_DNS="api-java-container-${rm}"

echo "==> ACI MySQL (dados em Azure Files)"
az container create \
  --resource-group "$resourceGroup" \
  --name "$MYSQL_ACI" \
  --image "${LOGIN_SERVER}/${rm}-mysql:${tag}" \
  --os-type Linux \
  --cpu 1 \
  --memory 1.5 \
  --ports 3306 \
  --ip-address Public \
  --dns-name-label "$MYSQL_DNS" \
  --location "$location" \
  --restart-policy Always \
  --registry-login-server "$LOGIN_SERVER" \
  --registry-username "$ACR_USER" \
  --registry-password "$ACR_PASS" \
  --azure-file-volume-account-name "$storageAccountName" \
  --azure-file-volume-account-key "$STORAGE_KEY" \
  --azure-file-volume-share-name "$file_share_name" \
  --azure-file-volume-mount-path /var/lib/mysql \
  --environment-variables \
    MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    MYSQL_DATABASE="$MYSQL_DATABASE" \
    MYSQL_USER="$MYSQL_USER" \
    MYSQL_PASSWORD="$MYSQL_PASSWORD"

echo "==> Aguardando MySQL..."
az container show -g "$resourceGroup" -n "$MYSQL_ACI" --query instanceView.state -o tsv
MYSQL_FQDN=$(az container show -g "$resourceGroup" -n "$MYSQL_ACI" --query ipAddress.fqdn -o tsv)
echo "MySQL FQDN: $MYSQL_FQDN"

echo "==> ACI App"
az container create \
  --resource-group "$resourceGroup" \
  --name "$APP_ACI" \
  --image "${LOGIN_SERVER}/${rm}-app:${tag}" \
  --os-type Linux \
  --cpu 1 \
  --memory 1.5 \
  --ports 8080 \
  --ip-address Public \
  --dns-name-label "$APP_DNS" \
  --location "$location" \
  --restart-policy Always \
  --registry-login-server "$LOGIN_SERVER" \
  --registry-username "$ACR_USER" \
  --registry-password "$ACR_PASS" \
  --environment-variables \
    SPRING_DATASOURCE_URL="jdbc:mysql://${MYSQL_FQDN}:3306/${MYSQL_DATABASE}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" \
    SPRING_DATASOURCE_USERNAME="$MYSQL_USER" \
    SPRING_DATASOURCE_PASSWORD="$MYSQL_PASSWORD"

APP_FQDN=$(az container show -g "$resourceGroup" -n "$APP_ACI" --query ipAddress.fqdn -o tsv)
echo "App URL: http://${APP_FQDN}:8080"
echo "Health:  curl http://${APP_FQDN}:8080/"
echo "CRUD:    curl http://${APP_FQDN}:8080/api/clientes"