"""Spike da T15: exporta o Maia-3 para ONNX e compara com o PyTorch.

Uso (na raiz do repositório, com o ambiente de tools/maia/requirements.txt):
    venv/bin/python tools/maia/export_onnx.py <pasta de saída>

Serve só para a decisão registrada em docs/decisao-maia-runtime.md: o app não
usa o arquivo gerado.
"""

from __future__ import annotations

import sys
import time
from pathlib import Path

import numpy as np
import onnxruntime
import torch

import reference
from make_fixtures import CASES


class ExportableRmsNorm(torch.nn.Module):
    """Mesma conta do torch.nn.RMSNorm, que o exportador clássico não conhece."""

    def __init__(self, norm: torch.nn.RMSNorm):
        super().__init__()
        self.weight = norm.weight
        self.eps = norm.eps if norm.eps is not None else torch.finfo(torch.float32).eps

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return x * torch.rsqrt(x.pow(2).mean(dim=-1, keepdim=True) + self.eps) * self.weight


def exportable(model: torch.nn.Module) -> torch.nn.Module:
    for block in model.transformer.layers:
        block.norm1 = ExportableRmsNorm(block.norm1)
        block.norm2 = ExportableRmsNorm(block.norm2)
    return model


def main() -> None:
    output = Path(sys.argv[1]) / "maia3-5m.onnx"
    output.parent.mkdir(parents=True, exist_ok=True)
    model, cfg = reference.load_model()
    patched = exportable(reference.load_model()[0])

    _, history = reference.replay(CASES[0][1], [])
    tokens = reference.tokens_for(history, cfg).unsqueeze(0)
    elo = torch.tensor([1500], dtype=torch.long)
    torch.onnx.export(
        patched,
        (tokens, elo, elo),
        str(output),
        input_names=["tokens", "self_elo", "oppo_elo"],
        output_names=["policy", "value", "ponder"],
        # O exportador novo (dynamo) falha na atenção do PyTorch 2.14.
        dynamo=False,
        opset_version=17,
    )
    print(f"{output} ({output.stat().st_size} bytes)")

    options = onnxruntime.SessionOptions()
    options.intra_op_num_threads = 1
    session = onnxruntime.InferenceSession(str(output), options)
    worst = 0.0
    elapsed = []
    for _, fen, moves, ratings in CASES:
        _, history = reference.replay(fen, moves)
        tokens = reference.tokens_for(history, cfg).unsqueeze(0)
        for self_elo, oppo_elo in ratings:
            with torch.no_grad():
                expected = model(
                    tokens,
                    torch.tensor([self_elo], dtype=torch.long),
                    torch.tensor([oppo_elo], dtype=torch.long),
                )
            start = time.perf_counter()
            got = session.run(
                None,
                {
                    "tokens": tokens.numpy(),
                    "self_elo": np.array([self_elo], dtype=np.int64),
                    "oppo_elo": np.array([oppo_elo], dtype=np.int64),
                },
            )
            elapsed.append(time.perf_counter() - start)
            for want, have in zip(expected, got):
                worst = max(worst, float(np.abs(want.numpy() - have).max()))
    print(f"maior diferença nas saídas brutas: {worst:.2e}")
    print(f"onnxruntime, 1 thread, mediana: {1000 * sorted(elapsed)[len(elapsed) // 2]:.1f} ms")


if __name__ == "__main__":
    main()
