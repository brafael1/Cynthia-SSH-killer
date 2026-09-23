#!/usr/bin/env bash
 
set -euo pipefail
 
usage() {
    cat <<EOF
Uso: $(basename "$0") [OPÇÕES]
 
Deploy e execução remota do Cynthia-SSH-killer.
 
OPÇÕES:
  -H, --host IP          IP ou hostname do host remoto (obrigatório)
  -u, --user USUARIO     Usuário SSH (obrigatório)
  -e, --ip-externo IP    IP externo a ser permitido (obrigatório)
  -d, --dir DIRETORIO    Diretório temporário no host remoto (padrão: /tmp)
  -k, --key ARQUIVO      Chave privada SSH para autenticação
  -p, --pass SENHA       Senha SSH e/ou senha do sudo
  -h, --help             Mostra esta ajuda
 
AUTENTICAÇÃO:
  - Chave: informe -k. Com senha na chave, use ssh-agent.
    Sem -p, o sudo remoto precisa estar configurado como NOPASSWD.
  - Senha: informe -p (usada para o SSH e para o sudo).
  - Ambos: -k autentica o SSH; -p é o fallback do SSH e a senha do sudo.
 
EXEMPLOS:
  $(basename "$0") -H 192.168.2.18 -u spying -k ~/.ssh/id_ed25519 -e 192.168.2.254
 
  $(basename "$0") -H 192.168.2.18 -u spying -k ~/.ssh/id_ed25519 -p 'senha_sudo' -e 192.168.2.254
 
  $(basename "$0") -H 192.168.2.18 -u spying -p 'minha_senha' -e 192.168.2.254
EOF
    exit 0
}
 
REMOTE_HOST=""
REMOTE_USER=""
REMOTE_PASS=""
SSH_KEY=""
REMOTE_DIR="/tmp"
IP_PERMITIDO=""
 
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
 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
 
source "$SCRIPT_DIR/lib/loader.sh"
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
 
DEST="$REMOTE_USER@$REMOTE_HOST"
ROOT_REMOTO="$REMOTE_DIR/Cynthia-SSH-killer"
 
echo "A campeã de Sinnoh Cynthia desfiou $DEST..."
 
if deploy_remoto "$SCRIPT_DIR/bin" "$SCRIPT_DIR/lib" "$DEST" "$ROOT_REMOTO" "$TIPO_SUDO" "$IP_PERMITIDO"; then
    echo "Operação remota concluída!"
    exit 0
fi
exit 1
