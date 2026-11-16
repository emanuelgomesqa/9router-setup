# Configuração (`.env`)

O `.env` é criado pelo `make init` a partir de [`config/.env.example`](../config/.env.example). Depois de editar, rode `make restart`.

## Rede

| Variável | Padrão aqui | Descrição |
|---|---|---|
| `PORT` | `20128` | Porta do dashboard e da API |
| `HOSTNAME` | `127.0.0.1` | Interface de escuta no modo npm. `0.0.0.0` expõe na rede. No Docker o container usa `0.0.0.0` e o limite vem do `ports` do compose (`127.0.0.1:20128`). |
| `BASE_URL` | `http://localhost:20128` | URL interna usada pelos jobs de sync |
| `NEXT_PUBLIC_BASE_URL` | `http://localhost:20128` | URL pública (compatibilidade) |
| `NODE_ENV` | `production` | Ambiente de execução |

## Dados

| Variável | Padrão | Descrição |
|---|---|---|
| `DATA_DIR_HOST` | `~/.9router` | Pasta de dados no host. No Docker é montada em `/app/data`; no npm vira `DATA_DIR`. |

## Segurança

| Variável | Padrão aqui | Descrição |
|---|---|---|
| `JWT_SECRET` | gerado | Assina o cookie de login do dashboard |
| `API_KEY_SECRET` | gerado | Segredo HMAC das API keys. **Se mudar, todas as keys existentes deixam de valer.** |
| `MACHINE_ID_SALT` | gerado | Salt do ID da máquina |
| `INITIAL_PASSWORD` | gerado | Senha do primeiro login (o padrão do 9router é `123456`, que este setup nunca usa) |
| `REQUIRE_API_KEY` | `false` | `true` exige `Authorization: Bearer` em `/v1/*`. **Obrigatório** se o 9router for acessível fora da máquina. |
| `AUTH_COOKIE_SECURE` | `false` | `true` quando servido por HTTPS |

## Diagnóstico e rede de saída

| Variável | Padrão | Descrição |
|---|---|---|
| `ENABLE_REQUEST_LOGS` | `false` | Grava requisições e respostas em `logs/`. Contém seus prompts; use só para depurar. |
| `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` | vazio | Proxy corporativo para chamadas aos provedores |
| `SEARXNG_URL` | `http://localhost:8888/search` | Provedor de busca web embutido (opcional) |

## Cloud e imagem

| Variável | Padrão | Descrição |
|---|---|---|
| `CLOUD_URL` / `NEXT_PUBLIC_CLOUD_URL` | `https://9router.com` | Endpoint de cloud sync |
| `NINEROUTER_IMAGE` | `decolua/9router:latest` | Imagem Docker. Fixe uma tag (ex.: `decolua/9router:0.3.72`) para builds reprodutíveis, ou use `ghcr.io/decolua/9router`. |

## Variáveis dos scripts (não vão no `.env`)

| Variável | Usada por | Descrição |
|---|---|---|
| `NINEROUTER_API_KEY` | `doctor`, `clients-*` | Sua API key do dashboard |
| `NINEROUTER_MODEL` | `clients-*` | Modelo ou combo padrão |
| `BACKUP_KEEP` | `backup` | Quantos backups manter (padrão 10) |
| `ASSUME_YES=1` | todos | Responde "sim" às confirmações (automação) |
