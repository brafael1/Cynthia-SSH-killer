#!/usr/bin/env bash

if [[ -n "${_SUDO_LOADED:-}" ]]; then
    return 0
fi
_SUDO_LOADED=1

sudo_executar() {
    local destino=$1
    local tipo=$2
    local comando=$3

    if [[ "$tipo" == "senha" ]]; then
        printf '%s\n' "${REMOTE_PASS:-}" | ssh_executar "$destino" "sudo -S -p '' $comando"
        return
    fi

    if ssh_executar "$destino" "sudo -n $comando"; then
        return 0
    fi
    local rc=$?
    if [[ "$rc" -eq 255 ]]; then
        echo "A sessão do deploy foi encerrada pelo killer por último." >&2
    else
        echo "Erro: o sudo do host remoto pediu senha." >&2
        echo "Configure sudoers NOPASSWD para ${REMOTE_USER:-} ou informe -p/--pass junto com -k/--key." >&2
    fi
    return 1
}