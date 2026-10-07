#!/usr/bin/env python3
"""Cenários das capturas da landing page (prints e vídeos), por idioma.

Uso:
  scenes.py -d <aparelho> -l pt|en|es [-o <pasta>] [cenário ...]

Sem cenários, roda todos. Cada cenário começa com o app limpo (com o tour),
no idioma pedido. Os arquivos crus (PNG do aparelho e MP4 em 1080x2404) vão
para <pasta>/<idioma>/ (padrão: build/capture); tools/capture/encode.sh gera
as versões da web em landing/assets/.
"""

from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

from lucena_capture import ROOT, App

SCENES = {}


def scene(fn):
    SCENES[fn.__name__.replace("_", "-")] = fn
    return fn


def lesson(lang: str, lesson_id: str) -> dict:
    data = json.loads((ROOT / f"assets/lessons/endgames/{lesson_id}.json").read_text())
    folder = "pt" if lang == "pt" else "en"
    texts = json.loads(
        (ROOT / f"assets/lessons/{folder}/endgames/{lesson_id}.json").read_text()
    )
    return {**data, "title": texts["title"]}


def finish_tour(app: App, level: str = "Casual"):
    while not app.exists(app.t("Começar")):
        app.tap_t("Próximo", then=0.7)
    app.tap_t(level, then=0.8)
    app.tap_t("Começar", then=3)


# --- cenários --------------------------------------------------------------


@scene
def inicio(app: App):
    app.fresh_start()
    finish_tour(app)
    app.shot("inicio")
    app.start_video("inicio")
    time.sleep(1.5)
    app.swipe(2300, 1100, ms=1400, then=1.8)
    app.swipe(1100, 2500, ms=1400, then=1.5)
    app.end_video()


@scene
def personalizacao(app: App):
    app.fresh_start()
    app.tap_t("Próximo", then=1.6)
    app.start_video("personalizacao")
    time.sleep(1.2)
    app.tap_t("Escuro", then=1.4)
    app.tap_t("Laranja", then=1.6)
    app.shot("personalizacao-tema")
    app.tap_t("Próximo", then=1.6)
    app.tap_t("Verde", then=1.3)
    app.tap_t("Merida", then=1.8)
    app.shot("personalizacao")
    app.end_video()


@scene
def iniciante(app: App):
    app.fresh_start()
    finish_tour(app, "Iniciante")
    app.shot("iniciante-trilha")
    app.start_video("iniciante-aulas")
    time.sleep(1.5)
    app.tap_t("Começar a primeira aula", then=2.5)
    app.tap_key("lessonContinue", then=2)
    board = app.find_board("8/8/8/8/8/8/8/R7 w - - 0 1")
    for uci in ["a1a6", "a6f6", "f6f2"]:
        board.game.turn = True
        board.move(uci, then=1.1)
    time.sleep(1)
    app.shot("iniciante-aulas")
    app.end_video()


@scene
def intermediario(app: App):
    app.fresh_start()
    finish_tour(app, "Intermediário")
    app.start_video("intermediario-jornada")
    time.sleep(1.5)
    app.tap_t("Jornada", then=2.2)
    app.shot("intermediario-jornada")
    app.swipe(2300, 1300, ms=1200, then=1.5)
    app.end_video()


def endgame_lesson(app: App, lesson_id: str, video: str, start: int, end: int, shot_at: int):
    """Faz os passos da lição até [end] e grava de [start] em diante (os
    passos de lance, sem as falas longas da abertura)."""
    data = lesson(app.lang, lesson_id)
    app.fresh_start()
    finish_tour(app)
    app.scroll_to(app.t("Aulas de finais"))
    app.tap_t("Aulas de finais", then=2)
    app.scroll_to(data["title"])
    app.tap_text(data["title"], then=2)
    app.shot(f"{video}-aula")
    app.tap_key("endgameLessonStart", then=2.2)
    for i, step in enumerate(data["steps"][:end]):
        if i == start:
            app.start_video(video)
        if i >= start:
            time.sleep(1.4)
        if step["type"] == "move":
            board = app.find_board(step["fen"], step.get("side", "white") == "white")
            for turn in step["line"]:
                board.move(turn.get("teach") or turn["accept"][0], then=0.8)
                if turn.get("reply"):
                    board.game.push_uci(turn["reply"])
                    time.sleep(1.3)
        if i == shot_at:
            app.shot(video)
        if i < end - 1:
            time.sleep(0.8 if i >= start else 0.3)
            app.tap_key("lessonContinue", then=1 if i >= start else 0.8)
    time.sleep(1.2)
    app.end_video()


@scene
def dama_vs_torre(app: App):
    endgame_lesson(app, "queen.vsRook.philidor", "aula-dama-vs-torre", start=2, end=5, shot_at=4)


@scene
def bispo_e_cavalo(app: App):
    endgame_lesson(app, "mates.bishopKnight.w", "aula-bispo-e-cavalo", start=3, end=6, shot_at=4)


@scene
def lucena(app: App):
    endgame_lesson(app, "rook.lucena", "aula-lucena", start=2, end=4, shot_at=3)


def open_setup(app: App, category_pt: str, position: int = 1):
    app.scroll_to(app.t("Treinar finais"))
    app.tap_t("Treinar finais", then=2)
    category = app.t(category_pt)
    app.scroll_to(category + "\n")
    app.tap_text(category + "\n", then=2)
    app.tap_text(app.text("catalogPositionNumber", number=position) + "\n", then=2)


@scene
def maia(app: App):
    app.fresh_start()
    finish_tour(app)
    open_setup(app, "Finais de torre")
    app.swipe(2300, 1200, ms=600, then=1)
    app.start_video("maia-nivel-e-ritmo")
    time.sleep(1.2)
    app.tap_text("· 1800", then=1)
    app.tap_text("3+2 ·", then=1.2)
    app.shot("maia-nivel-e-ritmo")
    app.tap_t("Começar partida", then=2.5)
    board = app.find_board("8/8/8/8/8/p7/k1K5/2R5 w - - 0 1")
    board.play(4, ms=1000)
    app.end_video()


@scene
def destaque(app: App):
    app.fresh_start()
    finish_tour(app)
    open_setup(app, "Finais de dama")
    app.swipe(2300, 1200, ms=600, then=1)
    app.tap_text("· 2000", then=0.8)
    app.tap_text("3+2 ·", then=0.8)
    app.tap_t("Começar partida", then=2.5)
    board = app.find_board("1rk5/4Q3/K7/8/8/8/8/8 w - - 0 1")
    app.start_video("destaque")
    time.sleep(0.5)
    board.play(4, ms=1000)
    app.shot("destaque")
    app.end_video()


@scene
def stockfish(app: App):
    app.fresh_start()
    finish_tour(app)
    open_setup(app, "Finais de dama", position=2)
    app.tap_t("Stockfish\n", then=1)
    app.swipe(2300, 1200, ms=600, then=1)
    app.tap_text("5+0 ·", then=0.8)
    app.tap_t("Começar partida", then=2.5)
    board = app.find_board("2k5/4r3/1K6/3Q4/8/8/8/8 w - - 0 1")
    app.start_video("partida-stockfish")
    time.sleep(0.5)
    board.play(5, ms=1000)
    app.shot("partida-stockfish")
    app.end_video()
    board.play(40, ms=800)
    time.sleep(3)
    app.tap_key("resultReview", then=2.5)
    app.start_video("analise-partida")
    time.sleep(1.2)
    app.tap_key("reviewStart", then=1.5)
    if app.exists(app.text("reviewQuick")):
        app.tap_key("reviewQuick", then=4)
    app.tap_key("reviewFirst", then=1.2)
    for _ in range(4):
        app.tap_key("reviewNext", then=1.3)
    app.shot("analise-partida")
    app.end_video()


@scene
def speedrun(app: App):
    stages = json.loads((ROOT / "assets/progression/speedrun_positions.json").read_text())
    fens = [p["fen"] for p in stages["speedruns"]["ending.queen"]]
    app.fresh_start()
    finish_tour(app)
    app.scroll_to(app.t("Speedrun"))
    app.tap_t("Speedrun", then=2)
    app.start_video("speedrun")
    time.sleep(1.2)
    app.tap_text(app.t("Mate de dama") + "\n", then=2)
    app.shot("speedrun")
    app.tap_key("speedrunStart", then=2.5)
    board = app.find_board_among(fens)
    board.play(30, pause=0.25, ms=300)
    time.sleep(3.5)
    app.end_video()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--device", required=True)
    parser.add_argument("-l", "--lang", default="pt", choices=["pt", "en", "es"])
    parser.add_argument("-o", "--out", default=str(ROOT / "build/capture"))
    parser.add_argument("scenes", nargs="*")
    args = parser.parse_args()
    app = App(args.device, args.lang, Path(args.out) / args.lang)
    try:
        for name in args.scenes or SCENES:
            print(f"== {name} ({args.lang})", flush=True)
            SCENES[name](app)
    finally:
        app.close()


if __name__ == "__main__":
    main()
