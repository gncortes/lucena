#!/usr/bin/env python3
"""Gera as posições das etapas dos speedruns de final.

O speedrun de final é sempre o mesmo final (o mesmo material e o mesmo
objetivo da posição do catálogo que o speedrun cita), mas cada etapa começa
com as peças em casas diferentes, perto do centro, e em algumas o jogador é
das pretas (pedido do Gabriel em 2026-10-05). O resultado vai versionado em
`assets/progression/speedrun_positions.json`; essas posições não entram no
catálogo.

Como cada etapa é escolhida:
1. Sorteio com semente fixa (o resultado é sempre o mesmo): o rei e as peças
   de quem ganha ficam na área do meio (colunas b–g, fileiras 2–7); o rei de
   quem defende nunca fica na borda e, nos mates, fica no quadrado central
   (c3–f6). Peão de quem ganha fica nas colunas b–g e nas fileiras 3–5 (do
   ponto de vista dele). A posição precisa ser legal, sem xeque no rei de quem
   defende e sem peça pendurada (nenhum lado captura de graça no primeiro
   lance).
2. Confere na tablebase do Lichess (com intervalo entre chamadas e cache em
   `tools/.cache/speedrun_tablebase.json`): precisa ser vitória de quem joga
   (`win`, não `cursed-win`) e a distância até o mate (DTM em meios-lances)
   precisa ser pelo menos o mínimo do final (`MIN_DTM`), tirado da posição
   original do catálogo. Mate em 1 ou 2 nunca aparece.
3. As dez posições aceitas vão em ordem crescente de DTM (o adversário fica
   mais forte a cada etapa, e o final não fica mais curto). Nas etapas de
   `BLACK_STAGES` o tabuleiro é espelhado (cores e lado a jogar trocados), e a
   posição espelhada é conferida de novo na tablebase.

Uso: python3 tools/gen_speedrun_positions.py [--offline]
  --offline  não chama a tablebase: usa só o cache (falha se faltar algo).
"""

import json
import random
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools" / ".cache" / "speedrun_tablebase.json"
SPEEDRUNS = ROOT / "assets" / "progression" / "speedruns.json"
POSITIONS = ROOT / "assets" / "positions" / "positions.json"
OUTPUT = ROOT / "assets" / "progression" / "speedrun_positions.json"
TABLEBASE = "https://tablebase.lichess.ovh/standard?fen="

SEED = 20261005
STAGES = 10
# Etapas (contando de 1) em que o jogador é das pretas.
BLACK_STAGES = {3, 5, 8, 10}
# Intervalo entre chamadas à tablebase (o Lichess limita o uso sem conta).
DELAY = 1.1

# DTM mínimo (meios-lances) de cada final. Ponto de partida: a posição
# original do catálogo (DTM entre parênteses); quando ela já era curta, o
# mínimo sobe para um mate de verdade a partir do centro.
MIN_DTM = {
    "rook": 25,  # (25) mate de torre: igual ao original
    "queen": 15,  # (15) mate de dama: igual ao original
    "twoBishopsVsKing": 27,  # (27) dois bispos: igual ao original
    "queenVsRook": 21,  # (21) dama contra torre: igual ao original
    "rookPawnVsRook": 55,  # (67) torre e peão contra torre: ~80%
    "pawnVsKing": 39,  # (47) rei e peão contra rei: ~80%
    "rookVsPawn": 33,  # (41) torre contra peão: ~80%
    "queenVsPawn": 23,  # (27) dama contra peão: ~85%
    "knightBishopVsKing": 41,  # (19) bispo e cavalo: o original era quase o
    # fim do mate; aqui o rei começa no centro, então pede pelo menos 21 lances
}

# Mates de rei sozinho (e dama contra torre): o rei de quem defende começa no
# quadrado central.
CENTER_DEFENDER = {
    "rook",
    "queen",
    "twoBishopsVsKing",
    "queenVsRook",
    "knightBishopVsKing",
}

FILES = "abcdefgh"


def sq(file: int, rank: int) -> int:
    return rank * 8 + file


def coords(square: int) -> tuple[int, int]:
    return square % 8, square // 8


def name(square: int) -> str:
    file, rank = coords(square)
    return f"{FILES[file]}{rank + 1}"


def inner(square: int) -> bool:
    """Fora da borda (colunas b–g, fileiras 2–7)."""
    file, rank = coords(square)
    return 1 <= file <= 6 and 1 <= rank <= 6


def central(square: int) -> bool:
    """No quadrado central (c3–f6)."""
    file, rank = coords(square)
    return 2 <= file <= 5 and 2 <= rank <= 5


# --- Regras mínimas (só o que estas posições de poucas peças precisam) ---

STEPS = {
    "n": [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)],
    "k": [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)],
}
RAYS = {
    "r": [(1, 0), (-1, 0), (0, 1), (0, -1)],
    "b": [(1, 1), (1, -1), (-1, 1), (-1, -1)],
}
RAYS["q"] = RAYS["r"] + RAYS["b"]


def attacks(board: dict, square: int) -> set[int]:
    """As casas que a peça em [square] ataca. [board]: casa -> 'K', 'q'..."""
    piece = board[square]
    kind = piece.lower()
    file, rank = coords(square)
    result = set()
    if kind == "p":
        forward = 1 if piece.isupper() else -1
        for df in (-1, 1):
            f, r = file + df, rank + forward
            if 0 <= f < 8 and 0 <= r < 8:
                result.add(sq(f, r))
    elif kind in STEPS:
        for df, dr in STEPS[kind]:
            f, r = file + df, rank + dr
            if 0 <= f < 8 and 0 <= r < 8:
                result.add(sq(f, r))
    else:
        for df, dr in RAYS[kind]:
            f, r = file + df, rank + dr
            while 0 <= f < 8 and 0 <= r < 8:
                result.add(sq(f, r))
                if sq(f, r) in board:
                    break
                f, r = f + df, r + dr
    return result


def attacked_by(board: dict, white: bool) -> set[int]:
    result = set()
    for square, piece in board.items():
        if piece.isupper() == white:
            result |= attacks(board, square)
    return result


def acceptable(board: dict) -> bool:
    """Legal, brancas a jogar, pretas sem xeque e ninguém pendurado.

    Nenhuma peça (fora os reis) começa atacada pelo outro lado: nem a de quem
    defende (seria captura no primeiro lance) nem a de quem ganha.
    """
    kings = {piece: square for square, piece in board.items() if piece in "Kk"}
    wk, bk = kings["K"], kings["k"]
    if bk in attacks(board, wk):
        return False  # reis encostados
    for square, piece in board.items():
        if piece.lower() == "p" and coords(square)[1] in (0, 7):
            return False
    by_white = attacked_by(board, True)
    by_black = attacked_by(board, False)
    if bk in by_white:
        return False  # quem defende começa em xeque (e as pretas não jogam)
    for square, piece in board.items():
        if piece in "Kk":
            continue
        if piece.islower() and square in by_white:
            return False
        if piece.isupper() and square in by_black:
            return False
    return True


def fen_of(board: dict, white_to_move: bool) -> str:
    rows = []
    for rank in range(7, -1, -1):
        row, empty = "", 0
        for file in range(8):
            piece = board.get(sq(file, rank))
            if piece is None:
                empty += 1
                continue
            if empty:
                row += str(empty)
                empty = 0
            row += piece
        rows.append(row + (str(empty) if empty else ""))
    return f"{'/'.join(rows)} {'w' if white_to_move else 'b'} - - 0 1"


def mirrored(board: dict) -> dict:
    """Espelha na horizontal do meio e troca as cores."""
    return {
        sq(coords(s)[0], 7 - coords(s)[1]): p.swapcase() for s, p in board.items()
    }


def material(fen: str) -> tuple[str, str]:
    """As peças de quem joga e as do outro, sem os reis (ex.: ('R', ''))."""
    placement, turn = fen.split()[:2]
    pieces = [c for c in placement if c.isalpha() and c not in "Kk"]
    white = "".join(sorted(c for c in pieces if c.isupper()))
    black = "".join(sorted(c.upper() for c in pieces if c.islower()))
    return (white, black) if turn == "w" else (black, white)


# --- Sorteio ---


def candidate(rng: random.Random, strong: str, weak: str, subcategory: str):
    """Um tabuleiro com as brancas ganhando: [strong] e [weak] em maiúsculas."""
    board = {}

    def place(piece: str, allowed) -> bool:
        options = [s for s in range(64) if s not in board and allowed(s)]
        if not options:
            return False
        board[rng.choice(options)] = piece
        return True

    if "P" in weak:
        # Peão de quem defende: o tema é o peão avançado. Contra a dama, na
        # 6ª ou 7ª dele (fileiras 3–2); contra a torre, da 4ª à 6ª. O rei dele
        # fica perto (no máximo a duas casas), como no final de verdade.
        ranks = (1, 2) if subcategory == "queenVsPawn" else (2, 3, 4)
        place("p", lambda s: 1 <= coords(s)[0] <= 6 and coords(s)[1] in ranks)
        pawn = next(s for s, p in board.items() if p == "p")

        def defender_area(s):
            return inner(s) and max(
                abs(coords(s)[0] - coords(pawn)[0]),
                abs(coords(s)[1] - coords(pawn)[1]),
            ) <= 2
    else:
        defender_area = central if subcategory in CENTER_DEFENDER else inner
    place("k", defender_area)
    place("K", inner)
    bishops = []
    for piece in strong:
        if piece == "P":
            # Peão de quem ganha: colunas b–g, fileiras 3–5.
            place("P", lambda s: 1 <= coords(s)[0] <= 6 and 2 <= coords(s)[1] <= 4)
        elif piece == "B":
            # Os dois bispos andam em cores diferentes.
            def other_color(s, used=tuple(bishops)):
                return inner(s) and all(
                    sum(coords(s)) % 2 != sum(coords(b)) % 2 for b in used
                )

            place("B", other_color)
            bishops = [s for s, p in board.items() if p == "B"]
        else:
            place(piece, inner)
    for piece in weak:
        if piece != "P":
            place(piece.lower(), inner)
    return board


# --- Tablebase ---


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(json.dumps(cache, indent=0, sort_keys=True), encoding="utf-8")


class Tablebase:
    def __init__(self, offline: bool):
        self.offline = offline
        self.cache = load_cache()
        self.calls = 0

    def probe(self, fen: str) -> dict:
        """{category, dtm, dtz} do ponto de vista de quem joga."""
        if fen in self.cache:
            return self.cache[fen]
        if self.offline:
            raise SystemExit(f"sem cache para {fen} (rode sem --offline)")
        url = TABLEBASE + urllib.parse.quote(fen)
        for attempt in range(6):
            try:
                with urllib.request.urlopen(url, timeout=30) as response:
                    data = json.load(response)
                self.calls += 1
                result = {
                    "category": data.get("category"),
                    "dtm": data.get("dtm"),
                    "dtz": data.get("dtz"),
                }
                self.cache[fen] = result
                if self.calls % 10 == 0:
                    save_cache(self.cache)
                time.sleep(DELAY)
                return result
            except urllib.error.HTTPError as error:
                if error.code == 429:
                    time.sleep(60)
                    continue
                if error.code == 400:
                    # Posição que a tablebase não aceita: conta como inválida.
                    self.cache[fen] = {"category": None, "dtm": None, "dtz": None}
                    return self.cache[fen]
                time.sleep(5 * (attempt + 1))
            except (urllib.error.URLError, TimeoutError):
                time.sleep(5 * (attempt + 1))
        raise SystemExit(f"tablebase indisponível para {fen}")


def good(result: dict, minimum: int) -> bool:
    dtm = result.get("dtm")
    if dtm is None:
        dtm = result.get("dtz")
    return result.get("category") == "win" and dtm is not None and dtm >= minimum


def generate(
    tablebase: Tablebase, speedrun_id: str, origin: dict, rng: random.Random
) -> list[dict]:
    subcategory = origin["subcategory"]
    strong, weak = material(origin["fen"])
    minimum = MIN_DTM[subcategory]
    accepted, seen, tries = [], set(), 0
    while len(accepted) < STAGES:
        tries += 1
        if tries > 20000:
            raise SystemExit(f"{speedrun_id}: não achou {STAGES} posições")
        board = candidate(rng, strong, weak, subcategory)
        if len(board) != 2 + len(strong) + len(weak) or not acceptable(board):
            continue
        fen = fen_of(board, True)
        if fen in seen:
            continue
        seen.add(fen)
        result = tablebase.probe(fen)
        if good(result, minimum):
            accepted.append((result["dtm"] or result["dtz"], fen, board))
    accepted.sort(key=lambda item: (item[0], item[1]))

    stages = []
    for index, (_, fen, board) in enumerate(accepted, start=1):
        if index in BLACK_STAGES:
            fen = fen_of(mirrored(board), False)
        result = tablebase.probe(fen)
        if not good(result, minimum):
            raise SystemExit(f"{speedrun_id}/{index}: espelhada não confere: {fen}")
        if material(fen) != (strong, weak):
            raise SystemExit(f"{speedrun_id}/{index}: material errado: {fen}")
        stage = {
            "id": f"{origin['category']}.{subcategory}.s{index:02d}",
            "fen": fen,
            "goal": origin["goal"],
            "dtm": result["dtm"],
            "dtz": result["dtz"],
            "verified": True,
        }
        if result["dtm"] is not None:
            stage["mateIn"] = (result["dtm"] + 1) // 2
        stages.append(stage)
    print(
        f"{speedrun_id}: DTM {accepted[0][0]}–{accepted[-1][0]} "
        f"(mínimo {minimum}), {len(seen)} sorteadas conferidas"
    )
    return stages


def main() -> int:
    offline = "--offline" in sys.argv
    speedruns = json.loads(SPEEDRUNS.read_text(encoding="utf-8"))["speedruns"]
    positions = {
        p["id"]: p
        for p in json.loads(POSITIONS.read_text(encoding="utf-8"))["positions"]
    }
    tablebase = Tablebase(offline)
    rng = random.Random(SEED)
    output = {}
    try:
        for speedrun in speedruns:
            if speedrun["kind"] != "ending":
                continue
            origin = positions[speedrun["position"]]
            if origin["goal"] != "win":
                raise SystemExit(f"{speedrun['id']}: só finais de ganhar")
            output[speedrun["id"]] = generate(
                tablebase, speedrun["id"], origin, rng
            )
    finally:
        save_cache(tablebase.cache)
    OUTPUT.write_text(
        json.dumps({"speedruns": output}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"{OUTPUT.relative_to(ROOT)}: {len(output)} speedruns")
    print(f"chamadas à tablebase nesta execução: {tablebase.calls}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
