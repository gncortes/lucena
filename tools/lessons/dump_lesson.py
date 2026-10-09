"""Mostra uma aula de final do jeito que o revisor e o reescritor da LIÇÃO precisam
(T61): os exercícios com a linha em SAN e as falas, as partes passo a passo com a
fala de cada lance de `demo`, o esqueleto da tabela de cobertura e a conferência dos
links de partida. Só lê; não muda nada.

    tools/.cache/venv/bin/python tools/lessons/dump_lesson.py <id> [--links] [--en]

`--links` reproduz cada `url` do tipo `lichess.org/analysis/pgn/...#ply` com
python-chess e diz se o FEN do ply bate com os passos que apontam a referência.
`--en` mostra as falas em inglês no lugar das em português.
"""
import argparse
import json
import pathlib
import re
import sys
import urllib.parse

import chess

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / 'tools' / 'lessons' / 'endgames'
TEXTS = ROOT / 'assets' / 'lessons'
FORBIDDEN = re.compile(r'lichess|tabela|tablebase|stockfish|wikipedia|\bmotor\b|\bengine\b',
                       re.I)
STEP_SECONDS = {'talk': 30, 'move': 60, 'play': 60}


def load(lesson_id, lang):
    source = json.loads((SRC / f'{lesson_id}.json').read_text())
    texts = json.loads((TEXTS / lang / 'endgames' / f'{lesson_id}.json').read_text())
    return source, texts


def san_line(fen, turns):
    """Lance ensinado e resposta de cada vez, em SAN."""
    board = chess.Board(fen)
    out = []
    for turn in turns:
        teach = chess.Move.from_uci(turn['teach'])
        out.append(board.san(teach))
        board.push(teach)
        reply = turn.get('reply')
        if reply and reply != 'auto':
            move = chess.Move.from_uci(reply)
            out.append(board.san(move))
            board.push(move)
        elif reply == 'auto':
            out.append('(auto)')
            break
    return ' '.join(out), board


def demo_moves(fen, line):
    board = chess.Board(fen)
    out = []
    for item in line:
        move = chess.Move.from_uci(item['uci'])
        out.append((board.turn, board.san(move)))
        board.push(move)
    return out


def minutes_of(steps):
    seconds = 0
    for step in steps:
        kind = step['type']
        if kind == 'think':
            seconds += 60 * (step.get('minutes') or 0)
        elif kind == 'demo':
            seconds += 10 * len(step.get('line', []))
        else:
            seconds += STEP_SECONDS.get(kind, 30)
    return seconds / 60


def short(text, n=110):
    text = (text or '').replace('\n', ' ')
    return text if len(text) <= n else text[: n - 1] + '…'


def dump(lesson_id, lang, check_links):
    source, texts = load(lesson_id, lang)
    say = lambda key: texts.get(f'{key}', '')
    refs = {r['id']: r for r in source.get('references', [])}
    print(f'# {lesson_id} · {say("title")}\n{say("summary")}\n')

    print('## Exercícios (ficam como estão; a lição precisa ensinar a ideia de cada um)\n')
    for ex in source['exercises']:
        line, _ = san_line(ex['fen'], ex['turns'])
        print(f"### {ex['id']} · {ex['stars']}★ · {ex['goal']} · origem {ex.get('origin')}")
        print(f"FEN {ex['fen']}\nLinha: {line}")
        eid = ex['id']
        print(f"Enunciado: {short(say(f'ex.{eid}'), 400)}")
        print(f"Dica: {short(say(f'ex.{eid}.hint'), 300)}")
        print(f"Solução: {short(say(f'ex.{eid}.solution'), 600)}\n")

    print('## Lição, parte por parte\n')
    parts = source.get('parts') or [{'id': 'main', 'steps': source.get('steps', [])}]
    total = 0
    for part in parts:
        minutes = minutes_of(part['steps'])
        total += minutes
        kinds = ' → '.join(s['type'] for s in part['steps'])
        pid = part['id']
        print(f"### Parte `{pid}` · {say(f'part.{pid}.title')} · ~{minutes:.1f} min · {kinds}")
        print(f"_{short(say(f'part.{pid}.summary'), 200)}_")
        for step in part['steps']:
            sid, kind = step['id'], step['type']
            ref = step.get('ref')
            rid = ref.split('#')[0] if ref else None
            tag = f" ref={ref}" if ref else ''
            if ref and rid not in refs:
                tag += ' (REFERÊNCIA INEXISTENTE)'
            elif ref and not refs[rid].get('url'):
                tag += ' (referência sem url)'
            print(f"- **{kind} `{sid}`**{tag} · {step.get('fen', '')}")
            print(f"  {short(say(f'step.{sid}'), 300)}")
            if kind == 'think':
                for i in range(1, (step.get('hints') or 0) + 1):
                    print(f"  dica{i}: {short(say(f'step.{sid}.hint{i}'), 200)}")
            elif kind == 'demo':
                for n, (turn, san) in enumerate(demo_moves(step['fen'], step['line']), 1):
                    text = say(f'step.{sid}.m{n}')
                    flag = '  ← FALA VAZIA' if len(text.strip()) < 30 else ''
                    who = 'B' if turn == chess.WHITE else 'P'
                    print(f"  m{n} {who} {san}: {short(text, 160)}{flag}")
            elif kind in ('move', 'play'):
                if step.get('turns'):
                    line, _ = san_line(step['fen'], step['turns'])
                    print(f"  linha: {line}")
                for sub in ('hint', 'done'):
                    if say(f'step.{sid}.{sub}'):
                        print(f"  {sub}: {short(say(f'step.{sid}.{sub}'), 200)}")
        print()
    print(f'Lição: ~{total:.1f} min ({len(parts)} partes). Alvo: 25 a 45 min; partes de 4 a 8.\n')

    print('## Esqueleto da tabela de cobertura (preencha a ideia e a parte que ensina)\n')
    print('| exercício | ★ | ideia cobrada | parte/passo que ensina |\n|---|---|---|---|')
    for ex in source['exercises']:
        print(f"| {ex['id']} | {ex['stars']} |  |  |")
    print()

    print('## Avisos automáticos\n')
    bad = [k for k, v in texts.items()
           if (k.startswith('step.') or k.startswith('ex.') or k.startswith('part.'))
           and FORBIDDEN.search(v)]
    for k in bad:
        print(f'- fala `{k}` cita motor, tabela, Lichess ou Wikipedia (só `key.*` e `history` podem)')
    other = 'en' if lang == 'pt' else 'pt'
    try:
        _, texts_other = load(lesson_id, other)
        missing = sorted(set(texts) ^ set(texts_other))
        if missing:
            print(f'- chaves que só existem num dos idiomas: {", ".join(missing)}')
    except FileNotFoundError:
        print(f'- não há falas em {other}')
    games = [r for r in refs.values() if r.get('kind') == 'game']
    for r in games:
        if not r.get('url'):
            print(f"- referência de partida `{r['id']}` sem url")
    steps_with_ref = [s for p in parts for s in p['steps'] if s.get('ref')]
    if not steps_with_ref:
        print('- nenhum passo da lição tem `ref` (regra 4 de licao.md)')
    if not bad and steps_with_ref and all(r.get('url') for r in games):
        print('- nada a apontar')
    print()

    if check_links:
        print('## Links de partida (lichess.org/analysis/pgn/...#ply)\n')
        for r in refs.values():
            url = r.get('url') or ''
            m = re.match(r'https://lichess\.org/analysis/pgn/([^#]+)(?:#(\d+))?', url)
            if not m:
                continue
            pgn = urllib.parse.unquote(m.group(1)).replace('_', ' ')
            ply = int(m.group(2) or 0)
            board = chess.Board()
            tokens = [t for t in pgn.split() if not re.match(r'^\d+\.+$', t)
                      and t not in ('1-0', '0-1', '1/2-1/2', '*')]
            fens = {}
            ok = True
            for i, san in enumerate(tokens):
                try:
                    board.push_san(san)
                except ValueError:
                    print(f"- `{r['id']}`: lance {i + 1} ({san}) ilegal no PGN da url")
                    ok = False
                    break
                fens[i + 1] = ' '.join(board.fen().split()[:4])
            if not ok:
                continue
            users = [s for p in parts for s in p['steps']
                     if (s.get('ref') or '').split('#')[0] == r['id']]
            users += [k for k in source.get('keyPositions', [])
                      if (k.get('ref') or '').split('#')[0] == r['id']]
            print(f"- `{r['id']}` url com ply {ply}: {fens.get(ply, 'início')}")
            for s in users:
                parts_ref = s['ref'].split('#')
                at = int(parts_ref[1]) if len(parts_ref) > 1 else ply
                same = ' '.join(s['fen'].split()[:4]) == fens.get(at)
                print(f"  - {s.get('type', 'key')} `{s['id']}` (ply {at}): "
                      f"{'bate' if same else 'NÃO BATE: ' + s['fen']}")
            if not users:
                print('  - nenhum passo ou posição-base aponta esta referência')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('lesson_id')
    parser.add_argument('--links', action='store_true')
    parser.add_argument('--en', action='store_true')
    args = parser.parse_args()
    dump(args.lesson_id, 'en' if args.en else 'pt', args.links)


if __name__ == '__main__':
    sys.exit(main())
