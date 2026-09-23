#!/usr/bin/env bash
 
set -euo pipefail
 
usage() {
    echo "Uso: sudo $(basename "$0") --ip IP_PERMITIDO"
    echo ""
    echo "Encerra todas as sessões SSH, exceto a atual e as do IP permitido."
    exit 0
}
 
if ! command -v pokeget &>/dev/null; then
    echo "Erro: pokeget não encontrado. Instale com: cargo install pokeget" >&2
    exit 1
fi
 
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
 
if [[ ! -d "$LIB_DIR" ]]; then
    echo "Erro: pasta 'lib/' não encontrada em $LIB_DIR" >&2
    exit 1
fi
 
for arquivo in core.sh notify.sh cynthia/aviso.sh; do
    if [[ ! -f "$LIB_DIR/$arquivo" ]]; then
        echo "Erro: '$arquivo' não encontrado em $LIB_DIR" >&2
        exit 1
    fi
done
 
source "$LIB_DIR/core.sh"
source "$LIB_DIR/notify.sh"
source "$LIB_DIR/cynthia/aviso.sh"
 
IP_PERMITIDO=""
 
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ip)
            if [[ $# -lt 2 ]]; then
                echo "Erro: --ip requer um valor" >&2
                exit 1
            fi
            IP_PERMITIDO="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Opção desconhecida: $1" >&2; exit 1 ;;
    esac
done
 
if [[ -z "$IP_PERMITIDO" ]]; then
    echo "Erro: --ip é obrigatório. Ex: --ip 192.168.2.254" >&2
    exit 1
fi
 
TTY_ATUAL=$(tty 2>/dev/null | sed 's|/dev/||' || true)
IP_ATUAL=${SSH_CLIENT:-}
IP_ATUAL=${IP_ATUAL%% *}
 
echo "Buscando sessões SSH ativas..."
echo ""
 
while IFS='|' read -r sessao_id usuario tty_display remote display; do
    [ -z "$sessao_id" ] && continue
 
    printf '%s\n' \
        "───────────────────────────────────────────" \
        "  Sessao  : $sessao_id" \
        "  Usuario : $usuario" \
        "  Terminal: $tty_display" \
        "  IP      : $remote" \
        "───────────────────────────────────────────"
 
    if [ -n "$display" ]; then
        aviso=$(cynthia_gerar_aviso) || aviso=""

        if [[ -n "$aviso" ]] && notify_enviar "$usuario" "$display" "$aviso"; then
            echo "Aviso enviado para $display!"
        else
            echo "Não foi possível enviar aviso"
        fi
        sleep 3
    fi
 
    if core_encerrar_sessao "$sessao_id"; then
        echo "Sessão $sessao_id derrotada!"
    else
        echo "Sessão $sessao_id fugiu da Cynthia"
    fi
    echo ""
done < <(core_listar_sessoes "$IP_PERMITIDO" "$IP_ATUAL" "$TTY_ATUAL")
 
echo "Operação concluída! Sessões de $IP_PERMITIDO mantidas."
