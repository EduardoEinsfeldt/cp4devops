# DimDim - Checkpoint Containers em Nuvem (ACR / ACI)

FIAP - DevOps Tools & Cloud Computing
1o Checkpoint 2o Semestre - Imagem e Containers em Nuvem

Aplicacao: API REST Java Spring Boot + MySQL 8
Recursos Azure criados **somente via Azure CLI** (scripts nesta pasta).

Representante: RM **556460**

| Recurso | Nome |
|---|---|
| Resource Group | `rg-dimdim` |
| ACR | `dimdimrm556460` |
| Storage Account | `volumedimdimrm556460` |
| File Share | `mysql-dimdim-volume` |
| Imagem / ACI MySQL | `rm556460-mysql` |
| Imagem / ACI App | `rm556460-app` |
| Tag | `v1` |
| Regiao | `eastus` |

---

## How To (tutorial de execucao)

### 0. Pre-requisitos
- Docker Desktop aberto (teste local + `docker build` / `docker push`)
- Conta Azure (portal so para **ver** recursos; criar e pelo CLI)
- Cloud Shell no portal **ou** Azure CLI no PC (`az login`)

Nao criar Resource Group / ACR / Storage / ACI clicando no portal.

### 1. Teste LOCAL (antes de subir pra nuvem)

Na pasta do projeto:

```bash
docker compose up --build
```

Health e CRUD (IntelliJ HTTP Client: `requests/api.http`, ou `curl.exe` no PowerShell):

```bash
curl.exe http://localhost:8080/
curl.exe http://localhost:8080/api/clientes
curl.exe -X POST http://localhost:8080/api/clientes -H "Content-Type: application/json" -d "@requests/post-cliente.json"
curl.exe http://localhost:8080/api/clientes/1
curl.exe -X PUT http://localhost:8080/api/clientes/1 -H "Content-Type: application/json" -d "@requests/put-cliente.json"
curl.exe -X DELETE http://localhost:8080/api/clientes/1
```

SELECT local:

```bash
docker exec dimdim-mysql-local mysql --user=dimdim --password=dimdim123 --database=dimdim --execute="SELECT * FROM cliente;"
```

Se estiver OK:

```bash
docker compose down
```

O video da prova **nao** usa localhost.

### 2. Comandos docker build e docker push

Rode no **PC** (Docker Desktop aberto), na pasta do projeto, depois do ACR existir (`scripts/01-criar-recursos.sh`).

```bash
az acr login --name dimdimrm556460

docker build -f docker/mysql/Dockerfile -t rm556460-mysql:v1 .
docker build -f docker/app/Dockerfile   -t rm556460-app:v1 .

docker tag rm556460-mysql:v1 dimdimrm556460.azurecr.io/rm556460-mysql:v1
docker tag rm556460-app:v1   dimdimrm556460.azurecr.io/rm556460-app:v1

docker push dimdimrm556460.azurecr.io/rm556460-mysql:v1
docker push dimdimrm556460.azurecr.io/rm556460-app:v1
```

Atalho (mesmos comandos):

```bash
bash scripts/02-build-push.sh
```

Se estiver so no Cloud Shell (sem Docker):

```bash
az acr build --registry dimdimrm556460 --image rm556460-mysql:v1 -f docker/mysql/Dockerfile .
az acr build --registry dimdimrm556460 --image rm556460-app:v1   -f docker/app/Dockerfile .
```

O PDF pede os `docker build` e `docker push` descritos neste README.

### 3. Criar recursos e subir os ACIs (CLI)

No Cloud Shell, na pasta do repositorio:

```bash
bash scripts/01-criar-recursos.sh
bash scripts/02-build-push.sh
bash scripts/03-deploy-aci.sh
```

Se o build foi no PC, no Cloud Shell rode so o `01` e o `03`.

O `03-deploy-aci.sh` cria os **dois** ACIs. Nao rode junto `03-aci-mysql.sh` + `04-aci-api-java.sh` (duplica).

Recursos criados:
- Resource Group `rg-dimdim`
- Azure Container Registry `dimdimrm556460`
- Storage Account + File Share `mysql-dimdim-volume` (persistencia do MySQL)
- ACI `rm556460-mysql`
- ACI `rm556460-app`

### 4. Testes na nuvem (manual — e o que vai no video)

URL do app:

```bash
az container show -g rg-dimdim -n rm556460-app --query ipAddress.fqdn -o tsv
```

Abra `http://<fqdn>:8080/api/clientes` e faca o CRUD **na mao** com os JSONs de `requests/`:

1. POST
2. GET
3. PUT
4. DELETE

Depois de **cada** operacao, SELECT no banco:

```bash
az container exec -g rg-dimdim -n rm556460-mysql --exec-command "mysql --user=root --password=senha-dimdim --database=dimdim --execute=SELECT * FROM cliente;"
```

Atalho opcional (nao substitui a demo no video):

```bash
bash scripts/04-select-crud.sh
```

Logs:

```bash
az container logs -g rg-dimdim -n rm556460-mysql
az container logs -g rg-dimdim -n rm556460-app
```

### 5. Video (a prova)
1. Comecar pelo portal: Resource Group com ACR, Storage, File Share e os 2 ACIs.
2. Mostrar a API publica (nao localhost).
3. POST / GET / PUT / DELETE, um de cada vez.
4. Depois de cada operacao, SELECT no MySQL do ACI.
5. Minimo 720p, com narracao.

### 6. Apagar no fim (credito)

```bash
az group delete --name rg-dimdim --yes --no-wait
```

---

## Estrutura

```
db/schema.sql                 DDL
docker/app/Dockerfile         App NAO roda como root
docker/mysql/Dockerfile       Imagem do banco
docker-compose.yml            Teste local
scripts/01-criar-recursos.sh  RG + ACR + Storage (CLI)
scripts/02-build-push.sh      docker build / tag / push
scripts/03-deploy-aci.sh      2 ACIs
scripts/04-select-crud.sh     atalho opcional do SELECT
requests/                     JSON do CRUD
src/                          Spring Boot
```

## Regras cobertas
- Banco e App em container na nuvem
- Dockerfile dos dois
- Build local + teste local
- Push ACR com prefixo RM
- Dois ACIs com prefixo RM
- Persistencia em Conta de Armazenamento (Azure Files)
- Recursos via CLI
- App sem root (`USER app`)
- Sem H2
- Codigo da API sem senha hardcoded (variaveis de ambiente)
