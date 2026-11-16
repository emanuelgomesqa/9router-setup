# 9router-setup

Instalação, configuração e manutenção do **[9router](https://github.com/decolua/9router)** em poucos comandos, em português, para **macOS, Linux e Windows**.

> **Autor do guia:** Emanuel Gomes

O 9router é um roteador de IA self-hosted. Ele expõe **um único endpoint local** (`http://localhost:20128`) que conversa com dezenas de provedores (assinaturas do Claude Code, Codex, Copilot, Kiro, GLM, Kimi…) e faz **fallback automático** entre modelos quando a cota de um acaba.

Este projeto não modifica o 9router. Ele automatiza a instalação, a segurança, a configuração das ferramentas, o backup e o diagnóstico.

```
 Claude Code ─┐                       ┌─► Assinatura Claude (cc/)
 Codex CLI  ──┤                       ├─► Assinatura Codex   (cx/)
 Cursor     ──┼─► 9router :20128  ────┼─► GLM / Kimi / MiniMax
 Cline/…    ──┘   (combos + fallback) └─► Free tiers (kr/, oc/)
```

## Sumário

- [Sistemas suportados](#sistemas-suportados)
- [Requisitos](#requisitos)
- [Instalação rápida](#instalação-rápida)
- [Primeiro uso](#primeiro-uso)
- [Todos os comandos](#todos-os-comandos)
- [Exemplos do dia a dia](#exemplos-do-dia-a-dia)
- [Configuração](#configuração)
- [Dados e backup](#dados-e-backup)
- [Segurança](#segurança)
- [Solução de problemas](#solução-de-problemas)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Documentação](#documentação)
- [Autor](#autor)

## Sistemas suportados

| Sistema | Como rodar | Observação |
|---|---|---|
| **macOS** (Intel e Apple Silicon) | `make <comando>` | Suporte completo |
| **Linux** (Ubuntu, Debian, Fedora, VPS…) | `make <comando>` | Suporte completo |
| **Windows 10/11** | `.\setup.cmd <comando>` | No PowerShell ou no cmd, sem WSL. Guia: [docs/WINDOWS.md](docs/WINDOWS.md) |
| **Windows com WSL2** | `make <comando>` dentro do WSL | Funciona como Linux |

Os comandos são **os mesmos** em todos os sistemas. Só muda o prefixo:

| macOS / Linux | macOS / Linux sem `make` | Windows |
|---|---|---|
| `make install` | `./setup.sh install` | `.\setup.cmd install` |

## Requisitos

| Item | macOS / Linux | Windows |
|---|---|---|
| Terminal | `bash`, `curl`, `make` (já vêm na maioria) | [Git for Windows](https://git-scm.com/download/win) (traz o Git Bash) |
| Runtime: **opção A** (recomendada) | Docker Desktop ou Docker Engine rodando | Docker Desktop rodando |
| Runtime: **opção B** | Node.js **20.18.1+** (22 LTS recomendado) | Node.js **20.18.1+** |
| Opcional | `lsof` (no Linux: `sudo apt install lsof`) | — |

Você só precisa de **uma** das opções de runtime. O instalador usa o Docker se ele estiver rodando; senão, usa o Node.js.

<details>
<summary><b>Instalar os requisitos no Windows (PowerShell)</b></summary>

```powershell
winget install --id Git.Git -e
winget install --id Docker.DockerDesktop -e      # ou: winget install --id OpenJS.NodeJS.LTS -e
```

Depois, abra um PowerShell **novo**.
</details>

## Instalação rápida

### macOS e Linux

```bash
make init       # cria o .env com segredos fortes e mostra a senha do dashboard
make install    # instala (Docker ou npm + pm2) e sobe o serviço
make doctor     # confere se está tudo certo
make open       # abre o dashboard no navegador
```

### Windows (PowerShell)

```powershell
.\setup.cmd init
.\setup.cmd install
.\setup.cmd doctor
.\setup.cmd open
```

Pronto: o dashboard fica em **http://localhost:20128/dashboard** e a API em **http://localhost:20128/v1**.

## Primeiro uso

1. **Entre no dashboard** (`open`) com a senha mostrada pelo `init`. Ela também fica em `INITIAL_PASSWORD` no `.env`. **Troque-a** no primeiro login.
2. **Conecte provedores** em *Providers*: assinatura Claude (`cc/`), Codex (`cx/`), Copilot (`gh/`), free tiers (`kr/`, `oc/`), chaves de API (`glm/`, `kimi/`…).
3. **Crie um combo** em *Combos*: uma lista de modelos em ordem de prioridade. Se o primeiro falhar, o 9router tenta o próximo.
4. **Gere uma API key** em *API Keys*.
5. **Conecte sua ferramenta:**

   ```bash
   make clients-claude          # Windows: .\setup.cmd clients-claude
   ```

   O script pede a API key e o modelo/combo e faz backup do `settings.json` antes de alterar. Abra um terminal novo e rode `claude`.

Passo a passo com exemplos: [docs/PRIMEIROS-PASSOS.md](docs/PRIMEIROS-PASSOS.md).

## Todos os comandos

Use `make <comando>` (macOS/Linux), `./setup.sh <comando>` ou `.\setup.cmd <comando>` (Windows). Rode `make` ou `.\setup.cmd` sem nada para ver a lista no terminal.

### Instalação

| Comando | O que faz |
|---|---|
| `init` | Cria o `.env` com segredos aleatórios e mostra a senha do dashboard. Não sobrescreve um `.env` existente. |
| `init-force` | Recria o `.env`, guardando o anterior como `.env.bak.<data>`. ⚠️ Invalida as API keys já geradas. |
| `install` | Instala e inicia, usando Docker se disponível e npm + pm2 se não. |
| `install-docker` | Força a instalação via Docker. |
| `install-npm` | Força a instalação via npm + pm2. |

### Operação

| Comando | O que faz |
|---|---|
| `start` | Inicia o serviço |
| `stop` | Para o serviço |
| `restart` | Reinicia (necessário depois de editar o `.env`) |
| `status` | Mostra o estado do container ou do processo pm2 |
| `logs` | Acompanha os logs em tempo real (`Ctrl+C` para sair) |
| `open` | Abre o dashboard no navegador |
| `doctor` | Diagnóstico: sistema, dependências, segredos, porta, serviço e API |

> `start`, `stop` e os demais funcionam igual em Docker e em npm. O setup lembra qual método foi instalado.

### Ferramentas de IA

| Comando | O que faz |
|---|---|
| `clients` | Mostra a configuração de Claude Code, Codex, Cursor, Cline, Continue e curl |
| `clients <ferramenta>` | Mostra só uma: `claude`, `codex`, `cursor`, `cline`, `continue`, `shell`. Com make: `make clients` mostra todas. |
| `clients-claude` | Configura o Claude Code automaticamente (com backup) |
| `clients-claude-off` | Desfaz: o Claude Code volta à conexão padrão |
| `clients-codex` | Configura o Codex CLI (macOS/Linux: `~/.zshrc` ou `~/.bashrc`; Windows: variáveis do usuário) |
| `clients-codex-off` | Desfaz a configuração do Codex |

### Manutenção

| Comando | O que faz |
|---|---|
| `backup` | Cria `backups/9router-AAAAMMDD-HHMMSS.tar.gz` (dados + `.env`) e mantém os 10 mais recentes |
| `backups` | Lista os backups |
| `restore <arquivo>` | Restaura um backup, fazendo antes um backup do estado atual. Com make: `make restore FILE=backups/xxx.tar.gz` |
| `update` | Faz backup e atualiza para a última versão |
| `uninstall` | Remove o 9router e **mantém** os dados |
| `purge` | Remove o 9router e **apaga** os dados (pede confirmação; o backup final é mantido) |

## Exemplos do dia a dia

```bash
# Testar a API no diagnóstico
NINEROUTER_API_KEY=sk-... make doctor

# Configurar o Claude Code já com um combo, sem perguntas
NINEROUTER_API_KEY=sk-... NINEROUTER_MODEL=dia-a-dia make clients-claude

# Restaurar o backup mais recente
make backups
make restore FILE=backups/9router-20261115-091846.tar.gz

# Pular as confirmações (ex.: em scripts)
ASSUME_YES=1 make uninstall
```

No Windows (PowerShell), defina a variável antes:

```powershell
$env:NINEROUTER_API_KEY = "sk-..."
.\setup.cmd doctor
.\setup.cmd restore backups\9router-20261115-091846.tar.gz
```

Teste direto na API:

```bash
curl http://127.0.0.1:20128/v1/chat/completions \
  -H "Authorization: Bearer $NINEROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"dia-a-dia","messages":[{"role":"user","content":"Olá!"}]}'
```

### Variáveis aceitas pelos comandos

| Variável | Usada em | Para quê |
|---|---|---|
| `NINEROUTER_API_KEY` | `doctor`, `clients-*` | API key do dashboard (evita a pergunta e testa `/v1/models`) |
| `NINEROUTER_MODEL` | `clients-*` | Modelo ou combo padrão |
| `ASSUME_YES=1` | `restore`, `uninstall`, `purge` | Responde "sim" às confirmações |
| `BACKUP_KEEP` | `backup` | Quantos backups manter (padrão 10) |

## Configuração

Tudo fica no `.env` (criado pelo `init` a partir de [config/.env.example](config/.env.example)). Depois de editar, rode `restart`.

| Variável | Padrão | Descrição |
|---|---|---|
| `PORT` | `20128` | Porta do dashboard e da API |
| `HOSTNAME` | `127.0.0.1` | `127.0.0.1` = só esta máquina; `0.0.0.0` = rede |
| `DATA_DIR_HOST` | `~/.9router` | Onde ficam banco, backups internos e segredos |
| `JWT_SECRET`, `API_KEY_SECRET`, `MACHINE_ID_SALT` | gerados | Segredos. Não troque depois do uso: as API keys dependem deles |
| `INITIAL_PASSWORD` | gerada | Senha do **primeiro** login no dashboard |
| `REQUIRE_API_KEY` | `false` | `true` para exigir API key em `/v1/*` (obrigatório fora do localhost) |
| `AUTH_COOKIE_SECURE` | `false` | `true` quando estiver atrás de HTTPS |
| `NINEROUTER_IMAGE` | `decolua/9router:latest` | Imagem Docker (fixe uma versão se quiser) |

Referência completa: [docs/CONFIGURACAO.md](docs/CONFIGURACAO.md).

## Dados e backup

| O quê | macOS / Linux | Windows |
|---|---|---|
| Banco (provedores, combos, keys, uso) | `~/.9router/db/data.sqlite` | `%USERPROFILE%\.9router\db\data.sqlite` |
| Backups automáticos do 9router | `~/.9router/db/backups/` | `%USERPROFILE%\.9router\db\backups\` |
| Backups deste setup | `./backups/` | `.\backups\` |

Os backups deste setup **incluem o `.env`**, porque as API keys geradas só valem com o mesmo `API_KEY_SECRET`.

## Segurança

- O serviço escuta **só em `127.0.0.1`**: nada fica exposto na rede por padrão.
- Os segredos são gerados aleatoriamente. O `doctor` avisa se algum estiver com valor padrão.
- O `.env` e a pasta `backups/` ficam com permissão `600`/`700` (macOS/Linux) e estão no `.gitignore`.
- Toda alteração em arquivos de configuração das ferramentas é precedida de backup e pode ser desfeita (`clients-*-off`).

Para usar em outra máquina, na rede local ou numa VPS com HTTPS: [docs/SEGURANCA.md](docs/SEGURANCA.md).

> ⚠️ Nunca publique o `.env` nem os arquivos de `backups/`: eles contêm segredos.

## Solução de problemas

Comece sempre por:

```bash
make doctor     # Windows: .\setup.cmd doctor
make logs       # Windows: .\setup.cmd logs
```

| Sintoma | Solução |
|---|---|
| `Docker não está rodando` | Abra o Docker Desktop e espere iniciar |
| `Node.js 20+ necessário` | Instale o Node 22 LTS (ou use Docker) |
| Porta 20128 ocupada | O `doctor` mostra o PID. Pare o processo ou mude `PORT` no `.env` |
| Senha inicial não funciona | Ela só vale no **primeiro** start. Depois, vale a senha que você definiu |
| `401` na API | API key errada, ou `REQUIRE_API_KEY=true` sem enviar a key |
| Windows: `Git Bash nao encontrado` | `winget install --id Git.Git -e` e abra um terminal novo |
| Windows: `$'\r': command not found` | Clone de novo com Git (o `.gitattributes` mantém os `.sh` com quebra de linha LF) |

Mais casos: [docs/SOLUCAO-DE-PROBLEMAS.md](docs/SOLUCAO-DE-PROBLEMAS.md) e [docs/WINDOWS.md](docs/WINDOWS.md).

## Estrutura do projeto

```
9router-setup/
├── setup.sh                 # ponto de entrada único (todos os comandos)
├── setup.cmd                # atalho para Windows (roda o setup.sh via Git Bash)
├── Makefile                 # atalhos make → setup.sh
├── docker-compose.yml       # serviço Docker (publicado só em 127.0.0.1)
├── .gitattributes           # mantém os scripts com LF no Windows
├── config/.env.example      # modelo do .env, comentado
├── scripts/
│   ├── lib/common.sh        # funções compartilhadas e portáveis (macOS/Linux/Windows)
│   ├── init.sh              # gera o .env e os segredos
│   ├── install.sh           # instala (docker | npm)
│   ├── service.sh           # start/stop/restart/status/logs/open
│   ├── doctor.sh            # diagnóstico
│   ├── configure-clients.sh # configura as ferramentas de IA
│   ├── backup.sh            # backup / restore / list
│   ├── update.sh            # atualização
│   └── uninstall.sh         # remoção
└── docs/                    # guias detalhados
```

## Documentação

| Guia | Conteúdo |
|---|---|
| [Primeiros passos](docs/PRIMEIROS-PASSOS.md) | Do zero ao primeiro prompt pelo 9router |
| [Windows](docs/WINDOWS.md) | Instalação e uso no Windows, passo a passo |
| [Configuração](docs/CONFIGURACAO.md) | Todas as variáveis do `.env`, explicadas |
| [Ferramentas cliente](docs/CLIENTES.md) | Claude Code, Codex, Cursor, Cline, Continue, curl |
| [Combos e modelos](docs/COMBOS.md) | Prefixos de modelo e estratégias de fallback |
| [Segurança e acesso remoto](docs/SEGURANCA.md) | Expor na rede/VPS com HTTPS e API key |
| [Solução de problemas](docs/SOLUCAO-DE-PROBLEMAS.md) | Erros comuns e como resolver |

## Autor

Guia e automação criados por **Emanuel Gomes**.

O 9router é um projeto independente de [decolua/9router](https://github.com/decolua/9router). Este repositório apenas facilita a instalação e o uso.
