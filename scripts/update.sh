#!/usr/bin/env bash
# Atualiza o 9router para a última versão (com backup antes).
source "$(dirname "$0")/lib/common.sh"
load_env

MODE="$(get_mode)"
[[ -n "$MODE" ]] || die "Instalação não encontrada. Rode: $RUN install"

title "9router · atualização ($MODE)"
bash "$ROOT_DIR/scripts/backup.sh"

case "$MODE" in
  docker)
    compose pull
    compose up -d   # recria o container só se a imagem mudou
    docker image prune -f --filter "label=org.opencontainers.image.title=9router" >/dev/null 2>&1 || true
    ;;
  npm)
    before="$(npm ls -g 9router --depth=0 2>/dev/null | grep -o '9router@[^ ]*' || echo '?')"
    npm install -g 9router@latest
    after="$(npm ls -g 9router --depth=0 2>/dev/null | grep -o '9router@[^ ]*' || echo '?')"
    info "$before → $after"
    export_data_dir
    pm2 restart 9router --update-env
    ;;
esac

ok "Atualizado. Rode '$RUN doctor' para conferir."
