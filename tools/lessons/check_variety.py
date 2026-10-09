#!/usr/bin/env python3
"""Variedade dos exercícios das aulas de finais (só leitura, sem dependências).

Dois exercícios são "a mesma família" quando têm a mesma posição depois de
tirar os reis e aplicar as simetrias do tabuleiro: espelhar as colunas, trocar
as cores (fileiras invertidas, peças e vez trocadas) e, sem peões, também as
rotações. Mexer só nos reis, espelhar ou trocar as cores não é posição nova.
"Duplicata exata" é a mesma conta com os reis.

Uso:
    python3 tools/lessons/check_variety.py [id ...] [--json] [--strict]

Sem ids, confere todas as aulas de `assets/lessons/endgames/`. Imprime uma
tabela e os avisos; no GitHub Actions, os avisos saem como anotações
(`::warning::`). Sai com 1 só com `--strict` e alguma duplicata exata. O
`build_aula.py` usa as mesmas funções: lá a duplicata exata é erro.
"""
import argparse
import difflib
import json
import os
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LESSONS = ROOT / 'assets' / 'lessons' / 'endgames'
TEXTS = ROOT / 'assets' / 'lessons'

# Abaixo disto a aula tem exercícios demais parecidos.
MIN_DISTINCT = 0.9
# Acima disto os exercícios só repetem as posições da lição.
MAX_TAUGHT = 0.7
# Texto de solução parecido demais com o de outro exercício.
CLOSE_TEXT = 0.6
MIN_EXERCISES = 3


def parse(fen):
    """As peças de um FEN como (letra, coluna, fileira) e quem joga."""
    board, side = fen.split()[:2]
    pieces = []
    for rank_index, row in enumerate(board.split('/')):
        file_index = 0
        for char in row:
            if char.isdigit():
                file_index += int(char)
            else:
                pieces.append((char, file_index, 7 - rank_index))
                file_index += 1
    return pieces, side


# As 8 simetrias do tabuleiro, como funções de (coluna, fileira). Com peões só
# valem as duas primeiras; a troca de cores é a inversão das fileiras com as
# peças e a vez trocadas.
SYMMETRIES = (
    lambda f, r: (f, r),
    lambda f, r: (7 - f, r),
    lambda f, r: (f, 7 - r),
    lambda f, r: (7 - f, 7 - r),
    lambda f, r: (r, f),
    lambda f, r: (7 - r, f),
    lambda f, r: (r, 7 - f),
    lambda f, r: (7 - r, 7 - f),
)


def canonical(fen, drop_kings):
    """A menor das formas equivalentes da posição: a mesma para duas posições
    que diferem só por simetria do tabuleiro (e pelos reis, se `drop_kings`)."""
    pieces, side = parse(fen)
    others = [p for p in pieces if p[0] not in 'kK']
    # Com uma peça só além dos reis (rei e peão, mate de dama ou de torre), o
    # exercício é onde os reis estão: a família os mantém.
    if drop_kings and len(others) > 1:
        pieces = others
    has_pawns = any(p[0] in 'pP' for p in pieces)
    symmetries = SYMMETRIES[:2] if has_pawns else SYMMETRIES
    forms = []
    for symmetry in symmetries:
        for swap in (False, True):
            placed = []
            for char, file_index, rank in pieces:
                if swap:
                    rank = 7 - rank
                    char = char.swapcase()
                placed.append((char, *symmetry(file_index, rank)))
            turn = side if not swap else ('b' if side == 'w' else 'w')
            forms.append((tuple(sorted(placed)), turn))
    return min(forms)


def material(fen):
    pieces, _ = parse(fen)
    white = ''.join(sorted(c for c, _, _ in pieces if c.isupper()))
    black = ''.join(sorted(c.upper() for c, _, _ in pieces if c.islower()))
    return min((white, black), (black, white))


def groups(keys, ids):
    """Os grupos de ids com a mesma chave, do maior para o menor."""
    by_key = {}
    for key, each in zip(keys, ids):
        by_key.setdefault(key, []).append(each)
    return sorted((g for g in by_key.values() if len(g) > 1),
                  key=lambda g: (-len(g), g))


def taught_positions(lesson):
    """Os FEN que a lição mostra: passos (em partes ou não) e posições-base."""
    fens = [k['fen'] for k in lesson.get('keyPositions', [])]
    parts = lesson.get('parts') or [{'steps': lesson.get('steps', [])}]
    for part in parts:
        for step in part['steps']:
            if step.get('fen'):
                fens.append(step['fen'])
    return fens


def analyse(lesson, texts=None):
    """O relatório de variedade de uma aula (fonte ou gerada)."""
    exercises = lesson['exercises']
    ids = [e['id'] for e in exercises]
    families = [canonical(e['fen'], True) for e in exercises]
    exact = [canonical(e['fen'], False) for e in exercises]
    taught = {canonical(fen, True) for fen in taught_positions(lesson)}
    solutions = [(texts or {}).get(f'ex.{e}.solution', '') for e in ids]
    close = []
    for i in range(len(solutions)):
        for j in range(i + 1, len(solutions)):
            if solutions[i] and solutions[j] and difflib.SequenceMatcher(
                    None, solutions[i], solutions[j]).ratio() > CLOSE_TEXT:
                close.append([ids[i], ids[j]])
    count = len(exercises)
    return {
        'lesson': lesson['id'],
        'exercises': count,
        'stars': sum(e.get('stars', 0) for e in exercises),
        'families': len(set(families)),
        'materials': len({material(e['fen']) for e in exercises}),
        'family_groups': groups(families, ids),
        'exact_groups': groups(exact, ids),
        'taught': [i for i, f in zip(ids, families) if f in taught],
        'close_solutions': close,
        'exact_keys': dict(zip(ids, exact)),
    }


def warnings_of(report):
    """Os avisos de uma aula, em frases."""
    out = []
    n = report['exercises']
    if n < MIN_EXERCISES:
        out.append(f'só {n} exercícios (mínimo {MIN_EXERCISES})')
    for group in report['exact_groups']:
        out.append('duplicata exata (só os reis, o espelho ou as cores '
                   f"mudam): {', '.join(group)}")
    for group in report['family_groups']:
        out.append(f"mesma família: {', '.join(group)}")
    if n and report['families'] / n < MIN_DISTINCT:
        out.append(f"{report['families']} famílias em {n} exercícios")
    if n and len(report['taught']) / n > MAX_TAUGHT:
        out.append(f"{len(report['taught'])} de {n} exercícios repetem uma "
                   'posição da lição')
    for pair in report['close_solutions']:
        out.append(f"soluções quase iguais: {' e '.join(pair)}")
    return out


def load_texts(lesson_id, lang='pt'):
    path = TEXTS / lang / 'endgames' / f'{lesson_id}.json'
    return json.loads(path.read_text()) if path.exists() else {}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('ids', nargs='*', help='aulas (padrão: todas)')
    parser.add_argument('--json', action='store_true')
    parser.add_argument('--strict', action='store_true',
                        help='sai com 1 se houver duplicata exata')
    args = parser.parse_args()

    ids = args.ids or sorted(p.stem for p in LESSONS.glob('*.json')
                             if p.stem != 'index')
    reports = []
    for lesson_id in ids:
        path = LESSONS / f'{lesson_id}.json'
        if not path.exists():
            sys.exit(f'Aula não encontrada: {path.relative_to(ROOT)}')
        lesson = json.loads(path.read_text())
        reports.append(analyse(lesson, load_texts(lesson_id)))

    # Duplicatas exatas entre aulas diferentes: aviso, não erro (a mesma
    # posição clássica pode ser exercício de duas aulas vizinhas).
    across = {}
    for report in reports:
        for each, key in report['exact_keys'].items():
            across.setdefault(key, []).append(f"{report['lesson']}/{each}")
    across = sorted(v for v in across.values()
                    if len({x.split('/')[0] for x in v}) > 1)

    if args.json:
        for report in reports:
            report.pop('exact_keys')
            report['warnings'] = warnings_of(report)
        json.dump({'lessons': reports, 'across': across}, sys.stdout,
                  ensure_ascii=False, indent=1)
        return

    ci = bool(os.environ.get('GITHUB_ACTIONS'))
    print(f"{'Aula':28} {'Ex.':>3} {'★':>3} {'Fam.':>4} {'Lição':>5}  Avisos")
    exact_found = False
    for report in reports:
        warnings = warnings_of(report)
        exact_found = exact_found or bool(report['exact_groups'])
        print(f"{report['lesson']:28} {report['exercises']:>3} "
              f"{report['stars']:>3} {report['families']:>4} "
              f"{len(report['taught']):>5}  {'; '.join(warnings) or 'ok'}")
        if ci:
            for warning in warnings:
                print(f"::warning title={report['lesson']}::{warning}")
    for group in across:
        line = f"mesma posição em aulas diferentes: {', '.join(group)}"
        print(line)
        if ci:
            print(f'::warning title=variedade::{line}')
    print('\nFam. = posições distintas sem os reis e sem simetrias; '
          'Lição = exercícios que repetem uma posição da lição.')
    if args.strict and exact_found:
        sys.exit(1)


if __name__ == '__main__':
    main()
