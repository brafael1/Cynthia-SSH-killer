#!/usr/bin/env bash

if [[ -n "${_SSH_CONFIG_LOADED:-}" ]]; then
    return 0
fi
_SSH_CONFIG_LOADED=1

# Lê um alias do ~/.ssh/config e expõe os parâmetros de conexão nas globais:
#   AC_HOSTNAME  → valor de HostName (vazio se o bloco não define)
#   AC_USER      → valor de User
#   AC_PORT      → valor de Port
#   AC_IDENTITY  → primeira IdentityFile (com ~ expandido)
#
# Segue a semântica do ssh: todo bloco Host que casar contribui e o primeiro
# valor obtido de cada parâmetro vence (o que significa que o fim da lista
# também vale, pois blocos que não casam são ignorados).
#
# Retorno:
#   0  alias resolvido (parâmetros não definidos ficam vazios)
#   1  ~/.ssh/config não encontrado
#   2  nenhum bloco Host casou com o alias
resolver_alias_ssh() {
    local alias_alvo=$1
    local config=${SSH_CONFIG_FILE:-"$HOME/.ssh/config"}
    local alvo_lc
    alvo_lc="$(printf '%s' "$alias_alvo" | tr 'A-Z' 'a-z')"

    AC_HOSTNAME=""
    AC_USER=""
    AC_PORT=""
    AC_IDENTITY=""

    if [[ ! -f "$config" ]]; then
        return 1
    fi

    local linha chave valor achou_alvo=0 ja_casou=0 p p_lc padroes

    while IFS= read -r linha || [[ -n "$linha" ]]; do
        linha="${linha%%#*}"                        # remove comentário
        linha="${linha#"${linha%%[![:space:]]*}"}"  # trim à esquerda
        linha="${linha%"${linha##*[![:space:]]}"}"  # trim à direita
        [[ -z "$linha" ]] && continue

        chave="${linha%%[[:space:]]*}"
        valor="${linha#*[[:space:]]}"
        chave="$(printf '%s' "$chave" | tr 'A-Z' 'a-z')"

        if [[ "$chave" == "host" ]]; then
            achou_alvo=0
            read -ra padroes <<<"$valor"
            for p in "${padroes[@]}"; do
                p_lc="$(printf '%s' "$p" | tr 'A-Z' 'a-z')"
                if [[ "$alvo_lc" == $p_lc ]]; then
                    achou_alvo=1
                    # "Host *" é catch-all: contribui com defaults, mas não
                    # conta como definição de um alias específico.
                    [[ "$p_lc" != "*" ]] && ja_casou=1
                fi
            done
            continue
        fi

        [[ "$achou_alvo" == 1 ]] || continue

        case "$chave" in
            hostname)     [[ -n "$AC_HOSTNAME" ]] || AC_HOSTNAME="$valor" ;;
            user)         [[ -n "$AC_USER" ]]     || AC_USER="$valor" ;;
            port)         [[ -n "$AC_PORT" ]]     || AC_PORT="$valor" ;;
            identityfile) [[ -n "$AC_IDENTITY" ]] || AC_IDENTITY="$valor" ;;
        esac
    done < "$config"

    [[ "$ja_casou" == 1 ]] || return 2

    AC_HOSTNAME="${AC_HOSTNAME/#\~/$HOME}"
    AC_IDENTITY="${AC_IDENTITY/#\~/$HOME}"
    return 0
}