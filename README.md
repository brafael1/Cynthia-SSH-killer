# Cynthia SSH Killer

<p align="center">
    <a style="width: 100%">
        <img src="https://c.tenor.com/BjI5K2TSw98AAAAd/tenor.gif" width="300">
</p>
        
Sistema de encerramento de sessões SSH com avisos temáticos da equipe da campeã Cynthia (Sinnoh).

## Requisitos

- [pokeget](https://crates.io/crates/pokeget) — `cargo install pokeget`
- `sshpass` — `apt install sshpass` (apenas para deploy remoto)
- `loginctl` (systemd)
- `pstree`, `write`
- `sudo` (necessário para encerrar sessões de outros processos)

## Instalação

```bash
git clone https://github.com/brafael1/Cynthia-SSH-killer.git
cd Cynthia-SSH-killer
chmod +x bin/*.sh lib/*.sh lib/cynthia/*.sh remote-exec.sh
```

## Uso

### Execução local

```bash
sudo ./bin/encerrar-sessoes-ssh.sh --ip 192.168.2.254
```

### Deploy e execução remota

```bash
./remote-exec.sh -H 192.168.2.18 -u 'usuario' -p 'senha' -e 192.168.2.254
```

| Parâmetro | Descrição |
|-----------|-----------|
| `-H, --host` | IP/hostname do host remoto |
| `-u, --user` | Usuário SSH |
| `-p, --pass` | Senha SSH |
| `-e, --ip-externo` | IP externo permitido |
| `-d, --dir` | Diretório temporário (padrão: /tmp) |

## Estrutura

```
Cynthia-SSH-killer/
├── remote-exec.sh              # Deploy remoto
├── bin/
│   └── encerrar-sessoes-ssh.sh # Entry point
└── lib/
    ├── core.sh                 # Gerenciamento de sessões
    ├── notify.sh               # Envio de mensagens via TTY
    └── cynthia/
        ├── aviso.sh            # Geração de avisos Pokemon
        └── equipe.sh           # Dados da equipe
```

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
