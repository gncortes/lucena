"""Gera `rook.philidor.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.philidor.py`
e depois o `build_aula.py rook.philidor`. O aluno defende de brancas: as
posições das fontes entram espelhadas (ver `tools/check_hold.py --mirror`)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, exercise, move, play, talk, think,  # noqa: E402
                         write)

PH = '8/8/8/8/4pk2/R7/7r/4K3 b - - 0 1'     # Philidor, pretas jogam
PHW = '8/8/8/8/4pk2/R7/7r/4K3 w - - 0 1'    # a mesma, brancas jogam
REACH = '8/8/8/8/4pk2/8/r7/1R2K3 w - - 0 1'  # falta tomar a terceira fileira
E3 = '8/8/8/8/5k2/R3p3/7r/4K3 w - - 0 1'    # o peão pisou na terceira
EARLY = after('1R6/8/8/8/4pk2/8/r7/4K3 w - - 0 1', 'Rf8+ Ke3')
PASSIVE = after(E3, 'Rb3 Kf3')
TRADE = after('8/8/8/8/3kp3/8/4K2R/6r1 w - - 0 1',
              'Rh3 Rg2+ Kd1 Ra2 Rg3 e3 Rg8 Ra5')
BISHOP = '6R1/8/8/8/2pk4/8/7r/3K4 w - - 0 1'
ADVANCED = '8/8/8/8/3kpR2/8/7r/4K3 w - - 0 1'
# Exercícios da régua T58 (2026-10-09).
AVOID = '8/8/8/8/3kp1R1/8/7r/4K3 w - - 0 1'      # tomar a terceira, sem pegar o peão
EXPEL = '8/8/8/8/2pk4/8/7r/3KR3 w - - 0 1'       # rei na frente, xeque na terceira
PH1777 = '8/8/8/5R2/3kp3/8/r7/4K3 w - - 0 1'     # Philidor 1777, cores trocadas
SIDE = '8/8/8/8/3pk3/R7/8/3K3r w - - 0 1'        # xeque lateral, peão de dama
KINGFIRST = '8/8/8/8/1kp5/1r6/4K3/4R3 w - - 0 1'  # rei primeiro, sem o espeto

REFERENCES = [
    {'id': 'wikipedia', 'kind': 'web', 'title': 'Philidor position (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Philidor_position'},
    {'id': 'rookPawn', 'kind': 'web',
     'title': 'Rook and pawn versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame'},
    {'id': 'stripes', 'kind': 'web',
     'title': 'James Stripes: Kling and Horwitz Defense (Chess Skills)',
     'url': 'https://chessskill.blogspot.com/2024/04/kling-and-horwitz-defense.html'},
    {'id': 'practice', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Basic Rook Endgames',
     'url': 'https://lichess.org/study/pqUSUw8Y'},
    {'id': 'practice2', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Intermediate Rook Endings',
     'url': 'https://lichess.org/study/heQDnvq7'},
    {'id': 'profangel', 'kind': 'study', 'author': 'ProfAngel',
     'title': 'Rook Endings. The Philidor Position.',
     'url': 'https://lichess.org/study/a1ss97T0'},
    {'id': 'ehenkes', 'kind': 'study', 'author': 'ehenkes',
     'title': 'Ending: Rook Philidor',
     'url': 'https://lichess.org/study/imxK73yH'},
    {'id': 'yuri61', 'kind': 'study', 'author': 'Yuri61',
     'title': 'Rook Endgames: Lucena & Philidor',
     'url': 'https://lichess.org/study/dDyC6HS6'},
    {'id': 'noseknows', 'kind': 'study', 'author': 'NoseKnowsAll',
     'title': 'Rook Endgames You Must Know!',
     'url': 'https://lichess.org/study/bnboDhFM'},
    {'id': 'nunn', 'kind': 'book', 'author': 'John Nunn',
     'title': 'Secrets of Rook Endings', 'publisher': 'Gambit Publications',
     'year': 1999},
    {'id': 'audax6', 'kind': 'study', 'author': 'Audax6',
     'title': '14 The Philidor Position (Third Rank Defense)',
     'url': 'https://lichess.org/study/AvGk7RWH'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'rook.philidor',
    'module': 'rook',
    'skills': ['rook.philidor'],
    'parts': [
        {'id': 'third', 'steps': [
            think('t_classic', PH, 5, 1, side='white'),
            talk('intro', PH, arrows=['a3h3'], marks=['e1', 'f3', 'g3', 'e3']),
            move('take', REACH, 'Rb3 Rh2 Ra3', accept='hold', goal='draw'),
            talk('pawn', E3, arrows=['f4f3', 'h2h1', 'a3a8'], marks=['e3']),
            move('behind', E3, 'Ra8 Kf3 Rf8+ Ke4 Re8+ Kd3 Rd8+',
                 accept={1: 'hold', 2: 'only', 3: 'hold', 4: 'only'},
                 goal='draw'),
        ]},
        {'id': 'errors', 'steps': [
            talk('early', EARLY, arrows=['a2a1'], marks=['e3']),
            talk('passive', PASSIVE, arrows=['h2h1'], marks=['f3']),
            talk('trade', TRADE, arrows=['g8d8', 'a5d5']),
            move('endgame', TRADE, 'Rd8+ Rd5 Rxd5+ Kxd5 Ke2 Kd4 Ke1',
                 accept={1: 'hold', 2: 'hold', 3: 'hold', 4: 'only'},
                 goal='draw'),
        ]},
        {'id': 'beyond', 'steps': [
            think('t_bishop', BISHOP, 5, 1, ask='line'),
            talk('bishop', BISHOP, arrows=['g8g3'], marks=['c1']),
            talk('limits', ADVANCED, arrows=['f4f8'], marks=['f3']),
            talk('recap', PH, arrows=['a3h3', 'a3a8']),
            play('finish', REACH, goal='draw'),
        ]},
    ],
    'exercises': [
        exercise('e15', 1, AVOID, 'Rg3', accept='hold', goal='draw',
                 origin='practice'),
        exercise('e12', 2, SIDE, 'Kd2', accept='hold', goal='draw',
                 origin='audax6'),
        exercise('e11', 2, PH1777, 'Rb5 Ke3 Rb3+',
                 accept={1: 'hold', 2: 'hold'}, goal='draw',
                 origin='wikipedia'),
        exercise('e16', 3, EXPEL, 'Kc1 Kc3 Re3+',
                 accept={1: 'only', 2: 'only'}, goal='draw'),
        exercise('e14', 3, KINGFIRST, 'Kd2 Rb2+ Kc1 Rh2 Re3',
                 accept={1: 'only', 2: 'only', 3: 'hold'}, goal='draw'),
    ],
    'passScore': 7,
    'keyPositions': [
        {'id': 'classic', 'fen': PH, 'ref': 'wikipedia'},
        {'id': 'reach', 'fen': REACH, 'ref': 'practice'},
        {'id': 'bishop', 'fen': BISHOP, 'ref': 'yuri61'},
        {'id': 'advanced', 'fen': ADVANCED, 'ref': 'practice2'},
    ],
    'practice': {'fen': REACH, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
})
