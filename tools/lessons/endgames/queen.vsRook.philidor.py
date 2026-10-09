"""Gera `queen.vsRook.philidor.json` (a fonte da aula) a partir dos lances em
SAN. Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/queen.vsRook.philidor.py`
e depois o `build_aula.py queen.vsRook.philidor`."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

B = '1k6/1r6/2K5/Q7/8/8/8/8 b - - 0 1'  # Philidor, pretas jogam
W = '1k6/1r6/2K5/Q7/8/8/8/8 w - - 0 1'  # Philidor, brancas jogam
G = '6k1/6r1/5K2/7Q/8/8/8/8 w - - 0 1'  # o mesmo no outro canto

REFERENCES = [
    {'id': 'wikipedia', 'kind': 'web',
     'title': 'Queen versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Queen_versus_rook_endgame'},
    {'id': 'calmodee', 'kind': 'study', 'author': 'calmodee',
     'title': 'Queen Vs. Rook Endgame (Intro)',
     'url': 'https://lichess.org/study/enHKHI2k'},
    {'id': 'unto', 'kind': 'study', 'author': 'Unto',
     'title': 'Queen vs Rook',
     'url': 'https://lichess.org/study/LTWpoOgD'},
    {'id': 'bxms', 'kind': 'study', 'author': 'NM BXMSChess',
     'title': 'Queen vs Rook Endgame',
     'url': 'https://lichess.org/study/3umTRoX6'},
    {'id': 'nunn', 'kind': 'book', 'author': 'John Nunn',
     'title': 'Secrets of Pawnless Endings', 'publisher': 'Gambit Publications',
     'year': 2002},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'queen.vsRook.philidor',
    'module': 'queen',
    'skills': ['queen.vsRook'],
    'parts': [
        {'id': 'philidor', 'steps': [
            think('t_philidor', B, 5, 2, marks=['a7', 'a8', 'c7']),
            talk('intro', B, arrows=['a5a8', 'c6c7'], marks=['a7', 'a8', 'c7']),
            talk('near', B,
                 arrows=['b7a7', 'b7c7', 'b7d7', 'b7b6', 'b7b5', 'b7b4']),
            move('pin', after(B, 'Kc8'), 'Qa6 Kb8 Qxb7#', accept={2: 'only'}),
        ]},
        {'id': 'fork', 'steps': [
            think('t_fork', after(B, 'Rg7'), 3, 2, marks=['b8', 'g7'],
                  ask='line'),
            talk('far', B, marks=['b1', 'b2', 'b3', 'e7', 'f7', 'g7', 'h7']),
            demo('d_fork', after(B, 'Rg7'), 'Qe5+ Ka7 Qxg7+',
                 notes={1: {'arrows': ['e5b8', 'e5g7']}}),
            move('efile', after(B, 'Re7'), 'Qb4+ Ka8 Qxe7'),
        ]},
        {'id': 'ladder', 'steps': [
            think('t_ladder', after(B, 'Rh7'), 3, 2, marks=['h7'], ask='line'),
            demo('d_ladder', after(B, 'Rh7'), 'Qe5+ Ka8 Qa1+ Kb8 Qb1+ Kc8 Qxh7',
                 notes={1: {'arrows': ['e5b8']}, 3: {'arrows': ['a1a8']},
                        5: {'arrows': ['b1b8', 'b1h7']}}),
            demo('d_rf7', after(B, 'Rf7'), 'Qe5+ Ka7 Qe3+ Ka8 Qe8+ Ka7 Qxf7+',
                 notes={1: {'arrows': ['e5b8']}, 3: {'arrows': ['e3a7']},
                        5: {'arrows': ['e8a8', 'e8f7']}}),
            move('rb1', after(B, 'Rb1'),
                 'Qe5+ Ka7 Qd4+ Ka8 Qh8+ Ka7 Qh7+ Ka6 Qxb1'),
        ]},
        {'id': 'triangle', 'steps': [
            think('t_triangle', W, 5, 2, marks=['a5']),
            talk('white', W, arrows=['a5e5', 'e5a1', 'a1a5']),
            demo('d_triangle', W, 'Qe5+ Ka8 Qa1+ Kb8 Qa5',
                 notes={1: {'arrows': ['e5b8']}, 3: {'arrows': ['a1a8']},
                        5: {'marks': ['a5']}}),
            move('triangle', W, 'Qe5+ Ka8 Qa1+ Kb8 Qa5',
                 accept={1: ['Qe5+', 'Qd5']}),
        ]},
        {'id': 'traps', 'steps': [
            talk('squeeze', '1k6/2r5/QK6/8/8/8/8/8 b - - 0 1', arrows=['c7c6'],
                 marks=['c6']),
            talk('false', '1k6/1r6/K7/2Q5/8/8/8/8 b - - 0 1', arrows=['b7d7'],
                 marks=['a6', 'c6']),
            talk('recap', B, arrows=['a5e5'], marks=['c6', 'a5', 'b7', 'b8']),
            play('finish', W),
        ]},
    ],
    'exercises': [
        exercise('e01', 1, W, 'Qe5+', accept={1: ['Qe5+', 'Qd5']},
                 origin='wikipedia'),
        exercise('e02', 1, after(B, 'Rb2'), 'Qe5+ Ka8 Qxb2'),
        exercise('e03', 1, after(B, 'Re7'), 'Qb4+'),
        exercise('e04', 1, after(B, 'Kc8'), 'Qa6'),
        exercise('e06', 2, after(B, 'Rh7'), 'Qe5+ Ka7 Qa1+ Kb8 Qb1+'),
        exercise('e08', 2, '1k6/2r5/Q1K5/8/8/8/8/8 w - - 0 1', 'Kd6',
                 accept='win', origin='wikipedia'),
        exercise('e09', 3, after(B, 'Rb3'),
                 'Qe5+ Ka7 Qg7+ Ka8 Qg8+ Ka7 Qxb3', origin='calmodee'),
        exercise('e10', 3, after(B, 'Rb1'),
                 'Qe5+ Ka7 Qd4+ Ka8 Qh8+ Ka7 Qh7+', origin='calmodee'),
    ],
    'passScore': 9,
    'keyPositions': [
        {'id': 'black', 'fen': B, 'ref': 'wikipedia'},
        {'id': 'white', 'fen': W, 'ref': 'wikipedia'},
        {'id': 'corner', 'fen': G, 'ref': 'bxms'},
        {'id': 'draw', 'fen': '1k6/2r5/QK6/8/8/8/8/8 b - - 0 1',
         'ref': 'wikipedia'},
    ],
    'practice': {'fen': '1rk5/4Q3/K7/8/8/8/8/8 w - - 0 1', 'goal': 'win',
                 'positionId': 'queen.queenVsRook.0001'},
    'references': REFERENCES,
})
