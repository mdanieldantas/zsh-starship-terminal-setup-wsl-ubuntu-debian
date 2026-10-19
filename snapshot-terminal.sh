#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SNAPSHOT_DIR="$SCRIPT_DIR/snapshots"
DEFAULT_NAME='instalacao-inicial'

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[AVISO] %s\n' "$*" >&2; }
die() { printf '[ERRO] %s\n' "$*" >&2; exit 1; }

on_error() {
  local code=$?
  printf '[ERRO] Falha na linha %s (código %s).\n' "$1" "$code" >&2
  exit "$code"
}
trap 'on_error "$LINENO"' ERR

[[ "$(id -u)" -ne 0 ]] || die 'Execute como usuário comum; não use sudo bash.'

command -v date >/dev/null 2>&1 || die 'Comando date não encontrado.'
command -v cp >/dev/null 2>&1 || die 'Comando cp não encontrado.'

normalize_name() {
  local value="$1"
  value="${value,,}"
  value="$(printf '%s' "$value" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || printf '%s' "$value")"
  value="$(printf '%s' "$value" | sed -E 's/[^a-z0-9_-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
  printf '%s' "$value"
}

mkdir -p "$SNAPSHOT_DIR"

printf 'Criando snapshot do terminal.\n\n'
read -r -p "Nome do snapshot [$DEFAULT_NAME]: " requested_name
requested_name="${requested_name:-$DEFAULT_NAME}"
snapshot_name="$(normalize_name "$requested_name")"
[[ -n "$snapshot_name" ]] || die 'O nome informado não contém caracteres válidos.'
[[ "$snapshot_name" != '.' && "$snapshot_name" != '..' ]] || die 'Nome inválido.'

stamp="$(date +%Y-%m-%d_%H%M%S)"
snapshot_path="$SNAPSHOT_DIR/$stamp-$snapshot_name"
[[ ! -e "$snapshot_path" ]] || die "O snapshot já existe: $snapshot_path"

printf '\nSnapshot:\n'
printf '  Nome: %s\n' "$snapshot_name"
printf '  Diretório: %s\n\n' "$snapshot_path"
read -r -p 'Criar este snapshot? [S/n] ' confirmation
[[ -z "$confirmation" || "$confirmation" =~ ^[sSyY]$ ]] || { info 'Criação cancelada.'; exit 0; }

config_dir="$snapshot_path/config"
mkdir -p "$config_dir"

copy_if_exists() {
  local source="$1"
  local relative="${source#"$HOME/"}"
  if [[ -e "$source" || -L "$source" ]]; then
    mkdir -p "$config_dir/$(dirname -- "$relative")"
    cp -a -- "$source" "$config_dir/$relative"
  fi
}

copy_if_exists "$HOME/.zshenv"
copy_if_exists "$HOME/.zshrc"
copy_if_exists "$HOME/.zprofile"
copy_if_exists "$HOME/.zlogin"
copy_if_exists "$HOME/.zlogout"
copy_if_exists "$HOME/.config/zsh"
copy_if_exists "$HOME/.config/starship.toml"
copy_if_exists "$HOME/.local/bin/bat"
copy_if_exists "$HOME/.local/bin/fd"

if command -v dpkg-query >/dev/null 2>&1; then
  dpkg-query -W -f='${binary:Package}\t${Version}\n' 2>/dev/null \
    | sort > "$snapshot_path/packages.txt"
else
  printf '%s\n' 'dpkg-query não disponível.' > "$snapshot_path/packages.txt"
fi

{
  printf '%s\n' '# Inventário de comandos do snapshot'
  printf 'Data: %s\n' "$(date --iso-8601=seconds)"
  printf 'Usuário: %s\n' "$(id -un)"
  printf 'HOME: %s\n' "$HOME"
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    printf 'Distribuição: %s\n' "${PRETTY_NAME:-desconhecida}"
  fi
  printf 'Kernel: %s\n' "$(uname -srmo)"
  printf '\n'
  for command_name in zsh starship zoxide fzf rg fd fdfind bat batcat eza git; do
    if command -v "$command_name" >/dev/null 2>&1; then
      printf '%-10s %s\n' "$command_name" "$(command -v "$command_name")"
      "$command_name" --version 2>/dev/null | head -n 1 | sed 's/^/  /' || true
    else
      printf '%-10s ausente\n' "$command_name"
    fi
  done
  printf '\nNerd Font: verificar no terminal gráfico; recomendada: JetBrainsMono Nerd Font Mono\n'
} > "$snapshot_path/commands.txt"

{
  printf 'snapshot_name=%s\n' "$snapshot_name"
  printf 'created_at=%s\n' "$(date --iso-8601=seconds)"
  printf 'project=%s\n' "$(basename -- "$SCRIPT_DIR")"
  printf 'config_directory=config\n'
  printf 'packages_file=packages.txt\n'
  printf 'commands_file=commands.txt\n'
  printf 'note=Snapshot de configurações e inventário; não é exportação completa do WSL.\n'
} > "$snapshot_path/snapshot-manifest.txt"

info "Snapshot criado: $snapshot_path"
warn 'Revise os arquivos antes de publicar ou versionar: configurações podem conter dados pessoais.'
