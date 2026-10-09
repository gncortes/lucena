"""Gera `rook.behindPasser.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.behindPasser.py`
e depois o `build_aula.py rook.behindPasser`. O aluno joga de brancas em todas
as posições; todas têm até 7 peças, e a tabela decide."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

BEHIND = 'r7/6k1/P5p1/8/8/6P1/6K1/R7 w - - 0 1'   # torre atrás: ganha
FRONT = 'R7/6k1/P5p1/8/8/6P1/6K1/r7 w - - 0 1'    # torres trocadas: empata
SIDE = '8/6k1/6p1/P1r5/8/6P1/6K1/3R4 w - - 0 1'   # só Ta1 ganha
RACE = '8/5rk1/P1R4p/8/6P1/8/7K/8 w - - 0 1'      # só Tc2 (Audax6)
DEFEND = '8/6k1/6p1/8/p1r5/6P1/6K1/3R4 w - - 0 1'  # Td5-d8 seguram; Ta1 perde
KRAMNIK = '8/8/8/5pk1/6rp/P4K2/8/1R6 w - - 0 1'   # exceção: Ta1 perde
SKEWER = 'R7/P4k2/6p1/8/8/6P1/6K1/r7 w - - 0 1'   # só Th8 ganha

REFERENCES = [
    {'id': 'tarraschRule', 'kind': 'web',
     'title': 'Tarrasch rule (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Tarrasch_rule'},
    {'id': 'tarrasch', 'kind': 'web',
     'title': 'Siegbert Tarrasch (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Siegbert_Tarrasch'},
    {'id': 'audax6', 'kind': 'study', 'author': 'Audax6',
     'title': 'E-39 Rook Endings 6: Rooks and Passed Pawns - The rook '
              'belongs behind a passed pawn - whether friend',
     'url': 'https://lichess.org/study/PlokBlnu'},
    {'id': 'shrekdavid', 'kind': 'study', 'author': 'SHREKDAVID',
     'title': 'Tarrasch Rule Rooks Endgames',
     'url': 'https://lichess.org/study/OuwVp71z'},
    {'id': 'rfanning', 'kind': 'study', 'author': 'rfanning',
     'title': 'Tarrasch Rule - Rooks and passed pawn',
     'url': 'https://lichess.org/study/Pumc4nOr'},
    {'id': 'practice', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Basic Rook Endgames',
     'url': 'https://lichess.org/study/pqUSUw8Y'},
    {'id': 'mueller', 'kind': 'web',
     'title': 'Karsten Müller: Rooks belong behind passed pawns (ChessBase, 2024)',
     'url': 'https://en.chessbase.com/post/rooks-belong-behind-passed-pawns-2'},
    {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
     'title': "Dvoretsky's Endgame Manual",
     'publisher': 'Russell Enterprises', 'year': 2020,
     'where': 'sumário da amostra em PDF, capítulo 9'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'rook.behindPasser',
    'module': 'rook',
    'skills': ['rook.behindPasser'],
    'parts': [
        {'id': 'own', 'steps': [
            think('t_behind', BEHIND, 5, 2, arrows=['a1a6'], marks=['a8']),
            talk('behind', BEHIND, arrows=['a1a6', 'a6a7'], marks=['a8']),
            talk('front', FRONT, arrows=['a1a8', 'a8h8'],
                 marks=['g7', 'h7']),
            demo('d_walk', BEHIND,
                 'a7 Kf7 Kf3 Kg7 Ke4 Kf7 Kd5 Ke7 Kc6 Kd8 Kb7',
                 notes={1: {'marks': ['a8']},
                        11: {'arrows': ['b7a8'], 'marks': ['a8']}}),
            move('twoTargets', BEHIND,
                 'a7 Kf7 Kf3 Ke7 Ke4 Kd7 Kf4 Kc7 Kg5 Kb7 Kxg6',
                 accept='win'),
        ]},
        {'id': 'get', 'steps': [
            think('t_side', SIDE, 3, 1, ask='line', arrows=['c5a5']),
            talk('side', SIDE, arrows=['d1a1', 'a1a5'], marks=['a1']),
            move('ra1', SIDE, 'Ra1', accept='only'),
            talk('race', RACE, arrows=['f7f2', 'f2a2'], marks=['a2']),
            move('getFirst', RACE, 'Rc2 Ra7 Ra2 Kf6 Kg3',
                 accept={1: 'only', 2: 'win', 3: 'win'}),
        ]},
        {'id': 'theirs', 'steps': [
            think('t_defend', DEFEND, 5, 2, arrows=['d1d8'], marks=['a8']),
            talk('defend', DEFEND, arrows=['d1d8', 'd8a8'], marks=['a1']),
            talk('passive', after(DEFEND, 'Ra1'), arrows=['g7b3'],
                 marks=['a1']),
            move('holdBehind', DEFEND, 'Rd8 a3 Ra8', accept='hold',
                 goal='draw'),
        ]},
        {'id': 'rules', 'steps': [
            talk('tarrasch', BEHIND, arrows=['a1a6']),
            talk('except', KRAMNIK, arrows=['b1a1', 'b1b8'], marks=['a1']),
            talk('recap', DEFEND, arrows=['d8a8'], marks=['a8']),
            play('finish', BEHIND),
        ]},
    ],
    'exercises': [
        exercise('e01', 1, '8/6k1/6p1/P7/2r5/6P1/6K1/3R4 w - - 0 1', 'Ra1',
                 accept='only'),
        exercise('e02', 1, '8/6k1/6p1/1P6/2r5/6P1/6K1/3R4 w - - 0 1', 'Rb1',
                 accept='only'),
        exercise('e03', 1, '8/6k1/6p1/8/p7/1r4P1/6K1/3R4 w - - 0 1', 'Rd8',
                 accept='hold', goal='draw'),
        exercise('e04', 2, '8/6k1/6p1/8/p1r5/6P1/6K1/4R3 w - - 0 1', 'Re8',
                 accept='hold', goal='draw'),
        exercise('e05', 2, 'r7/P7/1k1K4/8/8/8/2R5/8 w - - 0 1', 'Rb2+',
                 accept='only', origin='shrekdavid'),
        exercise('e06', 2, SKEWER, 'Rh8 Rxa7 Rh7+', accept='only'),
        exercise('e07', 2, '8/6k1/6p1/p7/2r5/6P1/6K1/3R4 w - - 0 1',
                 'Rd8 a4 Ra8', accept='hold', goal='draw'),
        exercise('e08', 3, '8/4r1k1/P1R4p/8/6P1/8/7K/8 w - - 0 1', 'Rc2',
                 accept='only'),
        exercise('e09', 3, '8/5rk1/1P1R3p/8/6P1/8/7K/8 w - - 0 1', 'Rd2',
                 accept='only'),
        exercise('e10', 3, '6r1/8/7K/8/4k2P/2P2R2/8/8 w - - 0 1', 'Rf7',
                 accept='win', origin='tarraschRule'),
    ],
    'passScore': 12,
    'keyPositions': [
        {'id': 'behind', 'fen': BEHIND},
        {'id': 'front', 'fen': FRONT},
        {'id': 'defend', 'fen': DEFEND},
        {'id': 'race', 'fen': RACE, 'ref': 'audax6'},
        {'id': 'exception', 'fen': KRAMNIK, 'ref': 'tarraschRule'},
    ],
    'practice': {'fen': BEHIND, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
})
