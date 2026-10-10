"""Gera `rook.shortSide.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.shortSide.py`
e depois o `build_aula.py rook.shortSide`. O aluno defende de brancas: as
posições das fontes entram espelhadas (ver `tools/check_hold.py --mirror`);
as das partidas (Ward-Arkell, Aronian-Carlsen) entram na orientação real, com o
aluno de pretas, para o link do Lichess abrir na mesma posição."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

LATE = '1R6/8/8/8/4pk2/8/r7/4K3 b - - 0 1'   # Philidor já não dá: pretas jogam
BEHIND = after(LATE, 'Kf3')                   # só Te8
SIDES = after(BEHIND, 'Re8 Ke3 Kf1')
FP = '1R6/8/8/8/5p2/6k1/r7/5K2 w - - 0 1'    # peão de bispo
FP2 = after(FP, 'Rf8 Kf3')                    # só Rg1 (lado curto)
BLUNDER = after(FP, 'Rf8 Kf3 Ke1')            # o rei foi para o lado longo
SHORTROOK = '6R1/8/8/8/5p2/5k2/7r/5K2 w - - 0 1'  # torre preta no lado curto
TARR = '5r2/R7/8/8/8/8/4p1K1/4k3 w - - 0 1'  # xeques laterais (Tarrasch)
K5 = '5R2/8/8/8/4p3/4k3/6K1/4r3 w - - 0 1'   # Karstedt 1897, espelhada
FLANKNOW = '2R5/8/8/8/8/3p4/1K1k4/3r4 w - - 0 1'  # peão na 3.ª: só Th8
TB = '5r2/1R6/8/8/8/8/4p1K1/4k3 w - - 0 1'   # Tarrasch com a torre em b: perde
CLOSE = '3r4/1R6/8/8/8/4p3/4k1K1/8 w - - 0 1'  # torre perto demais: perde
FAR = '3r4/R7/8/8/8/4p3/4k1K1/8 w - - 0 1'   # só Ta2+
BT = after(FAR, 'Ra2+ Rd2')                   # a torre preta tapou: não trocar
# Partidas, na orientação real (o aluno joga de pretas, como o mestre).
ARKELL45 = '6k1/R7/5K2/5P2/6r1/8/8/8 b - - 0 45'    # Ward-Arkell, ply 89
ARKELL51 = '5R2/7k/5K2/5P2/5r2/8/8/8 b - - 12 51'   # ply 101
G145 = 'r7/4K1k1/3RP3/8/8/8/8/8 b - - 4 73'         # Aronian-Carlsen, ply 145
G147 = '4K3/r5k1/3RP3/8/8/8/8/8 b - - 6 74'         # depois de 73...Ta7+ 74.Re8
LONG = '5R2/8/8/8/8/5p2/5k1K/5r2 w - - 0 1'  # a torre precisa do lado longo
WAIT8 = '8/8/8/8/4p3/8/R1rk2K1/8 w - - 0 1'  # esperar na primeira fileira
S1 = 'R7/8/8/8/4p3/5k2/1r6/4K3 w - - 0 1'
KARSTEDT = '5R2/8/8/8/4p3/4k3/7r/4K3 w - - 0 1'  # Karstedt 1897, espelhada
LATEST = '4R3/8/8/8/8/4p3/4k1K1/4r3 w - - 0 1'   # o último momento do flanco
TARR_D = 'r2K4/3P1k2/8/8/8/8/8/4R3 w - - 0 1'    # Tarrasch 1906: o aluno ataca
E14 = '8/8/8/5r1R/8/2p5/3k4/1K6 w - - 0 1'   # peão de bispo na outra ala: só Th2+

WARD_ARKELL = ('d4_d5_c4_dxc4_e4_Nc6_Nf3_Bg4_Bxc4_Bxf3_Qxf3_e6_d5_Ne5_Bb5+_c6_'
               'Qc3_Bd6_dxc6_bxc6_Bxc6+_Nxc6_Qxc6+_Ke7_Qb7+_Qc7_Qxc7+_Bxc7_Bg5+_'
               'Nf6_Nd2_Rhc8_Rc1_h6_Bxf6+_Kxf6_Ke2_Bf4_g3_Bxd2_Kxd2_Rcb8_b3_Rb4_'
               'Ke3_a5_Rhd1_a4_Rc4_Rxc4_bxc4_Rb8_Rd2_g5_f4_g4_c5_Ke7_f5_a3_Rd3_'
               'Rb2_Rxa3_Rxh2_Kf4_exf5_exf5_Rc2_Kxg4_Rxc5_Ra6_Rc2_Rxh6_Rxa2_Kg5_'
               'Rg2_g4_f6+_Kh5_Kf7_Rh7+_Kg8_Rb7_Rg1_Ra7_Rg2_Kg6_Rxg4+_Kxf6_Rf4_'
               'Ra8+_Kh7_Ke6_Kg7_Ra7+_Kf8_Kf6_Kg8_Ra8+_Kh7_Rf8_Ra4_Rf7+_Kg8_Re7_'
               'Kf8_Re6_Ra7_Rb6_Rf7+_Kg5_Ra7_f6_Kf7')
ARONIAN_CARLSEN = (
    'd4_Nf6_c4_e6_Nf3_b6_g3_Ba6_Qc2_Nc6_Nbd2_d5_cxd5_Qxd5_e4_Nb4_Qa4+_Qd7_'
    'Qxd7+_Nxd7_Bxa6_Nxa6_O-O_Nf6_a3_c5_Re1_Be7_Ne5_Rc8_b4_cxd4_Ndf3_Nb8_'
    'Nxd4_Nfd7_Nef3_O-O_Bf4_Nc6_Rac1_Nxd4_Nxd4_g5_Nc6_Rxc6_Rxc6_gxf4_Rc7_'
    'Ne5_Rxe7_Nf3+_Kf1_Nxe1_Kxe1_a5_Rb7_axb4_axb4_Rd8_f3_Rd3_Ke2_Rb3_Rxb6_'
    'Rb2+_Kd3_Rxh2_gxf4_h5_Rb5_h4_Rh5_h3_Kd4_Kf8_Ke5_Ke7_f5_exf5_Kxf5_Rb2_'
    'Rxh3_Rxb4_f4_Rb5+_e5_Kf8_Rd3_Rb4_Kg5_Kg7_Rd7_Rb5_Kg4_Kf8_Kf5_Kg7_Ke4_'
    'Rb4+_Rd4_Rb1_Rd7_Re1+_Kd5_Rd1+_Kc6_Rf1_Rd4_Kf8_Kd7_Rf2_Kd6_Rf1_Kd5_'
    'Ke7_Ra4_f6_Ra7+_Kf8_Kd6_fxe5_Ra8+_Kf7_Ra7+_Kf8_fxe5_Rd1+_Ke6_Re1_Rf7+_'
    'Ke8_Rh7_Kf8_Rh8+_Kg7_Rd8_Ra1_Ke7_Ra5_e6_Ra7+_Rd7_Ra8_Rd6_Ra7+_Ke8')


def ref(step, reference):
    """O passo vem de uma partida ou estudo (`id` ou `id#ply`)."""
    step['ref'] = reference
    return step


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
    {'id': 'gotham', 'kind': 'study', 'author': 'GothamMath',
     'title': 'Short-Side Defence',
     'url': 'https://lichess.org/study/F1UmnASX'},
    {'id': 'practice2', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Intermediate Rook Endings',
     'url': 'https://lichess.org/study/heQDnvq7'},
    {'id': 'nunn', 'kind': 'book', 'author': 'John Nunn',
     'title': 'Secrets of Rook Endings', 'publisher': 'Gambit Publications',
     'year': 1999},
    {'id': 'wardArkell1994', 'kind': 'game', 'white': 'Chris Ward',
     'black': 'Keith Arkell', 'event': 'Campeonato Britânico, Norwich',
     'year': 1994,
     'url': 'https://lichess.org/analysis/pgn/' + WARD_ARKELL + '#89'},
    {'id': 'wardArkellSrc', 'kind': 'web',
     'title': 'Ward vs Arkell, Norwich 1994 (chessgames.com)',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=2246825'},
    {'id': 'aronianCarlsen2006', 'kind': 'game', 'white': 'Levon Aronian',
     'black': 'Magnus Carlsen', 'event': 'Memorial Tal, Moscou', 'year': 2006,
     'url': 'https://lichess.org/analysis/pgn/' + ARONIAN_CARLSEN + '#145'},
    {'id': 'aronianCarlsenSrc', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Carlsen (Carlsen.zip)',
     'url': 'https://www.pgnmentor.com/players/Carlsen.zip'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'rook.shortSide',
    'module': 'rook',
    'skills': ['rook.shortSide'],
    'parts': [
        {'id': 'behind', 'steps': [
            think('t_behind', BEHIND, 2, ask='plan'),
            talk('behind', BEHIND, arrows=['b8e8', 'e8e4']),
            demo('d_late', after(BEHIND, 'Rb3+'),
                 'e3 Rd3 Ra1+ Rd1 Rxd1+ Kxd1 Kf2', goal='win', side='black'),
            move('behindPawn', BEHIND, 'Re8', accept='only', goal='draw'),
        ]},
        {'id': 'short', 'steps': [
            think('t_short', FP2, 2),
            talk('sides', FP2, arrows=['f1g1'],
                 marks=['g1', 'h1', 'a1', 'b1', 'c1', 'd1', 'e1']),
            ref(demo('d_arkell1', ARKELL45,
                     'Rf4 Ra8+ Kh7 Ke6 Kg7 Ra7+ Kf8 Kf6 Kg8', goal='draw',
                     side='black',
                     notes={1: {'arrows': ['g4f4']}, 3: {'marks': ['h7']}}),
                'wardArkell1994'),
            demo('d_blunder', BLUNDER, 'Ra1+ Kd2 Rf1 Rf5 Kg2 Rg5+ Kf2',
                 goal='win', side='black',
                 notes={1: {'marks': ['d2']}, 7: {'marks': ['e1', 'e2', 'e3']}}),
            move('shortRook', SHORTROOK, 'Kg1', accept='only', goal='draw'),
        ]},
        {'id': 'lateral', 'steps': [
            think('t_tarrasch', TARR, 2),
            ref(talk('lateral', TARR, arrows=['a7a1'], marks=['f1', 'f2']),
                'rookPawn'),
            demo('d_checks', TARR, 'Ra1+ Kd2 Ra2+ Kd3 Ra3+ Kd4', goal='draw'),
            move('checks', after(TARR, 'Ra1+ Kd2 Ra2+ Kd3 Ra3+ Kd4'),
                 'Ra4+ Kc3 Ra3+ Kb2 Re3', accept='only', goal='draw'),
        ]},
        {'id': 'flank', 'steps': [
            think('t_karstedt', K5, 3),
            ref(talk('karstedt', K5, arrows=['f8a8'],
                     marks=['a8', 'b8', 'c8', 'd8']), 'karstedt'),
            demo('d_karstedt', K5, 'Ra8 Rd1 Re8 Rd4 Kf1 Kd2 Kf2', goal='draw',
                 notes={1: {'arrows': ['f8a8']}, 3: {'arrows': ['e8e4']}}),
            ref(demo('d_arkell2', ARKELL51, 'Ra4 Rf7+ Kg8 Re7 Kf8 Re6 Ra7',
                     goal='draw', side='black',
                     notes={1: {'arrows': ['f4a4']}}),
                'wardArkell1994#101'),
            move('flankNow', FLANKNOW, 'Rh8 Ke2 Rh2+',
                 accept={1: 'only', 2: 'hold'}, goal='draw'),
        ]},
        {'id': 'distance', 'steps': [
            think('t_close', TB, 2),
            talk('distance', TB, arrows=['b7b1'], marks=['c1', 'd1']),
            demo('d_close', TB, 'Rb1+ Kd2 Rb2+ Kd3 Rb3+ Kc2 Re3 Kd2',
                 goal='win', side='black',
                 notes={6: {'arrows': ['c2b3']}}),
            move('closeWin', after(TB, 'Rb1+ Kd2 Rb2+'),
                 'Kd3 Rb3+ Kc2 Re3 Kd2',
                 accept={1: 'win', 2: ['Kc2'], 3: 'win'}, goal='win'),
        ]},
        {'id': 'block', 'steps': [
            think('t_block', FAR, 2),
            talk('block', FAR, arrows=['a7a2', 'd8d2'], marks=['e1']),
            demo('d_trade', BT, 'Rxd2+ Kxd2 Kf3 e2 Kf2 e1=Q+', goal='win',
                 side='black', notes={5: {'marks': ['e1']}}),
            move('blockE', BT, 'Ra1 Rd1 Ra2+ Ke1 Kf3 e2 Rxe2+',
                 accept={1: 'hold', 2: 'hold', 3: 'only', 4: 'hold'},
                 goal='draw'),
        ]},
        {'id': 'carlsen', 'steps': [
            think('t_carlsen', G145, 2, side='black'),
            ref(talk('carlsen', G145, arrows=['g7g6', 'a8a7'], side='black'),
                'aronianCarlsen2006'),
            ref(demo('d_carlsenError', G147, 'Ra8+ Rd8 Ra6 e7', goal='win',
                     side='white', notes={2: {'marks': ['e8']}}),
                'aronianCarlsen2006#147'),
            ref(move('king', G145, 'Kg6 Kd7 Kf6 e7+ Kf7 Re6 Ra7+',
                     accept={1: 'only', 2: 'hold', 3: 'only', 4: 'only'},
                     goal='draw'), 'aronianCarlsen2006'),
            talk('recap', SIDES, arrows=['e8e4'], marks=['f1']),
            play('finish', S1, goal='draw'),
        ]},
    ],
    'exercises': [
        exercise('e14', 1, E14, 'Rh2+ Kd3 Rh3+', accept='only', goal='draw'),
        exercise('e11', 2, KARSTEDT, 'Kf1 Rh1+ Kg2', accept='only',
                 goal='draw', origin='karstedt'),
        exercise('e13', 2, TARR_D, 'Kc7 Ra7+ Kc8 Ra8+ Kb7 Rd8 Kc7',
                 accept={1: 'only', 2: 'win', 3: 'win', 4: 'win'},
                 goal='win', origin='rookPawn'),
        exercise('e10', 3, after(S1, 'Rf8+ Ke3 Kf1 Rb1+ Kg2 Ke2'),
                 'Rf2+ Kd3 Ra2 e3 Ra3+ Kd2 Ra2+',
                 accept={1: 'hold', 2: 'only', 3: 'only', 4: 'hold'},
                 goal='draw', origin='yuri61'),
        exercise('e09', 3, WAIT8, 'Ra1 e3 Kf3 e2 Kf2 Rb2 Re1 Kd3 Ra1',
                 accept={1: 'hold', 2: 'hold', 3: 'only', 4: 'only',
                         5: 'only'},
                 goal='draw', origin='yuri61'),
    ],
    'passScore': 7,
    'keyPositions': [
        {'id': 'behind', 'fen': BEHIND, 'ref': 'profangel'},
        {'id': 'tarrasch', 'fen': TARR, 'ref': 'rookPawn'},
        {'id': 'karstedt', 'fen': K5, 'ref': 'karstedt'},
        {'id': 'arkell', 'fen': ARKELL45, 'ref': 'wardArkell1994'},
        {'id': 'close', 'fen': CLOSE, 'ref': 'rookPawn'},
        {'id': 'carlsen', 'fen': G145, 'ref': 'aronianCarlsen2006'},
    ],
    'practice': {'fen': S1, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
})
