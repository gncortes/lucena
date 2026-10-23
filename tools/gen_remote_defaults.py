#!/usr/bin/env python3
"""Gera `lib/config/remote_defaults.dart` a partir do modelo do Remote Config.

O modelo (`firebase/remoteconfig.template.json`) é a fonte: o CI publica ele
no Firebase e o app usa os mesmos valores como padrão, para quando nunca
buscou ou está sem Firebase (E1.32 §2).

Uso:
  python3 tools/gen_remote_defaults.py           # reescreve o arquivo Dart
  python3 tools/gen_remote_defaults.py --check   # só confere (CI de PR)
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "firebase" / "remoteconfig.template.json"
OUTPUT = ROOT / "lib" / "config" / "remote_defaults.dart"

KEY = re.compile(r"^[a-z][a-z0-9]*(?:_[a-z0-9]+)+$")
WIDTH = 80

HEADER = """\
// Gerado por tools/gen_remote_defaults.py a partir de
// firebase/remoteconfig.template.json. Não edite: mude o modelo e rode o
// script.

/// As chaves do Remote Config (E1.32 §1).
abstract final class RemoteKeys {
"""

DEFAULTS = """\
}

/// O valor de cada chave quando o app nunca buscou ou está sem Firebase.
const remoteDefaults = <String, Object>{
"""


def camel(key: str) -> str:
    first, *rest = key.split("_")
    return first + "".join(part[:1].upper() + part[1:] for part in rest)


def dart_string(text: str) -> str:
    escaped = (
        text.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\n", "\\n")
    )
    return f"'{escaped}'"


def dart_value(key: str, parameter: dict) -> str:
    raw = parameter.get("defaultValue", {}).get("value")
    if raw is None:
        raise ValueError(f"{key}: sem defaultValue.value")
    kind = parameter.get("valueType", "STRING")
    if kind == "BOOLEAN":
        if raw not in ("true", "false"):
            raise ValueError(f"{key}: BOOLEAN precisa ser true ou false")
        return raw
    if kind == "NUMBER":
        try:
            return str(int(raw))
        except ValueError:
            return repr(float(raw))
    if kind == "STRING":
        return dart_string(raw)
    raise ValueError(f"{key}: valueType {kind} não suportado")


def render(template: dict) -> str:
    parameters = template.get("parameters", {})
    if not parameters:
        raise ValueError("o modelo não tem nenhuma chave")
    lines = [HEADER]
    for key in parameters:
        if not KEY.match(key):
            raise ValueError(f"{key}: use snake_case com o prefixo da área")
        lines.append(f"  static const {camel(key)} = '{key}';\n")
    lines.append(DEFAULTS)
    for key, parameter in parameters.items():
        name = f"RemoteKeys.{camel(key)}"
        value = dart_value(key, parameter)
        line = f"  {name}: {value},"
        if len(line) > WIDTH:
            line = f"  {name}:\n      {value},"
        lines.append(line + "\n")
    lines.append("};\n")
    return "".join(lines)


def main() -> int:
    check = "--check" in sys.argv[1:]
    template = json.loads(TEMPLATE.read_text(encoding="utf-8"))
    try:
        expected = render(template)
    except ValueError as error:
        print(f"{TEMPLATE.relative_to(ROOT)}: {error}", file=sys.stderr)
        return 1
    current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else None
    if check:
        if current != expected:
            print(
                f"{OUTPUT.relative_to(ROOT)} não bate com "
                f"{TEMPLATE.relative_to(ROOT)}: rode "
                "python3 tools/gen_remote_defaults.py",
                file=sys.stderr,
            )
            return 1
        print("Padrões do Remote Config em dia.")
        return 0
    if current != expected:
        OUTPUT.write_text(expected, encoding="utf-8")
        print(f"Escrito {OUTPUT.relative_to(ROOT)}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
