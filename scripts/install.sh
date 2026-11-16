#!/usr/bin/env bash
# Instala e inicia o 9router.
# Uso: scripts/install.sh [docker|npm]   (sem argumento = escolhe automaticamente)
source "$(dirname "$0")/lib/common.sh"

MODE="${1:-}"

title "9router · instalação ($(os_name))"

[[ -f "$ENV_FILE" ]] || bash "$ROOT_DIR/scripts/init.sh"
load_env

# Evita conflito com uma instância já rodando fora deste setup.
if [[ -z "$(get_mode)" ]] && port_in_use "$PORT"; then
  pid="$(port_pid "$PORT")"
  if [[ -n "$pid" ]]; then fail "A porta $PORT já está em uso (PID $pid: $(pid_cmd "$pid"))."
  else fail "A porta $PORT já está em uso."; fi
  echo "  • Se for um 9router antigo, faça backup de ~/.9router, pare-o (${pid:+$(kill_hint "$pid")}) e rode de novo." >&2
  echo "    Os dados em ~/.9router são reaproveitados automaticamente." >&2
  echo "  • Ou mude PORT no .env para rodar lado a lado." >&2
  exit 1
fi

if [[ -z "$MODE" ]]; then
  if docker_ok; then MODE=docker
  elif has node && (( $(node_major) >= MIN_NODE_MAJOR )); then MODE=npm
  else
    fail "Nenhum método disponível."
    echo "  • Docker: instale o Docker Desktop/Engine e deixe-o rodando, ou"
    echo "  • Node.js ${MIN_NODE_MAJOR}+ (recomendado 22 LTS): https://nodejs.org"
    exit 1
  fi
  info "Método escolhido automaticamente: ${C_BOLD}${MODE}${C_RESET}"
fi

case "$MODE" in
  docker)
    docker_ok || die "Docker não está rodando. Abra o Docker Desktop e tente de novo."
    mkdir -p "$DATA_DIR_HOST"
    info "Baixando imagem ${NINEROUTER_IMAGE:-decolua/9router:latest}…"
    compose pull
    info "Subindo container…"
    compose up -d
    ;;
  npm)
    has node || die "Node.js não encontrado."
    (( $(node_major) >= MIN_NODE_MAJOR )) || die "Node.js ${MIN_NODE_MAJOR}+ necessário (atual: $(node -v))."
    info "Instalando 9router e pm2 globalmente via npm…"
    npm install -g 9router pm2
    mkdir -p "$DATA_DIR_HOST"
    pm2_start
    pm2 save >/dev/null
    if is_windows; then
      ok "Rodando sob pm2. Para iniciar com o Windows: npm i -g pm2-windows-startup && pm2-startup install"
    else
      ok "Rodando sob pm2. Para iniciar junto com o sistema: pm2 startup (siga a instrução exibida)."
    fi
    ;;
  *) die "Método inválido: '$MODE' (use docker ou npm)." ;;
esac

echo "$MODE" >"$MODE_FILE"

info "Aguardando o 9router responder em ${ROUTER_URL}…"
for _ in $(seq 1 30); do
  if curl -fsS -o /dev/null "$ROUTER_URL/"; then
    ok "9router no ar!"
    echo
    echo "  Dashboard : http://localhost:${PORT}/dashboard"
    echo "  API       : http://localhost:${PORT}/v1"
    echo "  Senha     : INITIAL_PASSWORD no arquivo .env"
    echo
    echo "Próximos passos: docs/PRIMEIROS-PASSOS.md  (conectar provedores, criar combo, gerar API key)"
    exit 0
  fi
  sleep 2
done

warn "O 9router não respondeu em 60s. Rode '$RUN logs' e '$RUN doctor' para investigar."
exit 1
