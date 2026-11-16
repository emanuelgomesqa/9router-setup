#!/usr/bin/env bash
# Funções compartilhadas pelos scripts do 9router-setup.
# shellcheck disable=SC2034

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
ENV_EXAMPLE="${ROOT_DIR}/config/.env.example"
MIN_NODE_MAJOR=20

# Comando que o usuário digita para chamar este setup (aparece nas mensagens).
# make (macOS/Linux), ./setup.sh (sem make) ou setup.cmd (Windows).
RUN="${NR_CMD:-make}"

# ---- Saída colorida ----------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
fi

info()  { printf '%s➜%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()    { printf '%s✔%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%s⚠%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
fail()  { printf '%s✖%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()   { fail "$*"; exit 1; }
title() { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"; }

has() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  # confirm "Pergunta?" [padrão s|n]  — respeita ASSUME_YES=1
  local prompt="$1" def="${2:-n}" ans
  [[ "${ASSUME_YES:-0}" == "1" ]] && return 0
  if [[ "$def" == "s" ]]; then prompt="$prompt [S/n] "; else prompt="$prompt [s/N] "; fi
  read -r -p "$prompt" ans || true
  ans="${ans:-$def}"
  [[ "$ans" =~ ^[sSyY]$ ]]
}

# ---- Sistema operacional ----------------------------------------------------
# Windows = Git Bash / MSYS2 / Cygwin (chamado pelo setup.cmd). WSL conta como Linux.
is_windows() { case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) return 0;; esac; return 1; }
is_macos()   { [[ "$(uname -s)" == Darwin ]]; }
is_wsl()     { grep -qi microsoft /proc/version 2>/dev/null; }
os_name() {
  if is_windows; then echo "Windows (Git Bash)"
  elif is_macos; then echo "macOS"
  elif is_wsl; then echo "Linux (WSL)"
  else echo "Linux"; fi
}

# Caminho no formato que programas nativos do Windows (node, docker) entendem.
native_path() { if is_windows && has cygpath; then cygpath -m "$1"; else printf '%s' "$1"; fi; }

# PID de quem escuta na porta $1 (vazio se ninguém ou se não for possível descobrir).
port_pid() {
  local port="$1"
  if has lsof; then
    lsof -t -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | head -1
  elif is_windows; then
    netstat -ano -p tcp 2>/dev/null | tr -d '\r' | awk -v p=":$port" \
      '$1=="TCP" && $4=="LISTENING" && substr($2,length($2)-length(p)+1)==p {print $5; exit}'
  elif has ss; then
    ss -ltnpH 2>/dev/null | awk -v p=":$port" 'substr($4,length($4)-length(p)+1)==p' \
      | grep -o 'pid=[0-9]*' | head -1 | cut -d= -f2
  fi
}

port_in_use() {
  local port="$1"
  [[ -n "$(port_pid "$port")" ]] && return 0
  # ss sem root não mostra o PID de processos de outros usuários: confere só a porta.
  if ! is_windows && ! has lsof && has ss; then
    ss -ltnH 2>/dev/null | awk -v p=":$port" 'substr($4,length($4)-length(p)+1)==p {f=1} END{exit !f}'
    return
  fi
  return 1
}

# Nome/comando do processo $1, para mensagens.
pid_cmd() {
  if is_windows; then
    tasklist //FI "PID eq $1" //FO CSV //NH 2>/dev/null | head -1 | cut -d, -f1 | tr -d '"\r'
  else
    ps -o command= -p "$1" 2>/dev/null | cut -c1-70
  fi
}

kill_hint() { if is_windows; then echo "taskkill /PID $1 /F"; else echo "kill $1"; fi; }

open_url() {
  local url="$1"
  if is_windows; then cmd.exe //c start "" "$url"
  elif is_macos; then open "$url"
  elif is_wsl && has wslview; then wslview "$url"
  elif is_wsl; then explorer.exe "$url" || true
  elif has xdg-open; then xdg-open "$url" >/dev/null 2>&1
  else info "Abra no navegador: $url"; fi
}

# tar do Git Bash trata "C:..." como host remoto; --force-local evita isso.
tar_local() { if is_windows; then tar --force-local "$@"; else tar "$@"; fi; }

# ---- .env --------------------------------------------------------------------
load_env() {
  [[ -f "$ENV_FILE" ]] || die ".env não encontrado. Rode primeiro: $RUN init"
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
  PORT="${PORT:-20128}"
  DATA_DIR_HOST="${DATA_DIR_HOST:-$HOME/.9router}"
  ROUTER_URL="http://127.0.0.1:${PORT}"
}

random_secret() {
  # $1 = bytes (padrão 32)
  local n="${1:-32}"
  if has openssl; then openssl rand -hex "$n"
  else head -c "$n" /dev/urandom | od -An -tx1 | tr -d ' \n'
  fi
}

# Substitui KEY=valor no .env (portável macOS/Linux/Windows).
set_env_var() {
  local key="$1" value="$2" tmp
  tmp="$(mktemp)"
  if grep -qE "^${key}=" "$ENV_FILE"; then
    awk -v k="$key" -v v="$value" 'BEGIN{FS=OFS="="} $1==k {print k"="v; next} {print}' "$ENV_FILE" >"$tmp"
  else
    cat "$ENV_FILE" >"$tmp"; printf '%s=%s\n' "$key" "$value" >>"$tmp"
  fi
  mv "$tmp" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
}

# ---- Detecção de modo de execução -------------------------------------------
docker_ok() { has docker && docker info >/dev/null 2>&1; }

compose() {
  # No Windows o Docker precisa de C:/Users/... em vez de /c/Users/...
  if is_windows; then export DATA_DIR_HOST="$(native_path "$DATA_DIR_HOST")"; fi
  if docker compose version >/dev/null 2>&1; then
    docker compose --project-directory "$ROOT_DIR" --env-file "$ENV_FILE" "$@"
  elif has docker-compose; then
    docker-compose --project-directory "$ROOT_DIR" --env-file "$ENV_FILE" "$@"
  else
    die "Docker Compose não encontrado."
  fi
}

# ---- Modo npm (pm2) ----------------------------------------------------------
# DATA_DIR para o processo node, em formato nativo do sistema.
export_data_dir() { export DATA_DIR; DATA_DIR="$(native_path "$DATA_DIR_HOST")"; }

# Arquivo JS de entrada do 9router instalado globalmente. Usar o .js direto
# (em vez do atalho do npm) faz o pm2 funcionar também no Windows.
ninerouter_entry() {
  local root; root="$(npm root -g 2>/dev/null)"
  [[ -f "$root/9router/package.json" ]] || { command -v 9router; return; }
  R="$(native_path "$root/9router")" node -e '
    const p=require("path"), r=process.env.R, j=require(p.join(r,"package.json"));
    const b=typeof j.bin==="string"?j.bin:(j.bin["9router"]||Object.values(j.bin)[0]);
    console.log(p.join(r,b));'
}

pm2_start() {
  export_data_dir
  if pm2 describe 9router >/dev/null 2>&1; then pm2 restart 9router --update-env
  else pm2 start "$(ninerouter_entry)" --name 9router; fi
}

node_major() { node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0; }

# Modo salvo pelo install: docker | npm
MODE_FILE="${ROOT_DIR}/.install-mode"
get_mode() { [[ -f "$MODE_FILE" ]] && cat "$MODE_FILE" || echo ""; }
