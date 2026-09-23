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
    local REMOTE_DIR="/tmp"
    local IP_PERMITIDO=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage ;;
            -H|--host|-u|--user|-p|--pass|-k|--key|-e|--ip-externo|-d|--dir)
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
                esac
                shift 2
                ;;
            *) echo "Opção desconhecida: $1" >&2; exit 1 ;;
        esac
    done

    if [[ -z "$REMOTE_HOST" || -z "$REMOTE_USER" || -z "$IP_PERMITIDO" ]]; then
        echo "Erro: --host, --user e --ip-externo são obrigatórios." >&2
        echo "Use --help para ver as opções." >&2
        exit 1
    fi

    if [[ -z "$SSH_KEY" && -z "$REMOTE_PASS" ]]; then
        echo "Erro: informe -k/--key (chave) ou -p/--pass (senha)." >&2
        echo "Use --help para ver as opções." >&2
        exit 1
    fi

    lib_carregar args.sh
    lib_carregar transport.sh
    lib_carregar sudo.sh
    lib_carregar deploy.sh

    TRANSPORT_KEY="$SSH_KEY"
    TRANSPORT_PASS="$REMOTE_PASS"
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
    local root_remoto="$REMOTE_DIR/Cynthia-SSH-killer"

    echo "A campeã de Sinnoh Cynthia desafiou $destino..."

    if deploy_remoto "$ROOT/bin" "$ROOT/lib" "$destino" "$root_remoto" "$TIPO_SUDO" "$IP_PERMITIDO"; then
        echo "Operação remota concluída!"
        exit 0
    fi
    exit 1
}