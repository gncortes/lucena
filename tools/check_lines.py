#!/usr/bin/env python3
"""Confere os personagens e as falas (assets/characters e assets/lines).

Cada personagem tem ficha, avatar e falas em inglês e em português com os
mesmos ids; pelo menos 100 falas (o Viktor, 200) e todas as categorias conhecidas, cada uma com
pelo menos 5; nenhuma fala repetida; nenhuma passa de 90 caracteres (o balão é
pequeno). Sai com erro e lista os problemas.

Uso: python3 tools/check_lines.py
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHARACTERS = ROOT / "assets" / "characters"
LINES = ROOT / "assets" / "lines"
LANGUAGES = ["en", "pt"]

# Os eventos que a partida sabe reconhecer (T25). Nova categoria entra aqui e
# no enum do app ao mesmo tempo.
CATEGORIES = [
    "gameStart", "bigAdvantage", "better", "equal", "worse", "bigDisadvantage",
    "opponentBlunder", "ownBlunder", "strongMove", "comeback", "collapse",
    "pieceCaptured", "pieceLost", "ownPromotion", "opponentPromotion",
    "opponentLowTime", "ownLowTime", "timeAdvantage", "opponentThinking",
    "win", "loss", "draw", "drawAccepted", "drawDeclined",
    "mateDelayed", "toldYouDraw",
]
EMOTIONS = {
    "calm", "happy", "confident", "playful", "focused", "surprised",
    "nervous", "frustrated", "sad",
}
LEVELS = [1000, 1200, 1400, 1600, 1800, 2000, 2200, 2400, 2600]
MIN_LINES = 100
# O Viktor é o professor da escola e homenagem a todos os professores de
# xadrez: tem pelo menos o dobro das falas dos outros (T31).
MIN_LINES_BY_CHARACTER = {"master": 200}
# Para quem a fala é, além de todo jogador: "student" só para quem fez aulas
# com o personagem.
AUDIENCES = {"student"}
MIN_PER_CATEGORY = 5
MAX_LENGTH = 90


def check() -> list[str]:
    problems = []
    profiles = sorted(CHARACTERS.glob("*.json"))
    levels = []
    for path in profiles:
        profile = json.loads(path.read_text(encoding="utf-8"))
        cid = path.stem
        where = f"{cid}:"
        if profile.get("id") != cid:
            problems.append(f"{where} id da ficha diferente do arquivo")
        levels.append(profile.get("level"))
        for field in ["name", "tagline", "personality", "traits", "avatar"]:
            if not profile.get(field):
                problems.append(f"{where} ficha sem {field}")
        for field in ["tagline", "personality"]:
            for lang in LANGUAGES:
                if not (profile.get(field) or {}).get(lang):
                    problems.append(f"{where} {field} sem {lang}")
        if not (ROOT / profile.get("avatar", "")).is_file():
            problems.append(f"{where} avatar não encontrado")

        ids = {}
        for lang in LANGUAGES:
            lines_path = LINES / lang / f"{cid}.json"
            if not lines_path.is_file():
                problems.append(f"{where} sem falas em {lang}")
                continue
            lines = json.loads(lines_path.read_text(encoding="utf-8"))["lines"]
            ids[lang] = {line["id"] for line in lines}
            if len(ids[lang]) != len(lines):
                problems.append(f"{where} id repetido em {lang}")
            texts = [line["text"] for line in lines]
            if len(set(texts)) != len(texts):
                problems.append(f"{where} fala repetida em {lang}")
            minimum = MIN_LINES_BY_CHARACTER.get(cid, MIN_LINES)
            if len(lines) < minimum:
                problems.append(f"{where} {len(lines)} falas em {lang} (mínimo {minimum})")
            for line in lines:
                tag = f"{where} {line.get('id')}"
                if line.get("category") not in CATEGORIES:
                    problems.append(f"{tag} categoria desconhecida")
                if line.get("emotion") not in EMOTIONS:
                    problems.append(f"{tag} emoção desconhecida")
                if "audience" in line and line["audience"] not in AUDIENCES:
                    problems.append(f"{tag} audiência desconhecida")
                if line.get("intensity") not in (1, 2, 3):
                    problems.append(f"{tag} intensidade fora de 1 a 3")
                if not line.get("text") or len(line["text"]) > MAX_LENGTH:
                    problems.append(f"{tag} texto vazio ou com mais de {MAX_LENGTH} caracteres ({lang})")
            for category in CATEGORIES:
                count = sum(1 for line in lines if line.get("category") == category)
                if count < MIN_PER_CATEGORY:
                    problems.append(f"{where} {category} com {count} falas em {lang}")
        if len(ids) == 2 and ids["en"] != ids["pt"]:
            problems.append(f"{where} ids diferentes entre en e pt")
    if sorted(levels) != LEVELS:
        problems.append(f"os níveis dos personagens deveriam ser {LEVELS}, são {sorted(levels)}")
    return problems


def main() -> int:
    problems = check()
    for problem in problems:
        print(problem)
    if problems:
        print(f"\n{len(problems)} problema(s) nas falas.")
        return 1
    print("Falas em ordem.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
