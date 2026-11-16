#!/usr/bin/env bash
# Mostra (ou aplica) a configuração das ferramentas de IA para usar o 9router.
#
# Uso:
#   scripts/configure-clients.sh                       → mostra instruções de todas
#   scripts/configure-clients.sh claude [--apply]      → Claude Code
#   scripts/configure-clients.sh codex  [--apply]      → Codex CLI
#   scripts/configure-clients.sh claude-off|codex-off  → desfaz
#   scripts/configure-clients.sh cursor|cline|continue|shell
#
# Variáveis: NINEROUTER_API_KEY (chave do dashboard), NINEROUTER_MODEL (modelo ou combo)
source "$(dirname "$0")/lib/common.sh"
load_env

TOOL="${1:-all}"
APPLY=0; [[ "${2:-}" == "--apply" ]] && APPLY=1

BASE="http://127.0.0.1:${PORT}"
KEY="${NINEROUTER_API_KEY:-}"
MODEL="${NINEROUTER_MODEL:-}"

# No Windows, $HOME do Git Bash é a pasta do usuário (%USERPROFILE%).
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

ask_key() {
  if [[ -z "$KEY" ]]; then
    read -r -s -p "Cole a API key do 9router (Dashboard → API Keys): " KEY; echo
    [[ -n "$KEY" ]] || die "API key obrigatória."
  fi
  if [[ -z "$MODEL" ]]; then
    read -r -p "Modelo ou combo padrão (ex.: meu-combo, cc/claude-sonnet-4-5) [enter = pular]: " MODEL
  fi
}

backup_file() { [[ -f "$1" ]] && cp "$1" "$1.bak.$(date +%Y%m%d%H%M%S)" && info "Backup: $1.bak.*"; return 0; }

# ---------------------------------------------------------------- Claude Code
claude_show() {
  title "Claude Code"
  local where="~/.claude/settings.json"
  is_windows && where='%USERPROFILE%\.claude\settings.json'
  cat <<EOF
Adicione em ${where} (escopo usuário) ou .claude/settings.json (projeto):

  {
    "env": {
      "ANTHROPIC_BASE_URL": "${BASE}",
      "ANTHROPIC_AUTH_TOKEN": "<SUA_API_KEY_9ROUTER>",
      "ANTHROPIC_MODEL": "<modelo-ou-combo>"
    }
  }

EOF
  if is_windows; then
    cat <<EOF
Ou só para a janela atual do PowerShell:
  \$env:ANTHROPIC_BASE_URL = "${BASE}"
  \$env:ANTHROPIC_AUTH_TOKEN = "<SUA_API_KEY_9ROUTER>"
  claude
EOF
  else
    cat <<EOF
Ou só para a sessão atual do terminal:
  export ANTHROPIC_BASE_URL=${BASE}
  export ANTHROPIC_AUTH_TOKEN=<SUA_API_KEY_9ROUTER>
  claude
EOF
  fi
  cat <<EOF

Atalho: o próprio dashboard tem "CLI Tools → Claude Code" que gera essa config.
Automático: ${RUN} clients-claude   (faz backup e mescla no settings.json)
EOF
}

claude_apply() {
  has node || die "Node.js é necessário para editar o JSON com segurança. Configure manualmente (veja acima)."
  ask_key
  local f="$CLAUDE_SETTINGS"
  mkdir -p "$(dirname "$f")"; backup_file "$f"
  F="$(native_path "$f")" B="$BASE" K="$KEY" M="$MODEL" node -e '
    const fs=require("fs"); const f=process.env.F;
    let j={}; try{ j=JSON.parse(fs.readFileSync(f,"utf8")); }catch(e){ if(fs.existsSync(f)){ console.error("settings.json inválido; corrija antes."); process.exit(1);} }
    j.env=Object.assign({}, j.env, {ANTHROPIC_BASE_URL:process.env.B, ANTHROPIC_AUTH_TOKEN:process.env.K});
    if(process.env.M) j.env.ANTHROPIC_MODEL=process.env.M;
    fs.writeFileSync(f, JSON.stringify(j,null,2)+"\n");'
  chmod 600 "$f"
  ok "Claude Code configurado em $f. Abra um novo terminal e rode: claude"
  info "Para desfazer: $RUN clients-claude-off"
}

claude_remove() {
  has node || die "Node.js necessário."
  local f="$CLAUDE_SETTINGS"
  [[ -f "$f" ]] || { ok "Nada a remover."; return; }
  backup_file "$f"
  F="$(native_path "$f")" node -e '
    const fs=require("fs"); const f=process.env.F; const j=JSON.parse(fs.readFileSync(f,"utf8"));
    if(j.env){ for(const k of ["ANTHROPIC_BASE_URL","ANTHROPIC_AUTH_TOKEN","ANTHROPIC_MODEL"]) delete j.env[k]; if(!Object.keys(j.env).length) delete j.env; }
    fs.writeFileSync(f, JSON.stringify(j,null,2)+"\n");'
  ok "Claude Code voltou a usar a conexão padrão."
}

# ---------------------------------------------------------------- Codex
codex_show() {
  title "Codex CLI"
  if is_windows; then
    cat <<EOF
  PowerShell (só esta janela):
    \$env:OPENAI_BASE_URL = "${BASE}"     # sem /v1 — é assim que o 9router documenta
    \$env:OPENAI_API_KEY = "<SUA_API_KEY_9ROUTER>"
    codex "seu prompt"

Automático: ${RUN} clients-codex  (grava as variáveis no seu usuário do Windows)
EOF
  else
    cat <<EOF
  export OPENAI_BASE_URL=${BASE}        # sem /v1 — é assim que o 9router documenta
  export OPENAI_API_KEY=<SUA_API_KEY_9ROUTER>
  codex "seu prompt"

Automático: ${RUN} clients-codex  (adiciona as variáveis ao seu ~/.zshrc ou ~/.bashrc)
EOF
  fi
}

shell_rc() { case "${SHELL:-}" in */zsh) echo "$HOME/.zshrc";; *) echo "$HOME/.bashrc";; esac; }

remove_rc_block() {
  awk '/^# >>> 9router >>>/{skip=1} !skip{print} /^# <<< 9router <<</{skip=0}' "$1" >"$1.tmp" && mv "$1.tmp" "$1"
}

codex_apply() {
  ask_key
  if is_windows; then
    # setx grava variáveis permanentes do usuário (valem para janelas novas).
    MSYS2_ARG_CONV_EXCL='*' setx OPENAI_BASE_URL "$BASE" >/dev/null
    MSYS2_ARG_CONV_EXCL='*' setx OPENAI_API_KEY "$KEY" >/dev/null
    ok "OPENAI_BASE_URL e OPENAI_API_KEY gravadas no seu usuário do Windows. Abra um NOVO terminal e rode: codex"
    info "Para desfazer: $RUN clients-codex-off"
    return
  fi
  local rc; rc="$(shell_rc)"; backup_file "$rc"
  [[ -f "$rc" ]] && remove_rc_block "$rc"   # remove bloco anterior, se existir
  cat >>"$rc" <<EOF
# >>> 9router >>>
export OPENAI_BASE_URL=${BASE}
export OPENAI_API_KEY=${KEY}
# <<< 9router <<<
EOF
  ok "Variáveis adicionadas em $rc. Rode: source $rc"
  info "Para desfazer: $RUN clients-codex-off"
}

codex_remove() {
  if is_windows; then
    local v
    for v in OPENAI_BASE_URL OPENAI_API_KEY; do
      MSYS2_ARG_CONV_EXCL='*' reg delete 'HKCU\Environment' /v "$v" /f >/dev/null 2>&1 || true
    done
    ok "Variáveis do Codex removidas do seu usuário do Windows (vale para terminais novos)."
    return
  fi
  local rc; rc="$(shell_rc)"
  if [[ ! -f "$rc" ]] || ! grep -q '^# >>> 9router >>>' "$rc"; then ok "Nada a remover."; return; fi
  backup_file "$rc"
  remove_rc_block "$rc"
  ok "Bloco do 9router removido de $rc. Abra um novo terminal."
}

# ---------------------------------------------------------------- Outros
openai_compat_show() {
  title "$1"
  cat <<EOF
  Provider   : OpenAI Compatible
  Base URL   : ${BASE}/v1
  API Key    : <SUA_API_KEY_9ROUTER>
  Modelo     : nome de um modelo (ex.: cc/claude-sonnet-4-5) ou de um combo
$2
EOF
}

shell_show() {
  title "Teste rápido via curl"
  cat <<EOF
  curl ${BASE}/v1/models -H "Authorization: Bearer \$NINEROUTER_API_KEY"

  curl ${BASE}/v1/chat/completions \\
    -H "Authorization: Bearer \$NINEROUTER_API_KEY" \\
    -H "Content-Type: application/json" \\
    -d '{"model":"<modelo-ou-combo>","messages":[{"role":"user","content":"Olá!"}]}'
EOF
  if is_windows; then
    cat <<EOF

  No PowerShell use curl.exe (o "curl" de lá é outro comando):
  curl.exe ${BASE}/v1/models -H "Authorization: Bearer <SUA_API_KEY_9ROUTER>"
EOF
  fi
}

case "$TOOL" in
  claude)     if (( APPLY )); then claude_apply; else claude_show; fi ;;
  claude-off) claude_remove ;;
  codex)      if (( APPLY )); then codex_apply; else codex_show; fi ;;
  codex-off)  codex_remove ;;
  cursor)     openai_compat_show "Cursor" "  Onde     : Settings → Models → Advanced → OpenAI API Base URL" ;;
  cline|continue|roo) openai_compat_show "Cline / Continue / RooCode" "" ;;
  shell)      shell_show ;;
  all)
    claude_show; codex_show
    openai_compat_show "Cursor" "  Onde     : Settings → Models → Advanced → OpenAI API Base URL"
    openai_compat_show "Cline / Continue / RooCode" ""
    shell_show ;;
  *) die "Ferramenta desconhecida: $TOOL" ;;
esac
