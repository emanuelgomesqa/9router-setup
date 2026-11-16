# Ferramentas cliente

Todas apontam para o mesmo lugar e usam a **API key gerada no dashboard** (não a chave do provedor). Rode `make clients` para ver tudo com a sua porta já preenchida.

> Dica: o dashboard tem uma seção **CLI Tools** que gera a configuração de várias ferramentas com um clique.

## Claude Code

Automático (faz backup de `~/.claude/settings.json` e só mexe nas chaves do 9router):

```bash
NINEROUTER_API_KEY=sk-... NINEROUTER_MODEL=meu-combo make clients-claude
```

Manual, em `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:20128",
    "ANTHROPIC_AUTH_TOKEN": "<API_KEY_9ROUTER>",
    "ANTHROPIC_MODEL": "meu-combo"
  }
}
```

Para voltar ao normal: `make clients-claude-off`.

Para usar o 9router só em uma sessão, sem mexer em arquivos:

```bash
ANTHROPIC_BASE_URL=http://127.0.0.1:20128 ANTHROPIC_AUTH_TOKEN=sk-... claude
```

## Codex CLI

```bash
make clients-codex     # adiciona um bloco "# >>> 9router >>>" ao ~/.zshrc ou ~/.bashrc
```

Manual:

```bash
export OPENAI_BASE_URL=http://127.0.0.1:20128     # sem /v1
export OPENAI_API_KEY=<API_KEY_9ROUTER>
```

## Cursor

Settings → Models → Advanced:

- **OpenAI API Base URL:** `http://127.0.0.1:20128/v1`
- **OpenAI API Key:** sua key do 9router
- Adicione o nome do modelo ou do combo e selecione-o.

## Cline · Continue · RooCode

- Provider: **OpenAI Compatible**
- Base URL: `http://127.0.0.1:20128/v1`
- API Key: sua key do 9router
- Model: modelo ou combo

## Qualquer cliente OpenAI (SDKs, scripts)

```python
from openai import OpenAI
client = OpenAI(base_url="http://127.0.0.1:20128/v1", api_key="<API_KEY_9ROUTER>")
r = client.chat.completions.create(model="meu-combo", messages=[{"role": "user", "content": "Olá!"}])
print(r.choices[0].message.content)
```

## curl

```bash
curl http://127.0.0.1:20128/v1/models -H "Authorization: Bearer $NINEROUTER_API_KEY"
```

## Por que `127.0.0.1` e não `localhost`?

Em algumas máquinas `localhost` resolve primeiro para IPv6 (`::1`), e o 9router pode estar escutando só em IPv4. Usar `127.0.0.1` evita esse problema.
