# zsh-starship-terminal-setup-wsl-ubuntu-Debian

Instalador reversível e portátil para configurar um terminal Zsh moderno em Ubuntu, Debian, WSL e servidores Linux compatíveis.

O projeto é inspirado no vídeo **The Perfect Zsh Setup For 2026**, mas tem escopo limitado à personalização do terminal. Ele não é um instalador completo de ambiente de desenvolvimento.

## Nome da pasta e do repositório

O nome definido para a pasta e para o repositório é:

```text
zsh-starship-terminal-setup-wsl-ubuntu-Debian
```

Use esse nome exatamente ao criar a pasta no WSL:

```bash
mkdir -p ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
```

E entre nela com:

```bash
cd ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
```

O nome é descritivo: informa que o projeto configura Zsh e Starship, é voltado ao terminal, prioriza WSL e atende Ubuntu/Debian. Embora tenha WSL no nome, os scripts poderão ser reaproveitados em servidores Linux compatíveis.

## O que este projeto faz

- Instala Zsh.
- Instala Git somente se estiver ausente e você autorizar.
- Configura `main` como branch padrão de novos repositórios.
- Configura Nano como editor do Git.
- Pergunta opcionalmente nome e e-mail do Git.
- Instala zoxide, fzf, ripgrep, fd, bat e Starship.
- Instala plugins do Zsh usando Git.
- Cria configuração modular em `~/.config/zsh/`.
- Cria aliases condicionais para Git, Docker, Podman, PostgreSQL e MariaDB quando esses comandos já existirem.
- Faz backup antes de alterar arquivos.
- Gera logs.
- Permite simulação com `--dry-run`.
- Permite restaurar configurações com `restore-terminal.sh`.

## O que este projeto não faz

- Não instala Docker ou Docker Engine.
- Não instala Docker Compose.
- Não instala Podman, Buildah ou Skopeo.
- Não instala PostgreSQL ou MariaDB.
- Não instala VS Code ou VS Code Server.
- Não instala fontes do Windows.
- Não remove pacotes, containers, imagens, volumes ou bancos.
- Não altera Docker Desktop.
- Não altera `/etc/wsl.conf`.
- Não configura tokens, senhas ou chaves SSH.
- Não cria aliases destrutivos.

## Estrutura

```text
zsh-starship-terminal-setup-wsl-ubuntu-Debian/
├── README-zsh-starship-terminal-setup-wsl-ubuntu-debian.md
├── guia-execucao-zsh-starship-terminal-setup-wsl-ubuntu-debian.md
├── install-terminal.sh
├── restore-terminal.sh
├── logs/
├── backups/
└── docs/
    └── planejamento-script-terminal-wsl.md
```

Os diretórios `logs/` e `backups/` podem ser criados automaticamente pelo instalador.

## Requisitos

- Ubuntu, Debian ou derivada compatível.
- Usuário comum com `sudo`, caso seja necessário instalar pacotes.
- Internet para baixar pacotes e plugins.
- Git instalado ou autorização para instalá-lo.

O script deve ser executado como usuário comum. Não use `sudo bash install-terminal.sh`.

## Onde colocar no WSL

Os artefatos baixados pela interface normalmente ficam no Windows, geralmente na pasta Downloads. Para executar o projeto corretamente no WSL, copie-o para o filesystem Linux da distribuição.

O local recomendado é:

```text
~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
```

Esse caminho corresponde a:

```text
/home/SEU_USUARIO_LINUX/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
```

`SEU_USUARIO_LINUX` é o nome da conta dentro do WSL. Você pode descobrir esse nome com:

```bash
whoami
```

Não copie literalmente `SEU_USUARIO_LINUX`; use o resultado mostrado pelo comando apenas para entender o caminho. No terminal, prefira `~`, pois ele já representa sua home.

## Copiar do Windows para o WSL

### 1. Descobrir o usuário do Windows

No PowerShell ou Prompt de Comando, execute:

```powershell
$env:USERNAME
```

O resultado será usado no lugar de `NOME_WINDOWS` nos exemplos abaixo. Não digite a palavra `NOME_WINDOWS` literalmente.

### 2. Confirmar a pasta de downloads

No WSL, verifique:

```bash
ls "/mnt/c/Users/NOME_WINDOWS/Downloads"
```

Substitua `NOME_WINDOWS` pelo usuário real mostrado no PowerShell. Se os arquivos estiverem em outra pasta, troque `Downloads` pelo nome dessa pasta.

Por exemplo, se o PowerShell mostrar `Ana`, o caminho será:

```text
/mnt/c/Users/Ana/Downloads
```

### 3. Criar a pasta definitiva no WSL

Dentro do WSL:

```bash
mkdir -p ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
```

### 4. Copiar os artefatos

Se os arquivos estiverem em Downloads:

```bash
cp -a \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/install-terminal.sh" \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/restore-terminal.sh" \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/README-zsh-starship-terminal-setup-wsl-ubuntu-debian.md" \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/guia-execucao-zsh-starship-terminal-setup-wsl-ubuntu-debian.md" \
  ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian/
```

Substitua `NOME_WINDOWS` pelo usuário real do Windows. Se algum arquivo tiver sido salvo em outra pasta, ajuste somente o caminho de origem.

Se preferir copiar todos os arquivos Markdown daquela pasta:

```bash
cp -a "/mnt/c/Users/NOME_WINDOWS/Downloads/"*.md \
  ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian/
```

Use esse segundo comando somente se a pasta não tiver outros Markdown que você não queira copiar.

### 5. Conferir a cópia

```bash
cd ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
ls -la
```

Você deverá encontrar pelo menos:

```text
install-terminal.sh
restore-terminal.sh
README-zsh-starship-terminal-setup-wsl-ubuntu-debian.md
guia-execucao-zsh-starship-terminal-setup-wsl-ubuntu-debian.md
```

## Por que não executar diretamente em `/mnt/c`

É possível executar scripts em `/mnt/c`, mas para projetos com Git, muitos arquivos pequenos, plugins e caches é preferível trabalhar em `~/projetos`, dentro do filesystem Linux do WSL. Isso reduz problemas de permissões, desempenho e diferenças entre os filesystems.

Use `/mnt/c` apenas como origem para copiar os arquivos baixados do Windows. Depois execute e mantenha o repositório em:

```text
~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
```

## Instalação

Entre na pasta:

```bash
cd ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
```

Dê permissão de execução:

```bash
chmod u+x install-terminal.sh restore-terminal.sh
```

Faça primeiro uma simulação:

```bash
./install-terminal.sh --dry-run
```

A simulação não deve instalar pacotes nem alterar arquivos de configuração.

Depois execute:

```bash
./install-terminal.sh
```

O script poderá perguntar:

- se deve instalar Git;
- se deve configurar `main` e Nano;
- se deve cadastrar nome e e-mail dos commits;
- se deve tornar Zsh o shell padrão.

## Git

Quando autorizado, o instalador configura:

```text
init.defaultBranch = main
core.editor = nano -w
sequence.editor = nano -w
```

Se você adiar a identidade:

```bash
git config --global user.name "SEU_NOME"
git config --global user.email "SEU_EMAIL"
```

Substitua `SEU_NOME` pelo nome que aparecerá nos commits e `SEU_EMAIL` por um e-mail apropriado. Não digite os placeholders literalmente.

## VS Code

O instalador não instala VS Code. Nano é o editor padrão universal.

Se o comando `code` já estiver disponível no WSL, você poderá escolher VS Code depois:

```bash
git config --global core.editor "code --wait"
git config --global sequence.editor "code --wait"
```

Para voltar ao Nano:

```bash
git config --global core.editor "nano -w"
git config --global sequence.editor "nano -w"
```

## Aliases opcionais

Aliases para Docker, Podman e bancos não instalam os programas. Eles somente aparecem quando os comandos correspondentes já existem.

Exemplos:

```text
dps       Docker: containers ativos
dpa       Docker: todos os containers
dctx      Docker: contextos
pps       Podman: containers ativos
ppa       Podman: todos os containers
pg-ready  PostgreSQL: disponibilidade
db-ping   MariaDB: disponibilidade
```

Não são criados aliases para limpeza, remoção, `DROP`, `TRUNCATE`, `DELETE`, `reset --hard`, `push --force` ou `prune`.

## Arquivos gerados

A configuração será criada em:

```text
~/.zshenv
~/.config/zsh/.zshrc
~/.config/zsh/aliases.zsh
~/.config/zsh/containers.zsh
~/.config/zsh/database.zsh
~/.config/zsh/fzf.zsh
~/.config/zsh/git.zsh
~/.config/zsh/plugins.zsh
~/.config/zsh/prompt.zsh
~/.config/zsh/starship.toml
```

## Backups e logs

Backups:

```text
~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian/backups/AAAA-MM-DD_HHMMSS/
```

Logs:

```text
~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian/logs/install-terminal-AAAA-MM-DD_HHMMSS.log
```

Não compartilhe logs publicamente sem verificar se há caminhos pessoais ou informações sensíveis.

## Restauração

Para restaurar uma configuração:

```bash
cd ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
./restore-terminal.sh
```

O restaurador lista os backups, pede confirmação e cria uma cópia da configuração atual antes de restaurar. Ele não remove pacotes nem altera containers, bancos ou o shell padrão.

## Após a instalação

Abra uma nova sessão ou execute:

```bash
exec zsh
```

Teste:

```bash
command -v zsh starship zoxide fzf rg fd git
zsh -n ~/.zshenv ~/.config/zsh/*.zsh
git config --global --get init.defaultBranch
git config --global --get core.editor
```

## Nerd Font

Ícones do eza e do Starship dependem de uma Nerd Font configurada no Windows Terminal ou no emulador gráfico. A fonte não é instalada pelo Bash dentro do WSL.

Sem Nerd Font, Zsh e as ferramentas continuam funcionando; apenas alguns ícones podem aparecer incorretamente.
