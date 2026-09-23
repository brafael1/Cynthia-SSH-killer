#!/usr/bin/env bash

if [[ -n "${_ARGS_LOADED:-}" ]]; then
    return 0
fi
_ARGS_LOADED=1

validar_formato_ip() {
    [[ "$1" =~ ^[A-Za-z0-9.:]+$ ]]
}

validar_formato_dir() {
    [[ "$1" =~ ^[A-Za-z0-9._/-]+$ ]]
}