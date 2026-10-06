"""Gera `rook.philidor.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.philidor.py`
e depois o `build_aula.py rook.philidor`. O aluno defende de brancas: as
posições das fontes entram espelhadas (ver `tools/check_hold.py --mirror`)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import after, exercise, move, talk, write  # noqa: E402

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
HARASS = after('8/8/8/8/4pk2/R7/1r6/4K3 w - - 0 1',
               'Rc3 Rb1+ Ke2 Rb2+ Ke1 Rh2 Ra3 Rh1+')

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
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'rook.philidor',
    'module': 'rook',
    'steps': [
        talk('intro', PH, arrows=['a3h3'], marks=['e1', 'f3', 'g3', 'e3']),
        move('take', REACH, 'Rb3 Rh2 Ra3', accept='hold', goal='draw'),
        talk('pawn', E3, arrows=['f4f3', 'h2h1', 'a3a8'], marks=['e3']),
        move('behind', E3, 'Ra8 Kf3 Rf8+ Ke4 Re8+ Kd3 Rd8+',
             accept={1: 'hold', 2: 'only', 3: 'hold', 4: 'only'}, goal='draw'),
        talk('early', EARLY, arrows=['a2a1'], marks=['e3']),
        talk('passive', PASSIVE, arrows=['h2h1'], marks=['f3']),
        talk('trade', TRADE, arrows=['g8d8', 'a5d5']),
        move('endgame', TRADE, 'Rd8+ Rd5 Rxd5+ Kxd5 Ke2 Kd4 Ke1',
             accept={1: 'hold', 2: 'hold', 3: 'hold', 4: 'only'}, goal='draw'),
        talk('bishop', BISHOP, arrows=['g8g3'], marks=['c1']),
        talk('limits', ADVANCED, arrows=['f4f8'], marks=['f3']),
        talk('recap', PH, arrows=['a3h3', 'a3a8']),
    ],
    'exercises': [
        exercise('e01', 1, REACH, 'Rb3', accept='hold', goal='draw',
                 origin='practice'),
        exercise('e02', 1, E3, 'Ra8', accept='hold', goal='draw'),
        exercise('e03', 1, after(E3, 'Ra8 Kf3'), 'Rf8+', accept='only',
                 goal='draw'),
        exercise('e04', 1, BISHOP, 'Rg3', accept='hold', goal='draw',
                 origin='yuri61'),
        exercise('e05', 2, '8/8/8/8/3k4/4p3/4K3/8 w - - 0 1', 'Ke1',
                 accept='only', goal='draw'),
        exercise('e06', 2, PHW, 'Rb3 e3 Rb8 Kf3 Rf8+',
                 accept={1: 'hold', 2: 'hold', 3: 'only'}, goal='draw',
                 origin='wikipedia'),
        exercise('e07', 2, after(E3, 'Ra8 Kf3 Rf8+ Ke4 Re8+ Kd3'), 'Rd8+',
                 accept='only', goal='draw'),
        exercise('e08', 2, TRADE, 'Rd8+ Rd5 Rxd5+ Kxd5 Ke2 Kd4 Ke1',
                 accept={1: 'hold', 2: 'hold', 3: 'hold', 4: 'only'},
                 goal='draw', origin='ehenkes'),
        exercise('e09', 3, HARASS, 'Ke2 Rh2+ Ke1 e3 Ra8 Kf3 Rf8+',
                 accept={1: 'hold', 2: 'hold', 3: 'hold', 4: 'only'},
                 goal='draw', origin='noseknows'),
        exercise('e10', 3, ADVANCED, 'Rf7 Kd3 Re7 Rh1+ Kf2',
                 accept={1: 'hold', 2: 'only', 3: 'only'}, goal='draw',
                 origin='practice2'),
    ],
    'passScore': 11,
    'keyPositions': [
        {'id': 'classic', 'fen': PH, 'ref': 'wikipedia'},
        {'id': 'reach', 'fen': REACH, 'ref': 'practice'},
        {'id': 'bishop', 'fen': BISHOP, 'ref': 'yuri61'},
        {'id': 'advanced', 'fen': ADVANCED, 'ref': 'practice2'},
    ],
    'practice': {'fen': REACH, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
})
