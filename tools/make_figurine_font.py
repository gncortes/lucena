#!/usr/bin/env python3
"""Gera a fonte de figurinos (`assets/fonts/LucenaFigurine.ttf`).

A lista de lances mostra a peça como um desenho (♘f3) que vale em qualquer
idioma. Os desenhos vêm da Noto Sans Symbols 2 (SIL Open Font License 1.1),
reduzida aqui às doze peças de xadrez (U+2654 a U+265F): a fonte inteira tem
650 KB, o recorte fica com poucos KB. Assim o figurino tem a cor e a linha de
base do texto em qualquer aparelho, sem depender das fontes do sistema.

Roda uma vez; o resultado vai versionado. Precisa do `fonttools`
(`pip install fonttools`).

Uso: python3 tools/make_figurine_font.py <NotoSansSymbols2-Regular.ttf>
"""

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

FAMILY = "Lucena Figurine"
CHESS_PIECES = "U+2654-265F"


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    root = Path(__file__).resolve().parent.parent
    target = root / "assets" / "fonts" / "LucenaFigurine.ttf"
    target.parent.mkdir(parents=True, exist_ok=True)

    subset.main(
        [
            sys.argv[1],
            f"--unicodes={CHESS_PIECES}",
            "--layout-features=",
            "--no-hinting",
            "--name-IDs=0,1,2,3,4,6,13,14",
            f"--output-file={target}",
        ]
    )

    # Nome próprio, para não se confundir com a fonte completa do sistema.
    font = TTFont(target)
    for record in font["name"].names:
        if record.nameID in (1, 4):
            record.string = FAMILY
        elif record.nameID == 6:
            record.string = FAMILY.replace(" ", "")
        elif record.nameID == 3:
            record.string = f"{FAMILY}: recorte da Noto Sans Symbols 2"
    font.save(target)

    print(f"Gerado {target} ({target.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
