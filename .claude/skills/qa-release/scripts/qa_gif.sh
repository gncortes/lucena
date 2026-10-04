#!/usr/bin/env bash
# Uso: qa_gif.sh TXX <rótulo> -- <comando que exercita a feature no emulador>
# Ex.:  qa_gif.sh T05 v0.1.1-rc.1 -- patrol test -t integration_test/board_settings_test.dart -d emulator-5554 --dart-define=E2E=true
#
# Grava a tela do emulador enquanto o comando roda, converte em GIF, publica no branch
# `qa-media` (fora da main, para não pesar o histórico do código) e imprime a linha de
# Markdown que vai na seção "Demonstração" do PR.
set -euo pipefail

TASK="${1:?informe a tarefa, ex.: T05}"
LABEL="${2:?informe o rótulo, ex.: v0.1.3-rc.1}"
[[ "${3:-}" == "--" && $# -gt 3 ]] || { echo "uso: qa_gif.sh TXX <rótulo> -- <comando>"; exit 2; }
shift 3

MEDIA_BRANCH="qa-media"
MAX_BYTES=$((8 * 1024 * 1024))
OUT_DIR="build/qa-release"
MP4="$OUT_DIR/demo.mp4"
GIF="$OUT_DIR/demo.gif"
REMOTE_MP4="/sdcard/qa_gif.mp4"
mkdir -p "$OUT_DIR"

fail() { echo "ERRO: $1"; exit 1; }

# O Patrol CLI é instalado pelo `dart pub global activate`.
export PATH="$PATH:$HOME/.pub-cache/bin"
DEVICE="${ANDROID_DEVICE:-$(sed -n 's/^ANDROID_DEVICE=//p' .env 2>/dev/null || true)}"
DEVICE="${DEVICE:-emulator-5554}"
for cmd in adb ffmpeg gh; do
  command -v "$cmd" >/dev/null || fail "comando $cmd não encontrado"
done
[[ "$(adb -s "$DEVICE" get-state 2>/dev/null)" == device ]] || fail "emulador $DEVICE não está ligado"

# 1. Gravar a tela enquanto o comando roda (o screenrecord para sozinho em 3 min).
# Grava em 720 px de largura na proporção da tela: na resolução nativa o codificador
# do emulador falha e cai num tamanho padrão com barras pretas nas laterais.
read -r SCREEN_W SCREEN_H < <(adb -s "$DEVICE" shell wm size | sed -n 's/.*: \([0-9]*\)x\([0-9]*\).*/\1 \2/p' | tail -1)
REC_H=$(( (720 * SCREEN_H / SCREEN_W + 8) / 16 * 16 ))
adb -s "$DEVICE" shell screenrecord --size "720x$REC_H" --bit-rate 4000000 "$REMOTE_MP4" &
REC_PID=$!
sleep 1
set +e
"$@"
CMD_EXIT=$?
set -e
sleep 1
adb -s "$DEVICE" shell pkill -INT screenrecord || true
wait "$REC_PID" || true
sleep 1
adb -s "$DEVICE" pull "$REMOTE_MP4" "$MP4" >/dev/null || fail "gravação não encontrada no emulador"
adb -s "$DEVICE" shell rm -f "$REMOTE_MP4"
[[ $CMD_EXIT -eq 0 ]] || fail "o comando gravado falhou (código $CMD_EXIT): GIF não publicado"

# 2. GIF leve: 12 quadros por segundo, 360 px de largura, paleta própria
ffmpeg -y -loglevel error -i "$MP4" \
  -vf "fps=12,scale=360:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" \
  "$GIF"
SIZE="$(stat -c %s "$GIF")"
[[ "$SIZE" -le "$MAX_BYTES" ]] || fail "GIF com $((SIZE / 1024)) KB passa de 8 MB: grave um trecho menor"

# 3. Publicar no branch de mídia, sem tocar na árvore de trabalho nem no branch atual
FILE_PATH="$TASK/$LABEL.gif"
BLOB="$(git hash-object -w "$GIF")"
COMMIT=""
for _ in 1 2 3; do
  INDEX="$(mktemp -u)"
  PARENT=()
  if git fetch --quiet origin "$MEDIA_BRANCH" 2>/dev/null; then
    PARENT=(-p "$(git rev-parse FETCH_HEAD)")
    GIT_INDEX_FILE="$INDEX" git read-tree FETCH_HEAD
  fi
  GIT_INDEX_FILE="$INDEX" git update-index --add --cacheinfo "100644,$BLOB,$FILE_PATH"
  TREE="$(GIT_INDEX_FILE="$INDEX" git write-tree)"
  rm -f "$INDEX"
  COMMIT="$(git commit-tree "$TREE" "${PARENT[@]}" -m "QA $TASK $LABEL")"
  # Outra sessão pode ter publicado ao mesmo tempo: refaz em cima do branch novo.
  git push --quiet origin "$COMMIT:refs/heads/$MEDIA_BRANCH" && break
  COMMIT=""
done
[[ -n "$COMMIT" ]] || fail "push do GIF para o branch $MEDIA_BRANCH falhou"

# 4. Markdown para o PR (link preso ao commit: não muda se o branch andar)
REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
echo "GIF: $GIF ($((SIZE / 1024)) KB)"
echo "![$TASK $LABEL no emulador](https://raw.githubusercontent.com/$REPO/$COMMIT/$FILE_PATH)"
