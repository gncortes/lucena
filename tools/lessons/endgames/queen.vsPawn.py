"""Gera `queen.vsPawn.json` (a fonte da aula: dama contra peão central e de
cavalo na sétima) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/queen.vsPawn.py`
e depois o `build_aula.py queen.vsPawn`. O aluno joga de brancas.

Lição refeita na T61 (2026-10-10), pelo plano em
docs/aulas/LICAO-queen.vsPawn.md. Os exercícios ficam como estavam (T58)."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import demo, move, play, talk, think  # noqa: E402


def ref(step, rid):
    step['ref'] = rid
    return step


# Parte 1: a escada (posição própria; a linha é a do estudo de Danghiangmanh)
START = 'K7/8/8/8/8/8/3kp3/6Q1 w - - 0 1'
STAIRS_F = 'K7/7Q/8/8/8/8/4pk2/8 w - - 0 1'        # própria, do lado f
# Parte 2: o ciclo (capítulo "Beginner" do estudo, depois de 3...Re1)
FRONT = 'K7/8/8/8/8/3Q4/4p3/4k3 w - - 0 4'
CYCLE2 = '8/1K6/8/8/8/5Q2/4p3/4k3 w - - 0 9'      # o estudo, depois de 8...Re1
# Parte 3: o lance calmo
QUIET = '8/8/2K5/8/3Q4/8/2k1p3/8 w - - 0 12'      # o estudo, com 11...Rc2
SEIRAWAN = '3Q4/1K6/8/8/8/4k3/4p3/8 w - - 0 2'     # Wikipedia, depois de 1...Re3
QUIET_B = 'K7/8/8/8/2Q5/8/1p1k4/8 w - - 0 1'       # própria, peão de cavalo
# Parte 4: a coroação cobre o xeque (próprias, achadas na tabela)
PIN = '8/8/8/8/4K3/8/1p4Q1/k7 w - - 0 1'           # só Dg7
PIN_MOVE = '8/8/8/3K3Q/8/8/1p6/k7 w - - 0 1'       # De5 ou Dh8
# Parte 5: deixar coroar (próprias)
LETQ = '8/8/8/8/Q3K3/8/6pk/8 w - - 0 1'           # só Rf3 (g1=D Dh4#)
FORK = '8/8/8/8/8/2Q2K2/7k/6n1 w - - 0 1'          # Rf4? Ce2+
# Parte 6: o nosso rei fecha uma linha
BLOCK = '2Q5/8/8/3K4/8/8/3kp3/8 w - - 0 1'         # Müller e Lamprecht (Wikipedia)
UNBLOCK = '2Q5/8/8/4K3/8/8/3kp3/8 w - - 0 1'       # o mesmo, rei em e5
BLOCK_MOVE = '8/8/8/7Q/5K2/8/3p4/2k5 w - - 0 1'    # própria: só Dc5+
# Parte 7: peão na sexta (Alatortsev-Chekhover 1937, ply 136)
RACE = '1K2r3/P7/8/8/8/5p2/2R2Pk1/8 w - - 21 69'
SIXTH = '7K/8/8/8/8/2p5/1k6/3Q4 w - - 0 1'         # própria: só Dd4
PRACTICE = '3K2Q1/8/8/8/8/5k2/3p4/8 w - - 0 1'     # catálogo queen.queenVsPawn.0005

AC_URL = ('https://lichess.org/analysis/pgn/d4_Nf6_c4_e6_g3_Bb4+_Bd2_Qe7_Bg2_Nc6_Nf3_e5_dxe5_Nxe5_Nxe5_Bxd2+_Qxd2_Qxe5_Nc3_O-O_O-O_d6_Rfe1_Qc5_Nd5_Nxd5_cxd5_Qb6_Rac1_Bd7_Rc3_c5_dxc6_Bxc6_Bxc6_bxc6_Rec1_c5_Rb3_Qa6_Ra3_Qb6_Rb3_Qa6_Ra3_Qb6_Rd3_Rad8_b3_Qc6_Rd5_Rfe8_e3_h6_Qd3_Qc7_Rd1_Re6_e4_Rc8_Rxd6_Rxd6_Qxd6_Qxd6_Rxd6_c4_bxc4_Rxc4_Ra6_Rxe4_Rxa7_Re1+_Kg2_Ra1_h4_g6_Kf3_Re1_Rd7_Kg7_Rd2_Kf6_Re2_Rd1_Ke3_Kf5_Rd2_Rc1_Kd3_Kg4_Rc2_Rd1+_Ke2_Ra1_Ke3_Re1+_Kd2_Ra1_Kc3_g5_hxg5_hxg5_Kb2_Re1_a4_f5_Kb3_f4_gxf4_gxf4_a5_f3_a6_Kh3_a7_Re8_Ra2_Ra8_Kc4_Kg2_Kc5_Rc8+_Kb6_Re8_Kc6_Kf1_Kb7_Re7+_Kb6_Re8_Rc2_Kg2_Kc7_Re7+_Kb8_Re8+_Rc8_Rxc8+_Kxc8_Kxf2_a8=Q_Ke3_Qd5_Kf2_Kd7_Kg3_Ke6_f2_Qh1'
          '#136')

REFERENCES = [
    {'id': 'delaVilla', 'kind': 'book', 'author': 'Jesús de la Villa',
     'title': '100 Endgames You Must Know (4th, improved edition)',
     'publisher': 'New In Chess', 'year': 2015,
     'where': 'Ending 16, "Queen vs. 7th-rank pawn", p. 59'},
    {'id': 'wikipedia', 'kind': 'web',
     'title': 'Queen versus pawn endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Queen_versus_pawn_endgame'},
    {'id': 'dang', 'kind': 'study', 'author': 'Danghiangmanh',
     'title': 'Queen vs Pawn: Beginner',
     'url': 'https://lichess.org/study/4JKLMbtH/PyYtrCDe'},
    {'id': 'mario', 'kind': 'study', 'author': 'MarioPB4',
     'title': 'Queen vs. Promoting Pawn',
     'url': 'https://lichess.org/study/o2EZohXS'},
    {'id': 'alatortsevChekhover', 'kind': 'game',
     'white': 'Vladimir Alatortsev', 'black': 'Vitaly Chekhover',
     'event': 'URS-ch10, Tbilisi', 'year': 1937, 'url': AC_URL},
    {'id': 'chessgamesAC', 'kind': 'web',
     'title': 'Alatortsev vs Chekhover, URS-ch10 1937 (chessgames.com)',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=1313041'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

AC = 'alatortsevChekhover#136'

LESSON = {
    'id': 'queen.vsPawn',
    'module': 'queen',
    'skills': ['queen.vsPawn'],
    'parts': [
        {'id': 'start', 'steps': [
            think('t_start', START, 2, marks=['e1']),
            talk('intro', START, marks=['e1', 'e2', 'a8']),
            demo('d_stairs', STAIRS_F,
                 'Qh4+ Kf1 Qf4+ Kg1 Qe3+ Kf1 Qf3+ Ke1',
                 notes={1: {'arrows': ['h4e1']},
                        5: {'marks': ['e3', 'f2']},
                        7: {'marks': ['e1']},
                        8: {'marks': ['e1', 'e2']}}),
            move('stairs', START, 'Qd4+ Kc1 Qe3+ Kd1 Qd3+'),
        ]},
        {'id': 'cycle', 'steps': [
            ref(think('t_front', FRONT, 2), 'dang'),
            ref(talk('idea', FRONT, arrows=['a8b7'], marks=['e1', 'e2']),
                'dang'),
            ref(demo('d_tempo', FRONT,
                     'Kb7 Kf2 Qd2 Kf1 Qf4+ Kg1 Qe3+ Kf1 Qf3+ Ke1',
                     notes={1: {'arrows': ['a8b7']},
                            3: {'arrows': ['d2f2'], 'marks': ['e2']},
                            7: {'marks': ['e3', 'f2']},
                            10: {'marks': ['e1']}}), 'dang'),
            ref(move('cycle2', CYCLE2, 'Kc6 Kd2 Qf2'), 'dang'),
        ]},
        {'id': 'quiet', 'steps': [
            ref(think('t_quiet', QUIET, 2), 'dang'),
            ref(talk('quietWhy', QUIET, arrows=['d4e3'],
                     marks=['e3', 'd2', 'd3']), 'dang'),
            ref(demo('d_quiet', SEIRAWAN,
                     'Qh4 Kd2 Qd4+ Kc2 Qe3 Kd1 Qd3+ Ke1',
                     notes={1: {'arrows': ['h4e1']},
                            5: {'marks': ['d2', 'd3']},
                            8: {'marks': ['e1']}}), 'wikipedia'),
            move('quiet', QUIET_B, 'Qb3 Kc1 Qc3+'),
        ]},
        {'id': 'pin', 'steps': [
            think('t_pin', PIN, 2),
            talk('pinWhy', PIN, arrows=['g2g7', 'g7a1'], marks=['b1', 'g1']),
            demo('d_pin', PIN, 'Qg7 Ka2 Qf7+ Ka3 Qb7',
                 notes={1: {'arrows': ['g7a1']},
                        5: {'arrows': ['b7b1']}}),
            move('pinMove', PIN_MOVE, 'Qe5 Ka2 Qe2', accept='win'),
        ]},
        {'id': 'letQueen', 'steps': [
            think('t_fork', FORK, 2),
            talk('letqWhy', LETQ, arrows=['a4h4'], marks=['f3', 'g3', 'g2']),
            demo('d_letq', LETQ, 'Kf3 g1=Q Qh4#',
                 notes={1: {'marks': ['g2', 'g3']}, 3: {'arrows': ['a4h4']}}),
            demo('d_knight', LETQ, 'Kf3 g1=N+ Kf2 Nh3+ Ke3',
                 notes={2: {'marks': ['f3']}, 3: {'marks': ['g1']}}),
            move('fork', FORK, 'Kf2', accept='win'),
        ]},
        {'id': 'block', 'steps': [
            ref(think('t_block', BLOCK, 2), 'wikipedia'),
            ref(talk('block', BLOCK, arrows=['d8d2'],
                     marks=['d5', 'd6', 'd7']), 'wikipedia'),
            demo('d_unblock', UNBLOCK, 'Qd8+ Kc1 Qh4 Kd1 Qd4+ Kc1',
                 notes={1: {'arrows': ['d8d2']},
                        3: {'arrows': ['h4e1']},
                        5: {'arrows': ['d4d1']}}),
            move('blockMove', BLOCK_MOVE, 'Qc5+ Kb1 Qb4+',
                 accept={1: 'only', 2: 'best'}),
        ]},
        {'id': 'sixth', 'steps': [
            ref(think('t_race', RACE, 2), AC),
            ref(talk('raceWhy', RACE, arrows=['c2c8'],
                     marks=['f3', 'f2', 'a8']), AC),
            ref(demo('d_race', RACE, 'Rc8 Rxc8+ Kxc8 Kxf2',
                     notes={1: {'arrows': ['c2c8']},
                            4: {'marks': ['f2', 'f3']}}), AC),
            move('sixthMove', SIXTH, 'Qd4 Kc2 Kg7',
                 accept={1: 'only', 2: 'best'}),
            talk('recap', FRONT, arrows=['a8b7'], marks=['e1']),
            play('finish', START),
        ]},
    ],
    'exercises': [
        {'id': 'e05', 'stars': 1, 'fen': 'K7/8/8/8/8/8/5kp1/7Q w - - 0 1',
         'goal': 'win', 'origin': 'own',
         'turns': [{'teach': 'h1h2', 'accept': 'win', 'reply': 'f2f1'},
                   {'teach': 'h2f4', 'accept': 'best'}]},
        {'id': 'e11', 'stars': 1, 'fen': 'Q1K5/8/8/8/8/4kp2/8/8 w - - 0 1',
         'goal': 'win', 'origin': 'wikipedia',
         'turns': [{'teach': 'a8d5', 'accept': 'best', 'reply': 'e3f2'},
                   {'teach': 'c8d7', 'accept': 'best'}]},
        {'id': 'e12', 'stars': 2, 'fen': '8/8/8/8/3K4/8/1Q2p3/5k2 w - - 0 1',
         'goal': 'win', 'origin': 'own',
         'turns': [{'teach': 'b2b5', 'accept': 'win', 'reply': 'auto'},
                   {'teach': 'b5f5', 'accept': 'win'}]},
        {'id': 'e13', 'stars': 2, 'fen': '8/2Q5/8/8/3K4/8/4p3/3k4 w - - 0 1',
         'goal': 'win', 'origin': 'own',
         'turns': [{'teach': 'd4d3', 'accept': 'win', 'reply': 'auto'},
                   {'teach': 'd3e3', 'accept': 'best'}]},
        {'id': 'e14', 'stars': 3, 'fen': '8/6KQ/8/8/8/2p5/8/k7 w - - 0 1',
         'goal': 'win', 'origin': 'wikipedia',
         'turns': [{'teach': 'h7h6', 'accept': 'win', 'reply': 'auto'},
                   {'teach': 'h6b6', 'accept': 'win', 'reply': 'auto'},
                   {'teach': 'b6g1', 'accept': 'best'}]},
        {'id': 'e16', 'stars': 3, 'fen': '8/8/7Q/8/3K4/8/4p3/3k4 w - - 0 1',
         'goal': 'win', 'origin': 'own',
         'turns': [{'teach': 'h6h5', 'accept': 'win', 'reply': 'auto'},
                   {'teach': 'h5h2', 'accept': 'best', 'reply': 'auto'},
                   {'teach': 'd4d3', 'accept': 'best', 'reply': 'auto'},
                   {'teach': 'd3c3', 'accept': 'best', 'reply': 'auto'},
                   {'teach': 'h2g2', 'accept': 'best'}]},
    ],
    'passScore': 8,
    'keyPositions': [
        {'id': 'start', 'fen': START},
        {'id': 'front', 'fen': 'K7/8/8/8/8/3Q4/4p3/4k3 w - - 0 1',
         'ref': 'dang'},
        {'id': 'dang', 'fen': 'K6Q/8/8/8/8/8/3kp3/8 w - - 0 1', 'ref': 'dang'},
        {'id': 'block', 'fen': BLOCK, 'ref': 'wikipedia'},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win',
                 'positionId': 'queen.queenVsPawn.0005'},
    'references': REFERENCES,
}

OUT = Path(__file__).with_suffix('.json')
OUT.write_text(json.dumps(LESSON, ensure_ascii=False, indent=2) + '\n')
print('Escrito', OUT)
