#!/usr/bin/env bash

if [[ -n "${_TRANSPORT_LOADED:-}" ]]; then
    return 0
fi
_TRANSPORT_LOADED=1

TRANSPORT_OPTS=(-o StrictHostKeyChecking=accept-new)

ssh_executar() {
    local destino=$1
    shift
    local -a cmd=(ssh "${TRANSPORT_OPTS[@]}")
    [[ -n "${TRANSPORT_PORT:-}" ]] && cmd+=(-p "$TRANSPORT_PORT")
    [[ -n "${TRANSPORT_KEY:-}" ]] && cmd+=(-i "$TRANSPORT_KEY")
    if [[ -n "${TRANSPORT_PASS:-}" ]]; then
        SSHPASS="$TRANSPORT_PASS" sshpass -e "${cmd[@]}" "$destino" "$@"
    else
        "${cmd[@]}" "$destino" "$@"
    fi
}

scp_enviar() {
    local -a cmd=(scp "${TRANSPORT_OPTS[@]}")
    [[ -n "${TRANSPORT_PORT:-}" ]] && cmd+=(-P "$TRANSPORT_PORT")
    [[ -n "${TRANSPORT_KEY:-}" ]] && cmd+=(-i "$TRANSPORT_KEY")
    if [[ -n "${TRANSPORT_PASS:-}" ]]; then
        SSHPASS="$TRANSPORT_PASS" sshpass -e "${cmd[@]}" "$@"
    else
        "${cmd[@]}" "$@"
    fi
}