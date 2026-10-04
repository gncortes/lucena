"""Carrega o Maia-3 oficial (PyTorch) no ponto exato usado como referência.

Tudo aqui usa o pacote `maia3` do repositório CSSLab/maia3 (ver
requirements.txt) e os pesos do Hugging Face numa revisão fixa, conferidos por
SHA-256. Os outros scripts desta pasta partem daqui.
"""

from __future__ import annotations

import hashlib
from collections import deque
from types import SimpleNamespace

import chess
import torch
from huggingface_hub import hf_hub_download
from maia3.dataset import get_historical_tokens, get_legal_moves_mask, tokenize_board
from maia3.model_registry import resolve_model_spec
from maia3.models import MAIA3Model
from maia3.utils import get_all_possible_moves, mirror_move

MODEL = "maia3-5m"
HF_REPO = "UofTCSSLab/Maia3-5M"
HF_FILE = "maia3-5m.pt"
HF_REVISION = "b6559de2398d7140b985f28fd2c19fb5e47ddabe"
CHECKPOINT_SHA256 = "ba14208b2992d85502f5fb501934abf6aaaeb355e9f3fdf90e326911f562524f"
CODE_COMMIT = "1e13597c42d4858b7cfd7cfdae01e297263364b2"

ALL_MOVES = get_all_possible_moves()
MOVE_INDEX = {move: index for index, move in enumerate(ALL_MOVES)}


def config() -> SimpleNamespace:
    cfg = SimpleNamespace(**resolve_model_spec(MODEL).config)
    cfg.device = "cpu"
    return cfg


def checkpoint_path() -> str:
    path = hf_hub_download(HF_REPO, HF_FILE, revision=HF_REVISION)
    with open(path, "rb") as file:
        digest = hashlib.sha256(file.read()).hexdigest()
    if digest != CHECKPOINT_SHA256:
        raise SystemExit(f"Pesos diferentes do esperado: {digest}")
    return path


def state_dict() -> dict[str, torch.Tensor]:
    """Pesos com os nomes atuais do modelo ("smolgen" virou "gab")."""
    checkpoint = torch.load(checkpoint_path(), map_location="cpu", weights_only=True)
    if isinstance(checkpoint, dict) and "model_state_dict" in checkpoint:
        checkpoint = checkpoint["model_state_dict"]
    return {name.replace("smolgen", "gab"): value for name, value in checkpoint.items()}


def app_state_dict() -> dict[str, torch.Tensor]:
    """Os pesos como vão no app: arredondados para float16 (metade do tamanho)."""
    return {
        name: value.to(torch.float16).to(torch.float32)
        for name, value in state_dict().items()
    }


def load_model(*, as_in_app: bool = False) -> tuple[MAIA3Model, SimpleNamespace]:
    """O modelo oficial; com [as_in_app], com os pesos arredondados do app."""
    cfg = config()
    model = MAIA3Model(cfg)
    weights = app_state_dict() if as_in_app else state_dict()
    missing, unexpected = model.load_state_dict(weights, strict=False)
    if missing or unexpected:
        raise SystemExit(f"Pesos não batem com o modelo: {missing} {unexpected}")
    model.eval()
    return model, cfg


def replay(fen: str, moves: list[str]) -> tuple[chess.Board, deque]:
    """Posição final e histórico de tokens, como o `--use-uci-history` oficial."""
    cfg = config()
    board = chess.Board(fen)
    history = deque(maxlen=cfg.history)
    history.append(tokenize_board(board))
    for uci in moves:
        move = chess.Move.from_uci(uci)
        if move not in board.legal_moves:
            raise SystemExit(f"Lance ilegal {uci} em {board.fen()}")
        board.push(move)
        history.append(tokenize_board(board))
    return board, history


def tokens_for(history: deque, cfg: SimpleNamespace) -> torch.Tensor:
    return get_historical_tokens(
        history, cfg, base=0.0, inc=0.0, clk_left_before=0.0, clk_ponder=0.0
    )


@torch.no_grad()
def evaluate(model, cfg, fen: str, moves: list[str], self_elo: int, oppo_elo: int) -> dict:
    """Roda o modelo oficial e devolve as saídas já no ponto de vista do tabuleiro."""
    board, history = replay(fen, moves)
    tokens = tokens_for(history, cfg).unsqueeze(0)
    logits_move, logits_value, ponder = model(
        tokens,
        torch.tensor([self_elo], dtype=torch.long),
        torch.tensor([oppo_elo], dtype=torch.long),
    )
    mask = get_legal_moves_mask(board, MOVE_INDEX)
    logits = logits_move[0].float().masked_fill(~mask, float("-inf"))
    probs = torch.softmax(logits, dim=-1)

    policy = {}
    for move in board.legal_moves:
        uci = move.uci()
        index = MOVE_INDEX[uci if board.turn == chess.WHITE else mirror_move(uci)]
        policy[uci] = float(probs[index])
    loss, draw, win = torch.softmax(logits_value[0].float(), dim=-1).tolist()
    return {
        "position": board.fen(),
        "policy": dict(sorted(policy.items(), key=lambda item: -item[1])),
        "value": {"win": win, "draw": draw, "loss": loss},
        "ponder": float(ponder[0]),
    }
