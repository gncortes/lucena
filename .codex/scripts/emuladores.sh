#!/usr/bin/env bash
# Uso: bash .codex/scripts/emuladores.sh <dono-da-sessao> <acao> [argumento]
set -euo pipefail
[[ $# -ge 2 ]] || { echo "Uso: $0 <dono> estado|lista|subir|instalar|aliviar|descer [argumento]" >&2; exit 2; }
owner="$1"; action="$2"; shift 2
[[ "$owner" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Dono inválido" >&2; exit 2; }
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$project_dir"
export DONO="$owner"
manager=.claude/skills/rodada-ajustes/scripts/emuladores.sh
case "$action" in
  estado|lista|aliviar|descer) [[ $# == 0 ]] || exit 2 ;;
  subir) [[ $# == 1 && "$1" =~ ^[0-9]+$ ]] || exit 2
    bash "$manager" estado ;;
  instalar) [[ $# == 1 && -f "$1" && "$1" == *.apk ]] || exit 2 ;;
  *) echo "Ação não permitida" >&2; exit 2 ;;
esac
exec bash "$manager" "$action" "$@"
