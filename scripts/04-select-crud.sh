#!/usr/bin/env bash
# Atalho do SELECT no MySQL do ACI (video).
# Nao substitui a demonstracao manual do CRUD.
set -euo pipefail

rm=rm556460
resourceGroup="rg-dimdim"
MYSQL_ACI="${rm}-mysql"
MYSQL_ROOT_PASSWORD=senha-dimdim
MYSQL_DATABASE=dimdim

az container exec \
  --resource-group "$resourceGroup" \
  --name "$MYSQL_ACI" \
  --exec-command "mysql --user=root --password=${MYSQL_ROOT_PASSWORD} --database=${MYSQL_DATABASE} --execute=SELECT * FROM cliente;"