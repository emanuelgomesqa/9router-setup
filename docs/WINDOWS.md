# Windows

No Windows, tudo funciona pelo **`setup.cmd`**, sem `make` e sem WSL. Ele roda os mesmos scripts do macOS/Linux usando o Git Bash, que vem com o Git for Windows. Você continua no **PowerShell** ou no **Prompt de Comando** de sempre.

## 1. Pré-requisitos (uma vez só)

Abra o **PowerShell** e instale:

```powershell
winget install --id Git.Git -e                   # obrigatório (traz o Git Bash)
winget install --id Docker.DockerDesktop -e      # recomendado
```

Sem Docker, instale o Node.js no lugar dele: `winget install --id OpenJS.NodeJS.LTS -e`.

Feche e **abra um PowerShell novo** depois de instalar. Se for usar Docker, abra o **Docker Desktop** e espere ele terminar de iniciar.

## 2. Instalar

Dentro da pasta do projeto:

```powershell
.\setup.cmd init       # cria o .env e mostra a senha do dashboard
.\setup.cmd install    # instala e sobe o 9router
.\setup.cmd doctor     # confere se está tudo certo
.\setup.cmd open       # abre o dashboard no navegador
```

> No Prompt de Comando (cmd) dá para omitir o `.\`: `setup.cmd install`.

## 3. Conectar o Claude Code

Gere uma API key no dashboard (**API Keys**) e rode:

```powershell
.\setup.cmd clients-claude
```

O script pede a chave e grava em `%USERPROFILE%\.claude\settings.json`, fazendo backup antes. Abra um terminal novo e rode `claude`.

Para o **Codex CLI**, `.\setup.cmd clients-codex` grava `OPENAI_BASE_URL` e `OPENAI_API_KEY` nas variáveis do seu usuário do Windows (vale para terminais abertos depois disso). Para desfazer: `.\setup.cmd clients-codex-off`.

## 4. Passar variáveis para um comando

Para testar `/v1/models` no diagnóstico:

```powershell
$env:NINEROUTER_API_KEY = "cole-a-chave-aqui"
.\setup.cmd doctor
```

## Docker ou npm?

| | Docker (recomendado) | npm + pm2 |
|---|---|---|
| Instalação | Docker Desktop | Node.js 20.18.1+ |
| Inicia com o Windows | Sim, se o Docker Desktop iniciar com o Windows | Só depois de `npm i -g pm2-windows-startup` e `pm2-startup install` |
| Isolamento | Container | Processo do seu usuário |

## Onde ficam as coisas

| O quê | Caminho |
|---|---|
| Dados do 9router | `%USERPROFILE%\.9router` |
| Config do Claude Code | `%USERPROFILE%\.claude\settings.json` |
| Backups deste setup | `backups\` dentro da pasta do projeto |

## Problemas comuns

| Sintoma | Solução |
|---|---|
| `Git Bash nao encontrado` | `winget install --id Git.Git -e` e abra um terminal novo |
| `setup.cmd` não é reconhecido no PowerShell | Use `.\setup.cmd` (o PowerShell exige o `.\`) |
| `Docker não está rodando` | Abra o Docker Desktop e espere o ícone ficar estável |
| Erros como `$'\r': command not found` | Os `.sh` foram salvos com quebra de linha do Windows. Clone de novo com Git (o `.gitattributes` corrige) ou rode `git config --global core.autocrlf input` e clone outra vez |
| Acentos/símbolos estranhos no terminal | Use o Windows Terminal; o `setup.cmd` já ativa UTF-8 |
| `curl` no PowerShell se comporta diferente | No PowerShell, `curl` é outro comando. Use `curl.exe` |
| Porta 20128 ocupada | `.\setup.cmd doctor` mostra o PID. Pare com `taskkill /PID <pid> /F` ou mude `PORT` no `.env` |

## Prefere o WSL?

Também funciona: dentro do Ubuntu no WSL, siga as instruções de Linux (`make install`). Só lembre que, nesse caso, `make clients-claude` configura o Claude Code **do WSL**, não o do Windows.
