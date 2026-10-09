#!/usr/bin/env bash
# Emuladores sem janela para os prints de uma rodada de ajustes.
#
#   DONO=<id da sessão> emuladores.sh estado         # o que está aberto, memória e quantos cabem
#   DONO=<id da sessão> emuladores.sh subir N        # sobe até N cópias do Lucena_Patrol (5560, 5562...)
#   DONO=<id da sessão> emuladores.sh instalar APK   # instala (-r, mantém dados) em todos os meus
#   DONO=<id da sessão> emuladores.sh lista          # os seriais meus, um por linha
#   DONO=<id da sessão> emuladores.sh aliviar        # fecha meus emuladores até a folga voltar
#   DONO=<id da sessão> emuladores.sh descer         # fecha todos os meus
#
# DONO marca de quem é cada emulador (use o nome da pasta do scratchpad da
# sessão). Regras (memória do Gabriel):
# - o 5554 é dele: nunca é contado, tocado nem fechado aqui;
# - emulador do Lucena aberto por outra sessão (outro DONO ou sem dono):
#   não sobe nenhum; espere ele liberar;
# - este projeto nunca é a prioridade: com outro projeto pesado rodando
#   (outro emulador, como o da Cogna, Chrome grande, build), abro menos e,
#   se a memória apertar no meio, fecho os meus (aliviar);
# - cada cópia gasta ~4,3 GB; a folga mínima é 12 GB livres, 18 GB com
#   outro emulador ou Chrome pesado aberto; no máximo 6 cópias, 3 com outro
#   emulador aberto, e metade se a CPU estiver acima de 70%.
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
# Emulador aberto que não é meu nem o 5554 (Cogna, outro projeto).
outro_emulador() { abertos | awk -v avd="$AVD" '$1 != avd && $2 != 5554' | grep -q .; }
# Memória (GB) do Chrome somado.
chrome_gb() { ps -C chrome -o rss= 2>/dev/null | awk '{s+=$1} END {printf "%d", s/1048576}'; }
pesado() { outro_emulador || (( $(chrome_gb) >= 6 )); }
folga() { pesado && echo 18 || echo 12; }
cpu_alta() { python3 -c "import os; print(int(os.getloadavg()[0] / os.cpu_count() > 0.7))"; }
cabem() {
  local livre cap
  livre="$(livre_gb)"
  cap=$(python3 -c "print(max(0, min(6, int(($livre - $(folga)) / 4.3))))")
  outro_emulador && ((cap > 3)) && cap=3
  [[ "$(cpu_alta)" == 1 ]] && cap=$((cap / 2))
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
    echo "Memória livre: $(livre_gb) GB; folga exigida: $(folga) GB; Chrome: $(chrome_gb) GB; outro emulador: $(outro_emulador && echo sim || echo não); CPU alta: $(cpu_alta)"
    echo "Cabem mais: $(cabem)"
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
  aliviar)
    # Fecha os meus, do último para o primeiro, até a folga voltar.
    for s in $(meus | sort -r); do
      (( $(livre_gb) >= $(folga) )) && break
      adb -s "$s" emu kill >/dev/null 2>&1 || true; rm -f "$DIR/${s#emulator-}"
      echo "fechei $s (memória livre $(livre_gb) GB, folga $(folga) GB)"; sleep 5
    done
    echo "Meus: $(meus | tr '\n' ' ')" ;;
  descer)
    for s in $(meus); do adb -s "$s" emu kill >/dev/null 2>&1 || true; rm -f "$DIR/${s#emulator-}"; done
    sleep 3; echo "Fechados. Abertos agora:"; abertos ;;
  *) sed -n 2,16p "$0"; exit 2 ;;
esac
