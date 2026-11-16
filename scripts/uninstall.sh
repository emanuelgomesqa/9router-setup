#!/usr/bin/env bash
# Remove o 9router. Por padrão MANTÉM os dados; use --purge para apagá-los também.
source "$(dirname "$0")/lib/common.sh"
load_env

PURGE=0; [[ "${1:-}" == "--purge" ]] && PURGE=1
MODE="$(get_mode)"

title "9router · desinstalação"
confirm "Remover o 9router ($MODE)?" || die "Cancelado."

bash "$ROOT_DIR/scripts/backup.sh" || warn "Não foi possível criar backup final."

case "$MODE" in
  docker) compose down ;;
  npm)    pm2 delete 9router 2>/dev/null || true; pm2 save >/dev/null 2>&1 || true; npm uninstall -g 9router ;;
  "")     warn "Modo não registrado; nada a parar." ;;
esac
rm -f "$MODE_FILE"

if (( PURGE )); then
  warn "Apagando permanentemente $DATA_DIR_HOST (o backup em backups/ foi mantido)."
  confirm "Tem certeza?" && rm -rf "$DATA_DIR_HOST" && ok "Dados apagados."
else
  info "Dados mantidos em $DATA_DIR_HOST (use --purge para apagar)."
fi
ok "Desinstalado. Para reverter a config do Claude Code: $RUN clients-claude-off"
