#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_NAME='zsh-starship-terminal-setup-wsl-ubuntu-Debian'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"
LOG_FILE="$LOG_DIR/install-terminal-$TIMESTAMP.log"
DRY_RUN=0
SKIP_GIT=0
ASSUME_YES=0

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[AVISO] %s\n' "$*" >&2; }
die() { printf '[ERRO] %s\n' "$*" >&2; exit 1; }

on_error() {
    local code=$?
    printf '[ERRO] Falha na linha %s (código %s). Log: %s\n' \
        "$1" "$code" "$LOG_FILE" >&2
    exit "$code"
}
trap 'on_error "$LINENO"' ERR

usage() {
    cat <<'EOF'
Uso: ./install-terminal.sh [opções]

  --dry-run    diagnostica e mostra ações, sem alterar o sistema
  --skip-git   não instala nem configura Git
  --yes        aceita confirmações com padrão positivo
  --help       mostra esta ajuda
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --skip-git) SKIP_GIT=1 ;;
        --yes) ASSUME_YES=1 ;;
        --help|-h) usage; exit 0 ;;
        *) die "Opção desconhecida: $1" ;;
    esac
    shift
done

[[ "$(id -u)" -ne 0 ]] || die 'Execute como usuário comum; não use sudo bash.'

ask_yes_no() {
    local question="$1" default="${2:-N}" answer=''
    if ((ASSUME_YES)); then
        [[ "$default" == S ]]
        return
    fi
    if [[ "$default" == S ]]; then
        read -r -p "$question [S/n] " answer || true
        answer="${answer:-S}"
    else
        read -r -p "$question [s/N] " answer || true
        answer="${answer:-N}"
    fi
    [[ "$answer" =~ ^[SsYy]$ ]]
}

run() {
    if ((DRY_RUN)); then
        printf '[SIMULAÇÃO]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

is_debian_family() {
    [[ -r /etc/os-release ]] || return 1
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID:-}" == ubuntu || "${ID:-}" == debian || "${ID_LIKE:-}" == *debian* ]]
}

show_diagnostics() {
    local pretty='desconhecida'
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        pretty="${PRETTY_NAME:-$pretty}"
    fi
    info "Projeto: $PROJECT_NAME"
    info "Data: $(date --iso-8601=seconds)"
    info "Usuário: $(id -un) (UID $(id -u))"
    info "Distribuição: $pretty"
    info "Kernel: $(uname -srmo)"
    if grep -qi microsoft /proc/version 2>/dev/null; then
        info 'Ambiente: WSL detectado'
    else
        info 'Ambiente: Linux não identificado como WSL'
    fi
    for command_name in git zsh curl wget gpg fzf rg fd fdfind bat batcat eza zoxide starship docker podman psql mariadb code; do
        if has_cmd "$command_name"; then
            info "$command_name: $(command -v "$command_name")"
        else
            info "$command_name: ausente"
        fi
    done
}

install_git_if_needed() {
    ((SKIP_GIT)) && { warn 'Git ignorado por --skip-git.'; return; }
    has_cmd git && { info 'Git já está instalado.'; return; }
    ask_yes_no 'Git não foi encontrado. Deseja instalar git agora?' S || {
        warn 'Git não instalado; plugins não serão baixados.'
        return
    }
    is_debian_family || {
        warn 'Distribuição não reconhecida como Ubuntu/Debian; Git não instalado.'
        return
    }
    run sudo apt-get update
    run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y git
}

valid_email() {
    [[ "$1" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]
}

configure_git() {
    ((SKIP_GIT)) && return
    has_cmd git || { warn 'Git ausente; configuração ignorada.'; return; }
    ask_yes_no 'Configurar branch padrão main e Nano como editor do Git?' S || {
        warn 'Configuração Git ignorada.'
        return
    }
    if ((DRY_RUN)); then
        info '[SIMULAÇÃO] Configuraria init.defaultBranch=main e editor=nano -w.'
    else
        git config --global init.defaultBranch main
        git config --global core.editor 'nano -w'
        git config --global sequence.editor 'nano -w'
    fi

    local existing_name existing_email git_name git_email
    existing_name="$(git config --global user.name 2>/dev/null || true)"
    existing_email="$(git config --global user.email 2>/dev/null || true)"
    if [[ -n "$existing_name" || -n "$existing_email" ]]; then
        info "Nome atual do Git: ${existing_name:-não configurado}"
        if [[ -n "$existing_email" ]]; then
            info 'E-mail atual do Git: configurado (não será exibido no log)'
        else
            info 'E-mail atual do Git: não configurado'
        fi
    fi

    ask_yes_no 'Deseja informar ou atualizar agora o nome e o e-mail dos commits?' S || {
        info 'Identidade Git atual preservada.'
        return
    }
    while :; do
        read -r -p 'Nome para os commits: ' git_name
        [[ -n "$git_name" ]] && break
        warn 'O nome não pode ficar vazio.'
    done
    while :; do
        read -r -p 'E-mail para os commits: ' git_email
        if valid_email "$git_email"; then
            break
        fi
        warn 'Formato de e-mail inválido. Digite somente algo como nome@dominio.com.'
    done
    if ((DRY_RUN)); then
        info "[SIMULAÇÃO] Configuraria o nome informado e o e-mail $git_email (não gravado)."
    else
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        info 'Nome e e-mail do Git configurados; o e-mail não será escrito no log.'
    fi
}

install_packages() {
    is_debian_family || die 'Este instalador suporta atualmente Ubuntu/Debian e derivados.'
    local packages=(zsh nano curl wget gpg ca-certificates unzip fzf ripgrep fd-find bat)
    run sudo apt-get update
    run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
}

install_zoxide() {
    has_cmd zoxide && { info 'zoxide já está instalado.'; return; }
    ask_yes_no 'Instalar zoxide?' S || return
    if ((DRY_RUN)); then
        info '[SIMULAÇÃO] Baixaria e executaria o instalador oficial do zoxide.'
        return
    fi
    mkdir -p "$HOME/.cache"
    local installer="$HOME/.cache/zoxide-install-$TIMESTAMP.sh"
    curl -fsSL \
        https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
        -o "$installer"
    sh "$installer"
    rm -f "$installer"
}

install_starship() {
    has_cmd starship && { info 'Starship já está instalado.'; return; }
    ask_yes_no 'Instalar Starship?' S || return
    if ((DRY_RUN)); then
        info '[SIMULAÇÃO] Baixaria e executaria o instalador oficial do Starship.'
        return
    fi
    mkdir -p "$HOME/.cache"
    local installer="$HOME/.cache/starship-install-$TIMESTAMP.sh"
    curl -fsSL \
        https://starship.rs/install.sh \
        -o "$installer"
    sh "$installer" -y
    rm -f "$installer"
}

install_eza_if_available() {
    has_cmd eza && { info 'eza já está instalado.'; return; }
    warn 'eza não foi instalado automaticamente nesta versão; aliases usarão ls como fallback.'
}

create_links() {
    if ((DRY_RUN)); then
        info '[SIMULAÇÃO] Verificaria aliases bat e fd em ~/.local/bin.'
        return
    fi
    mkdir -p "$HOME/.local/bin"
    if has_cmd batcat && [[ ! -e "$HOME/.local/bin/bat" && ! -L "$HOME/.local/bin/bat" ]]; then
        ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
    if has_cmd fdfind && [[ ! -e "$HOME/.local/bin/fd" && ! -L "$HOME/.local/bin/fd" ]]; then
        ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
}

install_plugins() {
    local plugin_dir="$HOME/.config/zsh/plugins"
    local repositories=(
        zsh-users/zsh-autosuggestions
        zdharma-continuum/fast-syntax-highlighting
        zsh-users/zsh-history-substring-search
        jeffreytse/zsh-vi-mode
    )
    mkdir -p "$plugin_dir"
    local repository name target
    for repository in "${repositories[@]}"; do
        name="${repository##*/}"
        target="$plugin_dir/$name"
        if [[ -d "$target/.git" ]]; then
            info "Plugin já existe: $name"
        elif ! has_cmd git; then
            warn "Git ausente; plugin não instalado: $repository"
        elif ((DRY_RUN)); then
            info "[SIMULAÇÃO] Clonaria $repository em $target"
        else
            git clone --quiet --depth=1 "https://github.com/$repository.git" "$target"
        fi
    done
}

write_zsh_files() {
    local zdotdir="$HOME/.config/zsh"
    if ((DRY_RUN)); then
        info "[SIMULAÇÃO] Criaria configuração em $zdotdir"
        return
    fi
    mkdir -p "$zdotdir/plugins" "$HOME/.local/state/zsh" "$HOME/.cache/zsh" "$HOME/.local/bin"
    cat > "$HOME/.zshenv" <<'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$ZDOTDIR/starship.toml}"
EOF
    cat > "$zdotdir/.zshrc" <<'EOF'
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_EXPIRE_DUPS_FIRST AUTO_CD NO_BEEP

autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

for file in aliases git containers database fzf plugins bindings prompt; do
    [[ -r "$ZDOTDIR/$file.zsh" ]] && source "$ZDOTDIR/$file.zsh"
done

if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
fi
EOF
    cat > "$zdotdir/aliases.zsh" <<'EOF'
if (( $+commands[eza] )); then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza --icons --group-directories-first -lh'
    alias la='eza --icons --group-directories-first -la'
    alias tree='eza --icons --tree'
else
    alias ll='ls -lh'
    alias la='ls -la'
fi
(( $+commands[bat] )) && alias cat='bat'
(( $+commands[fd] )) && alias ff='fd'
(( $+commands[rg] )) && alias rgg='rg'
alias ..='cd ..'
alias ...='cd ../..'
EOF
    cat > "$zdotdir/git.zsh" <<'EOF'
if (( $+commands[git] )); then
    alias gs='git status --short --branch'
    alias gl='git log --oneline --decorate --graph -15'
    alias gd='git diff'
    alias gds='git diff --staged'
    alias gb='git branch --all'
    alias gf='git fetch --all --prune'
    alias gp='git pull --ff-only'
    alias gps='git push'
    alias gr='git remote -v'
    alias gst='git stash'
    alias gstp='git stash pop'
fi
EOF
    cat > "$zdotdir/containers.zsh" <<'EOF'
if (( $+commands[docker] )); then
    alias dps='docker ps'
    alias dpa='docker ps -a'
    alias dtop='docker stats'
    alias di='docker image ls'
    alias dvol='docker volume ls'
    alias dnet='docker network ls'
    alias dctx='docker context ls'
    alias dinfo='docker info'
    alias ddf='docker system df'
    dlogs() { docker logs --follow --tail=100 "$@"; }
    dex() { docker exec -it "$1" sh; }
    if docker compose version >/dev/null 2>&1; then
        alias dc='docker compose'
        alias dcps='docker compose ps'
        alias dclogs='docker compose logs -f'
        alias dcup='docker compose up -d'
    fi
fi
if (( $+commands[podman] )); then
    alias pps='podman ps'
    alias ppa='podman ps -a'
    alias pitop='podman stats'
    alias pi='podman images'
    alias pvol='podman volume ls'
    alias pnet='podman network ls'
    alias pinfo='podman info'
    alias pdf='podman system df'
    pex() { podman exec -it "$1" sh; }
    if podman compose version >/dev/null 2>&1; then
        alias pc='podman compose'
        alias pcps='podman compose ps'
        alias pclogs='podman compose logs -f'
        alias pcup='podman compose up -d'
    fi
fi
EOF
    cat > "$zdotdir/database.zsh" <<'EOF'
if (( $+commands[psql] )); then
    alias pg-version='psql --version'
    alias pg-conn='psql -c "\\conninfo"'
    pgc() { psql "${1:-postgres}"; }
    pgl() { psql -l; }
    pg-tables() { psql "${1:-postgres}" -c '\dt'; }
    pg-schemas() { psql "${1:-postgres}" -c '\dn'; }
    pg-users() { psql "${1:-postgres}" -c '\du'; }
fi
if (( $+commands[pg_isready] )); then alias pg-ready='pg_isready'; fi
if (( $+commands[mariadb] )); then
    alias db-version='mariadb --version'
    mdb() { if [[ -n "$1" ]]; then mariadb "$1"; else mariadb; fi; }
    mdb-databases() { mariadb -e 'SHOW DATABASES;'; }
    mdb-tables() { local database="${1:?Informe o banco}"; mariadb "$database" -e 'SHOW TABLES;'; }
    mdb-status() { mariadb -e 'SHOW STATUS;'; }
    mdb-processes() { mariadb -e 'SHOW FULL PROCESSLIST;'; }
fi
if (( $+commands[mariadb-admin] )); then alias db-ping='mariadb-admin ping'; fi
EOF
    cat > "$zdotdir/fzf.zsh" <<'EOF'
if (( $+commands[fzf] )); then
    if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh)
    elif [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        [[ -r /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
    fi
    export FZF_DEFAULT_OPTS='--layout=reverse --inline-info --height=50% --border'
fi
EOF
    cat > "$zdotdir/plugins.zsh" <<'EOF'
PLUGIN_DIR="$ZDOTDIR/plugins"
load_plugin() {
    local repo="$1" name="${1##*/}" target="$PLUGIN_DIR/${1##*/}"
    [[ -d "$target" ]] || return 0
    if [[ -f "$target/$name.plugin.zsh" ]]; then
        source "$target/$name.plugin.zsh"
    elif [[ -f "$target/$name.zsh" ]]; then
        source "$target/$name.zsh"
    fi
}
load_plugin zsh-users/zsh-autosuggestions
load_plugin zdharma-continuum/fast-syntax-highlighting
load_plugin zsh-users/zsh-history-substring-search
load_plugin jeffreytse/zsh-vi-mode
EOF
    cat > "$zdotdir/bindings.zsh" <<'EOF'
zvm_config() {
    ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
    ZVM_VI_INSERT_ESCAPE_BINDKEY='jk'
}
EOF
    cat > "$zdotdir/prompt.zsh" <<'EOF'
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi
EOF
    cat > "$zdotdir/starship.toml" <<'EOF'
add_newline = false
command_timeout = 1000
[docker_context]
disabled = false
format = 'via [$symbol$context]($style) '
[git_branch]
symbol = ' '
[git_status]
disabled = false
EOF
}

validate() {
    ((DRY_RUN)) && {
        info '[SIMULAÇÃO] Validação omitida porque os arquivos não foram escritos.'
        return
    }
    bash -n "${BASH_SOURCE[0]}"
    if has_cmd zsh; then
        zsh -n "$HOME/.zshenv" "$HOME/.config/zsh/.zshrc" "$HOME/.config/zsh/"*.zsh
    fi
    [[ -r "$HOME/.config/zsh/bindings.zsh" ]] || die 'bindings.zsh não foi criado.'
    grep -q 'bindings' "$HOME/.config/zsh/.zshrc" || die 'bindings não está sendo carregado pelo .zshrc.'
    info 'Validação de sintaxe e bindings concluída.'
}

activate_zsh() {
    has_cmd zsh || {
        warn 'Zsh ausente; shell padrão preservado.'
        return
    }
    ask_yes_no 'Deseja tornar Zsh o shell padrão para este usuário?' N || {
        info 'Shell padrão preservado.'
        return
    }
    if ((DRY_RUN)); then
        info "[SIMULAÇÃO] Executaria chsh -s $(command -v zsh)"
    else
        chsh -s "$(command -v zsh)"
        info 'Zsh configurado como shell padrão; abra uma nova sessão.'
    fi
}

main() {
    info "Iniciando $PROJECT_NAME"
    show_diagnostics
    ((DRY_RUN)) && warn 'Modo simulação: nenhuma alteração será realizada.'
    install_git_if_needed
    configure_git
    install_packages
    install_eza_if_available
    install_zoxide
    install_starship
    create_links
    install_plugins
    write_zsh_files
    validate
    activate_zsh
    info "Concluído. Log: $LOG_FILE"
}

main "$@"
