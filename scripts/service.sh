#!/usr/bin/env bash
# Controla o serviço, independentemente de ter sido instalado via docker ou npm.
# Uso: scripts/service.sh start|stop|restart|status|logs|open
source "$(dirname "$0")/lib/common.sh"
load_env

ACTION="${1:-status}"
MODE="$(get_mode)"
if [[ "$ACTION" == open ]]; then open_url "http://localhost:${PORT}/dashboard"; exit 0; fi
[[ -n "$MODE" ]] || die "Instalação não encontrada. Rode: $RUN install"

case "$MODE:$ACTION" in
  docker:start)   compose up -d ;;
  docker:stop)    compose stop ;;
  docker:restart) compose restart ;;
  docker:status)  compose ps ;;
  docker:logs)    compose logs -f --tail=200 ;;
  npm:start)      pm2_start ;;
  npm:stop)       pm2 stop 9router ;;
  npm:restart)    export_data_dir; pm2 restart 9router --update-env ;;
  npm:status)     pm2 describe 9router | sed -n '1,25p' ;;
  npm:logs)       pm2 logs 9router --lines 200 ;;
  *) die "Ação inválida: $ACTION (use start|stop|restart|status|logs|open)" ;;
esac
