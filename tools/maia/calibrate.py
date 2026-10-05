"""Mede como o Maia joga os finais do catálogo em cada nível e temperatura.

Uso (na raiz do repositório, com o ambiente de tools/maia/requirements.txt):
    venv/bin/python tools/maia/calibrate.py --syzygy <pasta> --stockfish <binário>

Precisa das tablebases Syzygy de 3 a 5 peças (só os arquivos .rtbw, 380 MB, de
https://tablebase.lichess.ovh/tables/standard/3-4-5-wdl/) e de um Stockfish.
Nada disso vai para o app: são só os juízes da medição.

São duas medições, com o modelo oficial e os pesos do app (os mesmos das
fixtures), sorteando o lance como o `PickHumanMove`:

- `self`: o Maia joga os dois lados de cada posição do catálogo. Mostra se ele
  cumpre o objetivo da posição (ganhar ou empatar) e com que frequência joga
  fora um resultado, para comparar com o que o próprio modelo prevê para
  pessoas daquele rating.
- `user`: o Stockfish faz o papel do jogador que não erra e o Maia é o
  adversário, como no app. Mostra quanto o Maia resiste.

O resultado de cada lance vem da tablebase, então "jogar fora" é exato: o
lance troca vitória por empate ou derrota, ou empate por derrota.

Saída: docs/calibracao-dados.json, a base de docs/calibracao.md.
"""

from __future__ import annotations

import argparse
import json
import math
import queue
import random
import statistics
import time
from collections import defaultdict, deque
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path

import chess
import chess.engine
import chess.syzygy
import torch
from maia3.dataset import get_legal_moves_mask, tokenize_board
from maia3.utils import mirror_move

import reference

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "assets" / "positions" / "positions.json"
OUTPUT = ROOT / "docs" / "calibracao-dados.json"

LEVELS = [1000, 1200, 1400, 1600, 1800, 2000, 2200, 2400, 2600]
TEMPERATURES = [0.0, 0.25, 0.5, 0.75, 1.0]
MAX_PLIES = 300
BATCH = 512
# Mesmos números do `ThinkTimePolicy.human`.
OBVIOUS = 0.85


class Judge:
    """O resultado exato de uma posição, do ponto de vista de quem joga."""

    def __init__(self, path: str):
        self._tables = chess.syzygy.open_tablebase(path)
        self._cache: dict[str, int] = {}

    def result(self, board: chess.Board) -> int:
        """1 vitória, 0 empate, -1 derrota (com a regra dos 50 lances)."""
        if board.is_checkmate():
            return -1
        if board.is_stalemate() or board.is_insufficient_material():
            return 0
        key = board.epd()
        cached = self._cache.get(key)
        if cached is None:
            wdl = self._tables.probe_wdl(board)
            cached = 1 if wdl == 2 else -1 if wdl == -2 else 0
            self._cache[key] = cached
        return cached

    def after(self, board: chess.Board, move: chess.Move) -> int:
        """O resultado para quem joga depois de fazer [move]."""
        board.push(move)
        try:
            return -self.result(board)
        finally:
            board.pop()


@dataclass(eq=False)
class Game:
    position: dict
    level: int
    temperature: float
    mode: str  # "self" ou "user"
    board: chess.Board
    goal_side: chess.Color
    history: deque
    outcome: str | None = None  # "win", "draw" ou "loss" para o lado do objetivo
    moves: list[dict] = field(default_factory=list)

    def maia_to_move(self) -> bool:
        return self.mode == "self" or self.board.turn != self.goal_side

    def push(self, move: chess.Move) -> None:
        self.board.push(move)
        self.history.append(tokenize_board(self.board))
        board = self.board
        if board.is_checkmate():
            self.outcome = "loss" if board.turn == self.goal_side else "win"
        elif (
            board.is_stalemate()
            or board.is_insufficient_material()
            or board.is_fifty_moves()
            or board.is_repetition(3)
            or board.ply() >= MAX_PLIES
        ):
            self.outcome = "draw"

    @property
    def achieved(self) -> bool:
        if self.position["goal"] == "win":
            return self.outcome == "win"
        return self.outcome != "loss"


def new_game(position: dict, level: int, temperature: float, mode: str, cfg) -> Game:
    board = chess.Board(position["fen"])
    history = deque(maxlen=cfg.history)
    history.append(tokenize_board(board))
    return Game(position, level, temperature, mode, board, board.turn, history)


def pick(policy: dict[chess.Move, float], temperature: float, roll: float) -> chess.Move:
    """O mesmo sorteio do `PickHumanMove` do app."""
    best = max(policy, key=policy.get)
    if temperature <= 0:
        return best
    weights = {move: p ** (1 / temperature) for move, p in policy.items()}
    threshold = roll * sum(weights.values())
    for move, weight in weights.items():
        threshold -= weight
        if threshold < 0:
            return move
    return best


def tempered(policy: dict[chess.Move, float], temperature: float) -> dict[chess.Move, float]:
    if temperature <= 0:
        best = max(policy, key=policy.get)
        return {move: 1.0 if move == best else 0.0 for move in policy}
    weights = {move: p ** (1 / temperature) for move, p in policy.items()}
    total = sum(weights.values())
    return {move: weight / total for move, weight in weights.items()}


@torch.no_grad()
def maia_moves(model, cfg, games: list[Game], judge: Judge, rng: random.Random) -> None:
    tokens = torch.stack([reference.tokens_for(game.history, cfg) for game in games])
    elos = torch.tensor([game.level for game in games], dtype=torch.long)
    logits_move, logits_value, ponder = model(tokens, elos, elos)
    for index, game in enumerate(games):
        board = game.board
        mask = get_legal_moves_mask(board, reference.MOVE_INDEX)
        probs = torch.softmax(logits_move[index].float().masked_fill(~mask, float("-inf")), dim=-1)
        policy = {}
        for move in board.legal_moves:
            uci = move.uci()
            policy[move] = float(
                probs[reference.MOVE_INDEX[uci if board.turn == chess.WHITE else mirror_move(uci)]]
            )
        policy = dict(sorted(policy.items(), key=lambda item: -item[1]))
        move = pick(policy, game.temperature, rng.random())

        before = judge.result(board)
        after = {candidate: judge.after(board, candidate) for candidate in policy}
        chances = tempered(policy, game.temperature)
        loss, draw, win = torch.softmax(logits_value[index].float(), dim=-1).tolist()
        game.moves.append(
            {
                "goalSide": board.turn == game.goal_side,
                "before": before,
                "dropped": after[move] < before,
                # A chance de jogar fora o resultado neste lance, já com a temperatura.
                "dropChance": sum(chances[m] for m in policy if after[m] < before),
                "certainty": policy[move],
                "top": next(iter(policy.values())),
                "entropy": -sum(p * math.log(p) for p in policy.values() if p > 0),
                "legal": len(policy),
                "loneKing": chess.popcount(board.occupied_co[board.turn]) == 1,
                "ponder": float(ponder[index]),
                "predictedWin": win,
                "predictedDraw": draw,
            }
        )
        game.push(move)


def user_moves(games: list[Game], engines: queue.Queue, pool: ThreadPoolExecutor, seconds: float) -> None:
    def play(game: Game) -> None:
        engine = engines.get()
        try:
            move = engine.play(game.board, chess.engine.Limit(time=seconds)).move
        finally:
            engines.put(engine)
        game.push(move)

    list(pool.map(play, games))


def run(games: list[Game], model, cfg, judge: Judge, engines, pool, rng, seconds: float) -> None:
    active = games
    started = time.time()
    rounds = 0
    while active:
        maia = [game for game in active if game.maia_to_move()]
        user = [game for game in active if not game.maia_to_move()]
        for start in range(0, len(maia), BATCH):
            maia_moves(model, cfg, maia[start : start + BATCH], judge, rng)
        if user:
            user_moves(user, engines, pool, seconds)
        active = [game for game in active if game.outcome is None]
        rounds += 1
        if rounds % 10 == 0:
            print(f"  lance {rounds}: {len(active)} partidas em jogo ({time.time() - started:.0f} s)", flush=True)


def mean(values) -> float | None:
    values = list(values)
    return sum(values) / len(values) if values else None


def summarize_self(games: list[Game]) -> list[dict]:
    """Por nível e temperatura: o Maia contra ele mesmo."""
    rows = []
    groups = defaultdict(list)
    for game in games:
        groups[(game.level, game.temperature)].append(game)
    for (level, temperature), group in sorted(groups.items()):
        row = {"level": level, "temperature": temperature, "games": len(group)}
        for goal in ("win", "draw"):
            of_goal = [game for game in group if game.position["goal"] == goal]
            row[f"{goal}Achieved"] = mean(game.achieved for game in of_goal)
            # O que o modelo prevê para pessoas desse rating na posição inicial.
            first = [game.moves[0] for game in of_goal if game.moves]
            row[f"{goal}Predicted"] = mean(
                move["predictedWin"] if goal == "win" else move["predictedWin"] + move["predictedDraw"]
                for move in first
            )
        moves = [move for game in group for move in game.moves]
        winning = [move for move in moves if move["before"] == 1]
        drawing = [move for move in moves if move["before"] == 0]
        row["winningMoves"] = len(winning)
        row["winDropRate"] = mean(move["dropped"] for move in winning)
        row["winDropChance"] = mean(move["dropChance"] for move in winning)
        row["drawingMoves"] = len(drawing)
        row["drawDropRate"] = mean(move["dropped"] for move in drawing)
        row["drawDropChance"] = mean(move["dropChance"] for move in drawing)
        rows.append(row)
    return rows


def summarize_self_by_family(games: list[Game]) -> list[dict]:
    """Por subcategoria, nível e temperatura: objetivo cumprido contra o previsto."""
    groups = defaultdict(list)
    for game in games:
        position = game.position
        family = f"{position['category']}.{position['subcategory']}"
        groups[(family, position["goal"], game.level, game.temperature)].append(game)
    rows = []
    for (family, goal, level, temperature), group in sorted(groups.items()):
        first = [game.moves[0] for game in group if game.moves]
        rows.append(
            {
                "family": family,
                "goal": goal,
                "level": level,
                "temperature": temperature,
                "games": len(group),
                "achieved": mean(game.achieved for game in group),
                "predicted": mean(
                    move["predictedWin"] if goal == "win" else move["predictedWin"] + move["predictedDraw"]
                    for move in first
                ),
            }
        )
    return rows


def think_share(certainty: float) -> float:
    """A fatia do tempo disponível que o `ThinkTimePolicy.human` usa, sem o sorteio."""
    if certainty >= OBVIOUS:
        return 0.0
    return 0.35 + 0.65 * (1 - certainty / OBVIOUS)


def summarize_user(games: list[Game]) -> list[dict]:
    """Por nível e temperatura: o Maia contra um jogador que não erra."""
    groups = defaultdict(list)
    for game in games:
        groups[(game.level, game.temperature)].append(game)

    def resistance(of: list[Game]) -> list[float]:
        # Lances do jogador até o mate, em relação ao mínimo possível.
        return [
            ((game.board.ply() + 1) // 2) / game.position["mateIn"]
            for game in of
            if game.outcome == "win" and game.position.get("mateIn")
        ]

    def median(values: list[float]) -> float | None:
        return statistics.median(values) if values else None

    rows = []
    for (level, temperature), group in sorted(groups.items()):
        to_win = [game for game in group if game.position["goal"] == "win"]
        to_hold = [game for game in group if game.position["goal"] == "draw"]
        # O Maia só com o rei, ou com peças para se defender.
        lone = [g for g in to_win if chess.popcount(chess.Board(g.position["fen"]).occupied_co[not g.goal_side]) == 1]
        armed = [g for g in to_win if g not in lone]
        rows.append(
            {
                "level": level,
                "temperature": temperature,
                "games": len(group),
                "won": mean(game.outcome == "win" for game in to_win),
                "held": mean(game.outcome != "loss" for game in to_hold),
                "resistanceMedian": median(resistance(to_win)),
                "loneKingGames": len(lone),
                "loneKingWon": mean(game.outcome == "win" for game in lone),
                "loneKingResistanceMedian": median(resistance(lone)),
                "armedGames": len(armed),
                "armedWon": mean(game.outcome == "win" for game in armed),
                "armedResistanceMedian": median(resistance(armed)),
                "maiaMoves": sum(len(game.moves) for game in group),
            }
        )
    return rows


def correlation(xs: list[float], ys: list[float]) -> float | None:
    """Correlação de postos (Spearman)."""
    if len(xs) < 3:
        return None

    def ranks(values):
        order = sorted(range(len(values)), key=values.__getitem__)
        result = [0.0] * len(values)
        index = 0
        while index < len(order):
            end = index
            while end + 1 < len(order) and values[order[end + 1]] == values[order[index]]:
                end += 1
            for position in range(index, end + 1):
                result[order[position]] = (index + end) / 2
            index = end + 1
        return result

    rx, ry = ranks(xs), ranks(ys)
    mx, my = sum(rx) / len(rx), sum(ry) / len(ry)
    cov = sum((a - mx) * (b - my) for a, b in zip(rx, ry))
    vx = sum((a - mx) ** 2 for a in rx)
    vy = sum((b - my) ** 2 for b in ry)
    return cov / math.sqrt(vx * vy) if vx > 0 and vy > 0 else None


def summarize_think(games: list[Game]) -> list[dict]:
    """Por nível: o que o `ThinkTimePolicy.human` recebe do Maia como adversário."""
    groups = defaultdict(list)
    for game in games:
        groups[game.level].extend(game.moves)
    rows = []
    for level, moves in sorted(groups.items()):
        lone = [move for move in moves if move["loneKing"]]
        rest = [move for move in moves if not move["loneKing"]]
        rows.append(
            {
                "level": level,
                "moves": len(moves),
                "obvious": mean(move["certainty"] >= OBVIOUS for move in moves),
                "certaintyMedian": statistics.median(move["certainty"] for move in moves),
                "loneKingMoves": len(lone),
                "loneKingCertaintyMedian": statistics.median(m["certainty"] for m in lone) if lone else None,
                "loneKingObvious": mean(move["certainty"] >= OBVIOUS for move in lone),
                "otherCertaintyMedian": statistics.median(m["certainty"] for m in rest) if rest else None,
                # Fatia do tempo disponível que a regra do app usa em cada lance.
                "thinkShareMean": mean(think_share(move["certainty"]) for move in moves),
                "thinkShareMedian": statistics.median(think_share(move["certainty"]) for move in moves),
                "ponderMedian": statistics.median(move["ponder"] for move in moves),
                "ponderLoneKingMedian": statistics.median(m["ponder"] for m in lone) if lone else None,
                "ponderOtherMedian": statistics.median(m["ponder"] for m in rest) if rest else None,
                "ponderVsEntropy": correlation(
                    [move["ponder"] for move in moves], [move["entropy"] for move in moves]
                ),
                "ponderVsDoubt": correlation(
                    [move["ponder"] for move in moves], [1 - move["certainty"] for move in moves]
                ),
            }
        )
    return rows


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--syzygy", required=True)
    parser.add_argument("--stockfish", required=True)
    parser.add_argument("--self-games", type=int, default=8, help="partidas por posição, nível e temperatura")
    parser.add_argument("--user-games", type=int, default=4)
    parser.add_argument("--engines", type=int, default=12)
    parser.add_argument("--engine-seconds", type=float, default=0.05)
    parser.add_argument("--levels", type=int, nargs="*", default=LEVELS)
    parser.add_argument("--temperatures", type=float, nargs="*", default=TEMPERATURES)
    parser.add_argument("--limit", type=int, default=0, help="só as N primeiras posições (teste)")
    parser.add_argument("--seed", type=int, default=19)
    parser.add_argument("--output", default=str(OUTPUT))
    args = parser.parse_args()

    positions = json.loads(CATALOG.read_text())["positions"]
    if args.limit:
        positions = positions[: args.limit]
    model, cfg = reference.load_model(as_in_app=True)
    judge = Judge(args.syzygy)
    rng = random.Random(args.seed)

    def games_for(mode: str, count: int) -> list[Game]:
        return [
            new_game(position, level, temperature, mode, cfg)
            for position in positions
            for level in args.levels
            for temperature in args.temperatures
            # Sem sorteio (temperatura 0), toda partida sai igual.
            for _ in range(1 if temperature <= 0 else count)
        ]

    engines: queue.Queue = queue.Queue()
    for _ in range(args.engines):
        engine = chess.engine.SimpleEngine.popen_uci(args.stockfish)
        engine.configure({"Threads": 1, "Hash": 16})
        engines.put(engine)

    try:
        with ThreadPoolExecutor(args.engines) as pool:
            self_games = games_for("self", args.self_games)
            print(f"Maia contra Maia: {len(self_games)} partidas", flush=True)
            run(self_games, model, cfg, judge, engines, pool, rng, args.engine_seconds)

            user_games = games_for("user", args.user_games)
            print(f"Jogador perfeito contra Maia: {len(user_games)} partidas", flush=True)
            run(user_games, model, cfg, judge, engines, pool, rng, args.engine_seconds)
    finally:
        while not engines.empty():
            engines.get().quit()

    summary = {
        "model": reference.MODEL,
        "checkpoint": reference.CHECKPOINT_SHA256,
        "weights": "float16",
        "seed": args.seed,
        "positions": len(positions),
        "selfGames": args.self_games,
        "userGames": args.user_games,
        "self": summarize_self(self_games),
        "selfByFamily": summarize_self_by_family(self_games),
        "user": summarize_user(user_games),
        "think": summarize_think(user_games),
    }
    Path(args.output).write_text(json.dumps(summary, indent=1, ensure_ascii=False) + "\n")
    print(f"{args.output}: {len(self_games) + len(user_games)} partidas")


if __name__ == "__main__":
    main()
