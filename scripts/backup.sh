#!/usr/bin/env bash
# Backup e restauração dos dados do 9router (providers, combos, keys, uso).
# Uso:
#   scripts/backup.sh                 → cria backups/9router-AAAAMMDD-HHMMSS.tar.gz
#   scripts/backup.sh restore <arq>   → restaura (para o serviço, faz backup do atual, restaura, reinicia)
#   scripts/backup.sh list
source "$(dirname "$0")/lib/common.sh"
load_env

BACKUP_DIR="${ROOT_DIR}/backups"
KEEP="${BACKUP_KEEP:-10}"
mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"

do_backup() {
  [[ -d "$DATA_DIR_HOST" ]] || die "Diretório de dados não existe: $DATA_DIR_HOST"
  local out; out="${BACKUP_DIR}/9router-$(date +%Y%m%d-%H%M%S).tar.gz"
  # Inclui o .env: sem os mesmos segredos, as API keys geradas deixam de valer.
  tar_local -czf "$out" -C "$(dirname "$DATA_DIR_HOST")" "$(basename "$DATA_DIR_HOST")" -C "$ROOT_DIR" .env
  chmod 600 "$out"
  ok "Backup criado: $out ($(du -h "$out" | cut -f1))"
  # rotação
  local old; old="$(ls -1t "$BACKUP_DIR"/9router-*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)))"
  if [[ -n "$old" ]]; then
    echo "$old" | while read -r f; do rm -f "$f"; done
    info "Mantidos os ${KEEP} backups mais recentes."
  fi
}

do_restore() {
  local file="${1:-}"
  [[ -f "$file" ]] || die "Arquivo de backup não encontrado: ${file:-<vazio>}"
  warn "Isto substitui os dados atuais em $DATA_DIR_HOST e o .env."
  confirm "Continuar?" || die "Cancelado."
  do_backup
  bash "$ROOT_DIR/scripts/service.sh" stop || true
  local tmp; tmp="$(mktemp -d)"
  tar_local -xzf "$file" -C "$tmp"
  rm -rf "$DATA_DIR_HOST"
  mv "$tmp/$(basename "$DATA_DIR_HOST")" "$DATA_DIR_HOST" 2>/dev/null || mv "$tmp"/.9router "$DATA_DIR_HOST"
  [[ -f "$tmp/.env" ]] && cp "$tmp/.env" "$ENV_FILE" && chmod 600 "$ENV_FILE"
  rm -rf "$tmp"
  bash "$ROOT_DIR/scripts/service.sh" start
  ok "Restaurado a partir de $file"
}

case "${1:-backup}" in
  backup)  do_backup ;;
  restore) do_restore "${2:-}" ;;
  list)    ls -lh "$BACKUP_DIR"/9router-*.tar.gz 2>/dev/null || info "Nenhum backup ainda." ;;
  *) die "Uso: backup.sh [backup|restore <arquivo>|list]" ;;
esac
