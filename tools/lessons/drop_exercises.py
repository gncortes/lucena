#!/usr/bin/env python3
"""Corta exercícios de uma aula de final: fonte, falas e nota mínima.

Uso:
    python3 tools/lessons/drop_exercises.py <id> e04 e05 [--pass N]

Tira os exercícios da fonte (`tools/lessons/endgames/<id>.py`, se existir, e
o `.json`), as chaves `ex.eNN`, `ex.eNN.hint` e `ex.eNN.solution` das falas em
todos os idiomas e recalcula o `passScore` (60% do total, arredondado para
cima, ou `--pass N`). Os ids que ficam não são renumerados: o progresso do
aluno é gravado por id, e renumerar daria a estrela de um exercício a outro.
Depois, rode o `build_aula.py` para gerar o JSON do app.
"""
import argparse
import json
import math
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'tools' / 'lessons' / 'endgames'
TEXTS = ROOT / 'assets' / 'lessons'
PYTHON = ROOT / 'tools' / '.cache' / 'venv' / 'bin' / 'python'


def drop_from_py(path, ids):
    """Tira do gerador a chamada `exercise('eNN', …)` de cada id, com os
    parênteses balanceados e a vírgula que a fecha."""
    text = path.read_text()
    for each in ids:
        # Os geradores escrevem `exercise('eNN', …)`, `ex('eNN', …)` ou a
        # tupla `('eNN', …)`; o corte vai do começo da chamada ao parêntese
        # que a fecha.
        start = -1
        for form in (f"exercise('{each}'", f"ex('{each}'", f"('{each}',"):
            start = text.find(form)
            if start >= 0:
                break
        if start < 0:
            sys.exit(f'{path.name}: não achei o exercício {each!r}')
        depth, i = 0, start
        while True:
            char = text[i]
            if char == '(':
                depth += 1
            elif char == ')':
                depth -= 1
                if depth == 0:
                    break
            i += 1
        end = i + 1
        if text[end:end + 1] == ',':
            end += 1
        # A linha inteira, com a indentação de antes e a quebra de depois.
        line_start = text.rfind('\n', 0, start) + 1
        if text[line_start:start].strip() == '':
            start = line_start
        if text[end:end + 1] == '\n':
            end += 1
        text = text[:start] + text[end:]
    path.write_text(text)


def set_pass_py(path, value):
    text = path.read_text()
    new, n = re.subn(r"'passScore':\s*\d+", f"'passScore': {value}", text)
    if n != 1:
        sys.exit(f'{path.name}: esperava um passScore, achei {n}')
    path.write_text(new)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('id')
    parser.add_argument('exercises', nargs='+', metavar='eNN')
    parser.add_argument('--pass', dest='pass_score', type=int,
                        help='nota mínima (padrão: 60%% do total)')
    args = parser.parse_args()
    ids = set(args.exercises)

    json_path = SRC / f'{args.id}.json'
    source = json.loads(json_path.read_text())
    have = {e['id'] for e in source['exercises']}
    missing = sorted(ids - have)
    if missing:
        sys.exit(f"{args.id}: não tem {', '.join(missing)}")
    kept = [e for e in source['exercises'] if e['id'] not in ids]
    total = sum(e['stars'] for e in kept)
    pass_score = args.pass_score or math.ceil(total * 0.6)

    py_path = SRC / f'{args.id}.py'
    if py_path.exists():
        drop_from_py(py_path, sorted(ids))
        set_pass_py(py_path, pass_score)
        subprocess.run([str(PYTHON), str(py_path)], check=True)
        regenerated = json.loads(json_path.read_text())
        left = {e['id'] for e in regenerated['exercises']}
        if left & ids or regenerated['passScore'] != pass_score:
            sys.exit(f'{py_path.name}: o gerador não refletiu o corte')
    else:
        source['exercises'] = kept
        source['passScore'] = pass_score
        json_path.write_text(json.dumps(source, ensure_ascii=False, indent=2)
                             + '\n')

    for texts in sorted(TEXTS.glob(f'*/endgames/{args.id}.json')):
        data = json.loads(texts.read_text())
        before = len(data)
        for each in ids:
            for key in (f'ex.{each}', f'ex.{each}.hint', f'ex.{each}.solution'):
                data.pop(key, None)
        texts.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
        print(f'{texts.relative_to(ROOT)}: {before - len(data)} chaves a menos')

    print(f"{args.id}: ficam {len(kept)} exercícios, {total} estrelas, "
          f'mínimo {pass_score}. Agora rode o build_aula.py.')


if __name__ == '__main__':
    main()
