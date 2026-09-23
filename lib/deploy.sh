#!/usr/bin/env bash

if [[ -n "${_DEPLOY_LOADED:-}" ]]; then
    return 0
fi
_DEPLOY_LOADED=1

deploy_remoto() {
    local dir_bin=$1
    local dir_lib=$2
    local destino=$3
    local root_remoto=$4
    local tipo_sudo=$5
    local ip_permitido=$6

    echo "→ Enviando o killer para $root_remoto..."
    ssh_executar "$destino" "rm -rf $root_remoto && mkdir -p $root_remoto/bin $root_remoto/lib"

    scp_enviar -r "$dir_bin" "$destino:$root_remoto/"
    scp_enviar -r "$dir_lib/loader.sh" "$dir_lib/sessions.sh" "$dir_lib/notify.sh" "$dir_lib/cynthia" "$destino:$root_remoto/lib/"

    local ambiente_sudo='env PATH="$PATH"'
    local comando_killer="bash $root_remoto/bin/encerrar-sessoes-ssh.sh --ip $ip_permitido"

    echo "→ Executando o killer (sudo)..."
    sudo_executar "$destino" "$tipo_sudo" "$ambiente_sudo $comando_killer"
}