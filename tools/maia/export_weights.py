"""Converte os pesos oficiais do Maia-3 para o formato lido pelo app.

Uso (na raiz do repositório, com o ambiente de tools/maia/requirements.txt):
    venv/bin/python tools/maia/export_weights.py

Formato de assets/models/maia3-5m.bin (tudo little-endian):
    bytes 0..3   "LMW1"
    bytes 4..7   tamanho N do cabeçalho (uint32)
    N bytes      cabeçalho JSON: origem, configuração e, por tensor, nome,
                 formato e posição (em valores) dentro dos dados
    resto        todos os tensores em float16, um depois do outro, cada um
                 começando num múltiplo de 4 valores

Os pesos oficiais são float32. Em float16 o arquivo cai de 21 MB para 10,5 MB
e as probabilidades mudam menos de 0,001 (make_fixtures.py confere isso).

O checkpoint repete a mesma matriz do GAB em cada camada; aqui ela é gravada
uma vez só.
"""

from __future__ import annotations

import json
import struct
from pathlib import Path

import numpy as np
import torch

import reference

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets" / "models" / "maia3-5m.bin"

SHARED = "gab_shared_weight"


def main() -> None:
    state = reference.state_dict()
    cfg = reference.config()

    tensors = {}
    for name, value in state.items():
        if name.endswith("self_attn.gab_weight"):
            if not torch.equal(value, state[SHARED]):
                raise SystemExit(f"{name} difere de {SHARED}")
            continue
        tensors[name] = value.to(torch.float16).numpy()

    # Cada tensor começa num múltiplo de 4 valores, para o app poder
    # percorrê-lo de 4 em 4 (Float32x4) depois de convertido para float32.
    entries = []
    offset = 0
    for name, value in tensors.items():
        entries.append({"name": name, "shape": list(value.shape), "offset": offset})
        offset += value.size + (-value.size % 4)

    header = json.dumps(
        {
            "model": reference.MODEL,
            "source": f"https://huggingface.co/{reference.HF_REPO}/blob/{reference.HF_REVISION}/{reference.HF_FILE}",
            "sha256": reference.CHECKPOINT_SHA256,
            "dtype": "float16",
            "config": {
                "history": cfg.history,
                "dimEmb": cfg.dim_emb,
                "dim": cfg.dim_vit,
                "blocks": cfg.num_blocks,
                "heads": cfg.num_heads,
                "headDim": cfg.head_hid_dim,
                "gabGenSize": cfg.gab_gen_size,
                "gabIntermediateDim": cfg.gab_intermediate_dim,
            },
            "tensors": entries,
        },
        separators=(",", ":"),
    ).encode()
    header += b" " * (-(8 + len(header)) % 2)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, "wb") as file:
        file.write(b"LMW1")
        file.write(struct.pack("<I", len(header)))
        file.write(header)
        for value in tensors.values():
            file.write(np.ascontiguousarray(value, dtype="<f2").tobytes())
            file.write(b"\0" * (2 * (-value.size % 4)))
    print(f"{len(entries)} tensores, {offset} valores, {OUTPUT.stat().st_size} bytes")


if __name__ == "__main__":
    main()
