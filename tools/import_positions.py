#!/usr/bin/env python3
"""Importa as posições de finais para `assets/positions/positions.json`.

Fonte: supertorpe/chessendgametraining (GPL-3.0), arquivo
`code/src/static/endgamedatabase.json`. Roda uma vez; o resultado vai versionado.

Passos (PLANO.md, seção 4):
1. Converte o JSON original para o formato do app, com `id` estável
   (`categoria.subcategoria.NNNN`, pela ordem no original) e categoria e
   subcategoria como chaves.
   O app leva só uma seleção de finais de iniciante (cerca de 50, pedido do
   Gabriel em 2026-10-04): os temas típicos de BEGINNER (mates básicos, rei e
   peão contra rei, dama contra torre...), com as posições de menos peças de
   cada um, sem olhar o tamanho do mate, e poucas de empate.
2. Confere as posições de até 7 peças na tablebase do Lichess (com intervalo
   entre chamadas e cache local em `tools/.cache/`). Divergência com o objetivo
   vai para o relatório e sai do catálogo.
3. As de mais de 7 peças (ou com roque) entram com `verified: false`.

Uso: python3 tools/import_positions.py [--offline]
  --offline  não chama a tablebase: usa só o que já está no cache e marca o
             resto como não verificado (para testar o script sem rede).
"""

import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools" / ".cache"
SOURCE_URL = (
    "https://raw.githubusercontent.com/supertorpe/chessendgametraining/"
    "master/code/src/static/endgamedatabase.json"
)
SOURCE = CACHE / "endgamedatabase.json"
TABLEBASE_CACHE = CACHE / "tablebase.json"
OUTPUT = ROOT / "assets" / "positions" / "positions.json"
REPORT = ROOT / "tools" / "import_positions_report.md"
TABLEBASE = "https://tablebase.lichess.ovh/standard?fen="
SOURCE_NAME = "supertorpe/chessendgametraining"

# Finais de iniciante: subcategoria do original -> quantas de ganhar e quantas
# de empatar entram. As outras subcategorias ficam fora do app por enquanto.
BEGINNER = {
    "Queen": (6, 0),
    "Rook": (6, 0),
    "Two Rooks": (6, 0),
    "Pawn vs King": (6, 3),
    "Queen vs Rook": (6, 0),
    "Queen vs Pawn": (5, 0),
    "Rook Pawn vs Rook": (5, 3),
    "Rook vs Pawn": (4, 0),
}

# Intervalo entre chamadas à tablebase (o Lichess limita o uso sem conta).
DELAY = 1.1

# Nome da categoria no original -> chave no app (e na tradução).
CATEGORIES = {
    "Basic": "basic",
    "Pawn": "pawn",
    "Bishop": "bishop",
    "Knight": "knight",
    "Knight-Bishop": "knightBishop",
    "Rook-Pawn": "rookPawn",
    "Rook-Pieces": "rookPieces",
    "Queen": "queen",
}

# O que a tablebase pode dizer (do ponto de vista de quem joga) para cada
# objetivo continuar valendo. "cursed-win" ganha só ignorando a regra dos 50
# lances; "blessed-loss" perde só ignorando-a. O app ainda não aplica a regra:
# ganhar precisa ser "win" de verdade, e segurar não pode ser derrota.
ACCEPTED = {
    "win": {"win"},
    "draw": {"draw", "cursed-win", "win"},
}


def subcategory_key(name: str) -> str:
    """'Two Rooks Pawn vs Two Rooks' -> 'twoRooksPawnVsTwoRooks'."""
    words = re.findall(r"[A-Za-z]+", name)
    return words[0].lower() + "".join(w.capitalize() for w in words[1:])


def piece_count(fen: str) -> int:
    return sum(1 for c in fen.split()[0] if c.isalpha())


def has_castling(fen: str) -> bool:
    return fen.split()[2] != "-"


def select(name: str, games: list[dict]) -> list[tuple[int, dict]]:
    """As posições mais simples de uma subcategoria de BEGINNER, com o número
    de cada uma no original (que vira o fim do id). Ordem: menos peças e, entre
    as de mesmo tamanho, a ordem da fonte."""
    if name not in BEGINNER:
        return []
    wins_wanted, draws_wanted = BEGINNER[name]
    numbered = list(enumerate(games, start=1))

    def simplicity(item: tuple[int, dict]) -> tuple[int, int]:
        index, game = item
        return (piece_count(game["fen"]), index)

    wins = sorted((i for i in numbered if i[1]["target"] == "checkmate"), key=simplicity)
    draws = sorted((i for i in numbered if i[1]["target"] != "checkmate"), key=simplicity)
    chosen = wins[:wins_wanted] + draws[:draws_wanted]
    return sorted(chosen, key=lambda item: item[0])


def load_source() -> dict:
    if not SOURCE.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        print(f"baixando {SOURCE_URL}")
        urllib.request.urlretrieve(SOURCE_URL, SOURCE)
    return json.loads(SOURCE.read_text(encoding="utf-8"))


def load_cache() -> dict:
    if TABLEBASE_CACHE.exists():
        return json.loads(TABLEBASE_CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    TABLEBASE_CACHE.write_text(json.dumps(cache, indent=0), encoding="utf-8")


def tablebase_category(fen: str, cache: dict, offline: bool) -> str | None:
    """A categoria da tablebase (`win`, `draw`, `loss`...). Nulo se não deu."""
    if fen in cache:
        return cache[fen]
    if offline:
        return None
    url = TABLEBASE + urllib.parse.quote(fen.replace(" ", "_"))
    for attempt in range(5):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "lucena-import"})
            with urllib.request.urlopen(request, timeout=30) as response:
                category = json.load(response).get("category")
            time.sleep(DELAY)
            cache[fen] = category
            return category
        except urllib.error.HTTPError as error:
            # Muitas chamadas: espera um minuto, como o Lichess pede.
            wait = 61 if error.code == 429 else 5 * (attempt + 1)
            print(f"  HTTP {error.code}, esperando {wait} s")
            time.sleep(wait)
        except (urllib.error.URLError, TimeoutError) as error:
            print(f"  rede: {error}, tentando de novo")
            time.sleep(5 * (attempt + 1))
    return None


def main() -> int:
    offline = "--offline" in sys.argv
    source = load_source()
    cache = load_cache()
    positions, divergent, unchecked = [], [], 0
    checked_since_save = 0

    for category in source["categories"]:
        category_key = CATEGORIES[category["name"]]
        for subcategory in category["subcategories"]:
            sub_key = subcategory_key(subcategory["name"])
            for index, game in select(subcategory["name"], subcategory["games"]):
                fen = game["fen"].strip()
                goal = "win" if game["target"] == "checkmate" else "draw"
                position = {
                    "id": f"{category_key}.{sub_key}.{index:04d}",
                    "category": category_key,
                    "subcategory": sub_key,
                    "fen": fen,
                    "goal": goal,
                }
                if goal == "win" and game.get("mateIn"):
                    position["mateIn"] = int(game["mateIn"])

                verifiable = piece_count(fen) <= 7 and not has_castling(fen)
                verdict = (
                    tablebase_category(fen, cache, offline) if verifiable else None
                )
                if verifiable and fen in cache:
                    checked_since_save += 1
                    if checked_since_save % 50 == 0:
                        save_cache(cache)
                        print(f"  {len(cache)} posições conferidas")
                if verdict is None:
                    position["verified"] = False
                    unchecked += 1
                elif verdict in ACCEPTED[goal]:
                    position["verified"] = True
                else:
                    divergent.append((position["id"], fen, goal, verdict))
                    continue
                position["source"] = SOURCE_NAME
                positions.append(position)

    save_cache(cache)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(
            {"source": SOURCE_URL, "positions": positions},
            ensure_ascii=False,
            separators=(",", ":"),
        )
        + "\n",
        encoding="utf-8",
    )

    lines = [
        "# Importação das posições",
        "",
        f"Gerado por `tools/import_positions.py` a partir de `{SOURCE_NAME}`.",
        "",
        f"- Posições no catálogo: {len(positions)}",
        f"- Conferidas na tablebase do Lichess: {len(positions) - unchecked}",
        f"- Sem conferência (mais de 7 peças, roque ou tablebase indisponível): {unchecked}",
        f"- Fora do catálogo por divergência com a tablebase: {len(divergent)}",
        "",
    ]
    if divergent:
        lines += [
            "## Divergências",
            "",
            "| id | FEN | objetivo | tablebase |",
            "|---|---|---|---|",
        ]
        lines += [f"| {i} | `{f}` | {g} | {v} |" for i, f, g, v in divergent]
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines[4:8]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
