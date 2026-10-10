"""Gera tools/lessons/endgames/pawns.outsidePasser.json (aula "O peão passado distante").

Lances em SAN aqui, UCI no JSON. Depois de mudar, rode este arquivo e o
build_aula.py:
    tools/.cache/venv/bin/python tools/lessons/endgames/pawns.outsidePasser.py
    tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py pawns.outsidePasser
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


def ex(id_, stars, fen, sans, accepts, origin='own', goal='win'):
    return {'id': id_, 'stars': stars, 'fen': fen, 'goal': goal,
            'origin': origin, 'turns': turns(fen, sans, accepts)}


# Posições-base (todas conferidas na tabela do Lichess; ver o dossiê).
DECOY = F('8/8/8/3kp3/P5p1/3K2P1/8/8 w')        # própria: a5, Ke3... ganham
DOWN = F('8/p6k/1p6/5p2/1P6/6KP/8/8 w')         # fabian1999 ex. 2, cores trocadas: só b5
FAR = F('8/4k3/6p1/1p4P1/2K1P3/8/8/8 w')        # própria: só Kxb5, Kc4, Kd3
FAR_A = F('8/4k3/6p1/p5P1/2K1P3/8/8/8 w')       # própria: as brancas perdem
PROT = F('8/8/4k3/1pP4p/1P6/4K3/8/8 w')         # Fine & Benko (Wikipedia), sem os peões de a
FISCHER = F('8/5p2/3k2p1/8/P2K4/6P1/8/8 w')     # Fischer–Larsen 1971 sem os peões de h
PRACTICE = F('8/4kp2/6p1/8/P7/4K1P1/8/8 w')     # própria

src = {
    'id': 'pawns.outsidePasser', 'module': 'pawns',
    'skills': ['pawns.outsidePasser'],
    'parts': [
        {'id': 'decoy', 'steps': [
            {'type': 'think', 'id': 't_decoy', 'fen': DECOY, 'minutes': 5,
             'hints': 2, 'ask': 'plan', 'marks': ['a4', 'e5', 'g4']},
            {'type': 'talk', 'id': 'decoyWhy', 'fen': DECOY,
             'arrows': ['a4a8', 'd5b6', 'd3e4'], 'marks': ['e5', 'g4']},
            demo('d_decoy', DECOY, 'win',
                 'a5 Kc5 a6 Kb6 Ke4 Kxa6 Kxe5 Kb5 Kf4 Kc4 Kxg4',
                 notes={0: {'arrows': ['a5a8']},
                        4: {'arrows': ['e4e5'], 'marks': ['e5']},
                        6: {'arrows': ['e5f4', 'f4g4'], 'marks': ['g4']},
                        10: {'arrows': ['g3g8']}}),
            move('decoyMove', DECOY, 'win', 'a5 Kc5 a6 Kb6 Ke4',
                 ['win', 'win', 'win']),
        ]},
        {'id': 'down', 'steps': [
            {'type': 'think', 'id': 't_down', 'fen': DOWN, 'minutes': 5,
             'hints': 2, 'ask': 'plan', 'marks': ['b4', 'a7', 'b6']},
            {'type': 'talk', 'id': 'downWhy', 'fen': DOWN,
             'arrows': ['b4b5', 'h3h8', 'f5f1'], 'marks': ['a7', 'b6']},
            demo('d_down', DOWN, 'win',
                 'b5 Kg7 Kf4 Kf6 h4 Kg6 h5+ Kxh5 Kxf5 Kh4 Ke6 Kg5 Kd6 Kf5 '
                 'Kc6 Ke5 Kb7 Kd5 Kxa7',
                 notes={0: {'marks': ['a7', 'b6']},
                        6: {'arrows': ['g6h5']},
                        8: {'arrows': ['f5e6', 'e6d6', 'd6c6', 'c6b7']},
                        18: {'arrows': ['b5b6']}}),
            move('downMove', DOWN, 'win', 'b5 Kg7 Kf4 Kf6 h4',
                 ['only', 'win', 'win']),
        ]},
        {'id': 'far', 'steps': [
            {'type': 'think', 'id': 't_far', 'fen': FAR, 'minutes': 3,
             'hints': 2, 'ask': 'line', 'marks': ['b5', 'e4', 'g5']},
            {'type': 'talk', 'id': 'farWhy', 'fen': FAR,
             'arrows': ['c4b5', 'b5c4', 'c4d3'], 'marks': ['e4']},
            {'type': 'talk', 'id': 'farA', 'fen': FAR_A,
             'arrows': ['c4b5', 'b5a5'], 'marks': ['a5', 'e4', 'g5']},
            move('farMove', FAR, 'win', 'Kxb5 Kd6 Kc4 Ke5 Kd3',
                 ['only', 'only', 'only']),
        ]},
        {'id': 'protected', 'steps': [
            {'type': 'think', 'id': 't_prot', 'fen': PROT, 'minutes': 3,
             'hints': 2, 'ask': 'plan', 'marks': ['c5', 'h5']},
            {'type': 'talk', 'id': 'protWhy', 'fen': PROT,
             'arrows': ['b4c5', 'e3h5', 'c5c8'], 'marks': ['c5']},
            demo('d_prot', PROT, 'win',
                 'Kf4 Kd5 Kg5 Kc4 Kxh5 Kxb4 c6 Ka3 c7 b4 c8=Q',
                 notes={0: {'arrows': ['f4g5']},
                        4: {'marks': ['h5']},
                        6: {'arrows': ['c6c8']}}),
            move('protMove', PROT, 'win', 'Kf4 Kd5 Kg5 Kc4 Kxh5 Kxb4 c6',
                 ['win', 'win', 'win', 'only']),
        ]},
        {'id': 'recap', 'steps': [
            {'type': 'think', 'id': 't_fischer', 'fen': FISCHER, 'minutes': 3,
             'hints': 1, 'ask': 'plan', 'marks': ['a4']},
            {'type': 'talk', 'id': 'fischer', 'fen': FISCHER,
             'arrows': ['a4a8', 'd4f6'], 'marks': ['f7', 'g6']},
            {'type': 'talk', 'id': 'recap', 'fen': FISCHER},
            {'type': 'play', 'id': 'finish', 'fen': FISCHER, 'goal': 'win'},
        ]},
    ],
    'exercises': [
        ex('e11', 1, F('8/8/3k3p/3P3P/2K5/8/8/8 w'), 'Kd4 Kc7 Ke5',
           ['only', 'win'], origin='studyParca'),
        ex('e12', 2, F('8/8/4pp2/8/P7/4Pk2/8/3K4 b'), 'Ke4 a5 Kd5',
           ['only', 'only'], goal='draw'),
        ex('e08', 2, F('8/1p3k2/8/p4KP1/P7/8/8/8 w'), 'g6+ Kg7 Kg5',
           ['only', 'only'], origin='studyChessforall'),
        ex('e13', 2, F('8/8/4k1p1/7p/P5P1/3K4/8/8 b'), 'h4 Ke2 g5',
           ['only', 'only']),
        ex('e14', 3, F('8/8/8/6kp/4p3/2P1K1P1/8/8 w'),
           'c4 Kf5 c5 Ke5 c6 Kd6 Kxe4 Kxc6 Kf5',
           ['only', 'only', 'only', 'only', 'win'],
           origin='studyChessforall321'),
        ex('e15', 3, F('8/4k3/6K1/p2p4/P5P1/8/8/8 w'),
           'Kf5 Kd6 g5 Ke7 Ke5 Kf7 Kxd5 Kg6 Kc4 Kxg5 Kb5',
           ['only', 'only', 'only', 'only', 'win', 'only'],
           origin='studySlimshaggy'),
    ],
    'passScore': 8,
    'keyPositions': [
        {'id': 'decoy', 'fen': DECOY},
        {'id': 'down', 'fen': DOWN, 'ref': 'studyFabian'},
        {'id': 'far', 'fen': FAR},
        {'id': 'farA', 'fen': FAR_A},
        {'id': 'protected', 'fen': PROT, 'ref': 'wikiPawn'},
        {'id': 'fischerLarsen', 'fen': FISCHER, 'ref': 'fischerLarsen'},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win', 'positionId': None},
    'references': [
        {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
         'title': "Dvoretsky's Endgame Manual (6ª edição, revista por Karsten "
                  'Müller e Alex Fishbein)',
         'publisher': 'Russell Enterprises', 'year': 2025,
         'where': 'cap. 1, "The Outside Passed Pawn", p. 53 (sumário da '
                  'amostra da editora)'},
        {'id': 'delaVilla', 'kind': 'book', 'author': 'Jesús de la Villa',
         'title': '100 Endgames You Must Know (4ª edição)',
         'publisher': 'New In Chess', 'year': 2015,
         'where': 'cap. 12, Ending 83, "Rook\'s pawns and one distant passed '
                  'pawn", p. 181, e Ending 90, "Distant passed pawns", p. 200 '
                  '(sumário da amostra da editora)'},
        {'id': 'studyFabian', 'kind': 'study', 'author': 'fabian1999',
         'title': 'Outside Passed Pawns',
         'url': 'https://lichess.org/study/NkT0n2wa'},
        {'id': 'studyChessforall', 'kind': 'study', 'author': 'chessforall123',
         'title': 'Distant passed pawn',
         'url': 'https://lichess.org/study/65lYAbia'},
        {'id': 'studySlimshaggy', 'kind': 'study', 'author': 'slimshaggy',
         'title': 'Ptotected and distant passed pawn',
         'url': 'https://lichess.org/study/LOeqttPi'},
        {'id': 'studyChessforall321', 'kind': 'study',
         'author': 'Chessforall321', 'title': 'A Remote Passed Pawn',
         'url': 'https://lichess.org/study/dPHfVWmv'},
        {'id': 'studyParca', 'kind': 'study', 'author': 'La-Parca-Maldita',
         'title': 'Final de peones: Peones de torre y un peón pasado '
                  'alejado.',
         'url': 'https://lichess.org/study/IsRBdWIl'},
        {'id': 'studyKhelifa', 'kind': 'study', 'author': 'Khelifa',
         'title': 'Distant passed pawn',
         'url': 'https://lichess.org/study/0wXZXqKR'},
        {'id': 'wikiPassed', 'kind': 'web',
         'title': 'Wikipedia: Passed pawn',
         'url': 'https://en.wikipedia.org/wiki/Passed_pawn'},
        {'id': 'wikiEndgame', 'kind': 'web',
         'title': 'Wikipedia: Chess endgame',
         'url': 'https://en.wikipedia.org/wiki/Chess_endgame'},
        {'id': 'wikiPawn', 'kind': 'web',
         'title': 'Wikipedia: Pawn (chess)',
         'url': 'https://en.wikipedia.org/wiki/Pawn_(chess)'},
        {'id': 'fischerLarsen', 'kind': 'game', 'white': 'Bobby Fischer',
         'black': 'Bent Larsen',
         'event': 'Match de Candidatos, 5ª partida (citada pela Wikipedia, '
                  'Passed pawn)',
         'year': 1971},
        {'id': 'tablebase', 'kind': 'tablebase',
         'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print(f'gravado {OUT}')
