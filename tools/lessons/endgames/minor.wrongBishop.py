"""Gera a fonte da aula minor.wrongBishop (lances em SAN aqui, UCI no JSON).

Uso: tools/.cache/venv/bin/python tools/lessons/endgames/minor.wrongBishop.py
Depois: tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py minor.wrongBishop
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


def move(id_, fen, goal, sans, accepts, typ='move'):
    """sans: lance do aluno, resposta, lance do aluno, resposta, ..."""
    us = uci(fen, sans)
    turns = []
    for i in range(0, len(us), 2):
        t = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us):
            t['reply'] = us[i + 1]
        turns.append(t)
    return {'type': typ, 'id': id_, 'fen': fen, 'goal': goal, 'turns': turns}


def think(id_, fen, minutes, hints, **kw):
    d = {'type': 'think', 'id': id_, 'fen': fen, 'minutes': minutes, 'hints': hints, 'ask': 'plan'}
    d.update(kw)
    return d


def talk(id_, fen, **kw):
    d = {'type': 'talk', 'id': id_, 'fen': fen}
    d.update(kw)
    return d


CORNER = F('7k/8/5K2/7P/8/8/8/5B2 w')
CORNERB = F('7k/8/5K2/7P/8/8/8/5B2 b')
RIGHT = F('7k/8/5K2/7P/8/8/8/4B3 w')
RIGHT2 = F('7k/8/6KP/8/8/8/8/4B3 w')
APAWN = F('k7/8/PK6/8/8/8/8/4B3 w')
CUT = F('5k2/8/6K1/7P/8/3B4/8/8 w')
CUT2 = F('5k2/8/5K2/8/8/7P/8/3B4 w')
MEDNIS = F('5K2/5B2/7k/7P/8/8/8/8 w')
MEDNISB = F('5K2/5B2/7k/7P/8/8/8/8 b')
RACE = F('8/8/4k3/8/5K2/8/7P/3B4 b')
TAIM = F('8/8/5K2/3kn3/6B1/7P/8/8 b')
TWO = F('7k/8/5K2/7P/7P/8/8/5B2 w')
TWOB = F('5k2/8/8/5K1P/7P/8/8/3B4 b')
FINISH = F('8/8/8/2k5/8/6KP/4B3/8 b')

src = {
    'id': 'minor.wrongBishop', 'module': 'minor', 'skills': ['minor.wrongBishop'],
    'parts': [
        {'id': 'corner', 'steps': [
            think('t_corner', CORNER, 5, 2, marks=['h8'], arrows=['f1a6']),
            talk('corner', CORNER, marks=['h8', 'g8', 'h7'], arrows=['h8g8', 'g8h8']),
            demo('d_corner', CORNER, 'draw', 'h6 Kg8 Kg6 Kh8 h7',
                 {2: {'marks': ['g7', 'h7']}, 4: {'marks': ['g8', 'g7']}}),
            move('cornerMove', CORNERB, 'draw', 'Kg8 h6 Kh8 Kg6 Kg8 Bc4+ Kh8', ['hold'] * 4),
        ]},
        {'id': 'colour', 'steps': [
            think('t_colour', RIGHT, 3, 2, marks=['h8']),
            talk('colour', RIGHT, marks=['h8', 'a8'], arrows=['e1h4']),
            demo('d_right', RIGHT, 'win', 'Kg6 Kg8 h6 Kh8 Bc3+ Kg8 h7+ Kf8 h8=Q+',
                 {4: {'arrows': ['c3h8']}, 8: {'marks': ['h8']}}),
            talk('aPawn', APAWN, marks=['a8'], arrows=['e1a5']),
            move('rightMove', RIGHT2, 'win', 'Bc3+ Kg8 h7+ Kf8 h8=Q+', ['win'] * 3),
        ]},
        {'id': 'cutoff', 'steps': [
            think('t_cutoff', CUT, 5, 2, marks=['g8', 'h8']),
            talk('cutoff', CUT, marks=['g8', 'g7'], arrows=['d3c4', 'c4g8']),
            demo('d_cutoff', CUT, 'win', 'Bc4 Ke7 Kg7 Kd6 h6 Ke5 h7',
                 {0: {'arrows': ['c4g8']}, 2: {'marks': ['g7', 'g8', 'h8']}}),
            move('cutoffMove', CUT2, 'win', 'Bb3 Ke8 Kg7 Ke7 h4 Ke8 h5 Ke7 h6', ['win'] * 5),
        ]},
        {'id': 'race', 'steps': [
            think('t_mednis', MEDNISB, 3, 2, side='black', marks=['h8']),
            talk('mednis', MEDNIS, side='black', marks=['g8', 'g7'], arrows=['f8g8']),
            demo('d_mednis', MEDNISB, 'draw', 'Kh7 Ke7 Kh8 Kf6 Kh7',
                 {0: {'marks': ['h8']}}, side='black'),
            move('raceMove', RACE, 'draw', 'Kf6 h4 Kg6 Kg4 Kh6 Bc2 Kg7 Kg5 Kh8', ['hold'] * 5),
        ]},
        {'id': 'sacrifice', 'steps': [
            think('t_taimanov', TAIM, 3, 2, side='black'),
            talk('taimanov', TAIM, side='black', marks=['h8'], arrows=['e5d3', 'd3f4']),
            demo('d_taimanov', TAIM, 'draw', 'Nd3 h4 Nf4 Kg5 Ke5',
                 {2: {'arrows': ['f4h5']}, 4: {'arrows': ['e5f6', 'f6g7']}}, side='black'),
            talk('twoPawns', TWO, side='black', marks=['h8']),
            move('twoPawnsMove', TWOB, 'draw', 'Kg7 Kg5 Kh7 h6 Kh8', ['hold'] * 3),
        ]},
        {'id': 'summary', 'steps': [
            think('t_finish', FINISH, 1, 1, marks=['h8']),
            talk('recap', CORNER, side='black', marks=['h8']),
            talk('rules', FINISH, marks=['g8', 'h8'], arrows=['c5f8']),
            {'type': 'play', 'id': 'finish', 'fen': FINISH, 'goal': 'draw'},
        ]},
    ],
    'exercises': [],
    'passScore': 13,
    'keyPositions': [
        {'id': 'corner', 'fen': CORNER, 'ref': 'ibmm'},
        {'id': 'rightBishop', 'fen': RIGHT},
        {'id': 'aPawn', 'fen': APAWN, 'ref': 'wikiFortress'},
        {'id': 'cutoff', 'fen': CUT},
        {'id': 'mednis', 'fen': MEDNIS, 'ref': 'wikiWrongRookPawn'},
        {'id': 'fischerTaimanov', 'fen': TAIM, 'ref': 'fischerTaimanov'},
    ],
    'practice': {'fen': CUT2, 'goal': 'win', 'positionId': None},
    'references': [
        {'id': 'ibmm', 'kind': 'study', 'author': 'ibmm', 'title': 'ChessNetwork #17: What is a Wrong Colored Bishop?', 'url': 'https://lichess.org/study/gHNmrart'},
        {'id': 'studier', 'kind': 'study', 'author': 'TheStudier', 'title': 'Endings: Wrong Colored Bishop (ChessNetwork)', 'url': 'https://lichess.org/study/yed13sFE'},
        {'id': 'graupera', 'kind': 'study', 'author': 'ps503graupera', 'title': 'Pawn and Wrong Color Bishop Endings!', 'url': 'https://lichess.org/study/roslBBZl'},
        {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky', 'title': "Dvoretsky's Endgame Manual (5ª edição, revista por Karsten Müller)", 'publisher': 'Russell Enterprises', 'year': 2020, 'where': "cap. 4, 'Bishop versus Pawns': 'Bishop and Rook Pawn', p. 92 (visto no sumário)"},
        {'id': 'fce', 'kind': 'book', 'author': 'Karsten Müller e Frank Lamprecht', 'title': 'Fundamental Chess Endings', 'publisher': 'Gambit', 'year': 2001, 'where': "4.1 C, 'Wrong Rook's Pawn', p. 98 (visto no sumário)"},
        {'id': 'wikiWrongRookPawn', 'kind': 'web', 'title': 'Wikipedia: Wrong rook pawn', 'url': 'https://en.wikipedia.org/wiki/Wrong_rook_pawn'},
        {'id': 'wikiWrongBishop', 'kind': 'web', 'title': 'Wikipedia: Wrong bishop', 'url': 'https://en.wikipedia.org/wiki/Wrong_bishop'},
        {'id': 'wikiFortress', 'kind': 'web', 'title': 'Wikipedia: Fortress (chess)', 'url': 'https://en.wikipedia.org/wiki/Fortress_(chess)'},
        {'id': 'fischerTaimanov', 'kind': 'game', 'white': 'Bobby Fischer', 'black': 'Mark Taimanov', 'event': 'Candidatos, Vancouver (partida 2)', 'year': 1971},
        {'id': 'korchnoiKarpov', 'kind': 'game', 'white': 'Viktor Korchnoi', 'black': 'Anatoly Karpov', 'event': 'Campeonato mundial, Baguio (partida 5)', 'year': 1978},
        {'id': 'tablebase', 'kind': 'tablebase', 'title': 'Lichess tablebase (Syzygy)', 'url': 'https://tablebase.lichess.ovh'},
    ],
}

EX = [
    ('e01', 1, '1k6/8/1K6/P7/8/8/8/4B3 b', 'draw', 'own', 'Ka8', ['hold']),
    ('e02', 1, '2k5/8/2K5/8/8/P7/8/2B5 w', 'win', 'ibmm', 'Bf4', ['win']),
    ('e03', 1, '3k4/8/8/8/5K1P/3B4/8/8 b', 'draw', 'own', 'Ke7', ['hold']),
    ('e04', 2, 'k7/8/PK6/8/8/8/2B5/8 w', 'win', 'studier', 'Be4+', ['win']),
    ('e05', 2, '5K2/5B2/7k/7P/8/8/8/8 w', 'win', 'wikiWrongRookPawn', 'Kg8', ['win']),
    ('e06', 2, '4k3/8/8/8/2B1K2P/8/8/8 b', 'draw', 'own', 'Kf8', ['hold']),
    ('e07', 2, '8/4k3/8/8/2B1K2P/8/8/8 w', 'win', 'own', 'Kf5 Kf8 Kg6', ['win'] * 2),
    ('e08', 2, '4k3/8/8/5K1P/7P/8/8/3B4 b', 'draw', 'own', 'Kf7', ['hold']),
    ('e09', 2, '6k1/8/6PP/5K2/2B5/2b5/8/8 b', 'draw', 'wikiWrongRookPawn', 'Kf8', ['hold']),
    ('e10', 3, '8/8/8/3k4/5K1P/3B4/8/8 b', 'draw', 'own', 'Ke6 Kg5 Kf7 Kh6 Kg8', ['hold'] * 3),
    ('e11', 3, '5k2/5b2/8/8/4B1PP/5K2/8/8 b', 'draw', 'studier', 'Bh5 gxh5 Kg7', ['hold'] * 2),
]
for id_, st, fen, goal, origin, sans, acc in EX:
    m = move(id_, F(fen), goal, sans, acc)
    src['exercises'].append({'id': id_, 'stars': st, 'fen': F(fen), 'goal': goal,
                             'origin': origin, 'turns': m['turns']})

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print('estrelas:', sum(e['stars'] for e in src['exercises']), 'mínimo:', src['passScore'])
