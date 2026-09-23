#!/usr/bin/env bash

if [[ -n "${_CORE_LOADED:-}" ]]; then
    return 0
fi
_CORE_LOADED=1

core_find_tty() {
    local leader=$1
    local pids
    pids=$(pstree -p "$leader" 2>/dev/null | grep -oE '\([0-9]+\)' | tr -d '()') || true

    for pid in $pids; do
        local tty
        tty=$(ps -p "$pid" -o tty= 2>/dev/null)
        if [[ "$tty" != "?" && -n "$tty" ]]; then
            echo "$tty"
            return
        fi
    done
    echo ""
}

core_listar_sessoes() {
    local ip_permitido=$1
    local ip_atual=$2
    local tty_atual=$3

    while read -r sessao; do
        [ -z "$sessao" ] && continue

        local props
        props=$(loginctl show-session \
            -p RemoteHost -p Display -p Name -p Id -p Leader \
            "$sessao" 2>/dev/null) || continue

        local remote usuario sessao_id leader
        remote=$(echo "$props" | grep ^RemoteHost= | cut -d= -f2-)
        usuario=$(echo "$props" | grep ^Name= | cut -d= -f2-)
        sessao_id=$(echo "$props" | grep ^Id= | cut -d= -f2-)
        leader=$(echo "$props" | grep ^Leader= | cut -d= -f2-)

        [ -z "$remote" ] && continue

        remote="${remote#::ffff:}"

        [[ "$remote" == "$ip_permitido" ]] && continue
        [[ -n "$ip_atual" && "$remote" == "$ip_atual" ]] && continue

        local display
        display=$(core_find_tty "$leader")
        [[ -n "$tty_atual" && "$display" == "$tty_atual" ]] && continue

        local tty_display="$display"
        [ -z "$tty_display" ] && tty_display="(sem tty)"

        printf '%s\n' "$sessao_id|$usuario|$tty_display|$remote|$display"
    done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
}

core_encerrar_sessao() {
    local sessao=$1
    if loginctl terminate-session "$sessao" 2>/dev/null; then
        return 0
    fi
    return 1
}
