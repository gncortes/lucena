"""Gera `rook.frontal.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.frontal.py`
e depois o `build_aula.py rook.frontal`. O aluno defende de brancas: as
posições das fontes entram espelhadas (ver `tools/check_hold.py --mirror`)."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play,  # noqa: E402
                         talk, think)

FRONT = '8/5r2/6k1/6p1/8/8/4K3/1R6 w - - 0 1'   # Emms: peão de cavalo
FRONTC = '8/5r2/8/6pk/8/8/4K3/1R6 w - - 0 1'   # o rei preto foi para h5
EMMS = '8/4r3/5k2/5p2/8/8/3K4/1R6 w - - 0 1'   # Emms: peão de bispo
EMMSB = '8/4r3/5k2/5p2/8/8/3K4/1R6 b - - 0 1'  # pretas jogam: Rg5! ganha
FIVE = '8/5r2/8/6k1/6p1/8/4K3/1R6 w - - 0 1'   # peão na quinta: só a troca
FIVEB = '8/5r2/8/6k1/6p1/8/4K3/1R6 b - - 0 1'
BPAWN = '8/8/1k1r4/1p6/8/4K3/8/2R5 w - - 0 1'  # prática do Lichess
CPAWN = '4r3/8/2k5/2p5/8/5K2/8/2R5 b - - 0 1'  # mesma distância, perde
RANK = '2r5/8/1k6/1p1K4/8/8/8/1R6 w - - 0 1'   # Yuri61: só Rd4
RANKX = after(RANK, 'Rb2 Rc4')                 # o rei ficou na fileira
FAR = '8/5r2/6k1/6p1/8/8/2K5/R7 w - - 0 1'     # rei longe: só Rd3
QUICK = '8/5r2/6k1/6p1/8/8/3K4/4R3 w - - 0 1'  # torre fora do lugar
CAPA = '8/3r1p2/4k3/8/2K5/8/8/7R w - - 0 1'    # Capablanca, torre pronta
SIDE = after('3r4/8/2k5/2p5/8/4K3/8/2R5 w - - 0 1', 'Rh1 c4')  # Yuri61

REFERENCES = [
    {'id': 'rookPawn', 'kind': 'web',
     'title': 'Rook and pawn versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame'},
    {'id': 'practice2', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Intermediate Rook Endings',
     'url': 'https://lichess.org/study/heQDnvq7'},
    {'id': 'yuri61', 'kind': 'study', 'author': 'Yuri61',
     'title': 'Rook Endgames: Lucena & Philidor',
     'url': 'https://lichess.org/study/dDyC6HS6'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

LESSON = {
    'id': 'rook.frontal',
    'module': 'rook',
    'skills': ['rook.frontal'],
    'parts': [
        {'id': 'front', 'steps': [
            think('t_front', FRONTC, 5, 2, ask='line'),
            talk('intro', FRONTC, arrows=['f7f1', 'b1h1'],
                 marks=['g4', 'g3', 'g2']),
            demo('d_checks', FRONTC, 'Rh1+ Kg4 Rg1+ Kh4 Rh1+ Kg3 Rg1+',
                 goal='draw', notes={1: {'arrows': ['h1h5']},
                                     3: {'arrows': ['g1g4']}}),
            move('checks', FRONTC, 'Rh1+ Kg4 Rg1+ Kh3 Rxg5',
                 accept='only', goal='draw'),
        ]},
        {'id': 'trade', 'steps': [
            think('t_emms', EMMS, 5, 2),
            talk('emms', EMMSB, arrows=['f6g5', 'e7e5'], marks=['g5']),
            demo('d_trade', FRONT, 'Rf1 Rxf1 Kxf1 Kf5 Kg1 Kf4 Kf2',
                 goal='draw', notes={1: {'arrows': ['b1f1']},
                                     5: {'marks': ['g1']}}),
            talk('rule3', FIVEB, marks=['g3', 'g2']),
            move('five', FIVE, 'Rf1 Rxf1 Kxf1 Kh4 Kg2',
                 accept='only', goal='draw'),
        ]},
        {'id': 'files', 'steps': [
            think('t_bpawn', BPAWN, 5, 2, ask='line'),
            talk('bishop', CPAWN, arrows=['e8e1'], marks=['d4', 'b4']),
            talk('knight', BPAWN, marks=['a5', 'a4', 'a3']),
            move('getFront', BPAWN, 'Rb1 Ka5 Ra1+ Kb4 Rb1+ Kc4 Rc1+',
                 accept='only', goal='draw'),
        ]},
        {'id': 'king', 'steps': [
            think('t_rank', RANK, 5, 2),
            talk('rank', RANKX, arrows=['c4h4'], marks=['d5', 'b5']),
            talk('farKing', FAR, arrows=['c2d3'], marks=['f2', 'f1']),
            move('far', FAR, 'Kd3 Kh5 Rh1+ Kg4 Rg1+ Kh4 Rh1+',
                 accept='only', goal='draw'),
        ]},
        {'id': 'recap', 'steps': [
            talk('recap', FRONT, arrows=['f7f1'], marks=['g4', 'g3', 'g2']),
            talk('when', FRONTC),
            move('quick', QUICK, 'Rg1 Kh5 Rh1+ Kg4 Rg1+ Kh3 Rxg5',
                 accept='only', goal='draw'),
            play('finish', FRONT, goal='draw'),
        ]},
    ],
    'exercises': [
        exercise('e01', 1, '8/5r2/8/6pk/8/8/3K4/R7 w - - 0 1',
                 'Rh1+ Kg4 Rg1+', accept='only', goal='draw'),
        exercise('e02', 1, '8/2r5/8/kp6/8/8/4K3/1R6 w - - 0 1', 'Ra1+',
                 accept='only', goal='draw'),
        exercise('e03', 1, '8/2r5/8/1k6/1p6/8/3K4/7R w - - 0 1',
                 'Rc1 Rxc1 Kxc1', accept='only', goal='draw'),
        exercise('e04', 2, '8/2r5/1k6/1p6/8/8/4K3/3R4 w - - 0 1',
                 'Rb1 Ka5 Ra1+ Kb4 Rb1+ Ka4 Ra1+', accept='only',
                 goal='draw'),
        exercise('e05', 2, '5r2/8/6k1/4K1p1/8/8/8/6R1 w - - 0 1',
                 'Ke4 Kh5 Rh1+ Kg4 Rg1+', accept='only', goal='draw'),
        exercise('e06', 2, EMMS, 'Re1 Rxe1 Kxe1 Ke5 Kf1',
                 accept={1: 'hold', 2: 'only', 3: 'only'}, goal='draw',
                 origin='rookPawn'),
        exercise('e07', 2, CAPA, 'Re1+ Kf5 Rf1+ Kg4 Rg1+ Kh3 Rf1',
                 accept={1: 'only', 2: 'hold', 3: 'only', 4: 'only'},
                 goal='draw', origin='rookPawn'),
        exercise('e08', 3, SIDE, 'Rh5', accept='hold', goal='draw',
                 origin='yuri61'),
        exercise('e09', 3, after(EMMS, 'Kd3 Kg5'),
                 'Rg1+ Kh4 Rf1 Kg4 Rg1+', accept='only', goal='draw',
                 origin='rookPawn'),
        exercise('e10', 3, '8/2r5/8/1pk5/8/8/5K2/R7 w - - 0 1',
                 'Ke3 Kb4 Rb1+ Ka3 Rxb5', accept='only', goal='draw'),
    ],
    'passScore': 12,
    'keyPositions': [
        {'id': 'front', 'fen': FRONT, 'ref': 'rookPawn'},
        {'id': 'emms', 'fen': EMMS, 'ref': 'rookPawn'},
        {'id': 'bpawn', 'fen': BPAWN, 'ref': 'practice2'},
        {'id': 'rank', 'fen': RANK, 'ref': 'yuri61'},
        {'id': 'capa', 'fen': CAPA, 'ref': 'rookPawn'},
    ],
    'practice': {'fen': FRONT, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
}

OUT = Path(__file__).with_suffix('.json')
OUT.write_text(json.dumps(LESSON, ensure_ascii=False, indent=2) + '\n')
print('Escrito', OUT)
