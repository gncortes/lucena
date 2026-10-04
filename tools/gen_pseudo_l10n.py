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


def _closing(text: str, start: int) -> int:
    """A posição da chave que fecha a aberta em [start]."""
    depth = 0
    for index in range(start, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError(f"chaves desbalanceadas: {text}")


def _padding(text: str) -> str:
    extra = math.ceil(len(text) * GROWTH)
    words = []
    for word in FILLER * 10:
        if extra <= 0:
            break
        words.append(word)
        extra -= len(word) + 1
    return " ".join(words)


PLURAL = re.compile(r"^\s*(\w+)\s*,\s*(plural|select)\s*,(.*)$", re.S)


def _accent(text: str, pad: bool = False) -> str:
    """Acentua o texto fora das chaves. Marcadores (`{count}`) ficam como estão;
    em plural e select (`{count, plural, =1{...} other{...}}`) as palavras-chave
    ficam e só o texto de cada caso muda (com [pad], cada caso ganha o enchimento)."""
    out, index = [], 0
    while index < len(text):
        if text[index] != "{":
            out.append(text[index].translate(ACCENTS))
            index += 1
            continue
        end = _closing(text, index)
        inner = text[index + 1 : end]
        match = PLURAL.match(inner)
        if not match:
            out.append(text[index : end + 1])
        else:
            name, kind, rest = match.groups()
            cases, position = [], 0
            while position < len(rest):
                brace = rest.find("{", position)
                if brace == -1:
                    break
                selector = rest[position:brace].strip()
                close = _closing(rest, brace)
                body = _accent(rest[brace + 1 : close])
                if pad:
                    body = f"[{body} {_padding(body)}]"
                cases.append(f"{selector}{{{body}}}")
                position = close + 1
            out.append(f"{{{name}, {kind}, {' '.join(cases)}}}")
        index = end + 1
    return "".join(out)


def pseudo(text: str) -> str:
    # Mensagem que é um plural inteiro: o enchimento entra em cada caso, para o
    # ICU continuar válido.
    if text.startswith("{") and _closing(text, 0) == len(text) - 1 and PLURAL.match(text[1:-1]):
        return _accent(text, pad=True)
    return f"[{' '.join(filter(None, [_accent(text), _padding(text)]))}]"


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
