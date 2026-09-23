#!/usr/bin/env bash

if [[ -n "${_CYNTHIA_LOADED:-}" ]]; then
    return 0
fi
_CYNTHIA_LOADED=1

_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SOURCE_DIR/equipe.sh"

cynthia_gerar_aviso() {
    local idx=$(( RANDOM % ${#CYNTHIA_EQUIPE[@]} ))
    local entrada="${CYNTHIA_EQUIPE[$idx]}"
    local pokemon="${entrada%%|*}"
    local golpe="${entrada#*|}"

    local aviso=""
    if command -v pokeget &>/dev/null; then
        local sprite
        sprite=$(pokeget "$pokemon" --hide-name 2>/dev/null) || sprite=""
        if [[ -n "$sprite" ]]; then
            aviso="$sprite"$'\n\n'
        fi
    fi

    aviso+=$(printf '   %s USE %s!' "${pokemon^^}" "${golpe^^}")
    aviso+=$(printf '\n\n   SUA SESSAO SSH SERA ENCERRADA EM 3 SEGUNDOS!')

    echo "$aviso"
}
