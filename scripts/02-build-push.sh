#!/usr/bin/env bash
# Build local + push para o ACR.
# Imagens com prefixo do RM do representante.
# Rode no PC com Docker Desktop aberto, na pasta do projeto.
set -euo pipefail

rm=rm556460
acrName="dimdimrm556460"
tag="v1"

LOGIN_SERVER=$(az acr show --name "$acrName" --query loginServer -o tsv)

echo "==> Login no ACR"
az acr login --name "$acrName"

echo "==> Build MySQL"
docker build -f docker/mysql/Dockerfile -t "${rm}-mysql:${tag}" .

echo "==> Build App (nao-root)"
docker build -f docker/app/Dockerfile -t "${rm}-app:${tag}" .

echo "==> Tag"
docker tag "${rm}-mysql:${tag}" "${LOGIN_SERVER}/${rm}-mysql:${tag}"
docker tag "${rm}-app:${tag}"   "${LOGIN_SERVER}/${rm}-app:${tag}"

echo "==> Push"
docker push "${LOGIN_SERVER}/${rm}-mysql:${tag}"
docker push "${LOGIN_SERVER}/${rm}-app:${tag}"

echo "==> Imagens no ACR:"
az acr repository list --name "$acrName" -o table