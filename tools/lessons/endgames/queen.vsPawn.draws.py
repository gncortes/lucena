"""Gera a fonte da aula queen.vsPawn.draws (dama contra peão de torre e de
bispo na sétima). Os lances vão em SAN e viram UCI aqui; a tabela confere tudo
no build_aula.py. Uso: tools/.cache/venv/bin/python <este arquivo>"""
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


def move(id_, fen, goal, sans, accepts, typ='move'):
    """sans: lance do aluno, resposta, lance do aluno, resposta..."""
    us = uci(fen, sans)
    turns = []
    for i in range(0, len(us), 2):
        t = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us):
            t['reply'] = us[i + 1]
        turns.append(t)
    return {'type': typ, 'id': id_, 'fen': fen, 'goal': goal, 'turns': turns}


def think(id_, fen, minutes, hints, **kw):
    d = {'type': 'think', 'id': id_, 'fen': fen, 'minutes': minutes,
         'hints': hints, 'ask': 'plan'}
    d.update(kw)
    return d


def talk(id_, fen, **kw):
    d = {'type': 'talk', 'id': id_, 'fen': fen}
    d.update(kw)
    return d


# Peão de torre
ROOK = F('3Q4/1K6/8/8/8/8/pk6/8 w')          # Wikipedia (Seirawan): empate
ROOK_HOLD = F('8/1K6/8/8/3Q4/8/pk6/8 b')     # depois de 1.Dd4+
ROOK_STALE = F('8/1K6/8/8/8/1Q6/p7/k7 w')    # o fim da tentativa: afogamento
ROOK_ZONE = F('3Q4/8/8/3K4/8/8/pk6/8 w')     # Wikipedia: rei em d5 ganha
ROOK_KB3 = F('8/8/8/8/8/1K6/4Q3/qk6 b')      # a configuração com o rei em b3
ROOK_NEAR = F('8/8/8/8/2Q1K3/8/p7/1k6 w')    # própria
ZONE_ROOK = ['a5', 'b5', 'c5', 'd5', 'a4', 'b4', 'c4', 'd4', 'e4', 'd3', 'e3',
             'd2', 'e2', 'd1', 'e1']

# Peão de bispo
BISHOP = F('3Q4/8/8/8/4K3/8/1kp5/8 w')       # Wikipedia (Seirawan): empate
BISHOP_STALE = F('8/8/8/8/4K3/1Q6/2p5/k7 w')
BISHOP_HOLD = F('8/8/1Q6/8/4K3/8/1kp5/8 b')  # depois de 1.Db6+
ZONE_BISHOP = ['a4', 'b4', 'c4', 'd3', 'e3', 'd2', 'e2', 'e1']
LOLLI = F('8/8/8/8/6K1/6Q1/2p5/3k4 w')       # Lolli 1763 (Wikipedia)
BISHOP_NEAR = F('8/8/8/1K6/8/3Q4/2p5/2k5 w')  # do estudo de Danghiangmanh

# Os lados do peão e as armadilhas (de la Villa, pela Wikipedia)
TRAP410 = F('8/8/8/3K4/8/8/1kp1Q3/8 b')      # depois de 4.De2: só Ra1
TRAP410_PUNISH = F('8/8/8/3K4/8/8/2p1Q3/1k6 w')
LONG = F('8/8/8/8/8/8/1K2kp2/Q7 w')          # MarioPB4: rei do lado longo
TRAP412 = F('8/8/8/4K3/8/8/Q1pk4/8 b')       # depois de 3.Da2: só Rc3

# Resumo
VANWELY = F('6Q1/7K/8/8/8/8/2p5/k7 w')       # Van Wely-Leko 1996, depois de 60...c2
FISCHER = F('5Q2/8/6K1/8/8/8/2p5/1k6 w')     # Petrosian-Fischer 1958, análise
FINISH = F('6Q1/8/8/8/5K2/8/1kp5/8 b')       # própria: as pretas defendem
PRACTICE = F('Q7/8/8/4K3/8/3k4/2p5/8 w')     # catálogo queen.queenVsPawn.0004

src = {
    'id': 'queen.vsPawn.draws', 'module': 'queen',
    'skills': ['queen.vsPawnDraws'],
    'parts': [
        {'id': 'rook', 'steps': [
            think('t_rook', ROOK, 5, 2, marks=['a1', 'a2']),
            talk('rookWhy', ROOK_STALE, marks=['a1', 'b1', 'b2'],
                 arrows=['b3a2']),
            demo('d_rook', ROOK, 'draw',
                 'Qd4+ Kb1 Qb4+ Kc2 Qa3 Kb1 Qb3+ Ka1',
                 {7: {'marks': ['a1']}}),
            move('rookHold', ROOK_HOLD, 'draw',
                 'Kb1 Qb4+ Kc2 Qa3 Kb1 Qb3+ Ka1', ['hold'] * 4),
        ]},
        {'id': 'rookZone', 'steps': [
            think('t_rookZone', ROOK_ZONE, 5, 2),
            talk('rookZoneWhy', ROOK_ZONE, marks=ZONE_ROOK + ['b3'],
                 arrows=['d5b3']),
            demo('d_rookZone', ROOK_ZONE, 'win',
                 'Qf6+ Kb1 Qf1+ Kb2 Qe2+ Kb1 Kc4 a1=Q Kb3',
                 {6: {'arrows': ['c4b3']}, 8: {'marks': ['b3', 'c2', 'd1']}}),
            talk('rookKb3', ROOK_KB3, side='white', marks=['c2', 'd1', 'b2'],
                 arrows=['e2c2', 'e2d1']),
            move('rookZoneMove', ROOK_NEAR, 'win',
                 'Qb3+ Ka1 Qd1+ Kb2 Qd2+ Kb1 Kd3', ['win'] * 4),
        ]},
        {'id': 'bishop', 'steps': [
            think('t_bishop', BISHOP, 5, 2, marks=['a1', 'c2']),
            talk('bishopWhy', BISHOP_STALE, marks=['a1', 'a2', 'b1', 'b2'],
                 arrows=['b3c2']),
            demo('d_bishop', BISHOP, 'draw',
                 'Qb6+ Ka1 Qd4+ Kb1 Qb4+ Ka1 Qc3+ Kb1 Qb3+ Ka1',
                 {9: {'marks': ['a1', 'c2']}}),
            move('bishopHold', BISHOP_HOLD, 'draw',
                 'Ka1 Qd4+ Kb1 Qb4+ Ka1 Qc3+ Kb1 Qb3+ Ka1', ['hold'] * 5),
        ]},
        {'id': 'bishopZone', 'steps': [
            think('t_lolli', LOLLI, 5, 2),
            talk('bishopZoneWhy', BISHOP, marks=ZONE_BISHOP + ['b3'],
                 arrows=['e4d3', 'd3d2']),
            demo('d_lolli', LOLLI, 'win',
                 'Qb3 Kd2 Qb2 Kd1 Kf3 Kd2 Kf2 Kd1 Qd4+ Kc1 Qb4 Kd1 Qe1#',
                 {0: {'marks': ['b1', 'c2']}, 4: {'arrows': ['g4f3']},
                  10: {'marks': ['c1', 'e1']}}),
            move('bishopZoneMove', BISHOP_NEAR, 'win',
                 'Kb4 Kb2 Qd2 Kb1 Kb3', ['win'] * 3),
        ]},
        {'id': 'sides', 'steps': [
            think('t_trap', TRAP410, 3, 2, side='black'),
            talk('trapWhy', TRAP410, side='black', marks=['a1', 'b1', 'c3'],
                 arrows=['d5b3']),
            demo('d_trap', TRAP410_PUNISH, 'win', 'Kc4 c1=Q+ Kb3',
                 {2: {'marks': ['b3'], 'arrows': ['e2b2']}}),
            talk('longSide', LONG, marks=['g1', 'g2', 'd2'],
                 arrows=['a1a6', 'a6f1']),
            move('trapMove', TRAP412, 'draw', 'Kc3 Qa1+ Kd2', ['hold'] * 2),
        ]},
        {'id': 'summary', 'steps': [
            think('t_summary', FINISH, 1, 1, side='black'),
            talk('games', VANWELY, marks=['a1', 'c2', 'h7']),
            talk('recap', BISHOP, marks=ZONE_BISHOP),
            {'type': 'play', 'id': 'finish', 'fen': FINISH, 'goal': 'draw'},
        ]},
    ],
    'exercises': [],
    'passScore': 0,
    'keyPositions': [
        {'id': 'rookDraw', 'fen': ROOK, 'ref': 'wikipedia'},
        {'id': 'rookZone', 'fen': ROOK_ZONE, 'ref': 'wikipedia'},
        {'id': 'bishopDraw', 'fen': BISHOP, 'ref': 'wikipedia'},
        {'id': 'lolli', 'fen': LOLLI, 'ref': 'wikipedia'},
        {'id': 'trap', 'fen': TRAP410, 'ref': 'wikipedia'},
        {'id': 'longSide', 'fen': LONG, 'ref': 'mario'},
        {'id': 'vanWely', 'fen': VANWELY, 'ref': 'wikipedia'},
        {'id': 'fischer', 'fen': FISCHER, 'ref': 'wikipedia'},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win',
                 'positionId': 'queen.queenVsPawn.0004'},
    'references': [
        {'id': 'delaVilla', 'kind': 'book', 'author': 'Jesús de la Villa',
         'title': '100 Endgames You Must Know (4th, improved edition)',
         'publisher': 'New In Chess', 'year': 2015,
         'where': "Endings 17 and 18, \"Queen vs. 7th-rank rook's pawn\" "
                  "(p. 60) and \"Queen vs. 7th-rank bishop's pawn\" (p. 62)"},
        {'id': 'wikipedia', 'kind': 'web',
         'title': 'Queen versus pawn endgame (Wikipedia)',
         'url': 'https://en.wikipedia.org/wiki/Queen_versus_pawn_endgame'},
        {'id': 'mario', 'kind': 'study', 'author': 'MarioPB4',
         'title': 'Queen vs. Promoting Pawn',
         'url': 'https://lichess.org/study/o2EZohXS'},
        {'id': 'dang', 'kind': 'study', 'author': 'Danghiangmanh',
         'title': 'Queen vs Pawn',
         'url': 'https://lichess.org/study/4JKLMbtH'},
        {'id': 'tonyro', 'kind': 'study', 'author': 'TonyRo',
         'title': 'Queen vs. Rook or Bishop Pawns',
         'url': 'https://lichess.org/study/kkoVo7Fy'},
        {'id': 'tablebase', 'kind': 'tablebase',
         'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

EX = [
    # id, estrelas, FEN, objetivo, origem, lances (aluno, resposta, ...), regras
    # T58 (2026-10-09): cortados e01, e02, e03, e05, e06, e07, e08, e09, e11
    # (repetiam passos ou posições-base da lição, ou um ao outro).
    ('e12', 1, '7K/8/Q7/8/8/6k1/5p2/8 w', 'win', 'tonyro', 'Qf1', ['win']),
    ('e04', 2, '8/6K1/8/8/8/8/1kp5/4Q3 b', 'draw', 'own',
     'c1=Q Qxc1+ Kxc1', ['hold', 'hold']),
    ('e13', 2, '8/8/8/8/8/1K1Q4/2p5/k7 b', 'draw', 'own', 'c1=N+', ['hold']),
    ('e10', 2, '6Q1/8/8/4K3/8/8/4kp2/8 w', 'win', 'wikipedia',
     'Qc4+ Ke1 Qe4+ Kf1 Kf4', ['win'] * 3),
    ('e14', 2, '2Q5/7p/8/1K6/8/8/5p2/6k1 w', 'win', 'wikipedia',
     'Qg4+ Kh2 Qf3 Kg1 Qg3+ Kh1 Qxf2', ['win'] * 4),
    ('e16', 3, '8/8/8/6K1/6Q1/2k5/p7/8 w', 'win', 'own',
     'Qe2 Kb3 Qe5 Kc2 Qa1', ['win'] * 3),
    ('e15', 3, '8/1Q6/7K/8/8/4k3/2p5/8 w', 'win', 'own',
     'Qg2 Kd3 Qg5 Kc3 Qc1', ['win'] * 3),
]
for id_, st, fen, goal, origin, sans, acc in EX:
    m = move(id_, F(fen), goal, sans, acc)
    src['exercises'].append({'id': id_, 'stars': st, 'fen': F(fen),
                             'goal': goal, 'origin': origin,
                             'turns': m['turns']})
total = sum(e['stars'] for e in src['exercises'])
src['passScore'] = -(-total * 6 // 10)
OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print('estrelas', total, 'mínimo', src['passScore'])
