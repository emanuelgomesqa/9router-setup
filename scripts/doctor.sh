#!/usr/bin/env bash
# Diagnóstico completo: dependências, configuração, serviço e API.
# Uso: scripts/doctor.sh            (NINEROUTER_API_KEY=... para testar /v1/models)
source "$(dirname "$0")/lib/common.sh"
set +e

PROBLEMS=0
problem() { fail "$1"; [[ -n "${2:-}" ]] && echo "    → $2" >&2; PROBLEMS=$((PROBLEMS+1)); }
exec 2>&1   # mantém a ordem das mensagens

title "1. Sistema e dependências"
ok "Sistema: $(os_name)"
has curl && ok "curl" || problem "curl ausente" "Instale curl."
if ! is_windows && ! has lsof && ! has ss; then warn "Nem lsof nem ss instalados — a checagem de porta fica limitada (ex.: sudo apt install lsof)"; fi
if docker_ok; then ok "Docker rodando ($(docker --version | cut -d, -f1))"
elif has docker; then warn "Docker instalado, mas parado"
else info "Docker não instalado (ok se usar npm)"; fi
if has node; then
  if (( $(node_major) >= MIN_NODE_MAJOR )); then ok "Node.js $(node -v)"
  else warn "Node.js $(node -v) — o modo npm exige ${MIN_NODE_MAJOR}+"; fi
else info "Node.js não instalado (ok se usar Docker)"; fi

title "2. Configuração"
if [[ ! -f "$ENV_FILE" ]]; then
  problem ".env ausente" "Rode: $RUN init"; echo; exit 1
fi
load_env
ok ".env encontrado"
if is_windows; then
  info "Permissão do .env: no Windows ela segue a pasta do seu usuário (mantenha o projeto dentro dela)"
else
  perm="$(stat -f '%Lp' "$ENV_FILE" 2>/dev/null || stat -c '%a' "$ENV_FILE")"
  [[ "$perm" == "600" ]] && ok "Permissão do .env: 600" || problem "Permissão do .env é $perm" "chmod 600 .env"
fi
for v in JWT_SECRET API_KEY_SECRET MACHINE_ID_SALT INITIAL_PASSWORD; do
  val="${!v:-}"
  if [[ -z "$val" || "$val" == "__GERAR__" || "$val" == "123456" || "$val" == "endpoint-proxy-api-key-secret" || "$val" == "endpoint-proxy-salt" ]]; then
    problem "$v com valor padrão/vazio" "Rode: $RUN init-force (ou edite o .env)"
  fi
done
[[ "${HOSTNAME:-}" == "0.0.0.0" && "${REQUIRE_API_KEY:-false}" != "true" && "$(get_mode)" == "npm" ]] && \
  warn "Escutando em 0.0.0.0 sem REQUIRE_API_KEY=true — qualquer um na rede pode usar seu router."
[[ -d "$DATA_DIR_HOST" ]] && ok "Diretório de dados: $DATA_DIR_HOST" || problem "Diretório de dados ausente: $DATA_DIR_HOST" "mkdir -p \"$DATA_DIR_HOST\""
[[ -f "$DATA_DIR_HOST/db/data.sqlite" ]] && ok "Banco: $(du -h "$DATA_DIR_HOST/db/data.sqlite" | cut -f1)" || info "Banco ainda não criado (normal antes do 1º start)"

title "3. Serviço"
MODE="$(get_mode)"
if [[ -z "$MODE" ]]; then
  pid="$(port_pid "$PORT")"
  if [[ -n "$pid" ]]; then
    problem "Há um 9router (ou outro processo) na porta $PORT que não foi instalado por este setup (PID $pid: $(pid_cmd "$pid"))" \
            "Pare-o ($(kill_hint "$pid")) e rode '$RUN install', ou mude PORT no .env"
  else
    problem "Instalação não registrada" "Rode: $RUN install"
  fi
else
  ok "Modo de instalação: $MODE"
  if [[ "$MODE" == docker ]]; then
    state="$(docker inspect -f '{{.State.Status}} ({{if .State.Health}}{{.State.Health.Status}}{{else}}sem healthcheck{{end}})' 9router 2>/dev/null)"
    [[ "$state" == running* ]] && ok "Container: $state" || problem "Container: ${state:-inexistente}" "$RUN start / $RUN logs"
  else
    pm2 describe 9router 2>/dev/null | grep -q online && ok "pm2: online" || problem "pm2: 9router não está online" "$RUN start / $RUN logs"
  fi
fi
if port_in_use "$PORT"; then ok "Porta $PORT em uso (escutando)"
else problem "Nada escutando na porta $PORT" "Serviço parado ou PORT diferente"; fi

title "4. API"
code="$(curl -s -o /dev/null -w '%{http_code}' "$ROUTER_URL/")"
[[ "$code" =~ ^(200|30[0-9])$ ]] && ok "Dashboard responde (HTTP $code)" || problem "Dashboard não responde (HTTP $code)"
if [[ -n "${NINEROUTER_API_KEY:-}" ]]; then
  body="$(curl -s -w '\n%{http_code}' -H "Authorization: Bearer $NINEROUTER_API_KEY" "$ROUTER_URL/v1/models")"
  code="${body##*$'\n'}"
  if [[ "$code" == 200 ]]; then
    n="$(printf '%s' "${body%$'\n'*}" | grep -o '"id"' | wc -l | tr -d ' ')"
    ok "/v1/models OK — $n modelos/combos disponíveis"
  else problem "/v1/models retornou HTTP $code" "Confira a API key no dashboard"; fi
else
  info "Defina NINEROUTER_API_KEY para testar /v1/models (ex.: NINEROUTER_API_KEY=sk-... $RUN doctor)"
fi

echo
if (( PROBLEMS == 0 )); then ok "${C_BOLD}Tudo certo!${C_RESET}"; else fail "${PROBLEMS} problema(s) encontrado(s). Veja docs/SOLUCAO-DE-PROBLEMAS.md"; fi
exit $(( PROBLEMS > 0 ))
