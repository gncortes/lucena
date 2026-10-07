#!/usr/bin/env python3
"""Conduz o app (build de release) por adb para as capturas da landing page.

Sem Patrol: os toques vão pelo texto da tela (lido do uiautomator) e, no
tabuleiro, pelas casas, achadas no próprio print. Os lances do jogador vêm do
Stockfish do computador; o lance do adversário é lido do tabuleiro na tela.

Os textos dos botões saem dos arquivos de tradução (lib/l10n/app_<idioma>.arb):
o mesmo roteiro roda em qualquer idioma.

Dependências: adb, stockfish no PATH e `pip install chess pillow numpy`.
"""

from __future__ import annotations

import io
import json
import re
import subprocess
import time
from pathlib import Path

import chess
import chess.engine
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = "com.gncortes.lucena"
LOCALES = {"pt": "pt-BR", "en": "en-US", "es": "es-ES"}


class App:
    def __init__(self, serial: str, lang: str, out: Path):
        self.serial = serial
        self.lang = lang
        self.out = out
        out.mkdir(parents=True, exist_ok=True)
        self.arb = json.loads((ROOT / f"lib/l10n/app_{lang}.arb").read_text())
        self.arb_en = json.loads((ROOT / "lib/l10n/app_en.arb").read_text())
        pt = json.loads((ROOT / "lib/l10n/app_pt.arb").read_text())
        self._pt_keys = {v: k for k, v in pt.items() if not k.startswith("@")}
        self._recorder: subprocess.Popen | None = None
        self._video = ""
        self.engine = chess.engine.SimpleEngine.popen_uci("stockfish")
        self.board: Board | None = None

    # --- adb ---------------------------------------------------------------

    def adb(self, *args: str, check=True) -> str:
        return subprocess.run(
            ["adb", "-s", self.serial, *args], capture_output=True, text=True, check=check
        ).stdout

    def screen(self) -> Image.Image:
        png = subprocess.run(
            ["adb", "-s", self.serial, "exec-out", "screencap", "-p"],
            capture_output=True,
            check=True,
        ).stdout
        return Image.open(io.BytesIO(png)).convert("RGB")

    def tap(self, x: float, y: float, then: float = 1.0):
        self.adb("shell", "input", "tap", str(int(x)), str(int(y)))
        time.sleep(then)

    def swipe(self, y1: int, y2: int, ms: int = 900, then: float = 1.2):
        x = 672
        self.adb("shell", "input", "swipe", str(x), str(y1), str(x), str(y2), str(ms))
        time.sleep(then)

    def back(self, then: float = 1.2):
        self.adb("shell", "input", "keyevent", "BACK")
        time.sleep(then)

    # --- app ---------------------------------------------------------------

    def fresh_start(self):
        """App limpo, no idioma escolhido, aberto do zero (com o tour)."""
        self.adb("shell", "am", "force-stop", PACKAGE)
        self.adb("shell", "pm", "clear", PACKAGE)
        self.adb(
            "shell", "cmd", "locale", "set-app-locales", PACKAGE,
            "--user", "0", "--locales", LOCALES[self.lang],
        )
        self.adb("shell", "monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")
        time.sleep(4)

    def text(self, key: str, **args) -> str:
        """O texto [key] no idioma do app (com os {parâmetros} trocados)."""
        value = self.arb.get(key) or self.arb_en[key]
        for name, arg in args.items():
            value = value.replace("{" + name + "}", str(arg))
        return value

    def t(self, pt_text: str) -> str:
        """O texto em português [pt_text], no idioma do app."""
        key = self._pt_keys.get(pt_text)
        return self.text(key) if key else pt_text

    def tap_t(self, pt_text: str, then: float = 1.4, timeout: float = 15):
        self.tap_text(self.t(pt_text), then, timeout)

    # --- texto na tela -----------------------------------------------------

    def nodes(self) -> list[tuple[str, tuple[int, int, int, int]]]:
        xml = subprocess.run(
            ["adb", "-s", self.serial, "exec-out", "uiautomator", "dump", "/dev/tty"],
            capture_output=True,
            text=True,
        ).stdout
        found = []
        for node in re.findall(r"<node [^>]*>", xml):
            desc = re.search(r'content-desc="([^"]*)"', node)
            text = re.search(r' text="([^"]*)"', node)
            label = (desc.group(1) if desc else "") or (text.group(1) if text else "")
            bounds = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', node)
            if label and bounds:
                found.append((_unescape(label), tuple(map(int, bounds.groups()))))
        return found

    def find(self, label: str, timeout: float = 15, exact=False):
        end = time.time() + timeout
        while True:
            for text, box in self.nodes():
                if (text == label) if exact else (label in text):
                    return box
            if time.time() > end:
                raise RuntimeError(f"não achei na tela: {label!r}")
            time.sleep(0.5)

    def exists(self, label: str) -> bool:
        return any(label in text for text, _ in self.nodes())

    def tap_text(self, label: str, then: float = 1.4, timeout: float = 15, exact=False):
        x1, y1, x2, y2 = self.find(label, timeout, exact)
        self.tap((x1 + x2) / 2, (y1 + y2) / 2, then)

    def tap_key(self, key: str, then: float = 1.4, **args):
        self.tap_text(self.text(key, **args), then)

    def scroll_to(self, label: str, tries: int = 8):
        for _ in range(tries):
            if self.exists(label):
                x1, y1, x2, y2 = self.find(label)
                if 300 < (y1 + y2) / 2 < 2500:
                    return
                if (y1 + y2) / 2 >= 2500:
                    self.swipe(2200, 1300)
                    continue
            self.swipe(2200, 1300)
        self.find(label)

    # --- capturas ----------------------------------------------------------

    def shot(self, name: str):
        time.sleep(0.6)
        self.screen().save(self.out / f"{name}.png")
        print(f"● {name}.png")

    def start_video(self, name: str):
        self._video = name
        self.adb("shell", "rm", "-f", f"/sdcard/cap-{name}.mp4", check=False)
        self._recorder = subprocess.Popen(
            [
                "adb", "-s", self.serial, "shell", "screenrecord",
                "--size", "1080x2404", "--bit-rate", "20000000",
                f"/sdcard/cap-{name}.mp4",
            ]
        )
        time.sleep(1.2)
        print(f"▶ {name}")

    def end_video(self):
        time.sleep(0.6)
        self.adb("shell", "pkill", "-INT", "screenrecord", check=False)
        if self._recorder:
            self._recorder.wait(timeout=15)
        time.sleep(1)
        self.adb("pull", f"/sdcard/cap-{self._video}.mp4", str(self.out / f"{self._video}.mp4"))
        self.adb("shell", "rm", "-f", f"/sdcard/cap-{self._video}.mp4", check=False)
        print(f"■ {self._video}.mp4")

    # --- tabuleiro ---------------------------------------------------------

    def find_board(self, fen: str, white_bottom: bool = True) -> "Board":
        self.board = Board(self, fen, white_bottom)
        return self.board

    def find_board_among(self, fens: list[str], timeout: float = 15) -> "Board":
        """O tabuleiro na tela é uma das posições [fens] (sem saber qual nem
        de que lado): acha qual pelas peças na tela."""
        end = time.time() + timeout
        while time.time() < end:
            board = Board(self, fens[0], True)
            for white_bottom in (True, False):
                board.white_bottom = white_bottom
                seen = board.read()
                for fen in fens:
                    if _same(seen, board._expected(chess.Board(fen))):
                        board.game = chess.Board(fen)
                        self.board = board
                        return board
            time.sleep(0.5)
        raise RuntimeError("posição da tela fora da lista")

    def close(self):
        self.engine.quit()


class Board:
    """O tabuleiro na tela: onde fica, que peças tem e os lances."""

    def __init__(self, app: App, fen: str, white_bottom: bool):
        self.app = app
        self.game = chess.Board(fen)
        self.white_bottom = white_bottom
        self.rect = self._locate(np.asarray(app.screen(), dtype=np.int16))

    # As duas cores do tabuleiro azul (o padrão do app).
    SQUARES = ((222, 227, 230), (140, 162, 173))

    def _locate(self, px: np.ndarray):
        mask = np.zeros(px.shape[:2], bool)
        for color in self.SQUARES:
            mask |= np.all(np.abs(px - np.array(color)) <= 8, axis=2)
        rows = mask.mean(axis=1) > 0.3
        y0, y1 = max(_runs(rows), key=lambda r: r[1] - r[0])
        cols = mask[y0:y1].mean(axis=0) > 0.3
        x0, x1 = max(_runs(cols), key=lambda r: r[1] - r[0])
        return x0, y0, min(x1 - x0, y1 - y0)

    def center(self, square: str):
        x0, y0, size = self.rect
        s = chess.parse_square(square)
        file, rank = chess.square_file(s), chess.square_rank(s)
        col = file if self.white_bottom else 7 - file
        row = 7 - rank if self.white_bottom else rank
        return x0 + (col + 0.5) * size / 8, y0 + (row + 0.5) * size / 8

    def read(self) -> dict[int, bool]:
        """Casa -> peça branca (True) ou preta (False), pelo print."""
        px = np.asarray(self.app.screen(), dtype=np.int16)
        lum = px.mean(axis=2)
        x0, y0, size = self.rect
        cell = size / 8
        found = {}
        for s in chess.SQUARES:
            cx, cy = self.center(chess.square_name(s))
            r = int(cell * 0.3)
            patch = lum[int(cy - r) : int(cy + r), int(cx - r) : int(cx + r)]
            dark = (patch < 70).mean()
            light = (patch > 235).mean()
            if dark > 0.04 or light > 0.12:
                # As brancas têm muito branco; as pretas, só detalhes.
                found[s] = light > 0.2
        return found

    def _expected(self, game: chess.Board) -> dict[int, bool]:
        return {s: p.color == chess.WHITE for s, p in game.piece_map().items()}

    def move(self, uci: str, then: float = 0.9):
        a, b = uci[:2], uci[2:4]
        self.app.tap(*self.center(a), then=0.35)
        self.app.tap(*self.center(b), then=0.5)
        if len(uci) == 5:
            self.app.tap(*self.center(b), then=0.5)  # dama: na própria casa
        self.game.push_uci(uci)
        time.sleep(then)

    def wait_reply(self, timeout: float = 40) -> bool:
        """Espera o adversário jogar e registra o lance. False se não jogou."""
        if self.game.is_game_over():
            return False
        end = time.time() + timeout
        candidates = {}
        for m in self.game.legal_moves:
            g = self.game.copy()
            g.push(m)
            candidates[m] = self._expected(g)
        while time.time() < end:
            seen = self.read()
            for m, expected in candidates.items():
                if _same(seen, expected):
                    time.sleep(0.3)
                    if _same(self.read(), expected):
                        self.game.push(m)
                        return True
            time.sleep(0.4)
        return False

    def best(self, ms: int = 300) -> str:
        result = self.app.engine.play(self.game, chess.engine.Limit(time=ms / 1000))
        return result.move.uci()

    def play(self, moves: int, pause: float = 0.6, ms: int = 300, reply=True):
        """Joga [moves] lances do Stockfish, esperando cada resposta."""
        for _ in range(moves):
            if self.game.is_game_over():
                return
            time.sleep(pause)
            self.move(self.best(ms), then=0.3)
            if reply and not self.game.is_game_over():
                if not self.wait_reply():
                    return


def _same(seen: dict, expected: dict) -> bool:
    return seen.keys() == expected.keys() and all(seen[k] == expected[k] for k in seen)


def _runs(flags) -> list[tuple[int, int]]:
    runs, start = [], None
    for i, f in enumerate(list(flags) + [False]):
        if f and start is None:
            start = i
        elif not f and start is not None:
            runs.append((start, i))
            start = None
    return runs or [(0, len(flags))]


def _unescape(text: str) -> str:
    return (
        text.replace("&amp;", "&").replace("&quot;", '"').replace("&#10;", "\n")
        .replace("&lt;", "<").replace("&gt;", ">").replace("&apos;", "'")
    )
