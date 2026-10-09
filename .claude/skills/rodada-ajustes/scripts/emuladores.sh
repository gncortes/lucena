#!/usr/bin/env bash
# Emuladores sem janela para os prints de uma rodada de ajustes.
#
#   DONO=<id da sessão> emuladores.sh estado         # o que está aberto, memória e quantos cabem
#   DONO=<id da sessão> emuladores.sh subir N        # sobe até N cópias do Lucena_Patrol (5560, 5562...)
#   DONO=<id da sessão> emuladores.sh instalar APK   # instala (-r, mantém dados) em todos os meus
#   DONO=<id da sessão> emuladores.sh lista          # os seriais meus, um por linha
#   DONO=<id da sessão> emuladores.sh descer         # fecha todos os meus
#
# DONO marca de quem é cada emulador (use o nome da pasta do scratchpad da
# sessão). Regras (memória do Gabriel):
# - o 5554 é dele: nunca é contado, tocado nem fechado aqui;
# - emulador do Lucena aberto por outra sessão (outro DONO ou sem dono):
#   não sobe nenhum; espere ele liberar;
# - cada cópia gasta ~4,3 GB: sobra sempre ~12 GB livres; no máximo 6, e 4
#   com o emulador da Cogna aberto.
set -euo pipefail

SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
EMULATOR="$SDK/emulator/emulator"
export PATH="$PATH:$SDK/platform-tools"
AVD=Lucena_Patrol
FIRST_PORT=5560
DIR="${XDG_RUNTIME_DIR:-/tmp}/lucena-emus"
mkdir -p "$DIR"
: "${DONO:?defina DONO (ex.: o nome da pasta do scratchpad da sessão)}"

booted() { [[ "$(adb -s "$1" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; }

# "avd porta" de cada emulador aberto.
abertos() {
  ps -eo args | grep -E "qemu-system|/emulator " | grep -v grep |
    sed -nE 's/.*-avd ([^ ]+).*-port ([0-9]+).*/\1 \2/p; s/.*-port ([0-9]+).*-avd ([^ ]+).*/\2 \1/p' | sort -u
}
dono_de() { cat "$DIR/$1" 2>/dev/null || echo "?"; }
meus() {
  for f in "$DIR"/*; do
    [[ -f "$f" && "$(cat "$f")" == "$DONO" ]] || continue
    port="$(basename "$f")"
    abertos | grep -q " $port\$" && echo "emulator-$port" || rm -f "$f"
  done
}
livre_gb() { LC_ALL=C free -g | awk '/^Mem:/{print $7}'; }
cabem() {
  local livre cap cogna=0
  livre="$(livre_gb)"
  cap=$(python3 -c "print(max(0, min(6, int(($livre - 12) / 4.3))))")
  abertos | grep -qi cogna && cogna=1
  ((cogna)) && ((cap > 4)) && cap=4
  echo "$cap"
}
alheios() {
  abertos | while read -r avd port; do
    [[ "$port" == 5554 ]] && continue
    [[ "$avd" == "$AVD" ]] || continue
    [[ "$(dono_de "$port")" == "$DONO" ]] || echo "$avd $port (dono: $(dono_de "$port"))"
  done
}

case "${1:-estado}" in
  estado)
    echo "Abertos:"; abertos | while read -r avd port; do echo "  $port $avd dono=$(dono_de "$port")"; done
    echo "Meus: $(meus | tr '\n' ' ')"
    echo "Memória livre: $(livre_gb) GB; cabem mais: $(cabem)"
    a="$(alheios)"; [[ -n "$a" ]] && echo "ATENÇÃO, emulador de outra sessão: $a (não suba nenhum)"
    exit 0 ;;
  lista) meus; exit 0 ;;
  subir)
    want="${2:?quantos}"
    a="$(alheios)"
    if [[ -n "$a" ]]; then echo "Outra sessão está com emuladores: $a. Não subo nenhum." >&2; exit 3; fi
    have=$(meus | wc -l)
    room=$(cabem)
    n=$(( want - have )); (( n > room )) && n=$room
    if (( n <= 0 )); then echo "Nenhum a subir (meus: $have, cabem: $room)."; meus; exit 0; fi
    [[ -d "$HOME/.android/avd/$AVD.avd/snapshots/default_boot" ]] ||
      { echo "O $AVD ainda não foi preparado: rode tools/patrol_parallel.sh uma vez." >&2; exit 4; }
    port=$FIRST_PORT; started=()
    while (( ${#started[@]} < n )); do
      if ! abertos | grep -q " $port\$"; then
        echo "$DONO" > "$DIR/$port"
        "$EMULATOR" -avd "$AVD" -read-only -port "$port" -no-window -no-audio -no-boot-anim -gpu host \
          >"$DIR/$port.log" 2>&1 &
        started+=("emulator-$port"); sleep 2
      fi
      port=$((port + 2))
    done
    for s in "${started[@]}"; do
      for _ in $(seq 1 60); do booted "$s" && break; sleep 3; done
      booted "$s" || { echo "$s não subiu" >&2; continue; }
      adb -s "$s" shell "settings put global window_animation_scale 1; settings put system screen_off_timeout 2147483647" >/dev/null 2>&1 || true
    done
    meus ;;
  instalar)
    apk="${2:?caminho do APK}"
    for s in $(meus); do (adb -s "$s" install -r "$apk" | tail -1 | sed "s/^/$s: /") & done; wait ;;
  descer)
    for s in $(meus); do adb -s "$s" emu kill >/dev/null 2>&1 || true; rm -f "$DIR/${s#emulator-}"; done
    sleep 3; echo "Fechados. Abertos agora:"; abertos ;;
  *) sed -n 2,16p "$0"; exit 2 ;;
esac
