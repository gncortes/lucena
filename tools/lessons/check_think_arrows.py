#!/usr/bin/env python3
"""Confere o lance que o app aceita como "correto" em cada passo `think`.

Espelha `_guessed` e `_alsoAccepted` de `lib/ui/school/view_models/lesson_cubit.dart`.
O app olha só o passo seguinte ao `think` (na mesma parte):
- `talk`: a primeira seta;
- `demo`: o primeiro lance da linha;
- `move`: os `accept` do primeiro lance;
e, além disso, o primeiro `move` da mesma posição (mesmo FEN do `think`) que vier
antes do próximo `think`.

Para cada lance aceito confere:
1. se é legal no FEN do `think` (aviso: setas ilustrativas que o aluno nunca joga);
2. se mantém o objetivo da posição, pela tabela do Lichess (até 7 peças; erro).
   O objetivo é o veredito da tabela para a posição do `think`: vitória deve
   continuar vitória, o resto não pode virar derrota;
3. se há algum lance aceito; sem ele o aluno nunca ouve "correto" (aviso).

Uso:
    tools/.cache/venv/bin/python tools/lessons/check_think_arrows.py <id>... | --all

Saída: uma linha por problema; código 1 se houver erro.
"""

import hashlib
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

import chess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets' / 'lessons' / 'endgames'
CACHE = ROOT / 'tools' / '.cache' / 'tablebase'
TABLEBASE = 'https://tablebase.lichess.ovh/standard?fen='
# A categoria de um lance é a de quem joga depois dele.
WINS = {'loss'}
HOLDS = {'loss', 'blessed-loss', 'maybe-loss', 'draw', 'cursed-win'}


def probe(board):
    fen = board.fen()
    CACHE.mkdir(parents=True, exist_ok=True)
    cached = CACHE / (hashlib.sha1(fen.encode()).hexdigest() + '.json')
    if cached.exists():
        return json.loads(cached.read_text())
    url = TABLEBASE + urllib.parse.quote(fen)
    for attempt in range(5):
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                data = json.load(response)
            break
        except urllib.error.HTTPError as error:
            if error.code != 429:
                raise
            time.sleep(10 * (attempt + 1))
    else:
        sys.exit('A tabela do Lichess recusou as consultas (429).')
    cached.write_text(json.dumps(data))
    time.sleep(1)
    return data


def accepted(steps, index):
    """Os lances que o app aceita no think em `index` (lista de UCI)."""
    think = steps[index]
    out = []
    if index + 1 < len(steps):
        nxt = steps[index + 1]
        if nxt['type'] == 'talk' and nxt.get('arrows'):
            out.append(nxt['arrows'][0][:4] + nxt['arrows'][0][4:])
        elif nxt['type'] == 'demo' and nxt.get('line'):
            out.append(nxt['line'][0]['uci'])
        elif nxt['type'] == 'move' and nxt.get('line'):
            out.extend(nxt['line'][0]['accept'])
        for step in steps[index + 1:]:
            if step['type'] == 'think':
                break
            if (step['type'] == 'move' and step.get('fen') == think['fen']
                    and step.get('line')):
                out.extend(step['line'][0]['accept'])
                break
    return list(dict.fromkeys(out))


def check(lesson_id):
    path = OUT / f'{lesson_id}.json'
    data = json.loads(path.read_text())
    parts = data.get('parts') or [{'id': 'main', 'steps': data['steps']}]
    errors, warnings = [], 0
    for part in parts:
        steps = part['steps']
        for i, step in enumerate(steps):
            if step['type'] != 'think':
                continue
            where = f'{lesson_id} {step["id"]}'
            moves = accepted(steps, i)
            if not moves:
                warnings += 1
                print(f'AVISO {where}: nenhum lance aceito (o aluno nunca ouve "correto")')
                continue
            board = chess.Board(step['fen'])
            legal = {m.uci() for m in board.legal_moves}
            kinds = {}
            if chess.popcount(board.occupied) <= 7:
                info = probe(board)
                kinds = {m['uci']: m['category'] for m in info['moves']}
                winning = info['category'] in ('win', 'cursed-win') and \
                    info['category'] == 'win'
                keeps = WINS if winning else HOLDS
                if info['category'] == 'loss':
                    keeps = None
            else:
                keeps = None
            for uci in moves:
                if uci not in legal:
                    warnings += 1
                    print(f'AVISO {where} {uci}: ilegal no FEN do think')
                elif keeps is not None and kinds.get(uci) not in keeps:
                    goal = 'a vitória' if keeps is WINS else 'o empate'
                    errors.append((lesson_id, step['id'], uci,
                                   f'perde {goal} (tabela: {kinds.get(uci)})'))
    return errors, warnings


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    if args == ['--all']:
        args = sorted(p.stem for p in OUT.glob('*.json') if p.stem != 'index')
    total_errors = 0
    warns = {}
    for lesson_id in args:
        errors, warnings = check(lesson_id)
        warns[lesson_id] = warnings
        for aula, think, uci, problem in errors:
            print(f'ERRO {aula} {think} {uci}: {problem}')
        total_errors += len(errors)
    print(f'-- {total_errors} erro(s); avisos por aula: ' +
          ', '.join(f'{k}={v}' for k, v in warns.items() if v) or 'nenhum')
    sys.exit(1 if total_errors else 0)


if __name__ == '__main__':
    main()
