"""Gera `rook.backRank.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.backRank.py`
e depois o `build_aula.py rook.backRank`. O aluno defende de brancas: as
posições das fontes entram espelhadas (ver `tools/check_hold.py --mirror`)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, exercise, move, play, talk, think,  # noqa: E402
                         write)

KN = '8/8/8/8/8/5kp1/r7/1R4K1 b - - 0 1'     # peão de cavalo, defesa passiva
KNW = after(KN, 'Kg4')                        # a mesma, brancas jogam
TRICK = '8/8/8/8/8/6pk/6r1/1R4K1 w - - 0 1'  # o truque: xeque em g2
TRICKB = '8/8/8/8/8/kp6/1r6/1K4R1 w - - 0 1'  # o mesmo na outra ala
LUCENA = after(TRICK, 'Kf1 Kh2')              # o erro: caiu na Lucena
BISHOP = '8/8/8/8/8/5pk1/1r6/R5K1 b - - 0 1'  # peão de bispo: perde
BISHOP2 = after(BISHOP, 'Rg2+ Kf1 Rh2')
ACTIVE = '8/8/8/8/6k1/5p2/r7/1R3K2 w - - 0 1'  # o rei ainda não chegou
EARLY = '8/8/8/8/5pk1/8/r7/2R3K1 w - - 0 1'   # dá tempo de armar Philidor
KNIGHT5 = '7R/8/8/8/6p1/5rk1/8/6K1 w - - 0 1'  # por trás não serve
ROOKPAWN = '8/8/8/8/8/6kp/r7/1R5K b - - 0 1'
SEVENTH = '8/8/8/8/8/8/r2kpK2/1R6 w - - 0 1'  # peão na sétima

REFERENCES = [
    {'id': 'rookPawn', 'kind': 'web',
     'title': 'Rook and pawn versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame'},
    {'id': 'chessmood', 'kind': 'web',
     'title': 'Hovhannes Gabuzyan: Theoretical Rook Endgames (ChessMood)',
     'url': 'https://chessmood.com/blog/rook-endgames'},
    {'id': 'profangel', 'kind': 'study', 'author': 'ProfAngel',
     'title': 'Rook Endings. The Philidor Position.',
     'url': 'https://lichess.org/study/a1ss97T0'},
    {'id': 'practice2', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Intermediate Rook Endings',
     'url': 'https://lichess.org/study/heQDnvq7'},
    {'id': 'nunn', 'kind': 'book', 'author': 'John Nunn',
     'title': 'Secrets of Rook Endings', 'publisher': 'Gambit Publications',
     'year': 1999},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'rook.backRank',
    'module': 'rook',
    'parts': [
        {'id': 'wait', 'steps': [
            think('t_knight', KN, 5, 1),
            talk('intro', KN, arrows=['b1h1'], marks=['g1', 'h1']),
            talk('room', KN, marks=['h1', 'h2', 'h3']),
            move('wait', KNW, 'Rc1 Kh3 Rb1 Rg2+ Kh1 Rh2+ Kg1',
                 accept={1: 'hold', 2: 'hold', 3: 'only', 4: 'only'},
                 goal='draw'),
        ]},
        {'id': 'corner', 'steps': [
            think('t_trick', TRICK, 5, 1, ask='line'),
            talk('corner', TRICK, arrows=['g1h1'], marks=['f1', 'h1']),
            talk('lucena', LUCENA, arrows=['h2g1'], marks=['g1']),
            talk('bishop', BISHOP2, arrows=['h2h1', 'f3f2'],
                 marks=['g1', 'h1']),
            talk('free', ACTIVE, arrows=['g4g3', 'b1b8']),
            move('active', ACTIVE, 'Rb8 Kg3 Rg8+ Kf4 Rf8+',
                 accept={1: 'hold', 2: 'only', 3: 'hold'}, goal='draw'),
        ]},
        {'id': 'home', 'steps': [
            talk('behind', KNIGHT5, arrows=['h8a8', 'a8a1'], marks=['g8']),
            move('home', KNIGHT5, 'Ra8 Rb3 Ra1',
                 accept={1: 'hold', 2: 'only'}, goal='draw'),
            talk('rookPawn', ROOKPAWN, marks=['h1']),
            talk('recap', KN, arrows=['b1h1']),
            play('finish', KNW, goal='draw'),
        ]},
    ],
    'exercises': [
        exercise('e01', 1, TRICK, 'Kh1', accept='only', goal='draw',
                 origin='rookPawn'),
        exercise('e02', 1, ACTIVE, 'Rb8', accept='hold', goal='draw',
                 origin='rookPawn'),
        exercise('e03', 1, after(KNIGHT5, 'Ra8 Rb3'), 'Ra1', accept='only',
                 goal='draw', origin='profangel'),
        exercise('e04', 1, KNIGHT5, 'Ra8', accept='hold', goal='draw',
                 origin='profangel'),
        exercise('e05', 2, KNW, 'Rc1 Kh3 Rb1 Rg2+ Kh1',
                 accept={1: 'hold', 2: 'hold', 3: 'only'}, goal='draw',
                 origin='rookPawn'),
        exercise('e06', 2, ACTIVE, 'Rb8 Kg3 Rg8+ Kf4 Rf8+',
                 accept={1: 'hold', 2: 'only', 3: 'hold'}, goal='draw',
                 origin='rookPawn'),
        exercise('e07', 2, TRICKB, 'Ka1 Ra2+ Kb1',
                 accept='only', goal='draw'),
        exercise('e08', 2, KNIGHT5, 'Ra8 Rb3 Ra1',
                 accept={1: 'hold', 2: 'only'}, goal='draw',
                 origin='profangel'),
        exercise('e09', 3, SEVENTH, 'Re1 Kd3 Rb1 Kd2 Re1', accept='only',
                 goal='draw', origin='rookPawn'),
        exercise('e10', 3, EARLY, 'Rc3 f3 Rc8 Kg3 Rg8+',
                 accept={1: 'hold', 2: 'hold', 3: 'only'}, goal='draw',
                 origin='chessmood'),
    ],
    'passScore': 11,
    'keyPositions': [
        {'id': 'knight', 'fen': KN, 'ref': 'rookPawn'},
        {'id': 'trick', 'fen': TRICK, 'ref': 'rookPawn'},
        {'id': 'bishop', 'fen': BISHOP, 'ref': 'rookPawn'},
        {'id': 'seventh', 'fen': SEVENTH, 'ref': 'rookPawn'},
    ],
    'practice': {'fen': KNW, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
})
