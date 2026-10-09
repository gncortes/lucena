#!/usr/bin/env python3
"""Biblioteca de captura de telas do Lucena (build de release, pt-BR) num
emulador sem janela, para a skill `rodada-ajustes`.

Só adb + PIL (sem numpy/chess). Toques por texto (uiautomator: content-desc
ou text) e, no tabuleiro, pelas casas achadas no print. A partida contra o
app usa o Stockfish do sistema por UCI.

Uso num roteiro (no scratchpad da sessão):

    import sys; sys.path.insert(0, "<repo>/.claude/skills/rodada-ajustes/scripts")
    from telas import *          # SERIAL e SHOTS vêm do ambiente
    fresh_start(); finish_tour()
    shot("R3-tela-x")

Linha de comando:
    SERIAL=emulator-5560 python3 -I telas.py rotulos        # rótulos da tela
    SERIAL=emulator-5560 python3 -I telas.py print nome     # um print agora
    python3 -I telas.py compor saida.png a.png b.png ...    # lado a lado

As coordenadas de rolagem supõem o AVD `Lucena_Patrol` (1344 x 2992).
"""
from __future__ import annotations

import io
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image

SERIAL = os.environ.get("SERIAL", "emulator-5560")
PKG = "com.gncortes.lucena"
# Raiz do repositório (para ler as aulas em assets/).
ROOT = Path(os.environ.get("ROOT") or subprocess.run(
    ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True,
    cwd=Path(__file__).resolve().parent).stdout.strip())
# Onde os prints caem: $SHOTS (absoluto ou relativo ao diretório atual).
OUT = Path(os.environ.get("SHOTS", "shots")).resolve()
OUT.mkdir(parents=True, exist_ok=True)

def log(*a):
    print(*a, flush=True)


def adb(*args, check=True) -> str:
    return subprocess.run(["adb", "-s", SERIAL, *args], capture_output=True, text=True, check=check).stdout


def screen() -> Image.Image:
    png = subprocess.run(["adb", "-s", SERIAL, "exec-out", "screencap", "-p"], capture_output=True, check=True).stdout
    return Image.open(io.BytesIO(png)).convert("RGB")


def shot(name: str, wait: float = 0.8):
    time.sleep(wait)
    screen().save(OUT / f"{name}.png")
    log("●", name)


def tap(x, y, then=1.0):
    adb("shell", "input", "tap", str(int(x)), str(int(y)))
    time.sleep(then)


def swipe(y1, y2, ms=700, then=1.2, x=672):
    adb("shell", "input", "swipe", str(x), str(y1), str(x), str(y2), str(ms))
    time.sleep(then)


def back(then=1.2):
    adb("shell", "input", "keyevent", "BACK")
    time.sleep(then)


def _unescape(t: str) -> str:
    return (t.replace("&amp;", "&").replace("&quot;", '"').replace("&#10;", "\n")
            .replace("&lt;", "<").replace("&gt;", ">").replace("&apos;", "'"))


def nodes():
    xml = subprocess.run(["adb", "-s", SERIAL, "exec-out", "uiautomator", "dump", "/dev/tty"],
                         capture_output=True, text=True).stdout
    found = []
    for node in re.findall(r"<node [^>]*>", xml):
        desc = re.search(r'content-desc="([^"]*)"', node)
        text = re.search(r' text="([^"]*)"', node)
        label = (desc.group(1) if desc else "") or (text.group(1) if text else "")
        bounds = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', node)
        if label and bounds:
            found.append((_unescape(label), tuple(map(int, bounds.groups()))))
    return found


def find(label, timeout=15, exact=False):
    end = time.time() + timeout
    while True:
        for text, box in nodes():
            if (text == label) if exact else (label in text):
                return box
        if time.time() > end:
            raise RuntimeError(f"não achei na tela: {label!r}")
        time.sleep(0.5)


def wait_any(labels, timeout=20):
    end = time.time() + timeout
    while True:
        for text, box in nodes():
            for label in labels:
                if label in text:
                    return label, box
        if time.time() > end:
            raise RuntimeError(f"não achei nenhum: {labels!r}")
        time.sleep(0.5)


def exists(label, exact=False):
    return any((t == label) if exact else (label in t) for t, _ in nodes())


def tap_text(label, then=1.4, timeout=15, exact=False):
    x1, y1, x2, y2 = find(label, timeout, exact)
    tap((x1 + x2) / 2, (y1 + y2) / 2, then)


def scroll_to(label, tries=8, exact=False):
    for _ in range(tries):
        if exists(label, exact):
            x1, y1, x2, y2 = find(label, exact=exact)
            cy = (y1 + y2) / 2
            if 300 < cy < 2500:
                return
            if cy >= 2500:
                swipe(2200, 1300)
                continue
            swipe(1300, 2200)
            continue
        swipe(2200, 1300)
    find(label, exact=exact)


def fresh_start():
    adb("shell", "am", "force-stop", PKG)
    adb("shell", "pm", "clear", PKG)
    adb("shell", "cmd", "locale", "set-app-locales", PKG, "--user", "0", "--locales", "pt-BR")
    adb("shell", "settings", "put", "global", "sysui_demo_allowed", "1", check=False)
    adb("shell", "am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", "enter", check=False)
    adb("shell", "am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", "clock", "-e", "hhmm", "1200", check=False)
    adb("shell", "am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", "battery", "-e", "level", "100", "-e", "plugged", "false", check=False)
    adb("shell", "am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", "network", "-e", "wifi", "show", "-e", "level", "4", check=False)
    adb("shell", "am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", "notifications", "-e", "visible", "false", check=False)
    adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(5)


# --- tabuleiro ----------------------------------------------------------------

SQUARES = ((222, 227, 230), (140, 162, 173))


def _runs(flags):
    runs, start = [], None
    for i, f in enumerate(list(flags) + [False]):
        if f and start is None:
            start = i
        elif not f and start is not None:
            runs.append((start, i))
            start = None
    return runs or [(0, len(flags))]


def locate_board():
    img = screen()
    k = 4
    small = img.resize((img.width // k, img.height // k), Image.NEAREST)
    px = small.load()
    w, h = small.size
    mask = [[False] * w for _ in range(h)]
    for y in range(h):
        row = mask[y]
        for x in range(w):
            r, g, b = px[x, y]
            for cr, cg, cb in SQUARES:
                if abs(r - cr) <= 8 and abs(g - cg) <= 8 and abs(b - cb) <= 8:
                    row[x] = True
                    break
    rows = [sum(mask[y]) / w > 0.3 for y in range(h)]
    y0, y1 = max(_runs(rows), key=lambda r: r[1] - r[0])
    cols = [sum(mask[y][x] for y in range(y0, y1)) / max(1, y1 - y0) > 0.3 for x in range(w)]
    x0, x1 = max(_runs(cols), key=lambda r: r[1] - r[0])
    size = min(x1 - x0, y1 - y0) * k
    rect = (x0 * k, y0 * k, size)
    log("  tabuleiro", rect)
    return rect


def center(rect, square, white_bottom=True):
    x0, y0, size = rect
    file = "abcdefgh".index(square[0])
    rank = int(square[1]) - 1
    col = file if white_bottom else 7 - file
    row = 7 - rank if white_bottom else rank
    return x0 + (col + 0.5) * size / 8, y0 + (row + 0.5) * size / 8


def move(rect, uci, white_bottom=True, then=0.9):
    tap(*center(rect, uci[:2], white_bottom), then=0.35)
    tap(*center(rect, uci[2:4], white_bottom), then=0.5)
    if len(uci) == 5:
        # Promoção: a dama aparece na própria casa de chegada.
        tap(*center(rect, uci[2:4], white_bottom), then=0.6)
    time.sleep(then)


# --- fluxos do app -----------------------------------------------------------


def finish_tour():
    for _ in range(12):
        if exists("Começar", exact=True):
            break
        tap_text("Próximo", then=0.8)
    tap_text("Começar", then=3, exact=True)


def open_endgames():
    """Da tela inicial até 'Aulas de finais' (que pode estar em 'Outros modos')."""
    for _ in range(3):
        if exists("Aulas de finais"):
            break
        if exists("Outros modos"):
            tap_text("Outros modos", then=1.5)
        else:
            swipe(2200, 1300)
    scroll_to("Aulas de finais")
    tap_text("Aulas de finais", then=2.5)


def go_home():
    """Volta até a tela inicial (o app reabre onde parou)."""
    for _ in range(6):
        if exists("Olá, "):
            return
        back(then=2)
    raise RuntimeError("não cheguei à tela inicial")


def think_chooser():
    if exists("Quanto tempo você quer pensar?"):
        tap_text("Recomendado", then=1.5)
        for label in ("Confirmar", "Começar", "Continuar"):
            if exists(label, exact=True):
                tap_text(label, then=2, exact=True)
                break


class Engine:
    def __init__(self):
        self.p = subprocess.Popen(["stockfish"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
        self.cmd("uci")
        self.wait("uciok")
        self.cmd("isready")
        self.wait("readyok")

    def cmd(self, s):
        self.p.stdin.write(s + "\n")
        self.p.stdin.flush()

    def wait(self, token):
        lines = []
        while True:
            line = self.p.stdout.readline().strip()
            lines.append(line)
            if line.startswith(token):
                return lines

    def position(self, fen, moves):
        self.cmd(f"position fen {fen}" + (f" moves {' '.join(moves)}" if moves else ""))

    def legal(self, fen, moves):
        self.position(fen, moves)
        self.cmd("go perft 1")
        lines = self.wait("Nodes searched")
        return [l.split(":")[0] for l in lines if re.match(r"^[a-h][1-8][a-h][1-8][qrbn]?: \d+$", l)]

    def best(self, fen, moves, ms=500):
        self.position(fen, moves)
        self.cmd(f"go movetime {ms}")
        return self.wait("bestmove")[-1].split()[1]


def fen_pieces(fen):
    board = {}
    rows = fen.split()[0].split("/")
    for r, row in enumerate(rows):
        rank = 8 - r
        f = 0
        for ch in row:
            if ch.isdigit():
                f += int(ch)
            else:
                board["abcdefgh"[f] + str(rank)] = ch
                f += 1
    return board


def apply(board, uci):
    b = dict(board)
    piece = b.pop(uci[:2])
    if len(uci) == 5:
        piece = uci[4].upper() if piece.isupper() else uci[4]
    b[uci[2:4]] = piece
    return b


def expected(board):
    return {sq: p.isupper() for sq, p in board.items()}


def read_board(rect, white_bottom=True):
    img = screen().convert("L")
    x0, y0, size = rect
    cell = size / 8
    r = int(cell * 0.3)
    found = {}
    for file in "abcdefgh":
        for rank in "12345678":
            sq = file + rank
            cx, cy = center(rect, sq, white_bottom)
            patch = img.crop((int(cx - r), int(cy - r), int(cx + r), int(cy + r)))
            data = list(patch.getdata())
            n = len(data)
            dark = sum(1 for v in data if v < 70) / n
            light = sum(1 for v in data if v > 235) / n
            if dark > 0.04 or light > 0.12:
                found[sq] = light > 0.2
    return found


def same(seen, exp):
    return seen.keys() == exp.keys() and all(seen[k] == exp[k] for k in seen)


def play_out(step, engine):
    fen = step["fen"]
    white_bottom = step.get("side", "white") == "white"
    time.sleep(1.5)
    rect = locate_board()
    board = fen_pieces(fen)
    moves = []
    for _ in range(60):
        mine = engine.best(fen, moves)
        move(rect, mine, white_bottom, then=0.4)
        moves.append(mine)
        board = apply(board, mine)
        legal = engine.legal(fen, moves)
        if not legal:
            log("  mate em", len(moves), "lances")
            return
        candidates = {m: expected(apply(board, m)) for m in legal}
        end = time.time() + 40
        reply = None
        while time.time() < end and reply is None:
            seen = read_board(rect, white_bottom)
            for m, exp in candidates.items():
                if same(seen, exp):
                    time.sleep(0.3)
                    if same(read_board(rect, white_bottom), exp):
                        reply = m
                        break
            if reply is None:
                time.sleep(0.4)
        if reply is None:
            log("  sem resposta do adversário")
            return
        moves.append(reply)
        board = apply(board, reply)
        time.sleep(0.4)


def current_step():
    for t, _ in nodes():
        m = re.search(r"Passo (\d+) de (\d+)", t)
        if m:
            return int(m.group(1)) - 1
    return None


def run_part(data, part_index, engine=None, stop_at=None):
    """Faz os passos da parte lendo 'Passo N de M' na tela. Para em [stop_at]
    (índice) sem agir nele; senão vai até o 'Concluir'."""
    steps = data["parts"][part_index]["steps"]
    acted = -1
    for _ in range(60):
        think_chooser()
        i = current_step()
        if i is None:
            if exists("Concluir", exact=True):
                tap_text("Concluir", then=3, exact=True)
                return "concluded"
            if exists("Voltar à aula"):
                return "sheet"
            time.sleep(1)
            continue
        if stop_at is not None and i == stop_at:
            return "stopped"
        if stop_at is not None and i > stop_at:
            # Passou do ponto (a lição reabriu adiante): volta um passo.
            log("  passo", i, "> alvo, voltando")
            tap_text("Passo anterior", then=2.5)
            acted = -1
            continue
        if i == acted:
            if exists("Concluir", exact=True):
                tap_text("Concluir", then=3, exact=True)
                return "concluded"
            if exists("Continuar", exact=True):
                tap_text("Continuar", then=2.5, exact=True)
            else:
                time.sleep(1)
            continue
        step = steps[i]
        log("  passo", i, step["type"], step["id"])
        kind = step["type"]
        if kind == "think":
            find("Ver explicação", timeout=20)
            time.sleep(1)
            tap_text("Ver explicação", then=3)
        elif kind == "talk":
            time.sleep(1.2)
        elif kind == "move":
            time.sleep(1.5)
            rect = locate_board()
            white = step.get("side", "white") == "white"
            for turn in step["line"]:
                move(rect, turn["teach"], white, then=1.0)
                if turn.get("reply"):
                    time.sleep(1.6)
            time.sleep(1.5)
        elif kind == "play":
            play_out(step, engine or Engine())
            time.sleep(2)
        acted = i
    return "gave up"


def open_lesson(title):
    if exists("Olá, "):
        open_endgames()
    if exists("Todos"):
        tap_text("Todos", then=2, exact=True)
    scroll_to(title, tries=30)
    tap_text(title, then=3)


def lesson(lesson_id):
    """O JSON da aula (assets/lessons/endgames) e o título em português."""
    d = json.loads((ROOT / f"assets/lessons/endgames/{lesson_id}.json").read_text())
    t = json.loads((ROOT / f"assets/lessons/pt/endgames/{lesson_id}.json").read_text())
    return d, t["title"]


def play_from_setup(fen, side="white"):
    """Na tela do desafio: Jogar, Confirmar o ritmo (sem relógio) e a
    partida até o fim com o Stockfish. [fen] é a posição mostrada na tela."""
    tap_text("Jogar", then=3, timeout=25, exact=True)
    tap_text("Confirmar", then=6, timeout=15)
    play_out({"fen": fen, "side": side}, Engine())
    wait_any(["Próximo desafio", "Jogar de novo", "Tentar de novo"], timeout=40)


def compor(saida, *imagens, largura=448, gap=10):
    """Junta os prints lado a lado, reduzidos, numa imagem só (para o
    celular: uma imagem por item, legível na conversa)."""
    ims = [Image.open(p) for p in imagens]
    h = round(largura * ims[0].height / ims[0].width)
    out = Image.new("RGB", (largura * len(ims) + gap * (len(ims) - 1), h), "white")
    for i, im in enumerate(ims):
        out.paste(im.resize((largura, h)), (i * (largura + gap), 0))
    out.save(saida)
    return saida


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "rotulos":
        for text, box in nodes():
            print(repr(text[:90]), box)
    elif cmd == "print":
        shot(sys.argv[2], wait=0)
    elif cmd == "compor":
        compor(sys.argv[2], *sys.argv[3:])
    else:
        print(__doc__)
