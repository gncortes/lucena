"""Gera tools/lessons/endgames/pawns.shoulder.json (aula "O ombro").

Lances em SAN aqui, UCI no JSON. Depois de mudar, rode este arquivo e o
build_aula.py:
    tools/.cache/venv/bin/python tools/lessons/endgames/pawns.shoulder.py
    tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py pawns.shoulder
"""
import json
import pathlib

import chess

OUT = pathlib.Path(__file__).with_suffix('.json')


def F(s):
    return s + ' - - 0 1'


def uci(fen, sans):
    b = chess.Board(fen)
    out = []
    for s in sans.split():
        m = b.parse_san(s)
        out.append(m.uci())
        b.push(m)
    return out


def demo(id_, fen, goal, sans, notes=None, side=None):
    line = []
    for i, u in enumerate(uci(fen, sans)):
        e = {'uci': u}
        if notes and i in notes:
            e.update(notes[i])
        line.append(e)
    d = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': goal, 'line': line}
    if side:
        d['side'] = side
    return d


def turns(fen, sans, accepts):
    us = uci(fen, sans)
    out = []
    for i in range(0, len(us), 2):
        t = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us):
            t['reply'] = us[i + 1]
        out.append(t)
    return out


def move(id_, fen, goal, sans, accepts, side=None):
    d = {'type': 'move', 'id': id_, 'fen': fen, 'goal': goal,
         'turns': turns(fen, sans, accepts)}
    if side:
        d['side'] = side
    return d


# Posições-base (todas conferidas na tabela do Lichess).
STAIRS = F('8/8/8/1k6/8/8/K4P2/8 w')       # sibi.m, cap. 6: só Kb3
STAIRS_B = F('8/8/8/1k6/8/8/K4P2/8 b')     # pretas na vez: empate
STAIRS_G = F('8/8/8/1k6/8/8/K5P1/8 w')     # a mesma com peão de g: só Kb3
WALL = F('8/5p2/8/8/1k2K3/8/5P2/8 w')      # TLQ2JepT, cap. 3: só Kd4
ACROSS = F('8/5K2/p6k/8/8/8/1P6/8 w')      # TLQ2JepT, cap. 4: só Kf6
AWAY = F('8/5p2/8/8/5K2/5P2/8/7k w')       # TLQ2JepT, cap. 2: só Kg3
RACE = F('8/8/5p2/4kP2/K7/8/P7/8 w')       # TLQ2JepT, cap. 1: só Kb5
DEFEND = F('8/5p2/1p6/1P2K2k/8/8/8/8 w')   # 1tpnHFlG, cap. 7: só Kf5 empata
BLACK = F('8/8/3k4/1p6/6K1/8/P7/8 b')      # iA0o5q69, cap. 4: só Ke5
RULES = F('8/8/4k3/8/8/5P1K/8/8 w')        # catálogo pawn.pawnVsKing.0002: só Kg4
FINISH = F('8/k7/5K2/8/8/8/2P5/8 w')       # catálogo pawn.pawnVsKing.0004

src = {
    'id': 'pawns.shoulder', 'module': 'pawns', 'skills': ['pawns.shoulder'],
    'parts': [
        {'id': 'between', 'steps': [
            {'type': 'think', 'id': 't_stairs', 'fen': STAIRS, 'minutes': 5,
             'hints': 2, 'ask': 'plan', 'marks': ['c4', 'd3', 'e2'],
             'arrows': ['b5e2']},
            {'type': 'talk', 'id': 'stairs', 'fen': STAIRS,
             'arrows': ['a2b3', 'b5f1'], 'marks': ['c4']},
            {'type': 'talk', 'id': 'stairsDraw', 'fen': STAIRS_B,
             'side': 'white', 'arrows': ['b5c4', 'c4e2'], 'marks': ['f2']},
            demo('d_stairs', STAIRS, 'win',
                 'Kb3 Kc5 Kc3 Kd5 Kd3 Ke5 Ke3 Kf5 Kf3',
                 {0: {'marks': ['c4']}, 2: {'marks': ['d4']},
                  4: {'marks': ['e4']}, 8: {'marks': ['f2']}}),
            move('stairsMove', STAIRS_G, 'win', 'Kb3 Kc5 Kc3 Kd5 Kd3 Ke5 Ke3',
                 ['win'] * 4),
        ]},
        {'id': 'wall', 'steps': [
            {'type': 'think', 'id': 't_wall', 'fen': WALL, 'minutes': 3,
             'hints': 2, 'ask': 'plan'},
            {'type': 'talk', 'id': 'wall', 'fen': WALL,
             'arrows': ['e4d4', 'b4f8'], 'marks': ['d4', 'd5', 'd6']},
            demo('d_wall', WALL, 'win',
                 'Kd4 Kb5 Kd5 Kb6 Kd6 Kb7 f4 Kc8 Ke7 f5 Ke6 Kd8 Kxf5',
                 {0: {'marks': ['c5', 'c4', 'c3']}, 6: {'arrows': ['f4f5']},
                  12: {'marks': ['f5']}}),
            {'type': 'talk', 'id': 'across', 'fen': ACROSS,
             'arrows': ['f7f2', 'h6h2'], 'marks': ['b2']},
            move('acrossMove', ACROSS, 'win',
                 'Kf6 Kh5 Kf5 Kh4 Kf4 Kh3 Kf3 Kh2 Kf2', ['win'] * 5),
        ]},
        {'id': 'away', 'steps': [
            {'type': 'think', 'id': 't_away', 'fen': AWAY, 'minutes': 3,
             'hints': 2, 'ask': 'plan'},
            {'type': 'talk', 'id': 'away', 'fen': AWAY,
             'arrows': ['f4f5', 'h1g2', 'g2f3'], 'marks': ['f3']},
            demo('d_away', AWAY, 'win', 'Kg3 Kg1 f4 Kf1 f5 Ke2 Kf4 Kd3 Ke5 Ke3 f6',
                 {0: {'marks': ['g2', 'f2']}, 6: {'marks': ['e3', 'e4']},
                  10: {'arrows': ['e5d6', 'd6e7']}}),
            move('awayMove', AWAY, 'win', 'Kg3 Kg1 f4 Kf1 f5 Ke2 Kf4',
                 ['win'] * 4),
        ]},
        {'id': 'race', 'steps': [
            {'type': 'think', 'id': 't_race', 'fen': RACE, 'minutes': 3,
             'hints': 2, 'ask': 'plan'},
            {'type': 'talk', 'id': 'race', 'fen': RACE,
             'arrows': ['a4b5', 'b5c6', 'e5d7'], 'marks': ['a8']},
            demo('d_race', RACE, 'win',
                 'Kb5 Kxf5 a4 Ke6 Kc6 f5 a5 f4 a6 f3 a7 f2 a8=Q f1=Q Qe8+ Kf5 Qf8+ Ke4 Qxf1',
                 {4: {'marks': ['d6', 'd7']}, 14: {'arrows': ['e8e6']},
                  16: {'arrows': ['f8f1']}}),
            move('raceMove', RACE, 'win', 'Kb5 Kxf5 a4 Ke6 Kc6', ['win'] * 3),
        ]},
        {'id': 'defend', 'steps': [
            {'type': 'think', 'id': 't_defend', 'fen': DEFEND, 'minutes': 3,
             'hints': 2, 'ask': 'plan'},
            {'type': 'talk', 'id': 'defend', 'fen': DEFEND,
             'arrows': ['h5g4', 'g4c5'], 'marks': ['b5', 'f5']},
            move('defendMove', DEFEND, 'draw', 'Kf5 Kh4 Kf4 Kh3 Kf3 Kh2 Kf2',
                 ['hold'] * 4),
            {'type': 'talk', 'id': 'black', 'fen': BLACK, 'side': 'black',
             'arrows': ['d6e5', 'g4b4'], 'marks': ['a2']},
            move('blackMove', BLACK, 'win', 'Ke5 Kf3 Kd4 Ke2 Kc3 Kd1 Kb2',
                 ['win'] * 4),
        ]},
        {'id': 'summary', 'steps': [
            {'type': 'talk', 'id': 'recap', 'fen': STAIRS,
             'arrows': ['a2b3', 'b3c3', 'c3d3']},
            move('rulesMove', RULES, 'win', 'Kg4 Kf6 Kf4', ['win'] * 2),
            {'type': 'talk', 'id': 'last', 'fen': FINISH,
             'arrows': ['f6e5', 'a7c6'], 'marks': ['d6', 'c5']},
            {'type': 'play', 'id': 'finish', 'fen': FINISH, 'goal': 'win'},
        ]},
    ],
    'exercises': [],
    'passScore': 12,
    'keyPositions': [
        {'id': 'stairs', 'fen': STAIRS, 'ref': 'sibi'},
        {'id': 'wall', 'fen': WALL, 'ref': 'drMkc'},
        {'id': 'across', 'fen': ACROSS, 'ref': 'drMkc'},
        {'id': 'away', 'fen': AWAY, 'ref': 'drMkc'},
        {'id': 'race', 'fen': RACE, 'ref': 'drMkc'},
        {'id': 'defend', 'fen': DEFEND, 'ref': 'poojakanth'},
    ],
    'practice': {'fen': FINISH, 'goal': 'win', 'positionId': 'pawn.pawnVsKing.0004'},
    'references': [
        {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
         'title': "Dvoretsky's Endgame Manual (6th edition, revised by Karsten Müller and Alex Fishbein)",
         'publisher': 'Russell Enterprises', 'year': 2025,
         'where': 'cap. 1, "Shouldering", p. 47 (índice da amostra da editora)'},
        {'id': 'drMkc', 'kind': 'study', 'author': 'DrMkcTheHandsome',
         'title': 'Endgame Shouldering Away', 'url': 'https://lichess.org/study/TLQ2JepT'},
        {'id': 'zeeshan', 'kind': 'study', 'author': 'zeeshan30',
         'title': 'Shouldering', 'url': 'https://lichess.org/study/iA0o5q69'},
        {'id': 'manoj', 'kind': 'study', 'author': 'Manoj1988',
         'title': 'Shouldering', 'url': 'https://lichess.org/study/z4whjLOx'},
        {'id': 'poojakanth', 'kind': 'study', 'author': 'Poojakanth',
         'title': 'endgame study-shouldering', 'url': 'https://lichess.org/study/1tpnHFlG'},
        {'id': 'sibi', 'kind': 'study', 'author': 'sibi.m',
         'title': 'shouldering in the king and pawn endgame', 'url': 'https://lichess.org/study/UDGX1K3Z'},
        {'id': 'wikiKing', 'kind': 'web', 'title': 'Wikipedia: King (chess), "Shouldering"',
         'url': 'https://en.wikipedia.org/wiki/King_(chess)#Shouldering'},
        {'id': 'tablebase', 'kind': 'tablebase', 'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

# (id, estrelas, fen, objetivo, origem, lances do aluno e respostas, regra por vez)
EX = [
    ('e01', 1, '8/8/8/k7/8/8/K4P2/8 w', 'win', 'own', 'Ka3 Kb5 Kb3', ['win'] * 2),
    ('e02', 1, '7k/6p1/6K1/8/8/8/4P3/8 w', 'win', 'sibi', 'Kf7 Kh7 e4', ['win'] * 2),
    ('e03', 1, '8/8/8/1k6/8/8/K3P3/8 w', 'win', 'own', 'Kb3 Kc5 Kc3', ['win'] * 2),
    ('e04', 2, '8/2p5/8/8/2K5/2P5/8/k7 w', 'win', 'own', 'Kb3 Kb1 c4', ['win'] * 2),
    ('e05', 2, '8/7k/8/6K1/p7/8/1P6/8 w', 'win', 'zeeshan', 'Kf6 Kh6 Ke5', ['win'] * 2),
    ('e06', 2, '8/8/4k3/2p5/7K/8/1P6/8 b', 'win', 'own', 'Kf5 Kg3 Ke4 Kf2 Kd3', ['win'] * 3),
    ('e07', 2, '8/2p5/6p1/k2K2P1/8/8/8/8 w', 'draw', 'own', 'Kc5 Ka4 Kc4 Ka3 Kc3', ['hold'] * 3),
    ('e08', 3, '8/1p6/8/8/8/3K4/P7/6k1 w', 'win', 'manoj', 'Ke2 Kg2 a4 Kg3 Ke3', ['win'] * 3),
    ('e09', 3, '8/p4K2/P7/8/8/8/1k6/8 w', 'win', 'poojakanth', 'Ke6 Ka2 Kd5 Ka3 Kc6', ['win'] * 3),
    ('e10', 3, '8/2p5/6K1/8/8/5k2/P7/8 w', 'win', 'sibi', 'Kf5 c5 Ke5 c4 Kd4', ['win'] * 3),
]
for id_, st, fen, goal, origin, sans, acc in EX:
    src['exercises'].append({'id': id_, 'stars': st, 'fen': F(fen), 'goal': goal,
                             'origin': origin, 'turns': turns(F(fen), sans, acc)})

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print('estrelas:', sum(e['stars'] for e in src['exercises']))
