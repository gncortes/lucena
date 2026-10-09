#!/usr/bin/env python3
"""Monta `assets/lessons/course.json`, as aulas da Escola do Viktor.

Atenção: desatualizado. A notação, os primeiros truques e as aulas da T52
foram escritos direto no JSON; rodar este script apagaria essas aulas. A
conferência do curso inteiro é a do `tools/lessons/check_school.py`.

O curso é escrito aqui, em Python, e cada posição passa pelo Stockfish antes
de ir para o JSON:

- passo de lance: os lances aceitos saem da conta do motor (todos os mates em
  um, ou todos os lances que mantêm a vitória, ou que não perdem), e o lance
  que a aula ensina tem de estar entre eles;
- resposta `auto`: o melhor lance do outro lado;
- passo de jogar: a posição tem de estar ganha para quem joga.

Uso (só no desenvolvimento, não roda no CI):

    pip install python-chess
    python3 tools/build_lessons.py [--stockfish /caminho/stockfish]

O app não depende deste script: ele só lê o JSON gerado. As falas ficam em
`assets/lessons/<idioma>/lessons.json`, escritas à mão.
"""

import argparse
import json
import shutil
import sys
from pathlib import Path

import chess
import chess.engine

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets' / 'lessons' / 'course.json'
LIMIT = chess.engine.Limit(depth=14)


# --- O curso -----------------------------------------------------------------

def talk(id, fen=None, arrows=(), marks=()):
    step = {'type': 'talk', 'id': id}
    if fen:
        step['fen'] = fen
    if arrows:
        step['arrows'] = list(arrows)
    if marks:
        step['marks'] = list(marks)
    return step


def stars(id, fen, squares):
    return {'type': 'stars', 'id': id, 'fen': fen, 'stars': list(squares)}


def move(id, fen, *turns):
    """Cada vez: (lance ensinado, aceitos, resposta).

    aceitos: 'mate' (todos os mates em um), 'best' (os mates mais curtos,
    com folga de um lance), 'win' (todos que mantêm a vitória), 'hold'
    (todos que não perdem), 'only' (só o ensinado) ou a lista dos aceitos.
    resposta: lance UCI, 'auto' (o melhor do outro lado) ou None.
    """
    return {
        'type': 'move',
        'id': id,
        'fen': fen,
        'turns': [
            {'teach': teach, 'accept': accept, 'reply': reply}
            for teach, accept, reply in turns
        ],
    }


def play(id, fen, goal='mate', opponent='stockfish'):
    return {'type': 'play', 'id': id, 'fen': fen, 'goal': goal,
            'opponent': opponent}


COURSE = [
    ('pieces', [
        ('pieces.rook', [
            talk('intro', '8/8/8/8/3R4/8/8/8 w - - 0 1',
                 arrows=['d4d8', 'd4h4', 'd4d1', 'd4a4']),
            stars('stars1', '8/8/8/8/8/8/8/R7 w - - 0 1', ['a6', 'f6', 'f2']),
            talk('block', '8/8/2P5/8/8/8/8/2R5 w - - 0 1',
                 arrows=['c1c5'], marks=['c6']),
            stars('stars2', '8/8/2P5/8/8/8/8/2R5 w - - 0 1', ['c5', 'h5', 'h8']),
        ]),
        ('pieces.bishop', [
            talk('intro', '8/8/8/8/3B4/8/8/8 w - - 0 1',
                 arrows=['d4a7', 'd4h8', 'd4a1', 'd4g1']),
            stars('stars1', '8/8/8/8/8/8/8/2B5 w - - 0 1', ['a3', 'f8', 'h6']),
            talk('color', '8/8/8/8/8/8/8/2B2B2 w - - 0 1', marks=['c1', 'f1']),
            stars('stars2', '8/8/8/8/8/8/8/5B2 w - - 0 1', ['b5', 'e8', 'h5']),
        ]),
        ('pieces.queen', [
            talk('intro', '8/8/8/8/3Q4/8/8/8 w - - 0 1',
                 arrows=['d4d8', 'd4h8', 'd4h4', 'd4g1', 'd4d1', 'd4a1',
                         'd4a4', 'd4a7']),
            stars('stars1', '8/8/8/8/8/8/8/3Q4 w - - 0 1',
                  ['d7', 'a4', 'h4', 'e1']),
        ]),
        ('pieces.king', [
            talk('intro', '8/8/8/8/3K4/8/8/8 w - - 0 1',
                 marks=['c5', 'd5', 'e5', 'c4', 'e4', 'c3', 'd3', 'e3']),
            stars('stars1', '8/8/8/8/8/8/8/4K3 w - - 0 1', ['e3', 'f4', 'g4']),
            talk('active', '8/8/8/4K3/8/8/8/8 w - - 0 1'),
        ]),
        ('pieces.knight', [
            talk('intro', '8/8/8/8/3N4/8/8/8 w - - 0 1',
                 marks=['c6', 'e6', 'f5', 'f3', 'e2', 'c2', 'b3', 'b5']),
            stars('stars1', '8/8/8/8/8/8/8/1N6 w - - 0 1', ['c3', 'd5', 'f6']),
            talk('jump', '8/8/8/8/8/2PPP3/2PNP3/2PPP3 w - - 0 1',
                 arrows=['d2b1', 'd2f1', 'd2b3', 'd2f3']),
            stars('stars2', '8/8/8/8/8/8/8/6N1 w - - 0 1', ['h3', 'f4', 'e6', 'g7']),
        ]),
        ('pieces.pawn', [
            talk('intro', '8/8/8/8/8/8/4P3/8 w - - 0 1',
                 arrows=['e2e4'], marks=['e3']),
            move('double', '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',
                 ('e2e4', 'only', None)),
            talk('capture', '4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1',
                 arrows=['e4d5']),
            move('take', '4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1',
                 ('e4d5', 'only', None)),
            talk('promotion', '8/4P1k1/8/8/8/8/8/4K3 w - - 0 1',
                 arrows=['e7e8']),
            move('promote', '8/4P1k1/8/8/8/8/8/4K3 w - - 0 1',
                 ('e7e8q', 'only', None)),
        ]),
        ('pieces.check', [
            talk('check', '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
                 arrows=['a1a8']),
            talk('mate', 'R5k1/5ppp/8/8/8/8/8/6K1 b - - 0 1',
                 marks=['g8']),
            move('mate1', '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
                 ('a1a8', 'mate', None)),
            move('mate2', 'k7/8/1K6/8/8/8/7Q/8 w - - 0 1',
                 ('h2h8', 'mate', None)),
            move('mate3', '7k/8/6K1/8/8/8/8/R7 w - - 0 1',
                 ('a1a8', 'mate', None)),
        ]),
        ('pieces.stalemate', [
            talk('stalemate', 'k7/8/1Q6/8/8/8/8/7K b - - 0 1',
                 marks=['a8', 'a7', 'b7', 'b8']),
            move('avoid', 'k7/2K5/8/8/8/8/8/1Q6 w - - 0 1',
                 ('b1b7', 'mate', None)),
            move('avoid2', '7k/8/6K1/8/8/8/8/5Q2 w - - 0 1',
                 ('f1f8', 'mate', None)),
        ]),
    ]),
    ('firstMates', [
        ('mates.twoRooks', [
            talk('wall', '8/8/8/4k3/R7/8/8/1R4K1 w - - 0 1',
                 arrows=['a4h4']),
            talk('ladder', '8/8/8/4k3/R7/8/8/1R4K1 w - - 0 1',
                 arrows=['a4h4', 'b1b5']),
            move('climb', '8/8/8/4k3/R7/8/8/1R4K1 w - - 0 1',
                 ('b1b5', 'only', 'e5e6'),
                 ('a4a6', 'only', 'e6e7'),
                 ('b5b7', 'only', 'e7f8'),
                 ('a6a8', 'mate', None)),
            talk('far', '8/8/8/8/8/3k4/R7/1R4K1 w - - 0 1',
                 arrows=['b1b8', 'a2a7']),
            play('play', '8/8/8/3k4/8/8/8/R3K2R w - - 0 1'),
        ]),
        ('mates.queen', [
            talk('alone', '3k4/3Q4/3K4/8/8/8/8/8 b - - 0 1', marks=['d8']),
            talk('jump', '8/8/8/3k4/8/2Q5/8/4K3 w - - 0 1',
                 arrows=['c3c8', 'c3h3', 'c3a5', 'c3h8']),
            move('box', '8/8/4k3/8/8/2Q5/8/4K3 w - - 0 1',
                 ('c3c5', 'best', 'auto')),
            move('trap', '7k/8/8/6Q1/8/8/8/K7 w - - 0 1',
                 ('a1b2', ['a1a2', 'a1b1', 'a1b2'], None)),
            move('stalemateTrap', '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1',
                 ('g1g7', 'mate', None)),
            play('play1', '8/8/8/8/8/1k6/8/K6Q w - - 0 1'),
            play('play2', '8/8/8/3k4/8/8/8/2Q1K3 w - - 0 1'),
        ]),
    ]),
    ('technique', [
        ('technique.opposition', [
            talk('wall', '8/8/8/3k4/8/3K4/8/8 w - - 0 1',
                 marks=['c4', 'd4', 'e4']),
            talk('opposition', '8/8/8/3k4/8/3K4/8/8 b - - 0 1',
                 arrows=['d5d4']),
            move('take', '8/8/3k4/8/8/3K4/8/8 w - - 0 1',
                 ('d3d4', 'only', None)),
            move('keyPawn', '8/8/4k3/8/8/4K3/4P3/8 w - - 0 1',
                 ('e3e4', 'win', None)),
        ]),
        ('technique.zugzwang', [
            talk('idea', '3k4/3P4/4K3/8/8/8/8/8 b - - 0 1', marks=['d8']),
            talk('tempo', '4k3/4P3/4K3/8/8/8/8/8 b - - 0 1'),
            move('wait', '6k1/7R/6K1/8/8/8/8/8 w - - 0 1',
                 ('h7f7', ['h7f7'], 'g8h8'),
                 ('f7f8', 'mate', None)),
            move('pawnWait', '8/8/8/3k4/8/3K1P2/3P4/8 w - - 0 1',
                 ('f3f4', ['f3f4'], None)),
        ]),
        ('technique.rookCut', [
            talk('cut', '8/8/8/3k4/8/8/8/4K2R w - - 0 1', arrows=['h1h4']),
            move('cut1', '8/8/8/3k4/8/8/8/4K2R w - - 0 1',
                 ('h1h4', ['h1h4'], None)),
            talk('file', '8/8/8/3k4/8/8/8/4K2R w - - 0 1', arrows=['h1e1']),
            move('cut2', '8/2k5/8/8/8/8/8/R3K3 w - - 0 1',
                 ('a1d1', ['a1d1'], None)),
        ]),
        ('technique.rookMate', [
            talk('final', '3k4/8/3K4/8/8/8/8/7R w - - 0 1', arrows=['h1h8']),
            move('mate1', '3k4/8/3K4/8/8/8/8/7R w - - 0 1',
                 ('h1h8', 'mate', None)),
            talk('plan', '8/8/8/4k3/8/8/8/R3K3 w - - 0 1', arrows=['a1a4']),
            move('waitMate', '3k4/8/2K5/8/8/8/8/7R w - - 0 1',
                 ('h1e1', ['h1e1'], 'd8c8'), ('e1e8', 'mate', None)),
            play('play1', '4k3/8/4K3/8/8/8/8/7R w - - 0 1'),
            play('play2', '8/8/8/3k4/8/8/8/R3K3 w - - 0 1'),
        ]),
    ]),
    ('pawns', [
        ('pawns.kingPawn', [
            talk('front', '8/8/8/8/4K3/4P3/8/4k3 w - - 0 1', marks=['e4']),
            talk('key', '8/8/8/8/8/8/4P3/8 w - - 0 1', marks=['d4', 'e4', 'f4']),
            move('step', '8/8/4k3/8/8/4K3/4P3/8 w - - 0 1',
                 ('e3e4', 'win', None)),
            play('play', '8/8/4k3/8/8/4K3/4P3/8 w - - 0 1', goal='promote'),
        ]),
        ('pawns.square', [
            talk('square', '7k/8/8/p7/8/8/8/5K2 w - - 0 1',
                 marks=['a5', 'e5', 'a1', 'e1']),
            move('catch', '7k/8/8/p7/8/8/8/5K2 w - - 0 1',
                 ('f1e2', 'hold', None)),
            talk('run', '8/8/k7/6P1/8/8/8/K7 w - - 0 1',
                 marks=['g5', 'g8', 'd8', 'd5']),
            move('race', '8/8/k7/6P1/8/8/8/K7 w - - 0 1',
                 ('g5g6', ['g5g6'], None)),
        ]),
        ('pawns.rookPawn', [
            talk('team', '8/8/8/4k3/8/8/1P6/R3K3 w - - 0 1',
                 arrows=['a1a4']),
            play('play', '8/8/8/4k3/8/8/1P6/R3K3 w - - 0 1', goal='promote'),
        ]),
        ('pawns.rookTwoPawns', [
            talk('plan', '8/5p2/8/4k3/8/8/1PP5/R3K3 w - - 0 1',
                 arrows=['a1a4', 'b2b4']),
            play('play', '8/5p2/8/4k3/8/8/1PP5/R3K3 w - - 0 1', goal='promote'),
        ]),
    ]),
    ('minorPieces', [
        ('minor.rookBishop', [
            talk('team', '8/8/8/4k3/8/8/8/2B1K2R w - - 0 1',
                 arrows=['c1h6', 'h1h4']),
            move('mate', '6k1/8/6K1/8/8/8/1B6/R7 w - - 0 1',
                 ('a1a8', 'mate', None)),
            play('play', '8/8/8/4k3/8/8/8/2B1K2R w - - 0 1'),
        ]),
        ('minor.rookKnight', [
            talk('team', '8/8/8/4k3/8/8/8/1N2K2R w - - 0 1',
                 marks=['a3', 'c3', 'd2']),
            move('mate', '7k/8/5NK1/8/8/8/8/R7 w - - 0 1',
                 ('a1a8', 'mate', None)),
            play('play', '8/8/8/4k3/8/8/8/1N2K2R w - - 0 1'),
        ]),
        ('minor.rookTwoBishops', [
            talk('team', '8/8/8/4k3/8/8/8/2B1KB1R w - - 0 1',
                 arrows=['c1h6', 'f1a6']),
            play('play', '8/8/8/4k3/8/8/8/2B1KB1R w - - 0 1'),
        ]),
        ('minor.rookTwoKnights', [
            talk('team', '8/8/8/4k3/8/8/8/1N2K1NR w - - 0 1'),
            play('play', '8/8/8/4k3/8/8/8/1N2K1NR w - - 0 1'),
        ]),
        ('minor.rookBishopKnight', [
            talk('team', '8/8/8/4k3/8/8/8/1NB1K2R w - - 0 1'),
            play('play', '8/8/8/4k3/8/8/8/1NB1K2R w - - 0 1'),
        ]),
        ('minor.twoRooksVsKnight', [
            talk('defender', '8/8/3nk3/8/8/8/8/R3K2R w - - 0 1',
                 marks=['d6']),
            play('play', '8/8/3nk3/8/8/8/8/R3K2R w - - 0 1'),
        ]),
    ]),
    ('graduation', [
        ('graduation.twoBishops', [
            talk('wall', '8/8/8/4k3/8/3BB3/8/4K3 w - - 0 1',
                 arrows=['d3h7', 'e3a7']),
            talk('corner', 'k7/8/1K6/4B3/8/5B2/8/8 b - - 0 1',
                 marks=['a8']),
            move('mate', 'k7/8/1K6/4B3/8/8/8/3B4 w - - 0 1',
                 ('d1f3', 'mate', None)),
            play('play1', '7k/8/5K2/8/8/8/8/2BB4 w - - 0 1'),
            play('play2', '8/8/8/4k3/8/8/8/2B1KB2 w - - 0 1'),
        ]),
    ]),
]


# --- Conferência --------------------------------------------------------------

def mate_moves(board):
    out = set()
    for move in board.legal_moves:
        board.push(move)
        if board.is_checkmate():
            out.add(move.uci())
        board.pop()
    return out


def scored_moves(engine, board):
    """O placar de cada lance legal, do ponto de vista de quem joga."""
    side = board.turn
    infos = engine.analyse(board, LIMIT, multipv=board.legal_moves.count())
    return {info['pv'][0].uci(): info['score'].pov(side) for info in infos}


def accepted(engine, board, teach, kind):
    if isinstance(kind, list):
        return set(kind)
    if kind == 'only':
        return {teach}
    if kind == 'mate':
        return mate_moves(board)
    scores = scored_moves(engine, board)
    if kind == 'best':
        mating = {m: s.mate() for m, s in scores.items()
                  if s.is_mate() and s.mate() > 0}
        best = min(mating.values())
        return {m for m, n in mating.items() if n <= best + 1}
    if kind == 'win':
        return {m for m, s in scores.items()
                if s.is_mate() and s.mate() > 0 or (s.score() or 0) >= 400}
    if kind == 'hold':
        return {m for m, s in scores.items()
                if not (s.is_mate() and s.mate() < 0) and (s.score() is None
                                                           or s.score() > -300)}
    raise ValueError(kind)


def build(engine):
    problems = []
    report = []
    modules = []
    for module_id, lessons in COURSE:
        out_lessons = []
        for lesson_id, steps in lessons:
            ids = [step['id'] for step in steps]
            if len(ids) != len(set(ids)):
                problems.append(f'{lesson_id}: passos com o mesmo id')
            out_steps = []
            for step in steps:
                where = f"{lesson_id}.{step['id']}"
                print('…', where, file=sys.stderr, flush=True)
                if step['type'] == 'move':
                    board = chess.Board(step['fen'])
                    if not board.is_valid():
                        problems.append(f'{where}: FEN inválido')
                        continue
                    line = []
                    for turn in step['turns']:
                        teach = turn['teach']
                        move = chess.Move.from_uci(teach)
                        if move not in board.legal_moves:
                            problems.append(f'{where}: {teach} ilegal')
                            break
                        accept = accepted(engine, board, teach, turn['accept'])
                        if teach not in accept:
                            problems.append(
                                f'{where}: {teach} fora dos aceitos {sorted(accept)}')
                        report.append(f'{where} {teach}: {sorted(accept)}')
                        board.push(move)
                        entry = {'accept': sorted(accept)}
                        reply = turn['reply']
                        if reply == 'auto':
                            reply = engine.play(board, LIMIT).move.uci()
                        if reply:
                            reply_move = chess.Move.from_uci(reply)
                            if reply_move not in board.legal_moves:
                                problems.append(f'{where}: resposta {reply} ilegal')
                                break
                            board.push(reply_move)
                            entry['reply'] = reply
                            report.append(f'  resposta {reply}')
                        line.append(entry)
                    out_steps.append({'type': 'move', 'id': step['id'],
                                      'fen': step['fen'], 'line': line})
                    continue
                if step['type'] == 'play':
                    board = chess.Board(step['fen'])
                    if not board.is_valid():
                        problems.append(f'{where}: FEN inválido')
                    else:
                        score = engine.analyse(board, LIMIT)['score'].pov(board.turn)
                        report.append(f'{where}: {score}')
                        winning = score.is_mate() and score.mate() > 0 or (
                            (score.score() or 0) >= 250)
                        if not winning:
                            problems.append(f'{where}: não está ganha ({score})')
                if step['type'] == 'stars':
                    board = chess.Board(step['fen'])
                    # Peão é só obstáculo: nas estrelas ele não anda.
                    if board.occupied_co[chess.BLACK]:
                        problems.append(f'{where}: estrelas só com peças brancas')
                out_steps.append(step)
            out_lessons.append({'id': lesson_id, 'steps': out_steps})
        modules.append({'id': module_id, 'lessons': out_lessons})
    return {'modules': modules}, problems, report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--stockfish', default=shutil.which('stockfish'))
    args = parser.parse_args()
    if not args.stockfish:
        sys.exit('Stockfish não encontrado: passe --stockfish.')
    engine = chess.engine.SimpleEngine.popen_uci(args.stockfish)
    try:
        course, problems, report = build(engine)
    finally:
        engine.quit()
    print('\n'.join(report))
    if problems:
        print('\nProblemas:', *problems, sep='\n- ')
        sys.exit(1)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(course, ensure_ascii=False, indent=2) + '\n')
    print(f'\nGerado {OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
