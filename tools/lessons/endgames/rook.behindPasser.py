"""Gera `rook.behindPasser.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.behindPasser.py`
e depois o `build_aula.py rook.behindPasser`. O aluno joga de brancas em todas
as posições. A lição e os exercícios até 7 peças passam pela tabela; e13, e14
e e15 têm mais de 7 peças e são julgados pelo Stockfish (rodar o build com --stockfish)."""
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
    {'id': 'miles26', 'kind': 'study', 'author': 'miles26',
     'title': 'Rook behind the pawns',
     'url': 'https://lichess.org/study/2bxusiQ6'},
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
        exercise('e05', 1, 'r7/P7/1k1K4/8/8/8/2R5/8 w - - 0 1', 'Rb2+ Ka6 Kc7',
                 accept='only', origin='shrekdavid'),
        exercise('e06', 1, SKEWER, 'Rh8 Rxa7 Rh7+', accept='only'),
        exercise('e11', 2, '2R5/8/Pr6/7k/8/8/K7/8 w - - 0 1', 'Rc5+ Kg4 Ra5',
                 accept={1: 'only', 2: 'win'}, origin='miles26'),
        exercise('e10', 2, '6r1/8/7K/8/4k2P/2P2R2/8/8 w - - 0 1', 'Rf7',
                 accept='win', origin='tarraschRule'),
        exercise('e12', 2, '8/8/8/1r3P2/2p5/7R/3k2K1/8 w - - 0 1', 'f6',
                 accept='hold', goal='draw', origin='audax6'),
        exercise('e13', 2, 'r7/8/4pkp1/7p/P4P1P/6P1/5K2/4R3 w - - 0 1', 'Re4',
                 accept='only', origin='tarraschRule'),
        exercise('e14', 3, 'R7/8/P4pp1/7p/4k2P/r5P1/4KP2/8 w - - 0 1', 'f3+',
                 accept='only', origin='tarraschRule'),
        exercise('e15', 3, '1R6/5P2/4K3/8/2p5/p1P5/k4r2/8 w - - 0 1', 'Rb5',
                 accept='only', origin='audax6'),
    ],
    'passScore': 10,
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
