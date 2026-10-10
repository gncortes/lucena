"""Gera `pawns.minedSquares.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/pawns.minedSquares.py`
e depois o `build_aula.py pawns.minedSquares`. O aluno joga de brancas (e de
pretas num lance, como Lasker): ganha quase sempre e empata nas partes da
defesa e de quando a mina não decide. Lição refeita na T61 (2026-10-10): sete
partes, uma ideia por parte, com Voigt-Lasker (Filadélfia 1892) e
Alekhine-Yates (Hamburgo 1910), PGN do PGN Mentor."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)


def ref(step, reference):
    """O passo vem de uma partida ou estudo (`id` ou `id#ply`)."""
    step['ref'] = reference
    return step


TREB = '8/8/8/3pK3/2kP4/8/8/8 b - - 0 1'           # trebuchet (Flear, pela Wikipedia)
TREB_IN = '8/8/4K3/3p4/2kP4/8/8/8 w - - 0 1'       # entrar no trebuchet: Ke5
MINED = '8/8/1k1p4/3P1K2/8/8/8/8 w - - 0 1'        # casas minadas (Wikipedia; RyanGarg)
MINED_TRAP = after(MINED, 'Ke6 Kc5')               # Ke6? Kc5: brancas em zugzwang
# Própria (troca do recap, 2026-10-10): a posição antiga (monsienne, cap. 1,
# e5/e6) é o e16 de pawns.keySquares. Peões d6/d7: só 1.Re8! ganha.
RACE = '8/3p1K2/3P4/1k6/8/8/8/8 w - - 0 1'
DEFEND = '8/8/8/8/3p1k2/1K1P4/8/8 w - - 0 1'       # cores trocadas de MINED: só Kb4
DEFEND_TRAP = after(DEFEND, 'Kc4 Ke3')             # Kc4? Ke3: brancas em zugzwang
CHEESE = '8/8/1Kp5/4p3/4P3/7k/8/8 w - - 0 1'       # ThisIsCheeseman, cores trocadas
RODNEY = '8/1k6/8/1Pp3p1/6P1/2K5/8/8 w - - 0 1'    # Rodney_Opada, cap. 1
HOOPER = '2k5/2P5/K7/8/8/8/8/8 w - - 0 1'          # rumo ao zugzwang de Hooper (Wikipedia)
C_LOW = '8/8/8/4K3/k1p5/2P5/8/8 w - - 0 1'         # monsienne, cap. 11: empate, Kd4? perde
# Hooper 1970 (Wikipedia): pretas na vez perdem, brancas na vez empatam.
HOOPER_B = '2k5/2P5/1K6/8/8/8/8/8 b - - 0 1'
HOOPER_D = '3k4/8/2KP4/8/8/8/8/8 w - - 0 1'        # só 1.d7! ganha; 1...Re7 2.Rc7
# Voigt-Lasker, simultânea, Filadélfia 1892 (PGN Mentor), ply 161: 81...Txf3!
LASKER = '8/8/8/8/5pK1/2r2B2/5kP1/8 b - - 9 81'
# Alekhine-Yates, Hamburgo 1910 (PGN Mentor), ply 88: 45.Rf2! (9 peças)
ALEKHINE = '8/8/4k3/1p2P3/p3Pp2/P7/1P2K3/8 w - - 2 45'
ALEKHINE_B = '8/8/4k3/4P3/p3Pp2/P7/4K3/8 w - - 0 1'  # sem os peões b: só 1.Rf2
# RyanGarg, cap. 2 (d4/d5, Rf4, Rb5), levado para a ala do rei e uma coluna
# adiante, para não repetir o e13 (c3/c4) nem as casas do e10 (d5/f4).
NOMINE = '8/8/8/5p1k/3K1P2/8/8/8 w - - 0 1'       # empate
# Exercício próprio (nota A): trebuchet na coluna g. 1.Rf5! fecha o trebuchet
# com as pretas na vez; 1.Rf3? também protege g4, mas só empata.
G_TREB = '8/8/8/6p1/4K1Pk/8/8/8 w - - 0 1'

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
    {'id': 'voigtLasker1892', 'kind': 'game', 'white': 'H. G. Voigt',
     'black': 'Emanuel Lasker', 'event': 'Simultânea, Filadélfia',
     'year': 1892,
     'url': 'https://lichess.org/analysis/pgn/e4_c5_Nf3_Nc6_Nc3_g6_d4_cxd4_Nxd4_Bg7_Be3_d6_Be2_Nf6_O-O_O-O_Qd2_Bd7_Rad1_a6_h3_Rc8_f4_Qc7_Bf3_Na5_Qf2_Nc4_Bc1_b5_Rfe1_e5_Nde2_b4_Nd5_Nxd5_Rxd5_Be6_Rdd1_exf4_Nxf4_Nxb2_Bxb2_Bxb2_Nd5_Bxd5_Rxd5_Be5_Bg4_Ra8_Rb1_Qc4_Qe2_Qxa2_Rxb4_Rab8_Qc4_Qa3_Rb3_Qc1+_Rd1_Qf4_Rf3_Qh2+_Kf2_h5_Bd7_Rbd8_Ba4_Rc8_Qxa6_h4_Qf1_Bg3+_Ke2_Rc4_Bb3_Rxe4+_Kd3_Re7_Rf6_Kg7_Qf3_Be5_Rf1_Rc7_Kd2_Qg3_Qxg3_hxg3_R6f3_f5_Rd3_Rb8_Ke2_Kf6_Kf3_Rb4_Ke2_Re7_Re3_Ra7_Rd1_Rb8_Kf3_Rc8_Red3_Rb8_Rxd6+_Bxd6_Rxd6+_Kg5_Kxg3_Rb4_Rc6_Re7_Rd6_Rbe4_Rc6_Re3+_Kf2_Re2+_Kg1_Rd2_Be6_f4_Bg4_Re1+_Kh2_Rc1_Bf3_Rdxc2_Rxc2_Rxc2_Be4_Rb2_Bf3_Kf5_Bg4+_Ke4_Bf3+_Ke3_h4_Rf2_Bc6_g5_hxg5_Rc2_Bf3_Rc5_Kg1_Rxg5_Bc6_Rc5_Bf3_Rc1+_Kh2_Kf2_Kh3_Rc3_Kg4_Rxf3_gxf3_Ke3#161'},
    {'id': 'pgnMentorLasker', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Emanuel Lasker (Lasker.zip)',
     'url': 'https://www.pgnmentor.com/players/Lasker.zip'},
    {'id': 'alekhineYates1910', 'kind': 'game',
     'white': 'Alexander Alekhine', 'black': 'Frederick Yates',
     'event': 'Hamburgo (17.º Congresso da DSB), rodada 13', 'year': 1910,
     'url': 'https://lichess.org/analysis/pgn/d4_d5_c4_e6_Nf3_Nf6_Bg5_Be7_e3_Nbd7_Nc3_O-O_Qc2_b6_cxd5_exd5_Bd3_Bb7_h4_c5_O-O-O_cxd4_Nxd4_Re8_Kb1_a6_g4_b5_Bxf6_Nxf6_g5_Ne4_Nxe4_dxe4_Bxe4_Bxe4_Qxe4_Bxg5_Ne6_Qe7_hxg5_h6_gxh6_Qxe6_Qd4_Qe4+_Qxe4_Rxe4_hxg7_Kxg7_Rdg1+_Kf6_Rh6+_Ke7_Rc1_Ra7_Rcc6_a5_Ra6_Rxa6_Rxa6_a4_Rb6_Re5_Kc2_Rc5+_Kd3_Kd7_a3_Rf5_f4_Kc7_Rh6_Rd5+_Kc3_f5_Re6_Kd7_Re5_Rxe5_fxe5_Ke7_Kd3_Kd7_e4_f4_Ke2_Ke6_Kf2_Kxe5_Kf3#88'},
    {'id': 'pgnMentorAlekhine', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Alexander Alekhine (Alekhine.zip)',
     'url': 'https://www.pgnmentor.com/players/Alekhine.zip'},
    {'id': 'tommy92', 'kind': 'study', 'author': 'Tommy92',
     'title': 'Dovretsky - Mined Squares (capítulo "Alekhine Yates")',
     'url': 'https://lichess.org/study/cvN3e0Qx/s0HcYlne'},
    {'id': 'ryanGargD4', 'kind': 'study', 'author': 'RyanGarg',
     'title': 'Mined Squares (capítulo "Mined Squares - d4 Draw")',
     'url': 'https://lichess.org/study/sRutl3W9/LGJD5IXp'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'pawns.minedSquares',
    'module': 'pawns',
    'skills': ['pawns.trebuchet'],
    'parts': [
        {'id': 'halfPoint', 'steps': [
            think('t_hooper', HOOPER_B, 2, marks=['b8', 'd8']),
            talk('hooper', HOOPER_B, marks=['b8', 'd8', 'c6']),
            demo('d_hooper', HOOPER_B, 'Kd7 Kb7 Kd6 c8=Q',
                 notes={2: {'marks': ['c8']}}),
            move('hooperMove', HOOPER_D, 'd7 Ke7 Kc7', accept='win'),
        ]},
        {'id': 'trebuchet', 'steps': [
            think('t_treb', TREB, 2, marks=['d4', 'd5']),
            talk('treb', TREB, arrows=['c4d5', 'e5d4'], marks=['d4', 'd5']),
            demo('d_treb', TREB, 'Kb4 Kxd5 Kb5 Kd6',
                 notes={2: {'marks': ['d5']},
                        4: {'marks': ['c6', 'd6', 'e6']}}),
            move('trebMove', TREB_IN, 'Ke5 Kb4 Kxd5', accept='win'),
            ref(talk('lasker', LASKER, marks=['f3', 'f4'], side='black'),
                'voigtLasker1892#161'),
            ref(move('laskerMove', LASKER, 'Rxf3 gxf3 Ke3', accept='win'),
                'voigtLasker1892#161'),
        ]},
        {'id': 'mined', 'steps': [
            think('t_mined', MINED, 3, marks=['e6', 'c5']),
            talk('mines', MINED, arrows=['b6c5', 'f5e6'], marks=['e6', 'c5']),
            talk('trap', MINED_TRAP, arrows=['c5d5'], marks=['e6', 'c5']),
            demo('d_mined', MINED, 'Kf6 Kb5 Ke7 Kc5 Ke6 Kb6 Kxd6',
                 notes={1: {'marks': ['e7']},
                        3: {'arrows': ['e7d6']},
                        5: {'marks': ['e6', 'c5']}}),
            move('minedMove', MINED, 'Kf6 Kb5 Ke7 Kc5 Ke6', accept='win'),
        ]},
        {'id': 'defend', 'steps': [
            think('t_defend', DEFEND, 2, marks=['c4', 'e3']),
            talk('defend', DEFEND, arrows=['b3b4', 'f4e3'], marks=['c4', 'e3']),
            talk('defendTrap', DEFEND_TRAP, arrows=['e3d3'],
                 marks=['c4', 'e3']),
            demo('d_defend', DEFEND, 'Kb4 Ke3 Kc4 Kf3 Kxd4', goal='draw',
                 notes={1: {'marks': ['c4']},
                        3: {'marks': ['c4', 'e3']}}),
            move('defendMove', DEFEND, 'Kb4 Kf3 Kc5', accept='hold',
                 goal='draw'),
        ]},
        {'id': 'alekhine', 'steps': [
            ref(think('t_alekhine', ALEKHINE, 2, marks=['e4', 'f4']),
                'alekhineYates1910#88'),
            ref(talk('alekhine', ALEKHINE, arrows=['e2f2', 'e6e5'],
                     marks=['f3', 'e5']), 'alekhineYates1910#88'),
            demo('d_alekhine', ALEKHINE_B, 'Kf2 Kd7 Kf3 Ke6 Kxf4',
                 notes={1: {'marks': ['f3']},
                        3: {'arrows': ['f3f4']}}),
            move('alekhineMove', ALEKHINE_B, 'Kf2 Kxe5 Kf3', accept='win'),
        ]},
        {'id': 'noMine', 'steps': [
            think('t_noMine', NOMINE, 2, marks=['e5', 'g4']),
            talk('noMine', NOMINE, marks=['e5', 'g4', 'g6']),
            demo('d_noMine', NOMINE, 'Kd5 Kg6 Ke6 Kg7 Kxf5 Kf7',
                 goal='draw',
                 notes={2: {'marks': ['g6']},
                        6: {'marks': ['f7']}}),
            move('noMineMove', NOMINE, 'Kd5 Kg6 Ke6 Kg7 Kxf5', accept='hold',
                 goal='draw'),
        ]},
        {'id': 'recap', 'steps': [
            think('t_race', RACE, 2, marks=['e7', 'c6']),
            talk('race', RACE, arrows=['f7e8', 'e8d7'], marks=['e7', 'c6']),
            demo('d_race', RACE, 'Ke8 Kc6 Ke7 Kd5 Kxd7',
                 notes={1: {'arrows': ['e8d7']},
                        3: {'marks': ['e7', 'c6']}}),
            move('raceMove', RACE, 'Ke8 Kc5 Kxd7', accept='win'),
            talk('rules', MINED, marks=['e6', 'c5']),
            play('finish', MINED),
        ]},
    ],
    'exercises': [
        exercise('e11', 1, HOOPER, 'Kb6', accept='win',
                 origin='wikiZugzwang'),
        exercise('e15', 1, G_TREB, 'Kf5 Kh3 Kxg5', accept='win'),
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
        {'id': 'race', 'fen': RACE},
        {'id': 'cheeseman', 'fen': '8/8/7p/4p2K/4P3/1kP5/8/8 w - - 0 1',
         'ref': 'cheeseman'},
        {'id': 'lasker', 'fen': LASKER, 'ref': 'voigtLasker1892#161'},
        {'id': 'alekhine', 'fen': ALEKHINE, 'ref': 'alekhineYates1910#88'},
    ],
    'practice': {'fen': MINED, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
})
