# Primeiros passos

Do zero ao primeiro prompt passando pelo 9router. Leva uns 10 minutos.

> **No Windows**, troque `make <comando>` por `.\setup.cmd <comando>` (veja [WINDOWS.md](WINDOWS.md)). Sem `make` no macOS/Linux, use `./setup.sh <comando>`.

## 1. Instalar

```bash
make init
make install
```

O `make init` imprime a **senha inicial** do dashboard (também salva em `INITIAL_PASSWORD` no `.env`). O `make install` escolhe sozinho:

- **Docker**, se o Docker estiver rodando, ou
- **npm + pm2**, se houver Node.js 20+.

Para forçar um método: `make install-docker` ou `make install-npm`.

## 2. Entrar no dashboard

```bash
make open        # abre http://localhost:20128/dashboard
```

Entre com a senha inicial e **troque-a** nas configurações.

## 3. Conectar provedores

No dashboard, em **Providers**, conecte o que você tem. Exemplos:

| Você tem | Conecte | Prefixo dos modelos |
|---|---|---|
| Assinatura Claude Pro/Max | Claude Code (login OAuth) | `cc/` |
| ChatGPT Plus/Pro | Codex | `cx/` |
| GitHub Copilot | GitHub Copilot | `gh/` |
| Nada pago | Kiro / OpenCode Free | `kr/`, `oc/` |
| Chave de API barata | GLM, Kimi, MiniMax | `glm/`, `kimi/`, `minimax/` |

## 4. Criar um combo (fallback)

Em **Combos → Create New**, liste modelos em ordem de prioridade, por exemplo `dia-a-dia`:

1. `cc/claude-sonnet-4-5` — assinatura (já paga)
2. `glm/glm-5.1` — barato
3. `kr/claude-sonnet-4.5` — gratuito

Quando o primeiro falha ou estoura a cota, o 9router passa para o próximo. Mais estratégias em [COMBOS.md](COMBOS.md).

> Os nomes exatos dos modelos mudam com o tempo. Copie-os do dashboard ou de `GET /v1/models`.

## 5. Gerar uma API key

Em **API Keys**, crie uma chave e guarde-a. Exporte-a no terminal para os testes:

```bash
export NINEROUTER_API_KEY="cole-a-chave-aqui"
make doctor      # agora também testa /v1/models
```

## 6. Conectar sua ferramenta

```bash
NINEROUTER_MODEL=dia-a-dia make clients-claude
```

Abra um novo terminal e rode `claude`. Para Codex, Cursor e outras, veja [CLIENTES.md](CLIENTES.md) ou rode `make clients`.

## 7. Rotina

| Quando | Comando |
|---|---|
| Algo estranho | `make doctor` e `make logs` |
| Semanalmente | `make backup` |
| Nova versão | `make update` |
