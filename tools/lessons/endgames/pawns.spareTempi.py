"""Gera `pawns.spareTempi.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/pawns.spareTempi.py`
e depois o `build_aula.py pawns.spareTempi`. As duas primeiras partes usam um
trebuchet na ala do rei (Rg5 e peão de f4 contra Re4 e peão de f5) com os
tempos de reserva na coluna a, para não repetir o e02 (trebuchet do centro com
peões de h). Até 7 peças, julgado pela tabela; as três posições de
Nunn–Bischoff (9 peças) só em think/talk, julgadas pelo Stockfish (dossiê)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)


def ref(step, id):
    step['ref'] = id
    return step


TREB = '8/8/8/5pK1/4kP2/8/8/8 w - - 0 1'            # trebuchet: quem joga perde
PASS = '8/8/8/5pK1/4kP2/8/P7/8 w - - 0 1'           # + a2: a3/a4 ganham
EQUAL = '8/p7/8/5pK1/4kP2/8/P7/8 w - - 0 1'         # a2 contra a7: quem joga perde
EQUAL_B = '8/p7/8/5pK1/4kP2/8/P7/8 b - - 0 1'
EXTRA = '8/p7/8/5pK1/4kP2/8/PP6/8 w - - 0 1'        # a2 e b2 contra a7
H4 = '8/8/8/3pK3/2kP3p/8/7P/8 w - - 0 1'            # e02: h3, o único
DRMKC = '8/8/2p1k1p1/2P3P1/4K3/8/2P5/8 w - - 0 1'   # estudo de DrMkcTheHandsome
NO_C2 = '8/8/2p1k1p1/2P3P1/4K3/8/8/8 w - - 0 1'     # o mesmo sem o peão de c2
C4_WRONG = after(DRMKC, 'c4')                        # 1.c4? gasta os dois tempos
NUNN_41 = '8/5p2/2k3p1/p1Pp2P1/3K1P2/8/P7/8 w - - 0 41'   # 39...Rc6 40.Rd4 a5
NUNN_39 = '8/3k1p2/p5p1/2Pp2P1/5P2/2K5/P7/8 b - - 3 39'   # depois de 39.Rc3 (ply 77)
NUNN_A6 = '8/5p2/p1k3p1/2Pp2P1/3K1P2/8/P7/8 w - - 6 41'   # 39...Rc7 40.Rd4 Rc6
NUNN_MINI = '8/8/2k5/p1Pp4/3K4/8/P7/8 w - - 0 1'    # Nunn sem os peões de f e g
TIMING = '8/8/7p/3p4/1k1P4/5K2/7P/8 w - - 0 1'      # Rf4!, o peão espera
EARLY = after(TIMING, 'h4')                          # 1.h4? cedo
EARLY2 = '8/8/8/3p3p/3P3P/2k1K3/8/8 w - - 0 3'     # 1.h4? Rc3 2.Re3 h5: travaram
TIMING_B5 = '8/8/7p/1k1p4/3P4/5K2/7P/8 w - - 0 1'
DEF = '8/8/7p/1k1p4/3P4/8/2K4P/8 w - - 0 1'         # defesa: só 1.Rb3 empata
DEF_ERR = after(DEF, 'h3')                           # 1.h3? perde
FINISH = '8/8/7p/1k1p4/3P4/4K3/7P/8 w - - 0 1'
GH = after('8/6kp/8/6K1/6P1/8/7P/8 b - - 0 1', 'Kg8 Kh6 Kh8')  # suvkos, "gh vs h"
BURGESS = '8/8/7p/Kp6/1Pk5/8/7P/8 w - - 0 1'        # zugzwang de Burgess (Wikipedia), reduzido
MAISELIS = '8/8/8/5p1p/5k2/8/5K1P/8 w - - 0 1'     # suvkos, "Maiselis white": Re2! empata
SUVKOS = '8/2k5/2p5/2P5/8/8/1P6/5K2 w - - 0 1'     # suvkos cap. 3 / DrMkc parte 3

NUNN_URL = (
    'https://lichess.org/analysis/pgn/e4_c5_Nf3_e6_d4_cxd4_Nxd4_Nf6_Nc3_d6_g4'
    '_h6_h4_a6_Bg2_Nc6_g5_hxg5_hxg5_Rxh1+_Bxh1_Nd7_Bg2_g6_f4_Qb6_Nde2_Qc5_Qd3'
    '_b5_b3_Bb7_Bb2_Rc8_O-O-O_Nb4_Qd2_Nxc2_Kxc2_b4_Kb1_Qf2_Bh1_bxc3_Bxc3_Qa7'
    '_Bb2_Qa8_Qe3_Nc5_Nc3_Bg7_Nd5_Bxb2_Nb6_Bxe4+_Kxb2_Qa7_Rxd6_Nd3+_Ka3_Rc6'
    '_Rxc6_Qe7+_Qc5_Qxc5+_Rxc5_Nxc5_b4_Bxh1_bxc5_Bd5_Nxd5_exd5_Kb4_Kd7_Kc3#77')

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
    {'id': 'drmkcPart1', 'kind': 'study', 'author': 'DrMkcTheHandsome',
     'title': 'Endgame Reserve Tempi: Reserve Tempi Part 1',
     'url': 'https://lichess.org/study/txfLBiBv/KNxrWvip'},
    {'id': 'nunnBischoff', 'kind': 'game', 'white': 'John Nunn',
     'black': 'Klaus Bischoff', 'event': 'Lugano Open', 'year': 1986,
     'url': NUNN_URL},
    {'id': 'cgNunnBischoff', 'kind': 'web',
     'title': 'chessgames.com: John Nunn vs Klaus Bischoff (1986)',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=1103457'},
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
            think('t_pass', PASS, 2, ask='plan',
                  arrows=['g5f5', 'e4f4'], marks=['a2']),
            talk('treb', TREB, arrows=['g5f5', 'e4f4'], marks=['f4', 'f5']),
            talk('spare', PASS, arrows=['a2a3'], marks=['a2']),
            demo('d_pass', PASS, 'a3 Kd3 Kxf5 Ke3 a4',
                 notes={1: {'arrows': ['a2a3']},
                        3: {'marks': ['f5']},
                        5: {'arrows': ['a4a8', 'f4f8']}}),
            move('passMove', PASS, 'a4', accept='win'),
        ]},
        {'id': 'count', 'steps': [
            think('t_count', EQUAL, 2, marks=['a2', 'a7']),
            talk('equal', EQUAL, arrows=['a2a3', 'a7a6'],
                 marks=['a3', 'a4', 'a5', 'a6']),
            demo('d_equal', EQUAL_B, 'a6 a3 a5 a4 Kd4 Kxf5',
                 notes={2: {'arrows': ['a3a4']},
                        4: {'marks': ['a4', 'a5']}}),
            talk('extra', EXTRA, arrows=['b2b3', 'a2a3'],
                 marks=['a2', 'b2', 'a7']),
            move('extraMove', EXTRA, 'b3 a5 a3 a4 b4', accept='win'),
        ]},
        {'id': 'double', 'steps': [
            ref(think('t_double', DRMKC, 3, arrows=['e4e5'], marks=['c2']),
                'drmkcPart1'),
            ref(talk('noReserve', NO_C2, marks=['e4', 'e6']), 'drmkcPart1'),
            ref(demo('d_c4', C4_WRONG, 'Kf7 Ke5 Ke7 Kf4 Ke6 Ke4', goal='draw',
                     notes={1: {'marks': ['c4']},
                            3: {'marks': ['e7']}}), 'drmkcPart1'),
            ref(demo('d_double', DRMKC, 'c3 Kf7 Ke5 Ke7 c4 Kd7 Kf6 Kc7 Kxg6',
                     notes={1: {'arrows': ['c2c3']},
                            3: {'marks': ['e5']},
                            5: {'arrows': ['c3c4']},
                            7: {'arrows': ['f6g6']}}), 'drmkcPart1'),
            ref(move('doubleMove', DRMKC, 'c3 Kf7 Ke5 Ke7 c4',
                     accept={1: 'win', 2: 'only', 3: 'win'}), 'drmkcPart1'),
        ]},
        {'id': 'nunn', 'steps': [
            think('t_nunn', NUNN_41, 3, marks=['a2', 'a5']),
            ref(talk('nb_game', NUNN_39, arrows=['c3d4', 'a2a4']),
                'nunnBischoff'),
            talk('nb_other', NUNN_A6, arrows=['a2a3'], marks=['a6']),
            demo('d_nunn', NUNN_MINI, 'a4 Kd7 Kxd5 Kc7 c6 Kc8 Kc5',
                 notes={1: {'arrows': ['a2a4']},
                        3: {'marks': ['d5']},
                        7: {'arrows': ['c5a5']}}),
            move('nunnMove', NUNN_MINI, 'a4 Kd7 Kxd5',
                 accept={1: 'only', 2: 'win'}),
        ]},
        {'id': 'timing', 'steps': [
            think('t_timing', TIMING, 2, arrows=['f3f4', 'f4e5'],
                  marks=['h2']),
            talk('early', EARLY, side='white', arrows=['b4c3', 'c3d4']),
            talk('early2', EARLY2, side='white', marks=['d4', 'h4', 'h5']),
            demo('d_timing', TIMING, 'Kf4 Kc4 Ke5 h5 h4 Kc3 Kxd5',
                 notes={1: {'arrows': ['f4e5']},
                        3: {'marks': ['e5']},
                        5: {'arrows': ['h2h4']}}),
            move('timingMove', TIMING_B5, 'Kf4 Kc4 Ke5 Kc3 Kxd5',
                 accept='win'),
        ]},
        {'id': 'defense', 'steps': [
            think('t_def', DEF, 3, marks=['a4', 'b4', 'c4']),
            talk('defIdea', DEF, arrows=['c2b3', 'h6h5']),
            talk('defError', DEF_ERR, arrows=['b5c4', 'c4d4'],
                 marks=['h3']),
            demo('d_def', DEF, 'Kb3 h5 h4 Ka5 Ka3 Kb5 Kb3', goal='draw',
                 notes={1: {'marks': ['a4', 'b4', 'c4']},
                        3: {'marks': ['h3', 'h4']},
                        5: {'marks': ['a4', 'b4']}}),
            move('defMove', DEF, 'Kb3 h5 h4', accept={1: 'only', 2: 'only'},
                 goal='draw'),
        ]},
        {'id': 'recap', 'steps': [
            think('t_finish', FINISH, 2, marks=['h2']),
            talk('rules', PASS, marks=['a2']),
            talk('rulesDefense', DEF, marks=['b3', 'h2', 'h6']),
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
        {'id': 'drmkc', 'fen': DRMKC, 'ref': 'drmkcPart1'},
    ],
    'practice': {'fen': DRMKC, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
})
