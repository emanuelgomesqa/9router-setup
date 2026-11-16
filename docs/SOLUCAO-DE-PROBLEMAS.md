# Solução de problemas

Comece sempre por:

```bash
make doctor
make logs
```

## Instalação

| Sintoma | Causa provável | Solução |
|---|---|---|
| `Docker não está rodando` | Docker Desktop fechado | Abra o Docker Desktop, depois `make install` |
| `Node.js 20+ necessário` | Node antigo | `nvm install 22 && nvm use 22`, ou use Docker |
| `npm install -g` dá `EACCES` | npm global sem permissão | Use nvm (recomendado) ou `npm config set prefix ~/.npm-global` |
| Build falha em VPS pequena | Pouca memória | Use Docker (imagem pronta) ou crie swap temporário |

## Serviço

| Sintoma | Causa provável | Solução |
|---|---|---|
| `Nada escutando na porta 20128` | Serviço parado | `make start` |
| `address already in use` | Outro processo na porta | `lsof -iTCP:20128 -sTCP:LISTEN`; mude `PORT` no `.env` e rode `make restart` |
| Container reinicia em loop | Erro de config/permissão | `make logs`; confira se `~/.9router` pertence ao seu usuário |
| Não abre de outra máquina | Publicado só em 127.0.0.1 | Veja [SEGURANCA.md](SEGURANCA.md#usar-de-outra-máquina-rede-local) |

## Dashboard

| Sintoma | Solução |
|---|---|
| Senha inicial não funciona | `INITIAL_PASSWORD` só vale **no primeiro start**. Se o banco já existia, vale a senha antiga. |
| Login some a cada recarga | Em HTTP, `AUTH_COOKIE_SECURE` precisa ser `false` |
| Todo mundo deslogado após mudar o `.env` | Você mudou o `JWT_SECRET`; é só entrar de novo |

## API e clientes

| Sintoma | Causa provável | Solução |
|---|---|---|
| `401` em `/v1/*` | Key errada ou `REQUIRE_API_KEY=true` sem key | Gere uma key no dashboard e confira o header `Authorization: Bearer` |
| Todas as keys pararam | `API_KEY_SECRET` mudou | Restaure o `.env` de um backup ou gere novas keys |
| `model not found` | Nome do modelo ou combo errado | Confira em `GET /v1/models` |
| Claude Code ignora o 9router | Variável sobrescrita no shell | `env \| grep ANTHROPIC`; remova `ANTHROPIC_API_KEY` do shell |
| Codex dá 404 | `/v1` duplicado | No Codex use `OPENAI_BASE_URL=http://127.0.0.1:20128` (sem `/v1`) |
| `ECONNREFUSED ::1` | `localhost` resolvendo para IPv6 | Use `127.0.0.1` |
| Respostas lentas ou erros em cascata | Primeiro modelo do combo sem cota | Reordene o combo e veja o painel de uso |

## Recomeçar do zero (sem perder dados)

```bash
make backup
make uninstall
make install
```

Se precisar, restaure com `make restore FILE=backups/9router-AAAAMMDD-HHMMSS.tar.gz`.

## Windows

Problemas específicos do Windows (Git Bash, quebras de linha, PowerShell): veja [WINDOWS.md](WINDOWS.md#problemas-comuns).
