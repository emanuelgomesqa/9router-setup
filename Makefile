# 9router-setup — atalhos para macOS/Linux. Rode `make` para ver a lista.
# Todos os comandos repassam para ./setup.sh (no Windows use setup.cmd).
SHELL := /usr/bin/env bash
SETUP := NR_CMD=make bash ./setup.sh

.DEFAULT_GOAL := help
CMDS := init init-force install install-docker install-npm \
        start stop restart status logs open doctor \
        clients clients-claude clients-claude-off clients-codex clients-codex-off \
        backup backups update uninstall purge
.PHONY: help restore $(CMDS)

help:
	@$(SETUP) help

$(CMDS):
	@$(SETUP) $@

# make restore FILE=backups/9router-AAAAMMDD-HHMMSS.tar.gz
restore:
	@$(SETUP) restore "$(FILE)"
