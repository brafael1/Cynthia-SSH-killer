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
        tty=$(ps -p "$pid" -o tty= 2>/dev/null) || true
        if [[ "$tty" != "?" && -n "$tty" ]]; then
            echo "$tty"
            return
        fi
    done
    echo ""
}

core_sessao_propria() {
    local scope
    scope=$(grep -oE 'session-[A-Za-z0-9_-]+\.scope' /proc/self/cgroup 2>/dev/null | head -1) || true
    scope="${scope#session-}"
    printf '%s' "${scope%.scope}"
}

core_listar_sessoes() {
    local ip_permitido=$1
    local ip_atual=$2
    local tty_atual=$3

    local propria
    propria=$(core_sessao_propria)
    local outras=""
    local propria_linha=""

    while read -r sessao; do
        [ -z "$sessao" ] && continue

        local props
        props=$(loginctl show-session \
            -p RemoteHost -p Display -p Name -p Id -p Leader \
            "$sessao" 2>/dev/null) || continue

        local remote usuario sessao_id leader
        remote=$(printf '%s\n' "$props" | grep '^RemoteHost=' | cut -d= -f2-) || true
        usuario=$(printf '%s\n' "$props" | grep '^Name=' | cut -d= -f2-) || true
        sessao_id=$(printf '%s\n' "$props" | grep '^Id=' | cut -d= -f2-) || true
        leader=$(printf '%s\n' "$props" | grep '^Leader=' | cut -d= -f2-) || true

        [ -z "$remote" ] && continue

        remote="${remote#::ffff:}"

        [[ "$remote" == "$ip_permitido" ]] && continue
        [[ -n "$ip_atual" && "$remote" == "$ip_atual" ]] && continue

        local display
        display=$(core_find_tty "$leader")
        [[ -n "$tty_atual" && "$display" == "$tty_atual" ]] && continue

        local tty_display="$display"
        [ -z "$tty_display" ] && tty_display="(sem tty)"

        local linha="$sessao_id|$usuario|$tty_display|$remote|$display"
        if [[ -n "$propria" && "$sessao_id" == "$propria" ]]; then
            propria_linha="$linha"
        else
            outras+="$linha"$'\n'
        fi
    done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')

    printf '%s' "$outras"
    if [[ -n "$propria_linha" ]]; then
        printf '%s\n' "$propria_linha"
    fi
}

core_encerrar_sessao() {
    local sessao=$1
    loginctl terminate-session "$sessao" 2>/dev/null
}
