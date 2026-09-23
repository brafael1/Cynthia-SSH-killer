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

    local saida=""
    local rc=0
    saida="$(ssh_executar "$destino" "sudo -n $comando" 2>&1)" || rc=$?

    if [[ "$rc" -eq 0 ]]; then
        [[ -n "$saida" ]] && printf '%s\n' "$saida"
        return 0
    fi

    if printf '%s\n' "$saida" | grep -qiE 'a password is required|interactive authentication is required|authentication failed|incorrect password|sorry, try again'; then
        echo "Erro: o sudo do host remoto pediu senha." >&2
        echo "Configure sudoers NOPASSWD para ${REMOTE_USER:-${REMOTE_ALIAS:-}} ou informe -p/--pass junto com -k/--key." >&2
    elif printf '%s\n' "$saida" | grep -qE 'Sessao|derrotada|closed by remote host'; then
        printf '%s\n' "$saida" >&2
        echo "A sessão do deploy foi encerrada pelo killer por último." >&2
    else
        printf '%s\n' "$saida" >&2
        echo "Erro: falha na execução remota (rc=$rc)." >&2
    fi
    return 1
}