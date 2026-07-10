#!/usr/bin/env bash

if [[ -n "${_NOTIFY_LOADED:-}" ]]; then
    return 0
fi
_NOTIFY_LOADED=1

notify_enviar() {
    local usuario=$1
    local tty=$2
    local mensagem=$3
    local linhas_cabecalho=${4:-3}

    if [ -w "/dev/$tty" ]; then
        local i=0
        while [ $i -lt "$linhas_cabecalho" ]; do
            printf '\r\n' > "/dev/$tty"
            i=$((i + 1))
        done
        while IFS= read -r line; do
            printf '%s\r\n' "$line" > "/dev/$tty"
        done <<< "$mensagem"
        return 0
    fi

    printf '%s\n' "$mensagem" | write "$usuario" "$tty" 2>/dev/null && return 0

    return 1
}
