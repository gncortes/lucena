#!/usr/bin/env python3
"""Checagem de traduções, usada pelo CI.

Reprova quando:
- algum idioma não tem exatamente as mesmas chaves do inglês (`app_en.arb`);
- alguma chave do inglês está sem `@chave` com `description`;
- há texto fixo em widget de `lib/ui/` (o texto deve vir de `context.l10n`).

Uso: python3 tools/check_l10n.py [raiz do projeto]
"""

import json
import re
import sys
from pathlib import Path

BASE = "app_en.arb"

# Parâmetros e widgets que mostram texto ao usuário.
HARDCODED = re.compile(
    r"""(\bText\(\s*|\b(?:semanticLabel|semanticsLabel|tooltip|hintText|labelText|helperText|errorText)\s*:\s*)(['"])"""
)


def message_keys(arb: dict) -> set[str]:
    return {key for key in arb if not key.startswith("@")}


def check_arb_files(l10n_dir: Path) -> list[str]:
    base_path = l10n_dir / BASE
    if not base_path.exists():
        return [f"{base_path}: arquivo base não encontrado"]

    errors = []
    base = json.loads(base_path.read_text(encoding="utf-8"))
    base_keys = message_keys(base)

    for key in sorted(base_keys):
        if not base.get(f"@{key}", {}).get("description"):
            errors.append(f"{BASE}: a chave '{key}' está sem '@{key}' com 'description'")

    for path in sorted(l10n_dir.glob("app_*.arb")):
        if path.name == BASE:
            continue
        keys = message_keys(json.loads(path.read_text(encoding="utf-8")))
        for key in sorted(base_keys - keys):
            errors.append(f"{path.name}: falta a chave '{key}'")
        for key in sorted(keys - base_keys):
            errors.append(f"{path.name}: a chave '{key}' não existe em {BASE}")

    return errors


def check_hardcoded_text(ui_dir: Path) -> list[str]:
    errors = []
    for path in sorted(ui_dir.rglob("*.dart")):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.lstrip().startswith("//"):
                continue
            if HARDCODED.search(line):
                errors.append(f"{path}:{number}: texto fixo em widget, use context.l10n")
    return errors


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
    errors = check_arb_files(root / "lib" / "l10n") + check_hardcoded_text(root / "lib" / "ui")

    for error in errors:
        print(error)
    if errors:
        print(f"\n{len(errors)} problema(s) de tradução.")
        return 1

    print("Traduções em ordem.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
