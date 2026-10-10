"""Gera `rook.behindPasser.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.behindPasser.py`
e depois o `build_aula.py rook.behindPasser`. O aluno joga de brancas em todas
as posições. A lição e os exercícios até 7 peças passam pela tabela; e13, e14
e e15 têm mais de 7 peças e são julgados pelo Stockfish (rodar o build com
--stockfish). As posições de Alekhine–Capablanca e Anand–Kramnik (mais de 7
peças) ficam só em `talk`. Lição refeita na T61 (2026-10-10)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

BEHIND = 'r7/6k1/P5p1/8/8/6P1/6K1/R7 w - - 0 1'   # torre atrás: ganha
FRONT = 'R7/6k1/P5p1/8/8/6P1/6K1/r7 w - - 0 1'    # torres trocadas: empata
RACE = '8/5rk1/P1R4p/8/6P1/8/7K/8 w - - 0 1'      # só Tc2 (Audax6)
DEFEND = '8/6k1/6p1/8/p1r5/6P1/6K1/3R4 w - - 0 1'  # Td5-d8 seguram; Ta1 perde
SKEWER = 'R7/P4k2/6p1/8/8/6P1/6K1/r7 w - - 0 1'   # e06: só Th8 ganha

B7 = 'r7/P7/8/4K3/2k5/8/8/R7 w - - 0 1'           # só 1.Rd6: corrida até b7
SK1 = '1R6/1P2k3/8/8/8/8/6K1/1r6 w - - 0 1'       # só 1.Th8/1.Tg8 (espeto)
SK3 = '1R6/1P6/4k3/8/8/8/6K1/1r6 w - - 0 1'       # só 1.Te8+
RACE_ERR = '8/5rk1/P6p/8/6P1/2R5/7K/8 b - - 1 1'  # depois de 1.Tc3? (empata)
TEMPO = '8/8/8/P1r5/7k/8/K7/3R4 w - - 0 1'        # só 1.Td4+
TEMPO_M = '8/8/8/5r1P/k7/8/7K/4R3 w - - 0 1'      # espelho: só 1.Te4+
DEF_ERR = '8/6k1/6p1/8/p1r5/6P1/6K1/R7 b - - 1 1'  # depois de 1.Ta1? (perde)
ZW = 'R7/8/P7/8/5kp1/r7/5KP1/8 w - - 0 1'         # só 1.g3+; 1.a7? empata
ZW_ERR = 'R7/P7/8/8/5kp1/r7/5KP1/8 b - - 0 1'     # depois de 1.a7?
INT = '8/3P4/4K3/8/8/7R/1k6/3r4 w - - 0 1'        # 1.d8=D? empata; 1.Th5 ganha
INT_M = '8/4P3/3K4/8/8/R7/6k1/4r3 w - - 0 1'      # espelho de INT
KF = '8/8/7K/7P/4k3/8/2R5/6r1 w - - 0 1'          # só 1.Tc5; 1.Th2? empata
KF_ERR = '8/8/7K/7P/4k3/8/7R/6r1 b - - 1 1'       # depois de 1.Th2?
SIDE2 = 'r7/8/8/P4P2/6k1/8/7K/3R4 w - - 0 1'      # só 1.Td5; 1.Ta1? empata
SIDE2C = 'r7/8/8/P4P2/6k1/8/7K/2R5 w - - 0 1'     # só 1.Tc5
DEFEND_M = '8/1k6/1p6/8/5r1p/1P6/1K6/4R3 w - - 0 1'  # espelho: Te5-e8 seguram
KF_M = '8/8/K7/P7/3k4/8/5R2/1r6 w - - 0 1'          # espelho: só 1.Tf5
SWITCH = '8/8/r5p1/Pk6/8/2K3P1/R7/8 w - - 0 1'      # troca de alvo: 1.Rd4

# Partidas (PGN Mentor, conferidas com python-chess; ply = meio-lances).
ALEK107 = '8/5pk1/r5pp/P7/R6P/6P1/5PK1/8 b - - 6 54'     # depois de 54.Ta4
ANAND75 = '6k1/R5p1/5p2/p4P1p/8/r5P1/5K1P/8 b - - 1 38'  # depois de 38.Ta7
KB = '8/8/8/5pk1/6rp/P4K2/8/1R6 w - - 8 59'              # Kramnik, ply 116
KB_ERR = '8/8/8/5pk1/6rp/P4K2/8/R7 b - - 9 59'           # depois de 59.Ta1?

ALEKHINE_CAPABLANCA = (
    'd4_d5_c4_e6_Nc3_Nf6_Bg5_Nbd7_e3_c6_a3_Be7_Nf3_O-O_Bd3_dxc4_Bxc4_'
    'Nd5_Bxe7_Qxe7_Ne4_N5f6_Ng3_c5_O-O_Nb6_Ba2_cxd4_Nxd4_g6_Rc1_Bd7_Qe2_'
    'Rac8_e4_e5_Nf3_Kg7_h3_h6_Qd2_Be6_Bxe6_Qxe6_Qa5_Nc4_Qxa7_Nxb2_Rxc8_'
    'Rxc8_Qxb7_Nc4_Qb4_Ra8_Ra1_Qc6_a4_Nxe4_Nxe5_Qd6_Qxc4_Qxe5_Re1_Nd6_'
    'Qc1_Qf6_Ne4_Nxe4_Rxe4_Rb8_Re2_Ra8_Ra2_Ra5_Qc7_Qa6_Qc3+_Kh7_Rd2_Qb6_'
    'Rd7_Qb1+_Kh2_Qb8+_g3_Rf5_Qd4_Qe8_Rd5_Rf3_h4_Qh8_Qb6_Qa1_Kg2_Rf6_'
    'Qd4_Qxd4_Rxd4_Kg7_a5_Ra6_Rd5_Rf6_Rd4_Ra6_Ra4_Kf6_Kf3_Ke5_Ke3_h5_'
    'Kd3_Kd5_Kc3_Kc5_Ra2_Kb5_Kb3_Kc5_Kc3_Kb5_Kd4_Rd6+_Ke5_Re6+_Kf4_Ka6_'
    'Kg5_Re5+_Kh6_Rf5_f4_Rc5_Ra3_Rc7_Kg7_Rd7_f5_gxf5_Kh6_f4_gxf4_Rd5_'
    'Kg7_Rf5_Ra4_Kb5_Re4_Ka6_Kh6_Rxa5_Re5_Ra1_Kxh5_Rg1_Rg5_Rh1_Rf5_Kb6_'
    'Rxf7_Kc6_Re7'
)
ANAND_KRAMNIK = (
    'e4_e5_Nf3_Nf6_Nxe5_d6_Nf3_Nxe4_d4_d5_Bd3_Nc6_O-O_Be7_c4_Nb4_Be2_'
    'O-O_Nc3_Bf5_a3_Nxc3_bxc3_Nc6_Re1_Re8_cxd5_Qxd5_Bf4_Rac8_Qa4_Bd7_'
    'Qc2_Qf5_Qxf5_Bxf5_Bb5_Bd7_d5_Ne5_Bxd7_Nxd7_Bxc7_Rxc7_d6_Rxc3_dxe7_'
    'f6_Rad1_Rc7_Nd4_Ne5_f4_Nc6_Nxc6_bxc6_Rd6_c5_Ree6_c4_Rc6_Rexe7_Rxc4_'
    'Rxc4_Rxe7_Ra4_Rb7_h6_f5_Rxa3_Kf2_h5_g3_a5_Ra7_a4_h4_Ra2+_Kf3_a3_'
    'Ke3_Ra1_Kf2_Kf8_Kg2_a2_Kh2_Ke8_Kg2_Kd8_Kh2_Kc8_Kg2_Kb8_Ra3_Kb7_Ra4_'
    'Kb6_Ra8_Kc5_Ra7_Kd5_Ra4_Ke5_Ra5+_Ke4_Kh2_Kf3_Ra3+_Kf2_Ra4_Kf1_Kh1_'
    'Ke1_Kg2_Kd1_Ra7_Rc1_Rxa2_Rc2+_Rxc2_Kxc2_Kf3_Kd3_g4_hxg4+_Kxg4_Ke4_'
    'Kh5_Kxf5'
)
KRAMNIK_BELIAVSKY = (
    'c4_e5_Nc3_Nf6_Nf3_Nc6_d3_d5_cxd5_Nxd5_e3_Be7_Be2_O-O_O-O_Be6_a3_f5_'
    'Qc2_Kh8_Na4_Bd6_b4_Qf6_Bb2_Rae8_Nc5_Bc8_Qc4_Nb6_Qc2_Qh6_Rfd1_Nd5_'
    'Qc4_Nxe3_fxe3_e4_dxe4_fxe4_Nxe4_Qxe3+_Nf2_Qxe2_Qxe2_Rxe2_Bc3_Kg8_'
    'Kf1_Re3_Rac1_Ne7_Re1_Nd5_Rxe3_Nxe3+_Kg1_Re8_Bd4_Nd5_Rd1_b6_Nd3_Bb7_'
    'Kf2_Nf6_Bxf6_gxf6_Nd4_Kf7_Nb5_Rd8_Nxd6+_Rxd6_Rc1_c5_Nf4_Rc6_bxc5_'
    'Rxc5_Rd1_Rc2+_Kg3_Bc6_Rd6_b5_Nd5_Rc5_Nb4_Rg5+_Kf4_Bxg2_Ra6_h5_'
    'Rxa7+_Kg6_Nd3_Bf1_Ke3_Bxd3_Kxd3_Rg2_Ra5_Rxh2_Rxb5_f5_Rb1_h4_Ke3_'
    'Rg2_Kf3_Rg3+_Kf4_Rg4+_Kf3_Kg5_Ra1_Rg3+_Kf2_Kg4_Rb1_h3_Rb8_Rg2+_Kf1_'
    'Rd2_Kg1_f4_Rg8+_Kf3_Rh8_Rd1+_Kh2_Kf2_a4_f3_a5_Kf1_a6_Ra1_Ra8_f2_a7_'
    'Ra6_Kh1_h2_Rb8_Rxa7_Rb1+_Ke2_Rb2+_Ke3_Rb3+_Ke4_Rb4+_Kd3_Rb1_Rf7_'
    'Rf1_Ke2_Rxf2+_Kxf2'
)

LICHESS = 'https://lichess.org/analysis/pgn/'

REFERENCES = [
    {'id': 'tarraschRule', 'kind': 'web',
     'title': 'Tarrasch rule (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Tarrasch_rule'},
    {'id': 'tarrasch', 'kind': 'web',
     'title': 'Siegbert Tarrasch (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Siegbert_Tarrasch'},
    {'id': 'alekhineCapablanca1927', 'kind': 'game',
     'white': 'Alexander Alekhine', 'black': 'José Raúl Capablanca',
     'event': 'Campeonato Mundial, Buenos Aires, 34.ª partida', 'year': 1927,
     'url': LICHESS + ALEKHINE_CAPABLANCA + '#107'},
    {'id': 'anandKramnik2007', 'kind': 'game',
     'white': 'Viswanathan Anand', 'black': 'Vladimir Kramnik',
     'event': 'Campeonato Mundial, Cidade do México, rodada 3', 'year': 2007,
     'url': LICHESS + ANAND_KRAMNIK + '#75'},
    {'id': 'kramnikBeliavsky1993', 'kind': 'game',
     'white': 'Vladimir Kramnik', 'black': 'Alexander Beliavsky',
     'event': 'Torneio da PCA, Groningen, rodada 3', 'year': 1993,
     'url': LICHESS + KRAMNIK_BELIAVSKY + '#116'},
    {'id': 'pgnmentorAlekhine', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Alekhine (Alekhine.zip)',
     'url': 'https://www.pgnmentor.com/players/Alekhine.zip'},
    {'id': 'pgnmentorAnand', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Anand (Anand.zip)',
     'url': 'https://www.pgnmentor.com/players/Anand.zip'},
    {'id': 'pgnmentorKramnik', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Kramnik (Kramnik.zip)',
     'url': 'https://www.pgnmentor.com/players/Kramnik.zip'},
    {'id': 'wcc1927', 'kind': 'web',
     'title': 'World Chess Championship 1927 (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/World_Chess_Championship_1927'},
    {'id': 'audax6', 'kind': 'study', 'author': 'Audax6',
     'title': 'E-39 Rook Endings 6: Rooks and Passed Pawns - The rook '
              'belongs behind a passed pawn - whether friend',
     'url': 'https://lichess.org/study/PlokBlnu'},
    {'id': 'audax6Race', 'kind': 'study', 'author': 'Audax6',
     'title': 'E-39 Rook Endings 6: Rooks and Passed Pawns, '
              'capítulo 1 (White to move)',
     'url': 'https://lichess.org/study/PlokBlnu/739EsU6B'},
    {'id': 'shrekdavid', 'kind': 'study', 'author': 'SHREKDAVID',
     'title': 'Tarrasch Rule Rooks Endgames',
     'url': 'https://lichess.org/study/OuwVp71z'},
    {'id': 'rfanning', 'kind': 'study', 'author': 'rfanning',
     'title': 'Tarrasch Rule - Rooks and passed pawn',
     'url': 'https://lichess.org/study/Pumc4nOr'},
    {'id': 'miles26', 'kind': 'study', 'author': 'miles26',
     'title': 'Rook behind the pawns',
     'url': 'https://lichess.org/study/2bxusiQ6'},
    {'id': 'practice', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Basic Rook Endgames',
     'url': 'https://lichess.org/study/pqUSUw8Y'},
    {'id': 'mueller', 'kind': 'web',
     'title': 'Karsten Müller: Rooks belong behind passed pawns (ChessBase, 2024)',
     'url': 'https://en.chessbase.com/post/rooks-belong-behind-passed-pawns-2'},
    {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
     'title': "Dvoretsky's Endgame Manual",
     'publisher': 'Russell Enterprises', 'year': 2020,
     'where': 'sumário da amostra em PDF, capítulo 9'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]


def ref(step, reference):
    """O passo vem de uma partida ou estudo (`id` ou `id#ply`)."""
    step['ref'] = reference
    return step


write({
    'id': 'rook.behindPasser',
    'module': 'rook',
    'skills': ['rook.behindPasser'],
    'parts': [
        {'id': 'own', 'steps': [
            think('t_behind', BEHIND, 2, arrows=['a1a6'], marks=['a8']),
            talk('behind', BEHIND, arrows=['a1a7'], marks=['a8']),
            demo('d_walk', BEHIND,
                 'a7 Kf7 Kf3 Kg7 Ke4 Kf7 Kd5 Ke7 Kc6 Kd8 Kb7',
                 notes={1: {'marks': ['a8']},
                        9: {'marks': ['b7', 'c7']},
                        11: {'arrows': ['b7a8']}}),
            move('b7Race', B7, 'Kd6 Rd8+ Kc6 Ra8 Kb7',
                 accept={1: 'only', 2: 'win', 3: 'win'}),
        ]},
        {'id': 'front', 'steps': [
            think('t_skewer', SK1, 2, marks=['h7']),
            talk('front', FRONT, arrows=['a1a6'], marks=['g7', 'h7']),
            demo('d_skewer', SK1, 'Rh8 Rxb7 Rh7+',
                 notes={1: {'arrows': ['h8b8']}, 3: {'arrows': ['h7b7']}}),
            move('frontCheck', SK3, 'Re8+ Kd5 b8=Q Rxb8 Rxb8',
                 accept={1: 'only', 2: 'win', 3: 'win'}),
        ]},
        {'id': 'race', 'steps': [
            ref(think('t_race', RACE, 2, marks=['a2']), 'audax6Race'),
            demo('d_raceError', RACE_ERR, 'Rf2+ Kg3 Ra2', goal='draw',
                 notes={1: {'arrows': ['f7f2']}, 3: {'arrows': ['f2a2']}}),
            ref(move('getFirst', RACE, 'Rc2 Ra7 Ra2 Kf6 Kg3',
                     accept={1: 'only', 2: 'win', 3: 'win'}), 'audax6Race'),
            demo('d_tempo', TEMPO, 'Rd4+ Kg5 Ra4',
                 notes={1: {'arrows': ['d1d4']}, 3: {'arrows': ['d4a4']}}),
            move('tempoMove', TEMPO_M, 'Re4+ Kb5 Rh4',
                 accept={1: 'only', 2: 'win'}),
        ]},
        {'id': 'theirs', 'steps': [
            think('t_defend', DEFEND, 2, marks=['a4']),
            demo('d_defend', DEFEND, 'Rd8 a3 Ra8', goal='draw',
                 notes={1: {'arrows': ['d1d8']}, 3: {'arrows': ['d8a8']}}),
            talk('passive', DEF_ERR, arrows=['g7f6'],
                 marks=['a1', 'e5', 'd4']),
            ref(talk('anand', ANAND75, arrows=['a7a5']),
                'anandKramnik2007#75'),
            move('holdBehind', DEFEND_M, 'Re8 h3 Rh8', accept='hold',
                 goal='draw'),
        ]},
        {'id': 'twoPassers', 'steps': [
            ref(think('t_kramnik', KB, 2, marks=['f5', 'h4']),
                'kramnikBeliavsky1993#116'),
            ref(talk('kramnik', KB_ERR, arrows=['b1a1', 'g4g3']),
                'kramnikBeliavsky1993#117'),
            ref(talk('rb8', KB, arrows=['b1b8', 'b8g8']),
                'kramnikBeliavsky1993#116'),
            ref(move('kramnikMove', KB, 'Rb8 h3 Rg8+ Kh4 Rh8+',
                     accept={1: ['Rb8', 'Rb7', 'Rb6', 'Rc1'], 2: 'hold',
                             3: 'hold'}, goal='draw'),
                'kramnikBeliavsky1993#116'),
        ]},
        {'id': 'enemyBehind', 'steps': [
            think('t_order', ZW, 2, marks=['a2']),
            demo('d_orderError', ZW_ERR, 'Ra2+ Kg1 Kg3', goal='draw',
                 notes={1: {'arrows': ['a3a2']}, 3: {'marks': ['g3']}}),
            move('orderMove', ZW, 'g3+ Ke4 a7', accept={1: 'only', 2: 'win'}),
            demo('d_interfere', INT, 'Rh5 Re1+ Kd6 Rd1+ Rd5',
                 notes={1: {'arrows': ['h5d5']}, 5: {'marks': ['d5']}}),
            move('interfereMove', INT_M, 'Ra5 Rd1+ Ke6 Re1+ Re5',
                 accept={1: 'win', 2: 'win', 3: ['Re5']}),
        ]},
        {'id': 'exceptions', 'steps': [
            think('t_kingFront', KF, 2, marks=['h6']),
            talk('kfError', KF_ERR, arrows=['e4f5'], marks=['h2', 'f6']),
            demo('d_kf', KF, 'Rc5 Kf4 Kh7',
                 notes={1: {'arrows': ['c2c5'],
                            'marks': ['d5', 'e5', 'f5', 'g5']}}),
            move('kfMove', KF_M, 'Rf5 Kc4 Ka7', accept={1: 'only', 2: 'only'}),
            demo('d_sideGuard', SIDE2, 'Rd5 Kf4 Kg2 Ke4 Rb5',
                 notes={1: {'arrows': ['d1d5'], 'marks': ['a5', 'f5']},
                        5: {'arrows': ['d5b5']}}),
            move('sideGuardMove', SIDE2C, 'Rc5 Ra6 Kg2',
                 accept={1: 'only', 2: 'only'}),
        ]},
        {'id': 'rules', 'steps': [
            talk('tarrasch', BEHIND, arrows=['a1a6']),
            ref(talk('alekhine', ALEK107, arrows=['a4a5'], marks=['a6']),
                'alekhineCapablanca1927#107'),
            demo('d_switch', SWITCH,
                 'Kd4 Rd6+ Ke5 Rd1 Kf6 Rd6+ Kg5 Rd1 Kxg6',
                 notes={1: {'marks': ['g6']}}),
            talk('recap', BEHIND, arrows=['a1a7']),
            play('finish', BEHIND),
        ]},
    ],
    'exercises': [
        exercise('e05', 1, 'r7/P7/1k1K4/8/8/8/2R5/8 w - - 0 1', 'Rb2+ Ka6 Kc7',
                 accept='only', origin='shrekdavid'),
        exercise('e06', 1, SKEWER, 'Rh8 Rxa7 Rh7+', accept='only'),
        exercise('e11', 2, '2R5/8/Pr6/7k/8/8/K7/8 w - - 0 1', 'Rc5+ Kg4 Ra5',
                 accept={1: 'only', 2: 'win'}, origin='miles26'),
        exercise('e10', 2, '6r1/8/7K/8/4k2P/2P2R2/8/8 w - - 0 1', 'Rf7',
                 accept='win', origin='tarraschRule'),
        exercise('e12', 2, '8/8/8/1r3P2/2p5/7R/3k2K1/8 w - - 0 1', 'f6',
                 accept='hold', goal='draw', origin='audax6'),
        exercise('e13', 2, 'r7/8/4pkp1/7p/P4P1P/6P1/5K2/4R3 w - - 0 1', 'Re4',
                 accept='only', origin='tarraschRule'),
        exercise('e14', 3, 'R7/8/P4pp1/7p/4k2P/r5P1/4KP2/8 w - - 0 1', 'f3+',
                 accept='only', origin='tarraschRule'),
        exercise('e15', 3, '1R6/5P2/4K3/8/2p5/p1P5/k4r2/8 w - - 0 1', 'Rb5',
                 accept='only', origin='audax6'),
    ],
    'passScore': 10,
    'keyPositions': [
        {'id': 'behind', 'fen': BEHIND},
        {'id': 'front', 'fen': FRONT},
        {'id': 'defend', 'fen': DEFEND},
        {'id': 'race', 'fen': RACE, 'ref': 'audax6Race'},
        {'id': 'alekhine', 'fen': ALEK107,
         'ref': 'alekhineCapablanca1927#107'},
        {'id': 'anand', 'fen': ANAND75, 'ref': 'anandKramnik2007#75'},
        {'id': 'kramnik', 'fen': KB, 'ref': 'kramnikBeliavsky1993#116'},
    ],
    'practice': {'fen': BEHIND, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
})
