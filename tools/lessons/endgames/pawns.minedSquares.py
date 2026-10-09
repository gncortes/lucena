"""Gera `pawns.minedSquares.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/pawns.minedSquares.py`
e depois o `build_aula.py pawns.minedSquares`. O aluno joga de brancas: ganha
nas partes do trebuchet, das casas minadas e da corrida, e empata na parte da
defesa, em que o zugzwang recíproco salva quem defende."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

TREB = '8/8/8/3pK3/2kP4/8/8/8 b - - 0 1'           # trebuchet (Flear, pela Wikipedia)
TREB_W = '8/8/8/3pK3/2kP4/8/8/8 w - - 0 1'         # o mesmo, brancas na vez
TREB_IN = '8/8/4K3/3p4/2kP4/8/8/8 w - - 0 1'       # entrar no trebuchet: Ke5
MINED = '8/8/1k1p4/3P1K2/8/8/8/8 w - - 0 1'        # casas minadas (Wikipedia; RyanGarg)
MINED_TRAP = after(MINED, 'Ke6 Kc5')               # Ke6? Kc5: brancas em zugzwang
RACE = '8/2K5/4p3/4P3/6k1/8/8/8 w - - 0 1'         # monsienne, cap. 1: só Kd7
RACE_TRAP = after(RACE, 'Kd6 Kf5')                 # Kd6? Kf5: brancas em zugzwang
DEFEND = '8/8/8/8/3p1k2/1K1P4/8/8 w - - 0 1'       # cores trocadas de MINED: só Kb4
DEFEND_TRAP = after(DEFEND, 'Kc4 Ke3')             # Kc4? Ke3: brancas em zugzwang
MINED_E = '8/8/4p1k1/2K1P3/8/8/8/8 w - - 0 1'      # MINED espelhado na coluna e
CHEESE = '8/8/1Kp5/4p3/4P3/7k/8/8 w - - 0 1'       # ThisIsCheeseman, cores trocadas
RODNEY = '8/1k6/8/1Pp3p1/6P1/2K5/8/8 w - - 0 1'    # Rodney_Opada, cap. 1
HOOPER = '2k5/2P5/K7/8/8/8/8/8 w - - 0 1'          # rumo ao zugzwang de Hooper (Wikipedia)
C_LOW = '8/8/8/4K3/k1p5/2P5/8/8 w - - 0 1'         # monsienne, cap. 11: empate, Kd4? perde

REFERENCES = [
    {'id': 'wikiZugzwang', 'kind': 'web',
     'title': 'Wikipedia: Zugzwang (seções "Reciprocal zugzwang", '
              '"Trébuchet" e "Mined squares")',
     'url': 'https://en.wikipedia.org/wiki/Zugzwang'},
    {'id': 'wikiCorresponding', 'kind': 'web',
     'title': 'Wikipedia: Corresponding squares',
     'url': 'https://en.wikipedia.org/wiki/Corresponding_squares'},
    {'id': 'wikiTrebuchet', 'kind': 'web',
     'title': 'Wikipedia: Trebuchet (etimologia)',
     'url': 'https://en.wikipedia.org/wiki/Trebuchet'},
    {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
     'title': "Dvoretsky's Endgame Manual (6.ª edição, revista por Karsten "
              'Müller e Alex Fishbein)',
     'publisher': 'Russell Enterprises', 'year': 2025,
     'where': 'Índice da amostra da editora: "Mined Squares", p. 23'},
    {'id': 'monsienne', 'kind': 'study', 'author': 'monsienne',
     'title': 'TREBUCHETs',
     'url': 'https://lichess.org/study/eolTlSZl'},
    {'id': 'ryanGarg', 'kind': 'study', 'author': 'RyanGarg',
     'title': 'Mined Squares',
     'url': 'https://lichess.org/study/sRutl3W9'},
    {'id': 'rodneyOpada', 'kind': 'study', 'author': 'Rodney_Opada',
     'title': 'Reciprocal Zugzwang',
     'url': 'https://lichess.org/study/fu63jTLH'},
    {'id': 'daedricrift', 'kind': 'study', 'author': 'Daedricrift',
     'title': 'Mined Squares',
     'url': 'https://lichess.org/study/Iw9Nv19E'},
    {'id': 'cheeseman', 'kind': 'study', 'author': 'ThisIsCheeseman',
     'title': 'Endgame - Trebuchet',
     'url': 'https://lichess.org/study/Ga9cbsMH'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'pawns.minedSquares',
    'module': 'pawns',
    'skills': ['pawns.trebuchet'],
    'parts': [
        {'id': 'trebuchet', 'steps': [
            think('t_treb', TREB, 3, 2, marks=['d4', 'd5']),
            talk('treb', TREB, arrows=['c4d5', 'e5d4'], marks=['d4', 'd5']),
            talk('name', TREB_W, arrows=['c4d5', 'e5d4']),
            demo('d_treb', TREB, 'Kb4 Kxd5 Kb5 Kd6',
                 notes={2: {'marks': ['d5']},
                        4: {'marks': ['c6', 'd6', 'e6']}}),
            move('trebMove', TREB_IN, 'Ke5 Kb4 Kxd5', accept='win'),
        ]},
        {'id': 'mined', 'steps': [
            think('t_mined', MINED, 5, 3, marks=['e6', 'c5']),
            talk('mines', MINED, arrows=['f5e6', 'b6c5'], marks=['e6', 'c5']),
            talk('trap', MINED_TRAP, arrows=['c5d5'], marks=['e6', 'c5']),
            demo('d_mined', MINED, 'Kf6 Kb5 Ke7 Kc5 Ke6 Kb6 Kxd6',
                 notes={1: {'marks': ['e7']},
                        3: {'arrows': ['e7d6']},
                        5: {'marks': ['e6', 'c5']}}),
            move('minedMove', MINED, 'Kf6 Kb5 Ke7 Kc5 Ke6', accept='win'),
        ]},
        {'id': 'race', 'steps': [
            think('t_race', RACE, 3, 2, marks=['d6', 'f5']),
            talk('race', RACE, arrows=['c7d7', 'd7e6'], marks=['d6', 'f5']),
            talk('raceTrap', RACE_TRAP, arrows=['f5e5'], marks=['d6', 'f5']),
            demo('d_race', RACE, 'Kd7 Kf5 Kd6 Kg5 Kxe6',
                 notes={1: {'arrows': ['d7e6']},
                        3: {'marks': ['d6', 'f5']}}),
            move('raceMove', RACE, 'Kd7 Kf4 Kxe6', accept='win'),
        ]},
        {'id': 'defend', 'steps': [
            think('t_defend', DEFEND, 3, 2, marks=['c4', 'e3']),
            talk('defend', DEFEND, arrows=['b3b4', 'f4e3'], marks=['c4', 'e3']),
            talk('defendTrap', DEFEND_TRAP, arrows=['e3d3'],
                 marks=['c4', 'e3']),
            demo('d_defend', DEFEND, 'Kb4 Ke3 Kc4 Kf3 Kxd4', goal='draw',
                 notes={1: {'marks': ['c4']},
                        3: {'marks': ['c4', 'e3']}}),
            move('defendMove', DEFEND, 'Kb4 Kf3 Kc5', accept='hold',
                 goal='draw'),
        ]},
        {'id': 'recap', 'steps': [
            talk('rules', MINED, marks=['e6', 'c5']),
            talk('mirror', MINED_E, marks=['d6', 'f5']),
            move('mirrorMove', MINED_E, 'Kc6 Kg5 Kd7 Kf5 Kd6', accept='win'),
            play('finish', MINED),
        ]},
    ],
    'exercises': [
        exercise('e11', 1, HOOPER, 'Kb6', accept='win',
                 origin='wikiZugzwang'),
        exercise('e13', 2, C_LOW, 'Kd5', accept='hold', goal='draw',
                 origin='monsienne'),
        exercise('e08', 2, RODNEY, 'Kd3', accept='hold', goal='draw',
                 origin='rodneyOpada'),
        exercise('e10', 3, CHEESE, 'Kxc6 Kg4 Kd6 Kf4 Kd5', accept='win',
                 origin='cheeseman'),
    ],
    'passScore': 5,
    'keyPositions': [
        {'id': 'trebuchet', 'fen': TREB, 'ref': 'wikiZugzwang'},
        {'id': 'mined', 'fen': MINED, 'ref': 'wikiZugzwang'},
        {'id': 'race', 'fen': RACE, 'ref': 'monsienne'},
        {'id': 'cheeseman', 'fen': '8/8/7p/4p2K/4P3/1kP5/8/8 w - - 0 1',
         'ref': 'cheeseman'},
    ],
    'practice': {'fen': MINED, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
})
