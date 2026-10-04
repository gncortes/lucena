"""Gera test/fixtures/maia/reference.json com as saídas do Maia-3 oficial.

Uso (na raiz do repositório, com o ambiente de tools/maia/requirements.txt):
    venv/bin/python tools/maia/make_fixtures.py

Cada caso guarda a posição inicial (FEN), os lances jogados a partir dela (o
histórico que o modelo recebe), os ratings e as saídas do PyTorch: a
probabilidade de cada lance legal (temperatura 1), a previsão de resultado e a
saída bruta da cabeça de tempo.

As saídas vêm do código oficial com os pesos do app (os oficiais arredondados
para float16, ver export_weights.py). O script confere que esse arredondamento
não troca o lance mais provável de nenhum caso nem muda uma probabilidade em
mais de MAX_ROUNDING_DEVIATION em relação aos pesos oficiais.
"""

from __future__ import annotations

import json
from pathlib import Path

import chess
import torch

import reference

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "test" / "fixtures" / "maia" / "reference.json"

START = chess.STARTING_FEN
MAX_ROUNDING_DEVIATION = 0.002
LEVELS = [1000, 1400, 1800, 2200, 2600]
SAME = [(level, level) for level in LEVELS]

# (nome, FEN inicial, lances a partir dele, pares de rating (quem joga, oponente))
CASES = [
    ("start", START, [], SAME + [(1000, 2600), (2600, 1000)]),
    ("ruy-lopez-black-to-move", START, "e2e4 e7e5 g1f3 b8c6 f1b5".split(), [(1400, 1400)]),
    (
        "italian-long-history",
        START,
        "e2e4 e7e5 g1f3 b8c6 f1c4 f8c5 c2c3 g8f6 d2d3 d7d6 e1g1 e8g8".split(),
        [(1000, 1000), (1800, 1800), (2600, 2600)],
    ),
    (
        "castling-white",
        "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4",
        [],
        [(1400, 1400)],
    ),
    (
        "castling-black",
        "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4",
        ["e1g1"],
        [(1400, 1400)],
    ),
    (
        "castling-queenside",
        "r3kbnr/ppp1pppp/2nq4/3p1b2/3P1B2/2NQ4/PPP1PPPP/R3KBNR w KQkq - 6 5",
        [],
        [(1800, 1800)],
    ),
    (
        "en-passant",
        "rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3",
        [],
        [(1400, 1400)],
    ),
    ("promotion-white", "8/4P1k1/8/8/8/8/6K1/8 w - - 0 1", [], [(1000, 1000), (2200, 2200)]),
    ("promotion-capture-white", "3r4/4P1k1/8/8/8/8/6K1/8 w - - 0 1", [], [(1400, 1400)]),
    ("promotion-black", "8/6k1/8/8/8/8/4p1K1/8 b - - 0 1", [], [(1000, 1000), (2200, 2200)]),
    ("promotion-capture-black", "8/6k1/8/8/8/8/4p1K1/3R4 b - - 0 1", [], [(1400, 1400)]),
    ("queen-mate", "8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1", [], SAME),
    (
        "queen-mate-played",
        "8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1",
        "c1g5 d7c6 c2c3 c6d6 c3d4".split(),
        [(1000, 1000), (1800, 1800), (2600, 2600)],
    ),
    ("rook-mate", "8/8/8/4k3/8/8/8/R3K3 w - - 0 1", [], SAME),
    (
        "rook-mate-defender",
        "8/8/8/4k3/8/8/8/R3K3 w - - 0 1",
        ["a1a4"],
        [(1000, 2600), (1800, 1800), (2600, 1000)],
    ),
    ("two-rooks", "8/8/3k4/8/8/8/8/RR2K3 w - - 0 1", [], [(1000, 1000), (1800, 1800)]),
    ("pawn-vs-king", "8/8/8/4k3/8/4K3/4P3/8 w - - 0 1", [], SAME),
    ("pawn-vs-king-defender", "8/8/8/4k3/8/4K3/4P3/8 b - - 0 1", [], SAME),
    ("queen-vs-rook", "1rk5/4Q3/K7/8/8/8/8/8 w - - 0 1", [], [(1400, 1400), (2200, 2200)]),
    ("lucena", "1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1", [], SAME),
    ("philidor-defender", "4k3/8/8/4PK2/8/8/r7/7R b - - 0 1", [], SAME),
    (
        "rook-ending-played",
        "4k3/8/8/4PK2/8/8/r7/7R b - - 0 1",
        "a2a6 h1h8 e8e7 h8h7 e7e8 e5e6 a6a1 f5f6 a1f1".split(),
        [(1400, 1400), (2200, 2200)],
    ),
    ("queen-vs-pawn", "8/8/K7/8/8/5p2/6k1/Q7 w - - 0 1", [], [(1400, 1400)]),
    (
        "middlegame",
        "r2q1rk1/pp2bppp/2n1bn2/3p4/3P4/2NBBN2/PP3PPP/R2Q1RK1 w - - 4 11",
        [],
        [(1000, 1000), (1800, 1800), (2600, 2600)],
    ),
]


def rounded(values: dict[str, float], digits: int = 7) -> dict[str, float]:
    return {key: round(value, digits) for key, value in values.items()}


def main() -> None:
    torch.manual_seed(0)
    official, cfg = reference.load_model()
    model, _ = reference.load_model(as_in_app=True)
    cases = []
    deviation = 0.0
    for name, fen, moves, ratings in CASES:
        if not chess.Board(fen).is_valid():
            raise SystemExit(f"Posição impossível em {name}: {fen}")
        for self_elo, oppo_elo in ratings:
            out = reference.evaluate(model, cfg, fen, moves, self_elo, oppo_elo)
            exact = reference.evaluate(official, cfg, fen, moves, self_elo, oppo_elo)
            if next(iter(out["policy"])) != next(iter(exact["policy"])):
                raise SystemExit(f"O arredondamento trocou o melhor lance em {name}")
            deviation = max(
                deviation,
                max(abs(out["policy"][move] - exact["policy"][move]) for move in exact["policy"]),
            )
            cases.append(
                {
                    "name": f"{name}@{self_elo}v{oppo_elo}",
                    "fen": fen,
                    "moves": moves,
                    "selfElo": self_elo,
                    "oppoElo": oppo_elo,
                    "position": out["position"],
                    "best": next(iter(out["policy"])),
                    "policy": rounded(out["policy"]),
                    "value": rounded(out["value"]),
                    "ponder": round(out["ponder"], 5),
                }
            )
    if deviation > MAX_ROUNDING_DEVIATION:
        raise SystemExit(f"O arredondamento mudou uma probabilidade em {deviation}")
    document = {
        "model": reference.MODEL,
        "weights": {
            "repo": reference.HF_REPO,
            "file": reference.HF_FILE,
            "revision": reference.HF_REVISION,
            "sha256": reference.CHECKPOINT_SHA256,
            "rounding": "float16",
            "maxDeviationFromOfficial": round(deviation, 7),
        },
        "code": f"https://github.com/CSSLab/maia3/tree/{reference.CODE_COMMIT}",
        "torch": torch.__version__,
        "cases": cases,
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(document, indent=1) + "\n")
    print(f"{len(cases)} casos em {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
