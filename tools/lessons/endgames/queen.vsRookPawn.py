"""Gera `queen.vsRookPawn.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/queen.vsRookPawn.py`
e depois o `build_aula.py queen.vsRookPawn`. O aluno joga de brancas: nas
partes de defesa (objetivo empate) as brancas têm torre e peão, e as posições
das fontes entram espelhadas (`tools/check_hold.py --mirror`); nas partes de
ataque (objetivo vitória) as brancas têm a dama."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play,  # noqa: E402
                         talk, think)

# Defesa: a fortaleza da segunda fileira (Müller e Lamprecht, pela Wikipedia)
FORT = '8/8/1q6/8/5k2/4R3/5PK1/8 w - - 0 1'
# Van der Poel-Smits 2000 (Wikipedia, "Fortress"), espelhada, depois de Dd4+
VDP = '8/8/8/8/3qk3/5R2/3KP3/8 w - - 0 1'
# Quais peões seguram (coleção de Schnabelwolke no Lichess): posições-base
A3 = '8/8/8/8/3q4/PK1k4/1R6/8 w - - 0 1'                # só Ra2
C3 = '8/8/2q1k3/8/3R4/2P5/2K5/8 w - - 0 1'              # perdido
# T63: peão de cavalo, a torre que espera longe (Schnabelwolke, cap. 8)
B5 = '1q6/8/2R5/1P1k4/1K6/8/8/8 w - - 0 1'              # empate na quinta
B5_MIRROR = '6q1/8/5R2/4k1P1/6K1/8/8/8 w - - 0 1'       # a mesma, peão g5
# T63: montar a fortaleza do peão de cavalo (próprias, conferidas na tabela)
BUILD = '8/8/3R3K/8/6P1/2k5/8/1q6 w - - 0 1'            # g5 primeiro
BUILD2 = '8/8/4R2K/8/6P1/3k4/1q6/8 w - - 0 1'           # só g5; Tf6? cai
BUILD_T = '8/8/4R2K/8/6P1/2qk4/8/8 w - - 0 1'          # think: só g5
# Ataque: peão de torre na segunda (coleção de KaushalK no Lichess, cap. 8)
ROOK2 = '6k1/7p/6r1/5K2/7Q/8/8/8 w - - 0 1'
ROOK2_MIRROR = '1k6/p7/1r6/2K5/Q7/8/8/8 w - - 0 1'      # a mesma, peão a7
# T63: Carlsen-Matlakov, Grand Swiss 2019 (PGN Mentor e chessgames)
CARL_66 = '1Q6/8/2p5/3r4/2k3K1/8/8/8 w - - 25 66'       # ply 130: 66.Db6!
CARL_78 = '8/8/4K3/2p5/3k4/3r4/2Q5/8 w - - 20 78'       # ply 154: 78.Rd6!
# T63: o rei atacante além da terceira fileira do defensor (próprias)
BEYOND_D1 = '8/8/8/7q/8/4R3/1k3P2/5K2 w - - 0 1'
BEYOND_D2 = '8/8/8/8/7q/4R3/2k2P2/5K2 w - - 0 1'
# T63: peão na sétima, coroar com xeque e o espeto pela coluna (própria;
# pela coluna, para não encostar no e09, que espeta pela fileira)
SKEWER = '8/2P5/2k5/5q2/8/8/R6K/8 w - - 0 1'            # só Tc2+ depois
SKEWER2 = '8/5P2/5k2/2q5/8/8/K6R/8 w - - 0 1'           # espelho: só Tf2+
# T63: peão na sétima, a torre louca e o afogamento (próprias)
DESP_BOX = 'K7/P7/2k5/8/8/8/1q6/7R w - - 0 1'           # só Th6+
DESP_RUN = 'K7/P7/1q6/3k4/8/8/8/7R w - - 0 1'
DESP_B5 = after(DESP_BOX, 'Rh6+ Kb5')                   # só Th5+
# Exercícios: posições que a lição não mostra
FORT_H4 = '8/8/1q6/8/5k1p/4R3/5PK1/8 w - - 0 1'         # própria: peão a mais
B4 = '8/8/4k3/3q4/1PR5/8/2K5/8 w - - 0 1'               # Schnabelwolke, b4
B4_PIN = '8/8/8/1KR5/1P1k4/8/q7/8 w - - 0 1'            # Schnabelwolke, cap. 6
# Marcotulli-Malström 2001 (Wikipedia, "Fortress"), espelhada
MARC = '8/8/1K6/8/1P6/4k3/2R5/7q w - - 0 1'
LAZA = '7k/4Q2p/6r1/7K/8/8/8/8 w - - 0 1'               # e05 (coleção de KaushalK)
# Whitaker-Ferriz 1959 (Wikipedia, "Fortress"), espelhada: torre sem proteção
WHIT = '8/6pk/4r3/8/Q4K1P/8/8/8 w - - 0 1'              # só Dc2+
# Vaganian-Bologan 1997 (PGN Mentor), ply 188
VAG = '8/1Q6/8/6K1/2p5/8/2k5/2r5 w - - 0 1'             # só Rf4
BEYOND = '3k4/3p3K/4r3/8/1Q6/8/8/8 w - - 0 1'           # coleção de KaushalK, cap. 7
POGOSYANTS = '2k5/K4P1q/8/8/8/8/R7/8 w - - 0 1'          # estudo (MorosFan)
PROKES = '2R5/2P5/K7/2k5/8/8/8/2q5 w - - 0 1'            # estudo (MorosFan)
# Peão na sexta, torre atrás: zugzwang recíproco (Grigoriev 1933, Wikipedia)
GRIG = '8/4k3/4P3/8/8/2K1R3/8/3q4 b - - 0 1'            # pretas jogam: empate
GRIG_B3 = '8/4k3/4P3/8/8/1K2R3/8/3q4 w - - 0 1'         # só Rc3
GRIG_M = '8/3k4/3P4/8/8/3R2K1/8/4q3 w - - 0 1'          # espelho: só Rf3

LICHESS = 'https://lichess.org/analysis/pgn/'
CARLSEN_SANS = (
    'd4_Nf6_c4_e6_Nf3_d5_Nc3_c6_Bg5_h6_Bh4_dxc4_e4_g5_Bg3_b5_h4_'
    'g4_Ne5_Nbd7_Be2_Bb7_Nxd7_Qxd7_Be5_Qe7_b3_Rg8_Qc2_b4_Na4_c3_'
    'a3_Nd7_Bg3_Bg7_Rd1_a5_O-O_Bf6_Nc5_Nxc5_dxc5_e5_Rd6_Bxh4_Bc4_'
    'Bg5_Qd3_Rg6_f4_exf4_Bxf4_Bxf4_Rxf4_c2_Qxc2_Rxd6_cxd6_Qxd6_e5_'
    'Qc5+_Kh1_Qe3_Qf5_Kd8_Qxf7_Kc8_axb4_Qxe5_Qf8+_Kc7_Rf7+_Kb6_'
    'bxa5+_Qxa5_Qe7_Qh5+_Kg1_Ra1+_Bf1_Qxf7_Qxf7_Ba6_Qf2+_Kb7_Qd4_'
    'Rxf1+_Kh2_h5_Qc5_Rb1_Qxh5_Kb6_Qxg4_Rxb3_Qg8_Rd3_g4_Rd5_g5_'
    'Bd3_g6_Bxg6_Qxg6_Kc7_Qf7+_Kb8_Kg3_Rg5+_Kf4_Rd5_Qf8+_Kb7_Qb4+_'
    'Kc7_Ke4_Kc8_Qb6_Kd7_Qb7+_Kd6_Qc8_Kc5_Qb8_Rh5_Kf4_Rd5_Kg4_Kc4_'
    'Qb6_Rd4+_Kf5_c5_Qa5_Rd5+_Ke6_Rd4_Qa4+_Kc3_Qa3+_Kc4_Qa5_Rd3_'
    'Qa4+_Kc3_Qa3+_Kc4_Qc1+_Kb4_Qb2+_Kc4_Qc2+_Kd4_Kd6_c4_Qf2+_Re3_'
    'Qd2+')
VAGANIAN_SANS = (
    'Nf3_d6_d4_Nf6_g3_g6_Bg2_Bg7_O-O_O-O_c4_Nc6_Nc3_a6_h3_Bd7_e4_'
    'e5_dxe5_dxe5_Be3_Qc8_Kh2_Be6_Qe2_h6_Rfd1_a5_Bc5_Re8_Nd5_Nd7_'
    'Be3_b6_b3_Nc5_Ne1_Nd4_Bxd4_exd4_Nd3_g5_Qh5_Qd8_Nxc5_bxc5_Ne3_'
    'dxe3_Rxd8_Raxd8_Re1_exf2_Re2_Rd1_Rxf2_Red8_Bf3_R1d2_Kg2_'
    'Rxf2+_Kxf2_Rd2+_Ke3_Rxa2_Bg4_Bxg4_Qxg4_Ra3_Qc8+_Bf8_e5_Rxb3+_'
    'Ke4_Rb1_Qa8_Ra1_Kf5_Kg7_Qf3_Re1_Qc3_Rf1+_Kg4_a4_Kh5_Rf5_e6+_'
    'Rf6_exf7_Bd6_Qa1_Kxf7_Qxa4_Rf3_Qd7+_Kf6_Qd8+_Ke5_Kg4_Re3_h4_'
    'Kd4_h5_Rxg3+_Kf5_Rf3+_Kg6_g4_Qh8+_Be5_Qd8+_Kxc4_Kxh6_g3_Qd1_'
    'Rf8_Qe2+_Kd5_Qg2+_Kd6_Kg5_Rf2_Qg1_Rh2_Qd1+_Bd4_Qf3_g2_Qf8+_'
    'Kd5_Qf3+_Kc4_Qe2+_Kc3_Qe1+_Kd3_Qb1+_Kd2_Qa2+_Ke3_Qb3+_Kf2_'
    'Qa2+_Kf3_Qf7+_Ke4_Qf5+_Ke3_Qe6+_Kd3_Qb3+_Bc3_Qd5+_Kc2_Qa2+_'
    'Kc1_Qa3+_Kd2_Qxc5_Kc2_Qf5+_Kc1_Qc5_Kc2_Qf5+_Kc1_Qc5_Kb2_Qf2+_'
    'Kb3_Qg3_Rh1_Qxg2_Rc1_h6_c5_h7_c4_Qf3_Kb2_Qxc3+_Kxc3_h8=Q+_'
    'Kc2_Qh7+_Kb2_Qb7+_Kc2_Qe4+_Kb2_Qb7+_Kc2_Qg2+_Kb3_Qd5_Kb2_'
    'Qb5+_Ka3_Kf4_c3_Ke3_Rd1_Qc4_Kb2_Qb4+_Kc2_Qa4+_Kc1_Qb3_c2_Qa2')


def ref(step, reference):
    """O passo vem de uma partida ou estudo (`id` ou `id#ply`)."""
    step['ref'] = reference
    return step


REFERENCES = [
    {'id': 'wikiQR', 'kind': 'web',
     'title': 'Queen versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Queen_versus_rook_endgame'},
    {'id': 'wikiFort', 'kind': 'web',
     'title': 'Fortress (chess) (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Fortress_(chess)'},
    {'id': 'dvoretsky', 'kind': 'book',
     'author': 'Mark Dvoretsky (6.ª edição, revista por Karsten Müller e '
               'Alex Fishbein)',
     'title': "Dvoretsky's Endgame Manual",
     'publisher': 'Russell Enterprises', 'year': 2025,
     'where': 'Capítulo 13, "Queen versus Rook": seções "Queen vs. Rook and '
              'Pawn", "The Rook behind the Pawn", "The Pawn on the Seventh '
              'Rank", "The Pawn on the Sixth Rank" e "A Knight Pawn on the '
              'Fifth or Sixth Rank" (pp. 336-341, índice da amostra da '
              'editora)'},
    {'id': 'schnabel', 'kind': 'study', 'author': 'Schnabelwolke',
     'title': 'Queen vs. Rook and Pawn',
     'url': 'https://lichess.org/study/sS25yvmK'},
    {'id': 'schnabelA3', 'kind': 'study', 'author': 'Schnabelwolke',
     'title': 'Queen vs. Rook and Pawn: Pawn on a3 (Draw)',
     'url': 'https://lichess.org/study/sS25yvmK/8dRDUJE7'},
    {'id': 'schnabelC3', 'kind': 'study', 'author': 'Schnabelwolke',
     'title': 'Queen vs. Rook and Pawn: Pawn on c3',
     'url': 'https://lichess.org/study/sS25yvmK/BCXr7DUN'},
    {'id': 'schnabelB5', 'kind': 'study', 'author': 'Schnabelwolke',
     'title': 'Queen vs. Rook and Pawn: Kapitel 8 (peão em b5)',
     'url': 'https://lichess.org/study/sS25yvmK/FL3rLSRa'},
    {'id': 'kaushal', 'kind': 'study', 'author': 'KaushalK',
     'title': 'Queen vs Rook (and Pawn)',
     'url': 'https://lichess.org/study/bwF2cZOY'},
    {'id': 'kaushalRook2', 'kind': 'study', 'author': 'KaushalK',
     'title': 'Queen vs Rook (and Pawn): Chapter 8 (peão de torre na '
              'segunda)',
     'url': 'https://lichess.org/study/bwF2cZOY/zJikfuzO'},
    {'id': 'moros', 'kind': 'study', 'author': 'MorosFan',
     'title': 'Queen vs Rook (+Pawn) Endings',
     'url': 'https://lichess.org/study/suEcuEFO'},
    {'id': 'vaganian', 'kind': 'game', 'white': 'Rafael Vaganian',
     'black': 'Viktor Bologan',
     'event': 'FIDE World Championship (k.o.), Groningen', 'year': 1997,
     'url': LICHESS + VAGANIAN_SANS + '#188'},
    {'id': 'vaganianSrc', 'kind': 'web',
     'title': 'Vaganian vs Bologan, Groningen 1997 (PGN Mentor, '
              'Vaganian.zip)',
     'url': 'https://www.pgnmentor.com/players/Vaganian.zip'},
    {'id': 'carlsen', 'kind': 'game', 'white': 'Magnus Carlsen',
     'black': 'Maxim Matlakov',
     'event': 'FIDE Chess.com Grand Swiss, Douglas (Ilha de Man)',
     'year': 2019,
     'url': LICHESS + CARLSEN_SANS + '#130'},
    {'id': 'carlsenSrc', 'kind': 'web',
     'title': 'Carlsen vs Matlakov, Grand Swiss 2019 (chessgames.com)',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=1977194'},
    {'id': 'carlsenPgn', 'kind': 'web',
     'title': 'Carlsen vs Matlakov, Grand Swiss 2019 (PGN Mentor, '
              'Carlsen.zip)',
     'url': 'https://www.pgnmentor.com/players/Carlsen.zip'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

LESSON = {
    'id': 'queen.vsRookPawn',
    'module': 'queen',
    'skills': ['queen.vsRookPawn'],
    'parts': [
        # 1. A fortaleza da segunda fileira.
        {'id': 'fortress', 'steps': [
            ref(think('t_fortress', FORT, 2, marks=['e3', 'g3', 'f2']),
                'wikiQR'),
            ref(talk('why', FORT, arrows=['e3g3', 'f2e3', 'f2g3'],
                     marks=['e3', 'g3', 'h3']), 'wikiQR'),
            demo('d_shuttle', FORT, 'Rg3 Ke4 Re3+ Kf4 Rh3 Qc6+ Kg1 Qc1+ Kg2',
                 goal='draw',
                 notes={1: {'arrows': ['e3g3']}, 3: {'arrows': ['g3e3']},
                        5: {'arrows': ['e3h3']}, 7: {'marks': ['g1']},
                        9: {'marks': ['f2', 'h3']}}),
            ref(move('shuttle', VDP, 'Rd3 Qb4+ Kd1 Kf4 Rf3+',
                     accept={1: 'only', 2: 'only', 3: ['Rf3+', 'Rh3']},
                     goal='draw'), 'wikiFort'),
        ]},
        # 2. Peão de cavalo: a torre que espera longe na coluna.
        {'id': 'knight', 'steps': [
            ref(think('t_knight', B5, 2, marks=['a6', 'c6']), 'schnabelB5'),
            ref(talk('knight', B5, arrows=['c6c2'], marks=['c6', 'd5']),
                'schnabelB5'),
            ref(demo('d_knight', B5, 'Rc2 Kd4 Rc6 Kd5 Rc2', goal='draw',
                     notes={1: {'arrows': ['c6c2']},
                            3: {'arrows': ['c2c6']},
                            5: {'arrows': ['c6c2']}}), 'schnabelB5'),
            move('m_knight', B5_MIRROR, 'Rf2', accept='hold', goal='draw'),
        ]},
        # 3. Montar a fortaleza: o peão anda primeiro.
        {'id': 'build', 'steps': [
            think('t_build', BUILD_T, 2, marks=['g4', 'f6']),
            talk('build', BUILD_T, arrows=['g4g5'], marks=['f6', 'h6']),
            demo('d_build', BUILD, 'g5 Kc4 Rf6 Qh1+ Kg7 Kd5 Kg6',
                 goal='draw',
                 notes={1: {'marks': ['f6', 'h6']},
                        3: {'arrows': ['g5f6']}, 7: {'marks': ['g5', 'f6']}}),
            talk('buildDone', after(BUILD, 'g5 Kc4 Rf6 Qh1+ Kg7 Kd5 Kg6'),
                 marks=['g5', 'f6']),
            move('m_build', BUILD2, 'g5 Kd4 Rf6',
                 accept={1: 'only', 2: ['Rf6']}, goal='draw'),
        ]},
        # 4. Peão de torre na segunda: zugzwang e o rei que entra.
        {'id': 'rookPawn', 'steps': [
            ref(think('t_rookPawn', ROOK2, 2, marks=['g6', 'h7']),
                'kaushalRook2'),
            ref(talk('rookPawnWhy', ROOK2, arrows=['h4e7'],
                     marks=['g6', 'e8', 'f8']), 'kaushalRook2'),
            demo('d_zugzwang', ROOK2,
                 'Qe7 Ra6 Qd8+ Kg7 Qd7+ Kh6 Qc7 Rg6 Qe7',
                 notes={1: {'marks': ['g6', 'e8', 'f8']},
                        3: {'marks': ['f7', 'g7']}, 5: {'arrows': ['d7g7']},
                        7: {'arrows': ['c7g7']}, 9: {'marks': ['g6']}}),
            demo('d_kingIn', ROOK2, 'Qe7 Rh6 Kg5',
                 notes={3: {'arrows': ['g5h6']}}),
            move('m_rookPawn', ROOK2_MIRROR, 'Qd7', accept='best'),
        ]},
        # 5. Carlsen-Matlakov: o rei, não o xeque.
        {'id': 'king', 'steps': [
            ref(think('t_king', CARL_66, 2, marks=['c6', 'd4']),
                'carlsen#130'),
            ref(talk('kingWhy', CARL_66, arrows=['b8b6'],
                     marks=['c6', 'd4']), 'carlsen#130'),
            ref(demo('d_walk', CARL_66, 'Qb6 Rd4+ Kf5 c5 Qa5 Rd5+ Ke6 Rd4',
                     notes={1: {'arrows': ['b6c6', 'b6d4']},
                            3: {'arrows': ['f5e6']}, 5: {'arrows': ['a5c5']},
                            7: {'arrows': ['e6d6']}}), 'carlsen#130'),
            ref(move('m_kd6', CARL_78, 'Kd6', accept={1: ['Kd6']}),
                'carlsen#154'),
        ]},
        # 6. Quando o rei atacante passa da terceira fileira do defensor.
        {'id': 'beyond', 'steps': [
            think('t_beyond', BEYOND_D1, 2, marks=['b2', 'f1']),
            talk('beyondWhy', BEYOND_D1, arrows=['f1g2'], marks=['b2', 'e3']),
            demo('d_beyond', BEYOND_D1, 'Kg2 Qd5+ Kg1 Kc2 Kh2', goal='draw',
                 notes={1: {'arrows': ['f1g2']}, 5: {'arrows': ['g1h2']}}),
            move('m_beyond', BEYOND_D2, 'Kg2', accept='hold', goal='draw'),
        ]},
        # 7. Peão na sétima: coroar com xeque e o espeto.
        {'id': 'seventh', 'steps': [
            think('t_seventh', SKEWER, 2, marks=['c7', 'c8', 'c6']),
            demo('d_seventh', SKEWER, 'c8=Q+ Qxc8 Rc2+ Kd7 Rxc8 Kxc8',
                 goal='draw',
                 notes={1: {'arrows': ['c8c6']},
                        3: {'arrows': ['c2c8']}}),
            talk('seventhRule', after(SKEWER, 'c8=Q+ Qxc8 Rc2+ Kd7'),
                 arrows=['c2c8'], marks=['c8', 'd7']),
            move('m_seventh', SKEWER2, 'f8=Q+ Qxf8 Rf2+',
                 accept={1: ['f8=Q+', 'f8=R+'], 2: 'only'}, goal='draw'),
        ]},
        # 8. Peão na sétima: a torre louca e o afogamento.
        {'id': 'desperado', 'steps': [
            think('t_desperado', DESP_BOX, 2, marks=['b7', 'b8']),
            talk('desperado', DESP_BOX, arrows=['h1h6'], marks=['a8']),
            demo('d_desperado', DESP_RUN,
                 'Rh5+ Ke4 Rh4+ Kf3 Rh3+ Kg2 Rh2+ Kxh2', goal='draw',
                 notes={7: {'arrows': ['h2g2']}, 8: {'marks': ['a8']}}),
            move('m_desperado', DESP_B5, 'Rh5+ Kb6 Rh6+',
                 accept='only', goal='draw'),
        ]},
        # 9. Peão na sexta, torre atrás: o zugzwang recíproco de Grigoriev,
        # depois o resumo e o desafio prático.
        {'id': 'recap', 'steps': [
            ref(think('t_grig', GRIG_B3, 2, marks=['c3', 'e6', 'e3']),
                'wikiQR'),
            ref(talk('sixth', GRIG_B3, arrows=['b3c3'],
                     marks=['c3', 'e6', 'e3']), 'wikiQR'),
            demo('d_grig', GRIG, 'Qa1+ Kd2 Qa2+ Kc3', goal='draw',
                 notes={2: {'arrows': ['c3d2']}, 4: {'arrows': ['d2c3']}}),
            move('grig', GRIG_M, 'Kf3 Qh1+ Ke2', accept='hold',
                 goal='draw'),
            talk('summaryRules', FORT, marks=['e3', 'g3', 'f2']),
            play('finish', FORT, goal='draw'),
        ]},
    ],
    'exercises': [
        exercise('e01', 1, FORT_H4, 'Rh3', accept='hold', goal='draw'),
        exercise('e02', 1, B4, 'Rc5', accept='hold', goal='draw',
                 origin='schnabel'),
        exercise('e03', 2, MARC, 'b5 Kd3 Rc6 Kd2 Ka6', accept='hold',
                 goal='draw', origin='wikiFort'),
        exercise('e04', 2, B4_PIN, 'Rc8 Qa1 Rc5', accept='hold',
                 goal='draw', origin='schnabel'),
        exercise('e05', 2, LAZA, 'Qf8+ Rg8 Qf6+ Rg7 Kh6', accept='best',
                 origin='kaushal'),
        exercise('e06', 2, WHIT, 'Qc2+ Kg8 Qc8+ Kh7 Qxe6',
                 accept={1: 'only', 2: 'win', 3: 'win'}, origin='wikiFort'),
        exercise('e07', 2, VAG, 'Kf4', accept='win', origin='vaganian'),
        exercise('e08', 3, BEYOND, 'Qb8+ Ke7 Kg7',
                 accept={1: 'win', 2: 'best'}, origin='kaushal'),
        exercise('e09', 3, POGOSYANTS, 'Rc2+ Kd8 Kb8 Qf5 f8=Q+ Qxf8 Rc8+',
                 accept='hold', goal='draw', origin='moros'),
        exercise('e10', 3, PROKES,
                 'Rd8 Qh6+ Kb7 Qb6+ Ka8 Qxc7 Rd5+ Kb6 Rb5+ Ka6 Rb6+',
                 accept='hold', goal='draw', origin='moros'),
    ],
    'passScore': 13,
    'keyPositions': [
        {'id': 'fortress', 'fen': FORT, 'ref': 'wikiQR'},
        {'id': 'vdp', 'fen': VDP, 'ref': 'wikiFort'},
        {'id': 'a3', 'fen': A3, 'ref': 'schnabelA3'},
        {'id': 'c3', 'fen': C3, 'ref': 'schnabelC3'},
        {'id': 'b5', 'fen': B5, 'ref': 'schnabelB5'},
        {'id': 'rook2', 'fen': ROOK2, 'ref': 'kaushalRook2'},
        {'id': 'grigoriev', 'fen': GRIG, 'ref': 'wikiQR'},
        {'id': 'carlsen', 'fen': CARL_66, 'ref': 'carlsen#130'},
    ],
    'practice': {'fen': FORT, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
}

OUT = Path(__file__).with_suffix('.json')
OUT.write_text(json.dumps(LESSON, ensure_ascii=False, indent=2) + '\n')
total = sum(e['stars'] for e in LESSON['exercises'])
print('Escrito', OUT, '· estrelas', total, '· mínimo', LESSON['passScore'])
