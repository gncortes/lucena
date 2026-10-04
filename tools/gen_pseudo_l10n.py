#!/usr/bin/env python3
"""Gera o pseudo-idioma de teste (`app_en_XA.arb`) a partir do inglês.

Cada texto ganha acentos e fica ~40% mais longo, para o layout quebrar nos
testes antes de quebrar em alemão ou russo. O que está entre chaves (`{count}`)
não é alterado.

Uso: python3 tools/gen_pseudo_l10n.py [raiz do projeto]
"""

import json
import math
import re
import sys
from pathlib import Path

ACCENTS = str.maketrans(
    "aceginorsuyzACEGINORSUYZ",
    "åçéĝîñöŕšûýžÅÇÉĜÎÑÖŔŠÛÝŽ",
)
FILLER = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
GROWTH = 0.4


def pseudo(text: str) -> str:
    # Mantém os marcadores ICU ({count}, {name}) como estão.
    parts = re.split(r"(\{[^{}]*\})", text)
    accented = "".join(p if p.startswith("{") else p.translate(ACCENTS) for p in parts)
    extra = math.ceil(len(text) * GROWTH)
    padding = []
    for word in FILLER * 10:
        if extra <= 0:
            break
        padding.append(word)
        extra -= len(word) + 1
    return f"[{' '.join([accented, *padding])}]"


def generate(base: dict) -> dict:
    result = {"@@locale": "en_XA"}
    for key, value in base.items():
        if not key.startswith("@"):
            result[key] = pseudo(value)
    return result


def render(root: Path) -> str:
    base = json.loads((root / "lib" / "l10n" / "app_en.arb").read_text(encoding="utf-8"))
    return json.dumps(generate(base), indent=2, ensure_ascii=False) + "\n"


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
    target = root / "lib" / "l10n" / "app_en_XA.arb"
    target.write_text(render(root), encoding="utf-8")
    print(f"Gerado {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
