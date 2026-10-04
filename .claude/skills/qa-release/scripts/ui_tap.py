#!/usr/bin/env python3
"""Toca no elemento da tela do emulador cujo rótulo contém o texto informado.

Serve para os roteiros de GIF feitos com `adb` no build de release: o rótulo é o
texto visível, a dica (tooltip) ou a descrição de acessibilidade do elemento.

Uso:
  ui_tap.py "<rótulo>"   toca no primeiro elemento que contém o rótulo
  ui_tap.py --list       lista os rótulos da tela atual, com a posição

O aparelho vem de ANDROID_DEVICE (ou do `.env`); o padrão é emulator-5554.
"""

import os
import re
import subprocess
import sys
import time
from pathlib import Path


def device() -> str:
    value = os.environ.get("ANDROID_DEVICE")
    if not value and Path(".env").exists():
        match = re.search(r"^ANDROID_DEVICE=(.+)$", Path(".env").read_text(), re.M)
        value = match.group(1).strip() if match else None
    return value or "emulator-5554"


def nodes(serial: str) -> list[tuple[str, tuple[int, int, int, int]]]:
    xml = subprocess.run(
        ["adb", "-s", serial, "exec-out", "uiautomator", "dump", "/dev/tty"],
        capture_output=True,
        text=True,
    ).stdout
    found = []
    for node in re.findall(r"<node [^>]*>", xml):
        description = re.search(r'content-desc="([^"]*)"', node)
        text = re.search(r' text="([^"]*)"', node)
        label = (description.group(1) if description else "") or (text.group(1) if text else "")
        bounds = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', node)
        if label and bounds:
            found.append((label.replace("&#10;", " / "), tuple(map(int, bounds.groups()))))
    return found


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    serial = device()
    if sys.argv[1] == "--list":
        for label, bounds in nodes(serial):
            print(f"{label!r} {bounds}")
        return 0

    # A tela pode estar no meio de uma transição: tenta por alguns segundos.
    for _ in range(6):
        for label, (x1, y1, x2, y2) in nodes(serial):
            if sys.argv[1] in label:
                subprocess.run(
                    ["adb", "-s", serial, "shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2)],
                    check=True,
                )
                return 0
        time.sleep(0.5)
    print(f"não achei na tela: {sys.argv[1]}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
