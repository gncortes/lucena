"""Gera `rook.shortSide.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.shortSide.py`
e depois o `build_aula.py rook.shortSide`. O aluno defende de brancas: as
posições das fontes entram espelhadas (ver `tools/check_hold.py --mirror`)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import after, exercise, move, talk, write  # noqa: E402

LATE = '1R6/8/8/8/4pk2/8/r7/4K3 b - - 0 1'   # Philidor já não dá: pretas jogam
BEHIND = after(LATE, 'Kf3')                   # só Te8
SIDES = after(BEHIND, 'Re8 Ke3 Kf1')
FP = '1R6/8/8/8/5p2/6k1/r7/5K2 w - - 0 1'    # peão de bispo
BLUNDER = after(FP, 'Rf8 Kf3 Ke1')            # o rei foi para o lado longo
TARR = '5r2/R7/8/8/8/8/4p1K1/4k3 w - - 0 1'  # xeques laterais (Tarrasch)
CLOSE = '3r4/1R6/8/8/8/4p3/4k1K1/8 w - - 0 1'  # torre perto demais: perde
CARLSEN = '8/8/8/8/8/3rp3/4k1K1/R7 w - - 0 1'  # só Rg3
LONG = '5R2/8/8/8/8/5p2/5k1K/5r2 w - - 0 1'  # a torre precisa do lado longo
WAIT8 = '8/8/8/8/4p3/8/R1rk2K1/8 w - - 0 1'  # esperar na primeira fileira
S1 = 'R7/8/8/8/4p3/5k2/1r6/4K3 w - - 0 1'

REFERENCES = [
    {'id': 'rookPawn', 'kind': 'web',
     'title': 'Rook and pawn versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame'},
    {'id': 'karstedt', 'kind': 'web',
     'title': 'Max Karstedt (Wikipedia, em alemão)',
     'url': 'https://de.wikipedia.org/wiki/Max_Karstedt'},
    {'id': 'stripes', 'kind': 'web',
     'title': 'James Stripes: Kling and Horwitz Defense (Chess Skills)',
     'url': 'https://chessskill.blogspot.com/2024/04/kling-and-horwitz-defense.html'},
    {'id': 'profangel', 'kind': 'study', 'author': 'ProfAngel',
     'title': 'Rook Endings. The Philidor Position.',
     'url': 'https://lichess.org/study/a1ss97T0'},
    {'id': 'yuri61', 'kind': 'study', 'author': 'Yuri61',
     'title': 'Rook Endgames: Lucena & Philidor',
     'url': 'https://lichess.org/study/dDyC6HS6'},
    {'id': 'noseknows', 'kind': 'study', 'author': 'NoseKnowsAll',
     'title': 'Intermediate Endgames You Must Know!',
     'url': 'https://lichess.org/study/UsqmCsgC'},
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
    'id': 'rook.shortSide',
    'module': 'rook',
    'steps': [
        talk('intro', LATE, arrows=['f4f3', 'b8b3'], marks=['f3']),
        move('behindPawn', BEHIND, 'Re8 Ke3 Kf1',
             accept={1: 'only', 2: 'hold'}, goal='draw'),
        talk('sides', SIDES, marks=['f1', 'g1', 'h1', 'a1', 'b1', 'c1', 'd1']),
        move('dance', after(SIDES, 'Ra1+'), 'Kg2 Kd3 Kf2 Ra2+ Ke1 Ke3 Kf1',
             accept={1: 'only', 2: 'only', 3: 'hold', 4: 'hold'}, goal='draw'),
        move('fpawn', FP, 'Rf8 Kf3 Kg1 Ra1+ Kh2',
             accept={1: 'hold', 2: 'only', 3: 'only'}, goal='draw'),
        talk('blunder', BLUNDER, arrows=['a2a1', 'a1f1'], marks=['e1']),
        talk('lateral', TARR, arrows=['a7a1'], marks=['g2']),
        move('checks', TARR,
             'Ra1+ Kd2 Ra2+ Kd3 Ra3+ Kd4 Ra4+ Kc3 Ra3+ Kb2 Re3',
             accept='only', goal='draw'),
        talk('distance', CLOSE, arrows=['b7b2', 'd8d2'], marks=['b7']),
        talk('carlsen', CARLSEN, arrows=['g2g3'], marks=['g3']),
        move('king', CARLSEN, 'Kg3 Rd2 Kg2 Kd3+ Kf3 e2 Kf2',
             accept={1: 'only', 2: 'hold', 3: 'hold', 4: 'hold'}, goal='draw'),
        talk('recap', SIDES, arrows=['e8e4'], marks=['f1']),
    ],
    'exercises': [
        exercise('e01', 1, BEHIND, 'Re8', accept='only', goal='draw',
                 origin='profangel'),
        exercise('e02', 1, after(BEHIND, 'Re8 Ke3'), 'Kf1', accept='hold',
                 goal='draw', origin='profangel'),
        exercise('e03', 1, after(FP, 'Rf8 Kf3'), 'Kg1', accept='only',
                 goal='draw', origin='rookPawn'),
        exercise('e04', 1, TARR, 'Ra1+', accept='only', goal='draw',
                 origin='rookPawn'),
        exercise('e05', 2, S1, 'Rf8+ Ke3 Kf1',
                 accept={1: 'hold', 2: 'only'}, goal='draw', origin='yuri61'),
        exercise('e06', 2,
                 after(TARR, 'Ra1+ Kd2 Ra2+ Kd3 Ra3+ Kd4 Ra4+ Kc3'),
                 'Ra3+ Kb2 Re3', accept='only', goal='draw',
                 origin='rookPawn'),
        exercise('e07', 2, CARLSEN, 'Kg3', accept='only', goal='draw',
                 origin='noseknows'),
        exercise('e08', 2, LONG, 'Ra8 Re1 Ra2+', accept='hold', goal='draw',
                 origin='profangel'),
        exercise('e09', 3, WAIT8, 'Ra1 e3 Kf3 e2 Kf2 Rb2 Re1 Kd3 Ra1',
                 accept={1: 'hold', 2: 'hold', 3: 'only', 4: 'only',
                         5: 'only'},
                 goal='draw', origin='yuri61'),
        exercise('e10', 3, after(S1, 'Rf8+ Ke3 Kf1 Rb1+ Kg2 Ke2'),
                 'Rf2+ Kd3 Ra2 e3 Ra3+ Kd2 Ra2+',
                 accept={1: 'hold', 2: 'only', 3: 'only', 4: 'hold'},
                 goal='draw', origin='yuri61'),
    ],
    'passScore': 11,
    'keyPositions': [
        {'id': 'behind', 'fen': BEHIND, 'ref': 'profangel'},
        {'id': 'tarrasch', 'fen': TARR, 'ref': 'rookPawn'},
        {'id': 'close', 'fen': CLOSE, 'ref': 'rookPawn'},
        {'id': 'carlsen', 'fen': CARLSEN, 'ref': 'noseknows'},
    ],
    'practice': {'fen': S1, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
})
