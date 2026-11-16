#!/usr/bin/env bash
# Cria o .env a partir do modelo e gera segredos fortes.
# Uso: scripts/init.sh [--force]
source "$(dirname "$0")/lib/common.sh"

title "9router · inicializando configuração ($(os_name))"

if [[ -f "$ENV_FILE" && "${1:-}" != "--force" ]]; then
  ok ".env já existe — mantido (para recriar: $RUN init-force)."
  exit 0
fi

if [[ -f "$ENV_FILE" ]]; then
  cp "$ENV_FILE" "${ENV_FILE}.bak.$(date +%Y%m%d%H%M%S)"
  warn "Backup do .env anterior criado."
fi

cp "$ENV_EXAMPLE" "$ENV_FILE"
chmod 600 "$ENV_FILE"

set_env_var JWT_SECRET       "$(random_secret 32)"
set_env_var API_KEY_SECRET   "$(random_secret 32)"
set_env_var MACHINE_ID_SALT  "$(random_secret 16)"
PASS="$(random_secret 8)"
set_env_var INITIAL_PASSWORD "$PASS"
set_env_var DATA_DIR_HOST    "$HOME/.9router"

mkdir -p "$HOME/.9router"

ok ".env criado em ${ENV_FILE} (permissão 600)."
info "Senha inicial do dashboard: ${C_BOLD}${PASS}${C_RESET}"
info "Ela também está no .env (INITIAL_PASSWORD). Troque-a no primeiro login."
