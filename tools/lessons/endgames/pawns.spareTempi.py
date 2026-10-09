"""Gera `pawns.spareTempi.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/pawns.spareTempi.py`
e depois o `build_aula.py pawns.spareTempi`. Quase toda a aula gira em torno
do mesmo trebuchet (Re5 e peão de d4 contra Rc4 e peão de d5): quem tem um
lance de peão sobrando ganha. Tudo com até 7 peças, julgado pela tabela."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

TREB = '8/8/8/3pK3/2kP4/8/8/8 w - - 0 1'            # trebuchet: quem joga perde
PASS = '8/8/8/3pK3/2kP4/8/7P/8 w - - 0 1'           # + h2: h3/h4 ganham
EQUAL = '8/7p/8/3pK3/2kP4/8/7P/8 w - - 0 1'         # h2 contra h7: quem joga perde
EQUAL_B = '8/7p/8/3pK3/2kP4/8/7P/8 b - - 0 1'
EXTRA = '8/7p/8/3pK3/2kP4/8/6PP/8 w - - 0 1'        # g2 e h2 contra h7
H5 = '8/8/8/3pK2p/2kP4/8/7P/8 w - - 0 1'            # h4! (h3? perde)
H4 = '8/8/8/3pK3/2kP3p/8/7P/8 w - - 0 1'            # h3, o único
DRMKC = '8/8/2p1k1p1/2P3P1/4K3/8/2P5/8 w - - 0 1'   # estudo de DrMkcTheHandsome
NO_C2 = '8/8/2p1k1p1/2P3P1/4K3/8/8/8 w - - 0 1'     # o mesmo sem o peão de c2
C4_WRONG = after(DRMKC, 'c4 Kf7 Ke5 Ke7')            # c4? gastou os dois tempos
TIMING = '8/8/7p/3p4/1k1P4/5K2/7P/8 w - - 0 1'      # Rf4!, o peão espera
EARLY = after(TIMING, 'h3 Kc4 Kf4 h5 Ke5 h4')        # h3? cedo: as pretas ficam com o último
TIMING_B5 = '8/8/7p/1k1p4/3P4/5K2/7P/8 w - - 0 1'
FINISH = '8/8/7p/1k1p4/3P4/4K3/7P/8 w - - 0 1'
GH = after('8/6kp/8/6K1/6P1/8/7P/8 b - - 0 1', 'Kg8 Kh6 Kh8')  # suvkos, "gh vs h"
BURGESS = '8/8/7p/Kp6/1Pk5/8/7P/8 w - - 0 1'        # zugzwang de Burgess (Wikipedia), reduzido
MAISELIS = '8/8/8/5p1p/5k2/8/5K1P/8 w - - 0 1'     # suvkos, "Maiselis white": Re2! empata
SUVKOS = '8/2k5/2p5/2P5/8/8/1P6/5K2 w - - 0 1'     # suvkos cap. 3 / DrMkc parte 3

REFERENCES = [
    {'id': 'wikiTempo', 'kind': 'web',
     'title': 'Wikipedia: Tempo (chess)',
     'url': 'https://en.wikipedia.org/wiki/Tempo_(chess)'},
    {'id': 'wikiZugzwang', 'kind': 'web',
     'title': 'Wikipedia: Zugzwang',
     'url': 'https://en.wikipedia.org/wiki/Zugzwang'},
    {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
     'title': "Dvoretsky's Endgame Manual (6.ª edição, revista por Karsten "
              'Müller e Alex Fishbein)',
     'publisher': 'Russell Enterprises', 'year': 2025,
     'where': 'Índice da amostra da editora: "Reserve Tempi", p. 71'},
    {'id': 'suvkos', 'kind': 'study', 'author': 'suvkos',
     'title': 'Reserve Tempi',
     'url': 'https://lichess.org/study/YQzBce48'},
    {'id': 'drmkc', 'kind': 'study', 'author': 'DrMkcTheHandsome',
     'title': 'Endgame Reserve Tempi',
     'url': 'https://lichess.org/study/txfLBiBv'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'pawns.spareTempi',
    'module': 'pawns',
    'skills': ['pawns.spareTempi'],
    'parts': [
        {'id': 'pass', 'steps': [
            think('t_pass', PASS, 5, 2, ask='plan',
                  arrows=['e5d5', 'c4d4'], marks=['h2']),
            talk('treb', TREB, arrows=['e5d5', 'c4d4'], marks=['d4', 'd5']),
            talk('spare', PASS, arrows=['h2h3'], marks=['h2']),
            demo('d_pass', PASS, 'h3 Kb3 Kxd5 Kc3 h4',
                 notes={1: {'arrows': ['h2h3']},
                        3: {'marks': ['d5']},
                        5: {'arrows': ['h4h8', 'd4d8']}}),
            move('passMove', PASS, 'h4 Kc3 Kxd5', accept={1: 'win', 2: 'only'}),
        ]},
        {'id': 'count', 'steps': [
            think('t_count', EQUAL, 3, 2, marks=['h2', 'h7']),
            talk('equal', EQUAL, arrows=['h2h3', 'h7h6'], marks=['h3', 'h4',
                                                                 'h5', 'h6']),
            demo('d_equal', EQUAL_B, 'h6 h3 h5 h4 Kb4 Kxd5',
                 notes={2: {'arrows': ['h3h4']},
                        4: {'marks': ['h4', 'h5']}}),
            talk('extra', EXTRA, arrows=['g2g3', 'h2h3'], marks=['g2', 'h2',
                                                                 'h7']),
            move('extraMove', EXTRA, 'g3 h5 h3 h4 g4', accept='win'),
        ]},
        {'id': 'double', 'steps': [
            think('t_double', DRMKC, 5, 3, arrows=['e4e5'], marks=['c2']),
            talk('noReserve', NO_C2, marks=['e4', 'e6']),
            talk('c4wrong', C4_WRONG, arrows=['c2c4'], marks=['c4']),
            demo('d_double', DRMKC, 'c3 Kf7 Ke5 Ke7 c4 Kd7 Kf6 Kc7 Kxg6',
                 notes={1: {'arrows': ['c2c3']},
                        3: {'marks': ['e5']},
                        5: {'arrows': ['c3c4']},
                        7: {'arrows': ['f6g6']}}),
            move('doubleMove', DRMKC, 'c3 Kf7 Ke5 Ke7 c4', accept={1: 'win', 2: 'only', 3: 'win'}),
        ]},
        {'id': 'timing', 'steps': [
            think('t_timing', TIMING, 3, 2, arrows=['f3e5'], marks=['h2']),
            talk('early', EARLY, arrows=['h5h4'], marks=['h3', 'h4']),
            demo('d_timing', TIMING, 'Kf4 Kc4 Ke5 h5 h4 Kc3 Kxd5',
                 notes={1: {'arrows': ['f4e5']},
                        3: {'marks': ['e5']},
                        5: {'arrows': ['h2h4']}}),
            move('timingMove', TIMING_B5, 'Kf4 Kc4 Ke5 Kc3 Kxd5',
                 accept='win'),
        ]},
        {'id': 'recap', 'steps': [
            talk('rules', PASS, marks=['h2']),
            talk('jump', H5, arrows=['h2h4'], marks=['h3', 'h4']),
            move('jumpMove', H5, 'h4 Kc3 Kxd5', accept='win'),
            play('finish', FINISH),
        ]},
    ],
    'exercises': [
        exercise('e02', 1, H4, 'h3', accept='win'),
        exercise('e08', 2, GH, 'g5 Kg8 h3', accept='win', origin='suvkos'),
        exercise('e11', 2, BURGESS, 'h3 h5 h4', accept='win',
                 origin='wikiTempo'),
        exercise('e10', 3, SUVKOS, 'Ke2 Kd7 Kd3', accept='win',
                 origin='suvkos'),
        exercise('e12', 3, MAISELIS, 'Ke2 h4 Kf2', accept='hold',
                 goal='draw', origin='suvkos'),
    ],
    'passScore': 7,
    'keyPositions': [
        {'id': 'pass', 'fen': PASS},
        {'id': 'drmkc', 'fen': DRMKC, 'ref': 'drmkc'},
    ],
    'practice': {'fen': DRMKC, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
})
