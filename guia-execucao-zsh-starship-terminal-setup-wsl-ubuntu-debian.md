# Guia de Execução

Este guia mostra como copiar o projeto baixado no Windows para o filesystem Linux do WSL e executar a instalação de Zsh, Starship e ferramentas de terminal.

> **Importante:** substitua todos os placeholders pelos valores reais. Nos exemplos, `conta` é apenas um nome fictício de usuário do Windows.

## 1. Baixe os artefatos

Baixe pelo Windows os seguintes arquivos:

```text
install-terminal.sh
snapshot-terminal.sh
restore-terminal.sh
README-zsh-starship-terminal-setup-wsl-ubuntu-debian.md
guia-execucao-zsh-starship-terminal-setup-wsl-ubuntu-debian.md
```

O nome esperado da pasta do projeto é:

```text
zsh-starship-terminal-setup-wsl-ubuntu-Debian
```

O navegador pode salvar os arquivos diretamente em `Downloads` ou dentro dessa pasta de projeto.

## 2. Confirme o WSL

Abra o PowerShell e execute:

```powershell
wsl --list --verbose
```

Confirme o nome da distribuição que será usada. Depois abra essa distribuição, por exemplo pelo Windows Terminal.

> Se você estiver usando Linux sem WSL, pule as seções específicas do Windows e use diretamente uma pasta dentro de `~/projetos`.

## 3. Descubra os usuários

### Usuário do Windows

No PowerShell:

```powershell
$env:USERNAME
```

Anote o resultado. Neste guia, ele será representado por `NOME_WINDOWS`.

Se o resultado for `conta`, os caminhos usados nos exemplos serão:

```text
C:\Users\conta\Downloads
/mnt/c/Users/conta/Downloads
```

Não digite `NOME_WINDOWS` literalmente. Substitua-o pelo resultado real.

### Usuário do Linux/WSL

No Ubuntu/Debian:

```bash
whoami
```

O resultado será representado por `SEU_USUARIO_LINUX`. Como os comandos usam `~`, normalmente você não precisa escrever esse nome.

## 4. Localize os arquivos no Windows

Dentro do WSL, liste a pasta Downloads:

```bash
ls -la "/mnt/c/Users/NOME_WINDOWS/Downloads"
```

Se existir uma pasta do projeto, liste seu conteúdo:

```bash
find \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/zsh-starship-terminal-setup-wsl-ubuntu-Debian" \
  -maxdepth 2 \
  -type f \
  -printf '%P\n'
```

Exemplo com o usuário Windows `conta`:

```bash
find \
  "/mnt/c/Users/conta/Downloads/zsh-starship-terminal-setup-wsl-ubuntu-Debian" \
  -maxdepth 2 \
  -type f \
  -printf '%P\n'
```

Se os arquivos não estiverem nessa pasta, verifique se o navegador criou outra subpasta dentro de `Downloads`.

## 5. Copie o projeto para o WSL

O projeto deve ser executado no filesystem Linux do WSL, não diretamente em `/mnt/c`. Isso normalmente oferece melhor desempenho para Git, scripts, plugins, caches e operações com muitos arquivos. [web:75][web:238]

Crie o destino:

```bash
mkdir -p ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
```

Se os arquivos estiverem dentro da pasta do projeto em Downloads:

```bash
cp -a \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/zsh-starship-terminal-setup-wsl-ubuntu-Debian/." \
  ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian/
```

Exemplo com `conta`:

```bash
cp -a \
  "/mnt/c/Users/conta/Downloads/zsh-starship-terminal-setup-wsl-ubuntu-Debian/." \
  ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian/
```

O uso de `/.` copia também arquivos ocultos, caso existam, e evita problemas com uma pasta de destino duplicada.

### Se os arquivos estiverem diretamente em Downloads

Use este método somente se os arquivos estiverem diretamente em `Downloads`:

```bash
cp -a \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/." \
  ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian/
```

Se houver outros arquivos na pasta Downloads, prefira copiar apenas os artefatos do projeto:

```bash
cp -a \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/install-terminal.sh" \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/snapshot-terminal.sh" \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/restore-terminal.sh" \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/README-zsh-starship-terminal-setup-wsl-ubuntu-debian.md" \
  "/mnt/c/Users/NOME_WINDOWS/Downloads/guia-execucao-zsh-starship-terminal-setup-wsl-ubuntu-debian.md" \
  ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian/
```

## 6. Confira o conteúdo copiado

```bash
cd ~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian
ls -la
```

Confira os arquivos principais:

```bash
for file in \
  install-terminal.sh \
  snapshot-terminal.sh \
  restore-terminal.sh \
  README-zsh-starship-terminal-setup-wsl-ubuntu-debian.md \
  guia-execucao-zsh-starship-terminal-setup-wsl-ubuntu-debian.md
 do
  [[ -f "$file" ]] && printf '[OK] %s\n' "$file" || printf '[AUSENTE] %s\n' "$file"
done
```

## 7. Verifique o conteúdo dos scripts

Antes de executar scripts copiados do Windows, confira se eles não contêm links Markdown dentro de comandos Bash:

```bash
grep -nE '\[[^]]+\]\(https?://' \
  install-terminal.sh snapshot-terminal.sh restore-terminal.sh || true
```

O resultado esperado é vazio.

Também confira se os arquivos não têm finais de linha do Windows:

```bash
file install-terminal.sh snapshot-terminal.sh restore-terminal.sh
```

Se algum arquivo aparecer como `CRLF`, corrija com:

```bash
sed -i 's/\r$//' \
  install-terminal.sh snapshot-terminal.sh restore-terminal.sh
```

## 8. Dê permissão de execução

```bash
chmod u+x install-terminal.sh snapshot-terminal.sh restore-terminal.sh
```

Confira:

```bash
ls -l *.sh
```

Também é possível testar sem alterar permissões usando `bash` diretamente:

```bash
bash install-terminal.sh --dry-run
```

## 9. Valide a sintaxe

```bash
bash -n install-terminal.sh
bash -n snapshot-terminal.sh
bash -n restore-terminal.sh
```

Se algum comando apresentar erro, não prossiga. Corrija ou copie novamente o arquivo correspondente.

## 10. Execute a simulação

```bash
./install-terminal.sh --dry-run
```

A simulação mostra as ações sem instalar pacotes, criar configurações ou clonar plugins. As ações simuladas devem aparecer com `[SIMULAÇÃO]`.

O instalador pode fazer perguntas durante a simulação. Isso é esperado.

## 11. Execute a instalação

Execute como usuário comum:

```bash
./install-terminal.sh
```

Não use:

```bash
sudo bash install-terminal.sh
```

Durante a execução, o instalador poderá:

- instalar Zsh, Nano, curl, wget, GPG, unzip, fzf, ripgrep, fd-find e bat;
- instalar e configurar Git, se confirmado;
- perguntar se deseja instalar zoxide;
- perguntar se deseja instalar Starship;
- baixar os plugins do Zsh;
- criar a configuração em `~/.config/zsh`;
- validar a sintaxe dos arquivos;
- perguntar se o Zsh deve ser o shell padrão.

O eza não é instalado automaticamente pelo instalador. Ele é tratado na seção 13.1.

O instalador grava logs em:

```text
logs/install-terminal-AAAA-MM-DD_HHMMSS.log
```

## 12. Abra uma nova sessão Zsh

Se você confirmou o Zsh como shell padrão, feche e abra novamente a distribuição WSL.

Para iniciar o Zsh imediatamente:

```bash
exec zsh
```

Confirme:

```bash
command -v zsh
printf 'Shell configurado: %s\n' "$SHELL"
```

## 13. Atenção ao diretório inicial no WSL

O WSL pode iniciar na pasta pessoal do Linux ou herdar a pasta em que o Windows Terminal foi aberto. Por isso, é normal começar em um caminho do Windows, como:

```text
/mnt/c/Users/conta
```

Isso pode acontecer quando o terminal é aberto pelo Explorador de Arquivos, por uma pasta do Windows ou por um perfil cuja pasta inicial aponta para o Windows.

Nessa situação, o Starship pode exibir:

```text
[WARN] - (starship::context): Scanning current directory timed out.
```

Esse aviso não indica falha na instalação. Significa que a leitura da pasta atual demorou mais que o limite configurado. O Starship interrompe a varredura para manter o prompt responsivo. [web:559]

Você pode continuar normalmente ou acessar a pasta pessoal do Linux:

```bash
cd ~
```

Arquivos em `/mnt/c` continuam acessíveis pelo WSL. Porém, para projetos usados principalmente por ferramentas Linux, a pasta `~/` costuma oferecer melhor desempenho. [web:75][web:238]

Não é necessário mudar o diretório inicial padrão só por causa desse aviso. Se você usa frequentemente pastas do Windows, pode continuar trabalhando nelas.

## 14. Validação básica

```bash
command -v zsh starship zoxide fzf rg fd git
```

Confira a configuração:

```bash
printf 'ZDOTDIR=%s\n' "${ZDOTDIR:-não definido nesta sessão}"
ls -la ~/.config/zsh
```

Teste os aliases:

```bash
ll
la
ff
rgg
```

Sem eza, `ll` e `la` usam o `ls` como fallback.

Confira o Starship:

```bash
starship --version
ls -l ~/.config/zsh/starship.toml
```

## 15. Instalações opcionais

As opções desta seção não são necessárias para o funcionamento básico do Zsh e do Starship.

### 15.1. eza e Nerd Font

#### 15.1.1. Instalar eza no Ubuntu/Debian

O eza oferece uma listagem de arquivos com ícones e visualização em árvore. Esta etapa adiciona o repositório externo `deb.gierens.de` ao APT. Execute-a somente se você concordar com essa alteração.

Antes, confira se o eza já está disponível:

```bash
command -v eza && eza --version
```

Se ele ainda não estiver instalado, execute o bloco abaixo dentro do Ubuntu/Debian, como usuário comum:

```bash
bash <<'EOF'
set -Eeuo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT

curl -fsSL \
  https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
  -o "$tmpdir/deb.asc"

gpg --dearmor \
  -o "$tmpdir/gierens.gpg" \
  "$tmpdir/deb.asc"

sudo install -d -m 0755 /etc/apt/keyrings
sudo install -m 0644 \
  "$tmpdir/gierens.gpg" \
  /etc/apt/keyrings/gierens.gpg

printf '%s\n' \
  'deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main' |
  sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null

sudo chmod 0644 \
  /etc/apt/keyrings/gierens.gpg \
  /etc/apt/sources.list.d/gierens.list

sudo apt-get update
sudo apt-get install -y eza
EOF
```

Se `/etc/apt/sources.list.d/gierens.list` ou `/etc/apt/keyrings/gierens.gpg` já existirem por uma instalação anterior, confira o conteúdo antes de repetir o bloco. Ele substitui esses dois arquivos.

Verifique:

```bash
command -v eza
eza --version
```

Abra uma nova sessão Zsh:

```bash
exec zsh
```

Teste:

```bash
ls
ll
la
tree
```

O eza é opcional. Se você não quiser adicionar o repositório externo, continue usando os aliases com `ls`.

#### 15.1.2. Fonte para os ícones

A Nerd Font não é obrigatória. Se os ícones do comando `tree` já aparecem corretamente, você pode pular esta etapa.

Se os ícones aparecerem como quadrados ou símbolos incorretos, a fonte recomendada é:

```text
JetBrainsMono Nerd Font Mono
```

A variante `Mono` é adequada ao alinhamento de caracteres no terminal.

A fonte deve ser instalada no sistema que desenha a janela do terminal:

- no Windows Terminal, no Windows;
- em um terminal gráfico Linux, no Linux;
- em uma conexão SSH, no computador local que exibe o terminal.

##### Windows Terminal

No Windows:

1. Baixe a família JetBrainsMono na página oficial do Nerd Fonts: <https://www.nerdfonts.com/font-downloads>.
2. Extraia o arquivo.
3. Instale no Windows a variante `Nerd Font Mono`.
4. Abra as configurações do Windows Terminal.
5. Selecione o perfil da distribuição WSL.
6. Abra **Aparência**.
7. Escolha `JetBrainsMono Nerd Font Mono`.
8. Abra uma nova janela e teste `tree`.

No caso de Ubuntu/WSL dentro do Windows Terminal, a opção correta é instalar a fonte no Windows e selecioná-la no perfil do Windows Terminal. Não é necessário instalar a fonte dentro do Ubuntu WSL.

##### Linux pelo terminal

Use esta opção quando o terminal gráfico estiver rodando no próprio Linux:

```bash
set -Eeuo pipefail

command -v fc-cache >/dev/null 2>&1 || {
  sudo apt-get update
  sudo apt-get install -y fontconfig unzip curl
}

font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT

mkdir -p "$font_dir"

curl -fsSL \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
  -o "$tmp_dir/JetBrainsMono.zip"

unzip -q -o \
  "$tmp_dir/JetBrainsMono.zip" \
  -d "$font_dir"

find "$font_dir" \
  -type f \
  \( -iname '*.ttf' -o -iname '*.otf' \) \
  -exec chmod 644 {} \;

fc-cache -f "$HOME/.local/share/fonts"
```

Confirme:

```bash
fc-list | grep -i 'JetBrainsMono Nerd Font' | head
```

Depois selecione `JetBrainsMono Nerd Font Mono` nas configurações do terminal gráfico Linux e abra uma nova sessão.

##### Servidor SSH

Em uma sessão SSH, a janela pertence normalmente ao computador local. Não é necessário instalar a fonte no servidor remoto: instale-a no computador que exibe a sessão SSH.

## 16. Plugins

Os plugins ficam em:

```text
~/.config/zsh/plugins/
```

Confira:

```bash
find ~/.config/zsh/plugins -maxdepth 2 -type d -print
```

## 17. Primeiro snapshot

Depois de concluir a instalação e configurar os opcionais desejados, crie a foto inicial do terminal:

```bash
./snapshot-terminal.sh
```

Quando solicitado, use:

```text
instalacao-inicial
```

O snapshot será salvo em uma pasta semelhante a:

```text
snapshots/2026-09-25_150000-instalacao-inicial/
```

## 18. Sobre snapshots

Os snapshots permitem salvar vários pontos da configuração do terminal com nomes escolhidos pelo usuário.

```text
snapshot-terminal.sh → cria snapshots nomeados
restore-terminal.sh  → restaura o snapshot escolhido
```

Eles ficam em:

```text
~/projetos/zsh-starship-terminal-setup-wsl-ubuntu-Debian/snapshots/
```

O snapshot registra configurações pessoais do Zsh e Starship, plugins, links locais, inventário de comandos, versões e lista de pacotes. Ele não é uma exportação completa do WSL e não inclui a Nerd Font instalada no Windows.

O `restore-terminal.sh` cria automaticamente uma foto do estado atual antes de restaurar. A restauração altera apenas arquivos de configuração e componentes pessoais registrados no snapshot; não desinstala pacotes, não reinstala programas, não altera o shell padrão e não modifica o Windows Terminal.

Como os snapshots podem conter informações pessoais, revise-os antes de publicar ou versionar. Não armazene senhas, tokens, chaves privadas ou outros segredos nessas fotos.

Para aprofundar a estrutura, as limitações e as boas práticas dos snapshots, consulte o **Guia de snapshots**, que será elaborado separadamente.

## 19. Fluxo resumido

```text
1. Baixar os artefatos no Windows.
2. Descobrir o usuário do Windows e o usuário Linux.
3. Copiar o projeto de Downloads para ~/projetos no WSL.
4. Conferir os arquivos e remover CRLF, se necessário.
5. Aplicar permissões de execução.
6. Validar a sintaxe.
7. Executar install-terminal.sh --dry-run.
8. Executar install-terminal.sh.
9. Abrir uma nova sessão Zsh.
10. Validar comandos e aliases.
11. Instalar eza, se desejado.
12. Configurar a Nerd Font, se necessário.
13. Criar o snapshot instalacao-inicial.
```
