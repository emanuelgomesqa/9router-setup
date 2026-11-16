#!/usr/bin/env bash
# 9router-setup — ponto de entrada único, igual em macOS, Linux e Windows.
#
#   macOS/Linux : make <comando>   ou   ./setup.sh <comando>
#   Windows     : setup.cmd <comando>   (chama este arquivo pelo Git Bash)
#
# Rode sem argumentos para ver a lista de comandos.
set -euo pipefail

S="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"
export NR_CMD="${NR_CMD:-./setup.sh}"
RUN="$NR_CMD"

usage() {
  local b="" c="" r=""
  if [[ -t 1 ]]; then b=$'\033[1m'; c=$'\033[36m'; r=$'\033[0m'; fi
  cat <<EOF
${b}9router-setup${r} — uso: ${b}${RUN} <comando>${r}

${b}Instalação${r}
  ${c}init${r}                 Cria o .env com segredos fortes e mostra a senha do dashboard
  ${c}init-force${r}           Recria o .env (faz backup do atual)
  ${c}install${r}              Instala e inicia (Docker se disponível, senão npm + pm2)
  ${c}install-docker${r}       Instala usando Docker
  ${c}install-npm${r}          Instala usando npm + pm2

${b}Operação${r}
  ${c}start${r}                Inicia o serviço
  ${c}stop${r}                 Para o serviço
  ${c}restart${r}              Reinicia o serviço
  ${c}status${r}               Mostra o status
  ${c}logs${r}                 Acompanha os logs (Ctrl+C para sair)
  ${c}open${r}                 Abre o dashboard no navegador
  ${c}doctor${r}               Diagnóstico completo

${b}Ferramentas de IA${r}
  ${c}clients${r} [ferramenta] Mostra a config (claude, codex, cursor, cline, continue, shell)
  ${c}clients-claude${r}       Configura o Claude Code automaticamente (com backup)
  ${c}clients-claude-off${r}   Desfaz a configuração do Claude Code
  ${c}clients-codex${r}        Configura o Codex CLI automaticamente
  ${c}clients-codex-off${r}    Desfaz a configuração do Codex CLI

${b}Manutenção${r}
  ${c}backup${r}               Cria backup dos dados + .env
  ${c}backups${r}              Lista os backups
  ${c}restore${r} <arquivo>    Restaura um backup
  ${c}update${r}               Atualiza para a última versão (faz backup antes)
  ${c}uninstall${r}            Remove o 9router (mantém os dados)
  ${c}purge${r}                Remove o 9router E apaga os dados
EOF
}

cmd="${1:-help}"; shift || true

case "$cmd" in
  help|-h|--help)     usage ;;
  init)               bash "$S/init.sh" ;;
  init-force)         bash "$S/init.sh" --force ;;
  install)            bash "$S/install.sh" ;;
  install-docker)     bash "$S/install.sh" docker ;;
  install-npm)        bash "$S/install.sh" npm ;;
  start|stop|restart|status|logs|open)
                      bash "$S/service.sh" "$cmd" ;;
  doctor)             bash "$S/doctor.sh" ;;
  clients)            bash "$S/configure-clients.sh" "${1:-all}" ;;
  clients-claude)     bash "$S/configure-clients.sh" claude --apply ;;
  clients-claude-off) bash "$S/configure-clients.sh" claude-off ;;
  clients-codex)      bash "$S/configure-clients.sh" codex --apply ;;
  clients-codex-off)  bash "$S/configure-clients.sh" codex-off ;;
  backup)             bash "$S/backup.sh" ;;
  backups)            bash "$S/backup.sh" list ;;
  restore)
    [[ -n "${1:-}" ]] || { echo "Uso: $RUN restore <arquivo>  (veja '$RUN backups')" >&2; exit 1; }
    bash "$S/backup.sh" restore "$1" ;;
  update)             bash "$S/update.sh" ;;
  uninstall)          bash "$S/uninstall.sh" ;;
  purge)              bash "$S/uninstall.sh" --purge ;;
  *) echo "Comando desconhecido: $cmd" >&2; echo >&2; usage >&2; exit 1 ;;
esac
