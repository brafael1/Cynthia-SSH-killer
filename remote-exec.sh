#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<EOF
Uso: $(basename "$0") [OPÇÕES]

Deploy e execução remota do Cynthia-SSH-killer.

OPÇÕES:
  -H, --host IP          IP ou hostname do host remoto (obrigatório)
  -u, --user USUARIO     Usuário SSH (obrigatório)
  -p, --pass SENHA       Senha do usuário SSH (obrigatório)
  -e, --ip-externo IP    IP externo a ser permitido (obrigatório)
  -d, --dir DIRETORIO    Diretório temporário no host remoto (padrão: /tmp)
  -h, --help             Mostra esta ajuda

EXEMPLO:
  $(basename "$0") -H 192.168.2.18 -u spying -p 'minha_senha' -e 192.168.2.254
EOF
    exit 0
}

REMOTE_HOST=""
REMOTE_USER=""
REMOTE_PASS=""
REMOTE_DIR="/tmp"
IP_PERMITIDO=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -H|--host)      REMOTE_HOST="$2"; shift 2 ;;
        -u|--user)      REMOTE_USER="$2"; shift 2 ;;
        -p|--pass)      REMOTE_PASS="$2"; shift 2 ;;
        -e|--ip-externo) IP_PERMITIDO="$2"; shift 2 ;;
        -d|--dir)       REMOTE_DIR="$2"; shift 2 ;;
        -h|--help)      usage ;;
        *) echo "Opção desconhecida: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$REMOTE_HOST" || -z "$REMOTE_USER" || -z "$REMOTE_PASS" || -z "$IP_PERMITIDO" ]]; then
    echo "Erro: --host, --user, --pass e --ip-externo são obrigatórios." >&2
    echo "Use --help para ver as opções." >&2
    exit 1
fi

# Validação: os valores são interpolados na linha de comando executada
# no host remoto; sem isso, valores com metacaracteres permitiriam
# injeção de comandos arbitrários no remoto.
if [[ ! "$REMOTE_DIR" =~ ^[A-Za-z0-9._/-]+$ ]]; then
    echo "Erro: --dir contém caracteres inválidos: $REMOTE_DIR" >&2
    exit 1
fi

if [[ ! "$IP_PERMITIDO" =~ ^[A-Za-z0-9.:]+$ ]]; then
    echo "Erro: --ip-externo contém caracteres inválidos: $IP_PERMITIDO" >&2
    exit 1
fi

# sshpass -e lê a senha do ambiente (não do argv, que é visível no `ps`)
export SSHPASS="$REMOTE_PASS"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "A campeã de Sinnoh Cynthia desfiou $REMOTE_USER@$REMOTE_HOST..."

sshpass -e ssh -o StrictHostKeyChecking=no \
    "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR/Cynthia-SSH-killer/bin $REMOTE_DIR/Cynthia-SSH-killer/lib"

sshpass -e scp -o StrictHostKeyChecking=no -r \
    "$SCRIPT_DIR/bin/encerrar-sessoes-ssh.sh" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/Cynthia-SSH-killer/bin/"

sshpass -e scp -o StrictHostKeyChecking=no -r \
    "$SCRIPT_DIR/lib/"* \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/Cynthia-SSH-killer/lib/"

sshpass -e ssh -o StrictHostKeyChecking=no \
    "$REMOTE_USER@$REMOTE_HOST" \
    "sudo -S -p '' bash $REMOTE_DIR/Cynthia-SSH-killer/bin/encerrar-sessoes-ssh.sh --ip $IP_PERMITIDO" \
    <<< "$REMOTE_PASS"
