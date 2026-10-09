"""Gera tools/lessons/endgames/pawns.protectedPasser.json (aula "O peão passado protegido").

Lances em SAN aqui, UCI no JSON. Depois de mudar, rode este arquivo e o
build_aula.py:
    tools/.cache/venv/bin/python tools/lessons/endgames/pawns.protectedPasser.py
    tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py pawns.protectedPasser
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
TIED = F('8/4k3/8/1pP4p/1P6/4K3/8/8 w')      # Fine & Benko via Wikipedia, sem os peões de a
CONVERT = F('8/8/2k5/1pP5/1P6/4K3/8/8 w')    # depois de comer: K+2 contra K+1
BASE = F('8/8/8/pP6/Pk6/8/8/7K w')           # o rei preto ataca a base
BASE_D = F('8/8/8/2pP4/2Pk4/8/8/K7 w')       # o mesmo, no centro
CORNER = F('8/1k6/pP6/P1K5/8/8/8/8 w')       # sexta fileira, perto do canto: empate
CORNER_B = F('8/8/pP1k4/P7/8/2K5/8/8 b')     # pretas defendem o canto
NO_TARGET = F('8/8/8/3k4/1Pp5/2P5/3K4/8 w')  # base por dentro: nada para comer, empate
NO_TARGET_B = F('8/8/8/3k4/1Pp5/2P5/3K4/8 b')
RECAP = F('8/3k4/8/1pP4p/1P6/8/5K2/8 w')     # resumo: jogar até o fim
DEDRLE = F('8/2k5/8/8/Pp6/1P6/6K1/8 b')      # IsaacWiebeSupreme, cap. "Dedrele Study": só Rd6
PRACTICE = F('8/4k3/8/1pP3p1/1P6/8/4K3/8 w')

src = {
    'id': 'pawns.protectedPasser', 'module': 'pawns', 'skills': ['pawns.protectedPasser'],
    'parts': [
        {'id': 'tied', 'steps': [
            {'type': 'think', 'id': 't_tied', 'fen': TIED, 'minutes': 5, 'hints': 2,
             'ask': 'plan', 'marks': ['c5', 'h5']},
            {'type': 'talk', 'id': 'square', 'fen': TIED,
             'arrows': ['b4c5'], 'marks': ['c5', 'f5', 'f8', 'c8']},
            {'type': 'talk', 'id': 'free', 'fen': TIED,
             'arrows': ['e3f4', 'f4g3', 'g3h4', 'h4h5'], 'marks': ['h5', 'g6']},
            demo('d_tied', TIED, 'win', 'Kf4 Kf6 Kg3 Ke5 Kh4 Kd5 Kxh5',
                 {1: {'marks': ['g6']}, 4: {'arrows': ['h4h5']}, 6: {'marks': ['h5']}}),
            move('tiedMove', TIED, 'win', 'Kf4 Ke6 Kg5 Kd5 Kxh5', ['win'] * 3),
        ]},
        {'id': 'convert', 'steps': [
            {'type': 'think', 'id': 't_convert', 'fen': CONVERT, 'minutes': 3, 'hints': 2,
             'ask': 'plan', 'marks': ['b5', 'd5']},
            {'type': 'talk', 'id': 'convertWhy', 'fen': CONVERT,
             'arrows': ['e3d4', 'd4d5'], 'marks': ['b5', 'c6']},
            demo('d_convert', CONVERT, 'win', 'Kd4 Kb7 Kd5 Kc7 c6 Kc8 Kc5 Kc7 Kxb5',
                 {4: {'arrows': ['d5c5']}, 8: {'marks': ['b5']}}),
            move('convertMove', CONVERT, 'win', 'Kd4 Kd7 Kd5 Kc7 c6 Kc8 Kc5', ['win'] * 4),
        ]},
        {'id': 'base', 'steps': [
            {'type': 'think', 'id': 't_base', 'fen': BASE, 'minutes': 1, 'hints': 1,
             'ask': 'line', 'marks': ['a4', 'b4']},
            {'type': 'talk', 'id': 'baseWhy', 'fen': BASE,
             'arrows': ['b5b8'], 'marks': ['b6', 'b8', 'e8', 'e5']},
            demo('d_base', BASE, 'win', 'b6 Kc5 b7 Kc6 b8=Q',
                 {0: {'arrows': ['b6b8']}, 4: {'marks': ['b8']}}),
            move('baseMove', BASE_D, 'win', 'd6 Ke5 d7 Ke6 d8=Q', ['win'] * 3),
        ]},
        {'id': 'limits', 'steps': [
            {'type': 'think', 'id': 't_corner', 'fen': CORNER, 'minutes': 3, 'hints': 2,
             'ask': 'plan', 'marks': ['a8', 'b8']},
            {'type': 'talk', 'id': 'corner', 'fen': CORNER, 'marks': ['a8', 'c7', 'b6']},
            move('cornerMove', CORNER_B, 'draw', 'Kc6 Kd3 Kb7', ['hold'] * 2),
            {'type': 'talk', 'id': 'noTarget', 'fen': NO_TARGET,
             'marks': ['b3', 'd3', 'c4'], 'arrows': ['d5c4']},
            {'type': 'move', 'id': 'targetMove', 'fen': NO_TARGET_B, 'goal': 'draw',
             'turns': turns(NO_TARGET_B, 'Kd6', ['hold'])},
        ]},
        {'id': 'finish', 'steps': [
            {'type': 'talk', 'id': 'recap', 'fen': RECAP,
             'arrows': ['b4c5', 'f2h4'], 'marks': ['h5']},
            {'type': 'talk', 'id': 'rules', 'fen': RECAP, 'arrows': ['b4c5']},
            move('recapMove', RECAP, 'win', 'Kg3 Ke6 Kh4', ['win'] * 2),
            {'type': 'play', 'id': 'finish', 'fen': RECAP, 'goal': 'win'},
        ]},
    ],
    'exercises': [],
    'passScore': 9,
    'keyPositions': [
        {'id': 'tied', 'fen': TIED, 'ref': 'wikiPawn'},
        {'id': 'convert', 'fen': CONVERT},
        {'id': 'base', 'fen': BASE},
        {'id': 'corner', 'fen': CORNER, 'ref': 'studyIsaac'},
        {'id': 'noTarget', 'fen': NO_TARGET},
        {'id': 'dedrle', 'fen': DEDRLE, 'ref': 'studyIsaac'},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win', 'positionId': None},
    'references': [
        {'id': 'dvoretsky', 'kind': 'book',
         'author': 'Mark Dvoretsky (revisão de Karsten Müller e Alex Fishbein)',
         'title': "Dvoretsky's Endgame Manual, 6ª edição", 'publisher': 'Russell Enterprises',
         'year': 2025, 'where': 'cap. 1, "The Protected Passed Pawn", p. 60 (sumário da amostra da editora)'},
        {'id': 'delaVilla', 'kind': 'book', 'author': 'Jesús de la Villa',
         'title': '100 Endgames You Must Know (4ª edição)', 'publisher': 'New In Chess',
         'year': 2015, 'where': 'Ending 89, "Protected passed pawns", p. 198 (sumário da amostra da editora)'},
        {'id': 'studyIsaac', 'kind': 'study', 'author': 'IsaacWiebeSupreme',
         'title': 'Protected Passers', 'url': 'https://lichess.org/study/u3JyT8wE'},
        {'id': 'studyChessInstitute', 'kind': 'study', 'author': 'Chess_institute',
         'title': 'Protected Passed Pawn 1', 'url': 'https://lichess.org/study/d1sMYYB6'},
        {'id': 'studyYeongyong', 'kind': 'study', 'author': 'yeongyong',
         'title': 'Protected Passed Pawn', 'url': 'https://lichess.org/study/FZJX7Vgp'},
        {'id': 'wikiPawn', 'kind': 'web', 'title': 'Wikipedia: Pawn (chess), "Passed pawn"',
         'url': 'https://en.wikipedia.org/wiki/Pawn_(chess)#Passed_pawn'},
        {'id': 'wikiPassed', 'kind': 'web', 'title': 'Wikipedia: Passed pawn, "Protected passed pawn"',
         'url': 'https://en.wikipedia.org/wiki/Passed_pawn#Protected_passed_pawn'},
        {'id': 'tablebase', 'kind': 'tablebase', 'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

# (id, estrelas, fen, objetivo, origem, lances do aluno e respostas, regra por vez)
EX = [
    ('e01', 1, '8/8/8/pP6/Pk6/8/8/K7 w', 'win', 'own', 'b6 Kc5 b7', ['win'] * 2),
    ('e02', 1, '8/8/pPk5/P7/8/3K4/8/8 b', 'draw', 'own', 'Kb7', ['hold']),
    ('e03', 1, '8/3k4/8/1pP3p1/1P6/5K2/8/8 w', 'win', 'own', 'Kg4 Ke6 Kxg5', ['win'] * 2),
    ('e04', 2, '8/8/2k5/1pP5/1P6/4K3/8/8 w', 'win', 'own', 'Kd4 Kb7 Kd5 Kc7 c6', ['win'] * 3),
    ('e08', 3, '8/8/Pk6/1P5p/4p3/8/6K1/8 w', 'win', 'studyChessInstitute', 'Kg3 Kc7 Kf4', ['only', 'win']),
    ('e09', 3, '8/4k3/8/1pP4p/1P6/8/8/3K4 w', 'win', 'own', 'Ke2 Ke6 Kf3', ['win'] * 2),
    ('e10', 3, '8/2k5/8/8/Pp6/1P6/6K1/8 b', 'draw', 'studyIsaac', 'Kd6 Kf3 Kd5', ['only', 'only']),
]
for id_, st, fen, goal, origin, sans, acc in EX:
    src['exercises'].append({'id': id_, 'stars': st, 'fen': F(fen), 'goal': goal,
                             'origin': origin, 'turns': turns(F(fen), sans, acc)})

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print('estrelas:', sum(e['stars'] for e in src['exercises']))
