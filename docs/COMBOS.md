# Combos e modelos

## Prefixos

Cada modelo é chamado como `<prefixo>/<modelo>`:

| Prefixo | Provedor | Exemplo |
|---|---|---|
| `cc/` | Claude Code (assinatura) | `cc/claude-opus-4-7` |
| `cx/` | Codex (assinatura ChatGPT) | `cx/gpt-5.5` |
| `gh/` | GitHub Copilot | `gh/…` |
| `cu/` | Cursor | `cu/…` |
| `kr/` | Kiro (free tier) | `kr/claude-sonnet-4.5` |
| `oc/` | OpenCode Free | `oc/…` |
| `glm/` | GLM | `glm/glm-5.1` |
| `kimi/` | Kimi | `kimi/…` |
| `minimax/` | MiniMax | `minimax/…` |
| `vertex/`, `vertex-partner/` | Vertex AI | `vertex/…` |

A lista real dos seus modelos está em `GET /v1/models`, que também retorna os combos.

## O que é um combo

Um combo é um **nome virtual** que aponta para uma lista ordenada de modelos. Quando um modelo falha (cota, rate limit ou erro), o 9router tenta o próximo da lista. Na ferramenta cliente, você usa o nome do combo como se fosse um modelo.

## Estratégias prontas

**Custo mínimo**, que gasta primeiro o que você já paga:

```
economico:  cc/claude-sonnet-…  →  cx/gpt-…  →  glm/glm-5.1  →  kr/claude-sonnet-4.5
```

**Qualidade máxima** para tarefas pesadas:

```
pesado:     cc/claude-opus-…  →  cx/gpt-…  →  cc/claude-sonnet-…
```

**Somente gratuito**, para experimentos:

```
gratis:     kr/claude-sonnet-4.5  →  oc/…
```

## Boas práticas

- Coloque no topo os modelos de **assinatura**, que já estão pagos.
- Deixe sempre um modelo **gratuito ou barato no fim** como rede de segurança.
- Crie combos por **tipo de tarefa** (`rapido`, `pesado`), não por provedor.
- Acompanhe o painel de **uso/cota** do dashboard para ajustar a ordem.
- Para desativar o economizador de tokens em uma requisição específica, envie o header `X-9Router-Token-Saver: off`.
