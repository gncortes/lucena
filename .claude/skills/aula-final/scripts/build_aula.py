#!/usr/bin/env python3
"""Confere e monta uma aula de final do Viktor.

Lê a fonte `tools/lessons/endgames/<id>.json` e as falas em
`assets/lessons/<pt|en>/endgames/<id>.json`; grava
`assets/lessons/endgames/<id>.json` com os lances aceitos já calculados.

Nenhuma avaliação sai da cabeça de quem escreve a aula:

- até 7 peças, a verdade é a tabela de finais do Lichess (Syzygy);
- acima disso, o Stockfish (`--stockfish`), e o relatório avisa.

Uso (só no desenvolvimento):

    pip install chess
    python3 .claude/skills/aula-final/scripts/build_aula.py <id> [--dry-run]

O formato da fonte está em `.claude/skills/aula-final/formato.md`.
"""

import argparse
import hashlib
import json
import math
import re
import shutil
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

import chess
import chess.engine

ROOT = Path(__file__).resolve().parents[4]
SRC = ROOT / 'tools' / 'lessons' / 'endgames'
OUT = ROOT / 'assets' / 'lessons' / 'endgames'
TRAIL = SRC / 'trail.json'
INDEX = OUT / 'index.json'
TEXTS = ROOT / 'assets' / 'lessons'
CACHE = ROOT / 'tools' / '.cache' / 'tablebase'
TABLEBASE = 'https://tablebase.lichess.ovh/standard?fen='
LANGS = ('pt', 'en')
ENGINE_LIMIT = chess.engine.Limit(depth=24)
SQUARE = re.compile(r'^[a-h][1-8]$')
MATE_IN_N = re.compile(r'mate (em|in) \d+', re.IGNORECASE)

# A categoria que a tabela dá a um lance é a de quem joga depois dele.
# Para quem fez o lance: 'loss' do outro é vitória, e assim por diante.
WINS = {'loss'}
HOLDS = {'loss', 'blessed-loss', 'maybe-loss', 'draw', 'cursed-win'}

REFERENCE_FIELDS = {
    'book': ('author', 'title', 'publisher', 'year'),
    'study': ('author', 'title', 'url'),
    'game': ('white', 'black', 'event', 'year'),
    'tablebase': ('title', 'url'),
    'web': ('title', 'url'),
}


class Oracle:
    """Responde, para uma posição, quais lances ganham e quais seguram."""

    def __init__(self, stockfish):
        self._stockfish = stockfish
        self._engine = None
        self.used_engine = False

    def close(self):
        if self._engine:
            self._engine.quit()

    def _probe(self, board):
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
            sys.exit('A tabela do Lichess recusou as consultas (429). '
                     'Espere um minuto e rode de novo.')
        cached.write_text(json.dumps(data))
        time.sleep(0.3)
        return data

    def _analyse(self, board):
        if not self._engine:
            if not self._stockfish:
                sys.exit('Posição com mais de 7 peças: passe --stockfish.')
            self._engine = chess.engine.SimpleEngine.popen_uci(self._stockfish)
        self.used_engine = True
        infos = self._engine.analyse(
            board, ENGINE_LIMIT, multipv=board.legal_moves.count())
        return {info['pv'][0].uci(): info['score'].pov(board.turn)
                for info in infos}

    def in_tablebase(self, board):
        return chess.popcount(board.occupied) <= 7

    def verdict(self, board):
        """'win', 'draw', 'loss' ou a categoria crua da tabela."""
        if self.in_tablebase(board):
            return self._probe(board)['category']
        score = max(self._analyse(board).values())
        if score.is_mate():
            return 'win' if score.mate() > 0 else 'loss'
        if score.score() >= 400:
            return 'win'
        return 'loss' if score.score() <= -400 else 'draw'

    def moves(self, board):
        """{lance: (ganha, segura, distância do mate em meios-lances)}."""
        if self.in_tablebase(board):
            return {
                move['uci']: (move['category'] in WINS,
                              move['category'] in HOLDS,
                              abs(move['dtm']) if move['dtm'] is not None
                              else None)
                for move in self._probe(board)['moves']
            }
        out = {}
        for uci, score in self._analyse(board).items():
            if score.is_mate():
                out[uci] = (score.mate() > 0, score.mate() > 0, None)
            else:
                out[uci] = (score.score() >= 400, score.score() > -150, None)
        return out

    def best_reply(self, board):
        if self.in_tablebase(board):
            # O Lichess ordena os lances do melhor para o pior.
            return self._probe(board)['moves'][0]['uci']
        scores = self._analyse(board)
        return max(scores, key=scores.get)


def board_of(fen, where, problems):
    try:
        board = chess.Board(fen)
    except ValueError:
        problems.append(f'{where}: FEN ilegível')
        return None
    if not board.is_valid():
        problems.append(f'{where}: FEN inválido ({board.status()!r})')
        return None
    return board


def resolve_line(oracle, where, fen, turns, goal, problems, report):
    """Troca cada regra de `accept` pela lista dos lances aceitos."""
    board = board_of(fen, where, problems)
    if board is None:
        return []
    if not turns:
        problems.append(f'{where}: sem lances')
    line = []
    for number, turn in enumerate(turns, start=1):
        at = f'{where} (lance {number})'
        teach, rule, reply = turn['teach'], turn['accept'], turn.get('reply')
        moves = oracle.moves(board)
        if teach not in moves:
            problems.append(f'{at}: {teach} é ilegal')
            break
        keeps = {uci for uci, (wins, holds, _) in moves.items()
                 if (wins if goal == 'win' else holds)}
        if isinstance(rule, list):
            accept = set(rule)
            for uci in sorted(accept - set(moves)):
                problems.append(f'{at}: {uci} (aceito) é ilegal')
        elif rule == 'only':
            accept = {teach}
        elif rule == 'win':
            accept = {uci for uci, (wins, _, _) in moves.items() if wins}
        elif rule == 'hold':
            accept = {uci for uci, (_, holds, _) in moves.items() if holds}
        elif rule == 'best':
            winning = {uci: dtm for uci, (wins, _, dtm) in moves.items()
                       if wins}
            if not winning or None in winning.values():
                problems.append(f"{at}: 'best' precisa da distância do mate; "
                                "use 'win' ou a lista dos lances")
                break
            shortest = min(winning.values())
            # Folga de um lance, como em tools/build_lessons.py.
            accept = {uci for uci, dtm in winning.items()
                      if dtm <= shortest + 2}
        else:
            problems.append(f'{at}: regra {rule!r} desconhecida')
            break
        if teach not in accept:
            problems.append(f'{at}: o lance ensinado {teach} não está entre '
                            f'os aceitos {sorted(accept)}')
        for uci in sorted(accept & set(moves) - keeps):
            problems.append(f'{at}: {uci} é aceito mas joga fora o objetivo '
                            f'({goal})')
        # O lance ensinado vai junto: a resposta combinada é para ele, e é
        # ele que a dica mostra.
        entry = {'teach': teach, 'accept': sorted(accept)}
        report.append(f'{at}: aceita {" ".join(sorted(accept))} '
                      f'(de {len(moves)} lances)')
        board.push_uci(teach)
        if reply:
            if board.is_game_over():
                problems.append(f'{at}: resposta depois do fim da partida')
                break
            if reply == 'auto':
                reply = oracle.best_reply(board)
            if chess.Move.from_uci(reply) not in board.legal_moves:
                problems.append(f'{at}: resposta {reply} é ilegal')
                break
            board.push_uci(reply)
            entry['reply'] = reply
            report.append(f'{at}: resposta {reply}')
        elif number < len(turns):
            problems.append(f'{at}: falta a resposta antes do próximo lance')
            break
        line.append(entry)
    return line


def check_goal(oracle, where, fen, goal, problems, report):
    board = board_of(fen, where, problems)
    if board is None:
        return
    if goal not in ('win', 'draw'):
        problems.append(f'{where}: objetivo {goal!r} desconhecido')
        return
    verdict = oracle.verdict(board)
    report.append(f'{where}: {verdict}')
    if verdict != goal:
        problems.append(f'{where}: o objetivo é {goal}, mas a posição é '
                        f'{verdict} para quem joga')


def check_squares(where, step, problems):
    for arrow in step.get('arrows', []):
        if not (len(arrow) == 4 and SQUARE.match(arrow[:2])
                and SQUARE.match(arrow[2:])):
            problems.append(f'{where}: seta {arrow!r} inválida')
    for mark in step.get('marks', []):
        if not SQUARE.match(mark):
            problems.append(f'{where}: casa {mark!r} inválida')


def check_references(source, problems):
    references = source.get('references', [])
    ids = [reference.get('id') for reference in references]
    if len(ids) != len(set(ids)) or None in ids:
        problems.append('referências: cada uma precisa de um id único')
    for reference in references:
        kind = reference.get('kind')
        if kind not in REFERENCE_FIELDS:
            problems.append(f"referência {reference.get('id')}: tipo {kind!r} "
                            'desconhecido')
            continue
        for field in REFERENCE_FIELDS[kind]:
            if not reference.get(field):
                problems.append(f"referência {reference.get('id')}: falta "
                                f'{field}')
        url = reference.get('url', '')
        if kind == 'study' and not url.startswith('https://lichess.org/study/'):
            problems.append(f"referência {reference.get('id')}: estudo sem "
                            'link do Lichess')
    if not any(r.get('kind') in ('book', 'study') for r in references):
        problems.append('referências: falta ao menos um livro ou estudo')
    return set(ids)


def expected_text_keys(source):
    keys = {'title', 'summary', 'history', 'practice'}
    for step in source['steps']:
        keys.add(f"step.{step['id']}")
        if step['type'] == 'move':
            keys |= {f"step.{step['id']}.hint", f"step.{step['id']}.done"}
    for exercise in source['exercises']:
        keys |= {f"ex.{exercise['id']}", f"ex.{exercise['id']}.hint",
                 f"ex.{exercise['id']}.solution"}
    for position in source.get('keyPositions', []):
        keys.add(f"key.{position['id']}")
    return keys


def check_texts(source, problems):
    expected = expected_text_keys(source)
    for lang in LANGS:
        path = TEXTS / lang / 'endgames' / f"{source['id']}.json"
        if not path.exists():
            problems.append(f'falas: falta {path.relative_to(ROOT)}')
            continue
        texts = json.loads(path.read_text())
        for key in sorted(expected - set(texts)):
            problems.append(f'falas ({lang}): falta {key}')
        for key in sorted(set(texts) - expected):
            problems.append(f'falas ({lang}): {key} não é de nenhum passo')
        for key, value in texts.items():
            text = ' '.join(value) if isinstance(value, list) else str(value)
            if not text.strip():
                problems.append(f'falas ({lang}): {key} está vazia')
            if MATE_IN_N.search(text):
                problems.append(f'falas ({lang}): {key} diz "mate em N"')


def unique(where, ids, problems):
    if len(ids) != len(set(ids)):
        problems.append(f'{where}: ids repetidos')


def build(source, oracle):
    problems, report = [], []
    lesson_id = source['id']
    reference_ids = check_references(source, problems)

    steps = []
    unique('passos', [step['id'] for step in source['steps']], problems)
    for step in source['steps']:
        where = f"{lesson_id}.{step['id']}"
        out = {key: value for key, value in step.items() if key != 'turns'}
        if step['type'] == 'talk':
            if step.get('fen'):
                board_of(step['fen'], where, problems)
            check_squares(where, step, problems)
        elif step['type'] == 'move':
            out['line'] = resolve_line(
                oracle, where, step['fen'], step.get('turns', []),
                step.get('goal', 'win'), problems, report)
        elif step['type'] == 'play':
            check_goal(oracle, where, step['fen'], step.get('goal', 'win'),
                       problems, report)
        else:
            problems.append(f"{where}: tipo {step['type']!r} desconhecido")
        steps.append(out)

    exercises = []
    unique('exercícios', [e['id'] for e in source['exercises']], problems)
    for exercise in source['exercises']:
        where = f"{lesson_id}.ex.{exercise['id']}"
        goal = exercise.get('goal', 'win')
        if exercise.get('stars') not in (1, 2, 3):
            problems.append(f'{where}: estrelas de 1 a 3')
        origin = exercise.get('origin')
        if origin != 'own' and origin not in reference_ids:
            problems.append(f"{where}: origem {origin!r} não é 'own' nem o id "
                            'de uma referência')
        check_goal(oracle, where, exercise['fen'], goal, problems, report)
        out = {key: value for key, value in exercise.items() if key != 'turns'}
        out['line'] = resolve_line(
            oracle, where, exercise['fen'], exercise.get('turns', []), goal,
            problems, report)
        exercises.append(out)

    count = len(exercises)
    if not 8 <= count <= 12:
        problems.append(f'exercícios: {count}, e a aula pede de 8 a 12')
    max_score = sum(e.get('stars') or 0 for e in exercises)
    pass_score = source.get('passScore')
    if not isinstance(pass_score, int) or not (
            math.ceil(max_score / 2) <= pass_score <= max_score):
        problems.append(f'passScore {pass_score!r}: entre metade e o total '
                        f'({max_score}) das estrelas')

    unique('posições-base', [p['id'] for p in source.get('keyPositions', [])],
           problems)
    for position in source.get('keyPositions', []):
        where = f"{lesson_id}.key.{position['id']}"
        board_of(position['fen'], where, problems)
        if position.get('ref') and position['ref'] not in reference_ids:
            problems.append(f"{where}: referência {position['ref']!r} não "
                            'existe')
    if not source.get('keyPositions'):
        problems.append('keyPositions: a aula precisa de ao menos uma '
                        'posição-base')

    practice = source.get('practice') or {}
    if practice.get('fen'):
        check_goal(oracle, f'{lesson_id}.practice', practice['fen'],
                   practice.get('goal', 'win'), problems, report)
    else:
        problems.append('practice: falta a posição do treino final')

    check_texts(source, problems)

    lesson = {**source, 'steps': steps, 'exercises': exercises,
              'maxScore': max_score}
    return lesson, problems, report


def write_index():
    """`index.json`: os módulos da trilha (`trail.json`) só com as aulas que
    já têm o JSON gerado. É o que o app lê para montar a trilha."""
    trail = json.loads(TRAIL.read_text())
    modules = []
    for module in trail['modules']:
        lessons = [lesson for lesson in module['lessons']
                   if (OUT / f'{lesson}.json').exists()]
        if lessons:
            modules.append({'id': module['id'], 'lessons': lessons})
    INDEX.write_text(json.dumps({'modules': modules}, ensure_ascii=False,
                                indent=2) + '\n')
    return sum(len(module['lessons']) for module in modules)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('id', help='id da aula (ex.: mates.bishopKnight.w)')
    parser.add_argument('--stockfish', default=shutil.which('stockfish'))
    parser.add_argument('--dry-run', action='store_true',
                        help='só confere, não grava o JSON')
    args = parser.parse_args()

    path = SRC / f'{args.id}.json'
    if not path.exists():
        sys.exit(f'Fonte não encontrada: {path.relative_to(ROOT)}')
    source = json.loads(path.read_text())
    if source.get('id') != args.id:
        sys.exit(f"O id da fonte ({source.get('id')!r}) não bate com o arquivo.")

    oracle = Oracle(args.stockfish)
    try:
        lesson, problems, report = build(source, oracle)
    finally:
        oracle.close()

    print('\n'.join(report))
    if oracle.used_engine:
        print('\nAviso: posições com mais de 7 peças foram julgadas pelo '
              'Stockfish, não pela tabela. Registre isso no dossiê.')
    if problems:
        print('\nProblemas:', *problems, sep='\n- ')
        sys.exit(1)
    print(f"\nEstrelas: {lesson['maxScore']} · mínimo: {lesson['passScore']}")
    if args.dry_run:
        return
    OUT.mkdir(parents=True, exist_ok=True)
    out = OUT / f'{args.id}.json'
    out.write_text(json.dumps(lesson, ensure_ascii=False, indent=2) + '\n')
    print(f'Gerado {out.relative_to(ROOT)}')
    count = write_index()
    print(f'Índice {INDEX.relative_to(ROOT)}: {count} aulas na trilha')


if __name__ == '__main__':
    main()
