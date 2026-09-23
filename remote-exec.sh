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
 
if [[ ! "$REMOTE_DIR" =~ ^[A-Za-z0-9._/-]+$ ]]; then
    echo "Erro: --dir contém caracteres inválidos: $REMOTE_DIR" >&2
    exit 1
fi
 
if [[ ! "$IP_PERMITIDO" =~ ^[A-Za-z0-9.:]+$ ]]; then
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
 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$REMOTE_USER@$REMOTE_HOST"
REMOTE_ROOT="$REMOTE_DIR/Cynthia-SSH-killer"
 
source "$SCRIPT_DIR/lib/loader.sh"
lib_carregar transport.sh
 
TRANSPORT_KEY="$SSH_KEY"
TRANSPORT_PASS="$REMOTE_PASS"
 
echo "A campeã de Sinnoh Cynthia desfiou $DEST..."
 
echo "→ Enviando o killer para $REMOTE_ROOT..."
ssh_executar "$DEST" "rm -rf $REMOTE_ROOT && mkdir -p $REMOTE_ROOT"
scp_enviar -r "$SCRIPT_DIR/bin" "$SCRIPT_DIR/lib" "$DEST:$REMOTE_ROOT/"
 
SUDO_ENV='env PATH="$PATH"'
KILLER_CMD="bash $REMOTE_ROOT/bin/encerrar-sessoes-ssh.sh --ip $IP_PERMITIDO"
 
echo "→ Executando o killer (sudo)..."
if [[ -n "$REMOTE_PASS" ]]; then
    printf '%s\n' "$REMOTE_PASS" | ssh_executar "$DEST" "sudo -S -p '' $SUDO_ENV $KILLER_CMD"
else
    if ssh_executar "$DEST" "sudo -n $SUDO_ENV $KILLER_CMD"; then
        :
    else
        rc=$?
        if [[ "$rc" -eq 255 ]]; then
            echo "A sessão do deploy foi encerrada pelo killer por último." >&2
        else
            echo "Erro: o sudo do host remoto pediu senha." >&2
            echo "Configure sudoers NOPASSWD para $REMOTE_USER ou informe -p/--pass junto com -k/--key." >&2
        fi
        exit 1
    fi
fi
 
echo "Operação remota concluída!"
