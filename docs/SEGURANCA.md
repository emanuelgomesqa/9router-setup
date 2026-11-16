# Segurança e acesso remoto

O 9router guarda **tokens das suas assinaturas**. Quem acessar o endpoint usa as suas contas. Trate-o como uma senha.

## Padrões deste setup

- Docker publica a porta **apenas em `127.0.0.1`**; no npm, `HOSTNAME=127.0.0.1`.
- Segredos fortes gerados pelo `make init`, sem os padrões públicos (`123456`, `endpoint-proxy-…`).
- `.env` e `backups/` com permissão restrita e fora do git.
- O `make doctor` avisa se algum segredo estiver no valor padrão.

## Usar de outra máquina (rede local)

1. Docker: no `docker-compose.yml`, troque `"127.0.0.1:${PORT}:${PORT}"` por `"${PORT}:${PORT}"`. npm: use `HOSTNAME=0.0.0.0`.
2. No `.env`, defina `REQUIRE_API_KEY=true`.
3. Rode `make restart`.

## VPS / internet

Não exponha a porta 20128 diretamente. Use um reverse proxy com HTTPS. Exemplo com **Caddy**, que emite o certificado sozinho:

```caddy
router.seudominio.com {
    reverse_proxy 127.0.0.1:20128
}
```

E no `.env`:

```env
REQUIRE_API_KEY=true
AUTH_COOKIE_SECURE=true
BASE_URL=https://router.seudominio.com
NEXT_PUBLIC_BASE_URL=https://router.seudominio.com
```

Complementos recomendados:

- Firewall liberando só 80/443 (por exemplo, `ufw allow 80,443/tcp`).
- Ou, melhor ainda, nada público: acesse via **Tailscale** ou **WireGuard**.
- `make backup` agendado no cron, com a cópia guardada fora do servidor.

## Checklist

- [ ] Troquei a senha inicial do dashboard
- [ ] `make doctor` sem avisos de segredo padrão
- [ ] `REQUIRE_API_KEY=true` se o 9router for acessível fora da máquina
- [ ] HTTPS + `AUTH_COOKIE_SECURE=true` se estiver na internet
- [ ] `ENABLE_REQUEST_LOGS=false` em uso normal, porque os logs guardam prompts
- [ ] Backups em lugar seguro, porque contêm o `.env`
