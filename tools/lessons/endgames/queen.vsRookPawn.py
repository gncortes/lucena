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
FORT_CHECK = after(FORT, 'Rg3 Ke4 Re3+ Kf4 Rg3 Qc6+')   # só Rf1, Rg1, Rh2
# Van der Poel-Smits 2000 (Wikipedia, "Fortress"), espelhada, depois de Dd4+
VDP = '8/8/8/8/3qk3/5R2/3KP3/8 w - - 0 1'
VDP_E02 = '8/8/8/8/3k2q1/2R5/3PK3/8 w - - 0 1'          # a mesma, virada
# Defesa: quais peões seguram (estudo de Schnabelwolke)
A3 = '8/8/8/8/3q4/PK1k4/1R6/8 w - - 0 1'                # só Ra2
A3_E04 = '8/8/8/8/8/PK1k4/1R6/4q3 w - - 0 1'            # variante própria
B3 = '8/8/3qk3/8/2R5/1P6/2K5/8 w - - 0 1'               # empate
B5 = '1q6/8/2R5/1P1k4/1K6/8/8/8 w - - 0 1'              # empate na quinta
C3 = '8/8/2q1k3/8/3R4/2P5/2K5/8 w - - 0 1'              # perdido
# Marcotulli-Malström 2001 (Wikipedia, "Fortress"), espelhada
MARC = '8/8/1K6/8/1P6/4k3/2R5/7q w - - 0 1'
# Ataque: peão de torre na segunda (estudo de KaushalK)
ROOK2 = '6k1/7p/6r1/5K2/7Q/8/8/8 w - - 0 1'
# Ataque: a fortaleza sem o peão no lugar (FORT espelhada depois de f3)
LOOSE = '8/6k1/4rp2/5K2/8/1Q6/8/8 w - - 0 1'
# Ataque: o rei entra (Vaganian-Bologan 1997 e Carlsen-Matlakov 2019,
# estudo de MorosFan)
VAG = '8/1Q6/8/6K1/2p5/8/2k5/2r5 w - - 0 1'             # só Rf4
CARL_END = '8/8/8/2K5/2p2Q2/3r4/2k5/8 w - - 0 1'
CARL_ZZ = '1Q6/8/2p5/3r4/2k3K1/8/8/8 w - - 0 1'         # Db6: zugzwang
# Whitaker-Ferriz 1959 (Wikipedia, "Fortress"), espelhada: torre sem proteção
WHIT = '8/6pk/4r3/8/Q4K1P/8/8/8 w - - 0 1'              # só Dc2+
# Exercícios: posições que a lição não mostra
FORT_H4 = '8/8/1q6/8/5k1p/4R3/5PK1/8 w - - 0 1'         # própria: peão a mais
B4 = '8/8/4k3/3q4/1PR5/8/2K5/8 w - - 0 1'               # Schnabelwolke, b4
B4_PIN = '8/8/8/1KR5/1P1k4/8/q7/8 w - - 0 1'            # Schnabelwolke, cap. 6
LAZA = '7k/4Q2p/6r1/7K/8/8/8/8 w - - 0 1'               # G. Laza (KaushalK)
BEYOND = '3k4/3p3K/4r3/8/1Q6/8/8/8 w - - 0 1'           # KaushalK, cap. 7
POGOSYANTS = '2k5/K4P1q/8/8/8/8/R7/8 w - - 0 1'          # estudo (MorosFan)
PROKES = '2R5/2P5/K7/2k5/8/8/8/2q5 w - - 0 1'            # estudo (MorosFan)
CARL_START = '8/2k5/2p3Q1/3r4/8/8/7K/8 w - - 0 1'       # Carlsen-Matlakov, 54.
# Peão na sexta, torre atrás: zugzwang recíproco (Grigoriev 1933, Wikipedia)
GRIG = '8/4k3/4P3/8/8/2K1R3/8/3q4 b - - 0 1'            # pretas jogam: empate
GRIG_B3 = '8/4k3/4P3/8/8/1K2R3/8/3q4 w - - 0 1'         # só Rc3
GRIG_C4 = '8/4k3/4P3/8/2K5/4R3/8/3q4 w - - 0 1'         # só Rc3

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
    {'id': 'kaushal', 'kind': 'study', 'author': 'KaushalK',
     'title': 'Queen vs Rook (and Pawn)',
     'url': 'https://lichess.org/study/bwF2cZOY'},
    {'id': 'moros', 'kind': 'study', 'author': 'MorosFan',
     'title': 'Queen vs Rook (+Pawn) Endings',
     'url': 'https://lichess.org/study/suEcuEFO'},
    {'id': 'vaganian', 'kind': 'game', 'white': 'Rafael Vaganian',
     'black': 'Viktor Bologan', 'event': 'FIDE World Championship, Groningen',
     'year': 1997},
    {'id': 'carlsen', 'kind': 'game', 'white': 'Magnus Carlsen',
     'black': 'Maxim Matlakov', 'event': 'Douglas (Ilha de Man)',
     'year': 2019},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

LESSON = {
    'id': 'queen.vsRookPawn',
    'module': 'queen',
    'skills': ['queen.vsRookPawn'],
    'parts': [
        {'id': 'fortress', 'steps': [
            think('t_fortress', FORT, 5, 2, marks=['e3', 'g3', 'f2']),
            talk('why', FORT, arrows=['f2e3', 'f2g3'],
                 marks=['e3', 'g3', 'g1', 'h1', 'h2']),
            demo('d_shuttle', FORT, 'Rg3 Ke4 Re3+ Kf4 Rg3 Qc6+ Kg1 Qc1+ Kg2',
                 goal='draw',
                 notes={1: {'arrows': ['e3g3']}, 3: {'arrows': ['g3e3']},
                        7: {'marks': ['g1']}, 9: {'marks': ['g2']}}),
            move('shuttle', VDP, 'Rd3 Qb4+ Kd1 Kf4 Rf3+',
                 accept='hold', goal='draw'),
        ]},
        {'id': 'rules', 'steps': [
            think('t_rules', A3, 3, 2, marks=['a2', 'b2']),
            talk('rulesTalk', C3, arrows=['e6d5', 'd5e4', 'e4d3'],
                 marks=['b4', 'd4', 'c3']),
            talk('knight', B5, arrows=['b5c6'], marks=['a6', 'c6', 'b5']),
            move('corner', A3, 'Ka2 Qd5+ Ka1 Qd4 Ka2 Kc3 Ka1 Qd1+ Ka2',
                 accept='hold', goal='draw'),
        ]},
        {'id': 'rookPawn', 'steps': [
            think('t_rookPawn', ROOK2, 5, 2, marks=['g6', 'h7']),
            talk('rookPawnWhy', after(ROOK2, 'Qe7'), side='white',
                 marks=['g6', 'e8', 'f8'], arrows=['e7e8', 'e7f8']),
            demo('d_zugzwang', ROOK2,
                 'Qe7 Ra6 Qd8+ Kg7 Qd7+ Kh6 Qc7 Rg6 Qe7',
                 notes={1: {'marks': ['g6', 'e8', 'f8']},
                        3: {'marks': ['f7', 'g7']}, 5: {'arrows': ['d7g7']},
                        7: {'arrows': ['c7g7']}, 9: {'marks': ['g6']}}),
            move('punish', LOOSE, 'Qxe6', accept='best'),
        ]},
        {'id': 'king', 'steps': [
            think('t_king', CARL_ZZ, 5, 2, marks=['c6', 'd4', 'c5']),
            talk('kingWhy', CARL_START, arrows=['h2f4', 'f4e4'],
                 marks=['d6', 'c5', 'd4']),
            demo('d_last', CARL_END, 'Qf5 Kc3 Qf6+ Kb3 Qf1 Rd8 Qxc4+',
                 notes={1: {'arrows': ['f5d3']}, 5: {'arrows': ['f1d3']},
                        7: {'arrows': ['f1c4']}}),
            move('zugzwang', CARL_ZZ, 'Qb6', accept='best'),
        ]},
        {'id': 'recap', 'steps': [
            talk('summaryRules', FORT, marks=['e3', 'g3', 'f2']),
            talk('sixth', GRIG, side='white', marks=['c3', 'e6', 'e3'],
                 arrows=['e3e6']),
            move('grig', GRIG_B3, 'Kc3 Qa1+ Kd2', accept='hold',
                 goal='draw'),
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
        {'id': 'a3', 'fen': A3, 'ref': 'schnabel'},
        {'id': 'b5', 'fen': B5, 'ref': 'schnabel'},
        {'id': 'rook2', 'fen': ROOK2, 'ref': 'kaushal'},
        {'id': 'grigoriev', 'fen': GRIG, 'ref': 'wikiQR'},
        {'id': 'carlsen', 'fen': CARL_ZZ, 'ref': 'carlsen'},
    ],
    'practice': {'fen': FORT, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
}

OUT = Path(__file__).with_suffix('.json')
OUT.write_text(json.dumps(LESSON, ensure_ascii=False, indent=2) + '\n')
total = sum(e['stars'] for e in LESSON['exercises'])
print('Escrito', OUT, '· estrelas', total, '· mínimo', LESSON['passScore'])
