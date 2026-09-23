# Cynthia SSH Killer

<p align="center">
    <a style="width: 100%">
        <img src="https://c.tenor.com/BjI5K2TSw98AAAAd/tenor.gif" width="250">
</p>
        
Sistema de encerramento de sessões SSH com avisos temáticos da equipe da campeã Cynthia (Sinnoh).

## Requisitos

- [pokeget](https://crates.io/crates/pokeget) — `cargo install pokeget` (opcional; sem ele o aviso vai apenas em texto)
- `sshpass` — `apt install sshpass` (apenas para deploy remoto com senha)
- `loginctl` (systemd)
- `pstree`, `write`
- `sudo` (necessário para encerrar sessões de outros processos)

## Instalação

```bash
git clone https://github.com/brafael1/Cynthia-SSH-killer.git
cd Cynthia-SSH-killer
chmod +x bin/*.sh lib/*.sh lib/cynthia/*.sh
```

## Uso

### Execução local

```bash
sudo ./bin/encerrar-sessoes-ssh.sh --ip 192.168.2.254
```

### Deploy e execução remota

```bash
# Com senha
./bin/remote-exec.sh -H 192.168.2.18 -u 'usuario' -p 'senha' -e 192.168.2.254

# Com chave (exige sudo NOPASSWD no host remoto)
./bin/remote-exec.sh -H 192.168.2.18 -u 'usuario' -k ~/.ssh/id_ed25519 -e 192.168.2.254

# Com chave + senha para o sudo
./bin/remote-exec.sh -H 192.168.2.18 -u 'usuario' -k ~/.ssh/id_ed25519 -p 'senha_sudo' -e 192.168.2.254
```

Informe `-k` (chave) ou `-p` (senha). Com ambos, a chave autentica o SSH e a senha é usada para o sudo (e como fallback do SSH). Chaves com passphrase exigem `ssh-agent`.

| Parâmetro | Descrição |
|-----------|-----------|
| `-H, --host` | IP/hostname do host remoto |
| `-u, --user` | Usuário SSH |
| `-k, --key` | Chave privada SSH |
| `-p, --pass` | Senha SSH e/ou senha do sudo |
| `-e, --ip-externo` | IP externo permitido |
| `-d, --dir` | Diretório temporário (padrão: /tmp) |

## Estrutura

```
Cynthia-SSH-killer/
├── bin/                          # Entradas de programa
│   ├── encerrar-sessoes-ssh.sh   # Killer: CLI + loop de encerramento de sessões
│   └── remote-exec.sh            # Cliente: CLI + deploy e execução remota
└── lib/                          # Camadas reaproveitáveis (dependência unidirecional)
    ├── loader.sh                 # Bootstrap único: lib_carregar <modulo>
    ├── args.sh                   # Validações de formato (IP, diretório)
    ├── transport.sh              # SSH/SCP com chave ou senha
    ├── sudo.sh                   # Execução do sudo remoto + diagnóstico de erro
    ├── deploy.sh                 # Orquestração: envia arquivos e executa o killer
    ├── sessions.sh               # Sessões logind: listar/filtrar/terminar/própria
    ├── notify.sh                 # Envio de mensagens via TTY
    └── cynthia/
        ├── aviso.sh              # Geração de avisos Pokemon
        └── equipe.sh             # Dados da equipe
```

Fluxo: `bin/*` valida argumentos, carrega módulos via `lib/loader.sh` e delega. `deploy.sh` usa `transport.sh` e `sudo.sh`; `sessions.sh`, `notify.sh` e `cynthia/*` são independentes (folhas).

## Equipe Cynthia (Platinum)

| Pokemon | Golpe |
|---------|-------|
| Garchomp | Dragon Rush |
| Spiritomb | Dark Pulse |
| Roserade | Energy Ball |
| Togekiss | Aura Sphere |
| Lucario | Close Combat |
| Milotic | Surf |

Para adicionar ou trocar pokemons, edite `lib/cynthia/equipe.sh`.
