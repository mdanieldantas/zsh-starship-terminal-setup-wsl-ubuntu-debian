#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SNAPSHOT_DIR="$SCRIPT_DIR/snapshots"

info() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERRO] %s\n' "$*" >&2; exit 1; }

on_error() {
  local code=$?
  printf '[ERRO] Falha na linha %s (código %s).\n' "$1" "$code" >&2
  exit "$code"
}
trap 'on_error "$LINENO"' ERR

[[ "$(id -u)" -ne 0 ]] || die 'Execute como usuário comum; não use sudo bash.'
[[ -d "$SNAPSHOT_DIR" ]] || die "Pasta de snapshots ausente: $SNAPSHOT_DIR"

mapfile -t SNAPSHOTS < <(
  find "$SNAPSHOT_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -r
)
((${#SNAPSHOTS[@]} > 0)) || die 'Nenhum snapshot encontrado.'

printf 'Snapshots disponíveis:\n'
for index in "${!SNAPSHOTS[@]}"; do
  printf '  %d) %s\n' "$((index + 1))" "${SNAPSHOTS[index]}"
done

read -r -p 'Escolha o número do snapshot: ' choice
[[ "$choice" =~ ^[0-9]+$ ]] || die 'Escolha inválida.'
((choice >= 1 && choice <= ${#SNAPSHOTS[@]})) || die 'Escolha fora da lista.'

selected="${SNAPSHOTS[choice - 1]}"
source_dir="$SNAPSHOT_DIR/$selected"
config_dir="$source_dir/config"
[[ -d "$config_dir" ]] || die "Snapshot sem diretório de configuração: $selected"

printf '\nSnapshot escolhido: %s\n' "$selected"
printf 'Arquivos salvos:\n'
find "$config_dir" -mindepth 1 -print | sed "s#^$config_dir#.#" || true
printf '\n'

read -r -p 'Restaurar este snapshot? [s/N] ' confirmation
[[ "$confirmation" =~ ^[sSyY]$ ]] || { info 'Restauração cancelada.'; exit 0; }

stamp="$(date +%Y-%m-%d_%H%M%S)"
current_snapshot="$SNAPSHOT_DIR/restore-before-$stamp"
current_config="$current_snapshot/config"
mkdir -p "$current_config"

copy_current_if_exists() {
  local source="$1"
  local relative="${source#"$HOME/"}"
  if [[ -e "$source" || -L "$source" ]]; then
    mkdir -p "$current_config/$(dirname -- "$relative")"
    cp -a -- "$source" "$current_config/$relative"
  fi
}

restore_relative() {
  local relative="$1"
  local source="$config_dir/$relative"
  local target="$HOME/$relative"

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    return 0
  fi

  case "$relative" in
    /*|../*|*/../*|..)
      die "Caminho inválido no snapshot: $relative"
      ;;
  esac

  copy_current_if_exists "$target"
  rm -rf -- "$target"
  mkdir -p -- "$(dirname -- "$target")"
  cp -a -- "$source" "$target"
  info "Restaurado $relative"
}

restore_relative '.zshenv'
restore_relative '.zshrc'
restore_relative '.zprofile'
restore_relative '.zlogin'
restore_relative '.zlogout'
restore_relative '.config/zsh'
restore_relative '.config/starship.toml'
restore_relative '.local/bin/bat'
restore_relative '.local/bin/fd'

if find "$config_dir" -mindepth 1 -print -quit | grep -q .; then
  info 'Restauração concluída.'
else
  die 'O snapshot não contém arquivos de configuração.'
fi

info "Backup automático do estado anterior: $current_snapshot"
info 'Pacotes não foram instalados ou removidos.'
info 'O shell padrão e as configurações do Windows Terminal não foram alterados.'
