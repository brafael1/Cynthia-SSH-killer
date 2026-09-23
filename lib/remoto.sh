#!/usr/bin/env bash

if [[ -n "${_REMOTO_LOADED:-}" ]]; then
    return 0
fi
_REMOTO_LOADED=1

cli_remote() {
    local REMOTE_HOST=""
    local REMOTE_USER=""
    local REMOTE_PASS=""
    local SSH_KEY=""
    local REMOTE_ALIAS=""
    local REMOTE_PORT=""
    local REMOTE_DIR="/tmp"
    local IP_PERMITIDO=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage ;;
            -H|--host|-u|--user|-p|--pass|-k|--key|-e|--ip-externo|-d|--dir|-a|--alias|-P|--port)
                if [[ $# -lt 2 ]]; then
                    echo "Erro: $1 requer um valor" >&2
                    exit 1
                fi
                case "$1" in
                    -H|--host)       REMOTE_HOST="$2" ;;
                    -u|--user)       REMOTE_USER="$2" ;;
                    -p|--pass)       REMOTE_PASS="$2" ;;
                    -k|--key)        SSH_KEY="$2" ;;
                    -e|--ip-externo) IP_PERMITIDO="$2" ;;
                    -d|--dir)        REMOTE_DIR="$2" ;;
                    -a|--alias)      REMOTE_ALIAS="$2" ;;
                    -P|--port)       REMOTE_PORT="$2" ;;
                esac
                shift 2
                ;;
            *) echo "Opção desconhecida: $1" >&2; exit 1 ;;
        esac
    done

    if [[ -z "$IP_PERMITIDO" ]]; then
        echo "Erro: --ip-externo é obrigatório." >&2
        echo "Use --help para ver as opções." >&2
        exit 1
    fi

    lib_carregar args.sh
    lib_carregar transport.sh
    lib_carregar sudo.sh
    lib_carregar deploy.sh

    if [[ -n "$REMOTE_ALIAS" ]]; then
        if [[ -n "$REMOTE_HOST" || -n "$REMOTE_USER" ]]; then
            echo "Erro: --alias não pode ser combinado com --host/--user." >&2
            exit 1
        fi
        lib_carregar ssh_config.sh
        local rc_alias=0
        resolver_alias_ssh "$REMOTE_ALIAS" || rc_alias=$?
        case "$rc_alias" in
            1) echo "Erro: arquivo de config SSH não encontrado (~/.ssh/config)." >&2; exit 1 ;;
            2) echo "Erro: alias '$REMOTE_ALIAS' não encontrado em ~/.ssh/config." >&2; exit 1 ;;
        esac
        REMOTE_USER="$AC_USER"
        local resolvido="${AC_HOSTNAME:-$REMOTE_ALIAS}"
        echo "→ Alias '$REMOTE_ALIAS' aponta para ${resolvido}${AC_PORT:+:$AC_PORT}"
    else
        if [[ -z "$REMOTE_HOST" || -z "$REMOTE_USER" ]]; then
            echo "Erro: --host e --user são obrigatórios (ou use --alias)." >&2
            echo "Use --help para ver as opções." >&2
            exit 1
        fi
        if [[ -z "$SSH_KEY" && -z "$REMOTE_PASS" ]]; then
            echo "Erro: informe -k/--key (chave) ou -p/--pass (senha)." >&2
            echo "Use --help para ver as opções." >&2
            exit 1
        fi
    fi

    if [[ -n "$REMOTE_PORT" ]] && { [[ ! "$REMOTE_PORT" =~ ^[0-9]+$ ]] || (( REMOTE_PORT < 1 || REMOTE_PORT > 65535 )); }; then
        echo "Erro: porta inválida: $REMOTE_PORT" >&2
        exit 1
    fi

    TRANSPORT_KEY="$SSH_KEY"
    TRANSPORT_PASS="$REMOTE_PASS"
    TRANSPORT_PORT="$REMOTE_PORT"
    TIPO_SUDO="nopasswd"
    [[ -n "$REMOTE_PASS" ]] && TIPO_SUDO="senha"

    if ! validar_formato_dir "$REMOTE_DIR"; then
        echo "Erro: --dir contém caracteres inválidos: $REMOTE_DIR" >&2
        exit 1
    fi

    if ! validar_formato_ip "$IP_PERMITIDO"; then
        echo "Erro: --ip-externo contém caracteres inválidos: $IP_PERMITIDO" >&2
        exit 1
    fi

    if [[ -n "$SSH_KEY" && ! -f "$SSH_KEY" ]]; then
        echo "Erro: chave não encontrada: $SSH_KEY" >&2
        exit 1
    fi

    if [[ -n "$REMOTE_PASS" ]] && ! command -v sshpass &>/dev/null; then
        echo "Erro: sshpass não encontrado. Instale com: apt install sshpass" >&2
        exit 1
    fi

    local destino="$REMOTE_USER@$REMOTE_HOST"
    [[ -n "$REMOTE_ALIAS" ]] && destino="$REMOTE_ALIAS"
    local root_remoto="$REMOTE_DIR/Cynthia-SSH-killer"

    echo "A campeã de Sinnoh Cynthia desafiou $destino..."

    if deploy_remoto "$ROOT/bin" "$ROOT/lib" "$destino" "$root_remoto" "$TIPO_SUDO" "$IP_PERMITIDO"; then
        echo "Operação remota concluída!"
        exit 0
    fi
    exit 1
}