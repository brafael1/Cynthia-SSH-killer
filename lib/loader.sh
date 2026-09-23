#!/usr/bin/env bash

if [[ -n "${_LOADER_LOADED:-}" ]]; then
    return 0
fi
_LOADER_LOADED=1

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

lib_carregar() {
    local modulo=$1
    local caminho="$LIB_DIR/$modulo"
    if [[ ! -f "$caminho" ]]; then
        echo "Erro: módulo '$modulo' não encontrado em $LIB_DIR" >&2
        exit 1
    fi
    source "$caminho"
}