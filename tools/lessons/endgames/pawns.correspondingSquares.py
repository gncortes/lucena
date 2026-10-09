"""Gera `pawns.correspondingSquares.json` (a fonte da aula) a partir dos
lances em SAN. Rodar:
`tools/.cache/venv/bin/python tools/lessons/endgames/pawns.correspondingSquares.py`
e depois o `build_aula.py pawns.correspondingSquares`. O aluno joga de brancas
em toda a aula: ganha nas estruturas de Grigoriev e de Lasker, defende em
Rösch–Mast e no estudo de prvn16. Só a parte de Lasker–Reichhelm (10 peças)
é julgada pelo Stockfish; o resto, pela tabela. Exercícios: uma posição por
ideia, nenhuma da lição (regra da T58)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

# Grigoriev, 1924 (pela Wikipedia, "Corresponding squares"): peões c3, d3, c2.
# Pares: a2–b4, b1–c5, c1–d4, d1–e3, e1–f3, a1–b5; portas e2/f2 e a3/b3.
GRIG = '8/8/8/8/5k2/2pP4/2P5/4K3 w - - 0 1'           # Re1 × Rf4: Re2/Rf2
GRIG_PAIR = '8/8/8/8/8/2pP1k2/2P5/4K3 w - - 0 1'      # Re1 × Rf3: empate
ENTER = '8/8/8/8/5k2/2pP4/2P1K3/8 w - - 0 1'          # Re2 × Rf4: só Rf2
METHOD = '8/8/8/3k4/8/2pP4/2P5/2K5 w - - 0 1'         # Rc1 × Rd5: só Rd1
DANCE = '8/8/8/8/8/2pP1k2/2P5/5K2 w - - 0 1'          # Rf1 × Rf3: só Re1
PRACTICE = '8/8/8/1k6/8/2pP4/2P5/2K5 w - - 0 1'       # Rc1 × Rb5: só Rd1
TREB = '8/8/8/3Kp3/4Pk2/8/8/8 w - - 0 1'              # trebuchet: quem joga perde
# Rösch–Mast, 1995 (pela Wikipedia): pares f3–d3, f2–d2, f1–d1 (a oposição).
ROSCH = '8/8/8/5p2/4k3/7p/4K2P/8 w - - 0 1'           # só Rf2 empata
ROSCH_MIRROR = '8/8/8/2p5/3k4/p7/P2K4/8 w - - 0 1'    # espelho: só Rc2
TRI = '8/8/8/1p6/1P6/3P1k2/3K4/8 w - - 0 1'           # Grigoriev: triangulação
# Lasker e Reichhelm, 1901 (pela Wikipedia): 10 peças, julgada pelo Stockfish.
LASKER = '8/k7/3p4/p2P1p2/P2P1P2/8/8/K7 w - - 0 1'    # só Rb1
# Estudo de prvn16 no Lichess: as brancas defendem; só Rg2 empata.
PRVN = '5k2/8/5p2/7p/8/4PK2/8/8 w - - 0 1'
# Estudo de Peperde no Lichess, capítulo 1: só Rb4 empata.
PEPERDE = '1k6/8/Pp4p1/6P1/K7/8/8/8 w - - 0 1'
# Rei e peão contra rei, os pares da Wikipedia (exemplo 1): só Rc6 ganha.
KP = '4k3/8/3P4/2K5/8/8/8/8 w - - 0 1'
# Estudo de RuelleCanino_12_CDOC no Lichess, capítulo 4 ("Mined Squares"):
# o par c4–b6; Rd4, Rd3 e Rb3 ganham, Rc4? Rb6! empata.
RUELLE4 = '8/1k6/8/1P6/1P6/2K5/8/8 w - - 0 1'
# Estudo de Strategically_Endgam no Lichess, capítulo "1-7 B3", depois de
# 1...Rc7: só Ra6 ganha; o tempo a3–a4 decide a vez.
STRAT3 = '8/2k5/1p6/1K6/2P5/P7/8/8 w - - 0 1'
# Estudo de Strategically_Endgam no Lichess, capítulo 4: só Rh1 empata.
STRAT = '8/8/8/4p1p1/8/5P2/6K1/3k4 w - - 0 1'
# Estudo de miguel_angel_jodraza no Lichess, capítulo 5: só Rg1 ganha (a
# oposição distante vale nas colunas f e g; nas colunas d e e os pares somem).
MIGUEL = '8/6k1/3p4/3P4/2P5/8/8/7K w - - 0 1'

REFERENCES = [
    {'id': 'wikiCorresponding', 'kind': 'web',
     'title': 'Wikipedia: Corresponding squares',
     'url': 'https://en.wikipedia.org/wiki/Corresponding_squares'},
    {'id': 'wikiZugzwang', 'kind': 'web', 'title': 'Wikipedia: Zugzwang',
     'url': 'https://en.wikipedia.org/wiki/Zugzwang'},
    {'id': 'wikiOpposition', 'kind': 'web',
     'title': 'Wikipedia: Opposition (chess)',
     'url': 'https://en.wikipedia.org/wiki/Opposition_(chess)'},
    {'id': 'wikiHalberstadt', 'kind': 'web',
     'title': 'Wikipedia: Vitaly Halberstadt',
     'url': 'https://en.wikipedia.org/wiki/Vitaly_Halberstadt'},
    {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
     'title': "Dvoretsky's Endgame Manual (6.ª edição, revista por Karsten "
              'Müller e Alex Fishbein)',
     'publisher': 'Russell Enterprises', 'year': 2025,
     'where': 'Índice da amostra da editora: "Corresponding Squares", p. 19'},
    {'id': 'prvn16', 'kind': 'study', 'author': 'prvn16',
     'title': 'Corresponding squares',
     'url': 'https://lichess.org/study/yPvKBvaX'},
    {'id': 'peperde', 'kind': 'study', 'author': 'Peperde',
     'title': 'CORRESPONDING SQUARES',
     'url': 'https://lichess.org/study/Q9SBq8UG'},
    {'id': 'miguel', 'kind': 'study', 'author': 'miguel_angel_jodraza',
     'title': 'Corresponding Squares',
     'url': 'https://lichess.org/study/YYpXsMt2'},
    {'id': 'caicara', 'kind': 'study', 'author': 'Caicara',
     'title': 'Corresponding Squares',
     'url': 'https://lichess.org/study/BRZgQrGn'},
    {'id': 'sambeaux', 'kind': 'study', 'author': 'sambeaux',
     'title': 'Corresponding Squares',
     'url': 'https://lichess.org/study/28Y3TlhL'},
    {'id': 'ruelle', 'kind': 'study', 'author': 'RuelleCanino_12_CDOC',
     'title': 'Corresponding Square',
     'url': 'https://lichess.org/study/dVtrvWmh'},
    {'id': 'strategically', 'kind': 'study', 'author': 'Strategically_Endgam',
     'title': 'Corresponding squares',
     'url': 'https://lichess.org/study/nlUKrO0X'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'pawns.correspondingSquares',
    'module': 'pawns',
    'skills': ['pawns.correspondingSquares'],
    'parts': [
        {'id': 'doors', 'steps': [
            think('t_doors', GRIG, 3, 2, marks=['e2', 'f2', 'a3', 'b3']),
            talk('trebuchet', TREB, marks=['d5', 'f4'],
                 arrows=['d5e5', 'f4e4']),
            talk('doors', GRIG_PAIR, marks=['e2', 'f2', 'a3', 'b3'],
                 arrows=['e1d1', 'f3e3']),
            demo('d_enter', GRIG,
                 'Ke2 Kf5 Ke3 Ke5 d4+ Kd5 Kd3 Kd6 Ke4 Ke6 d5+ Kd6 Kd4 Kd7 Kc5',
                 notes={1: {'marks': ['e2']},
                        5: {'arrows': ['d3d4']},
                        7: {'marks': ['c3']},
                        15: {'arrows': ['c5b4', 'd5d6'], 'marks': ['c3']}}),
            move('enter', ENTER, 'Kf2', accept='win'),
        ]},
        {'id': 'number', 'steps': [
            think('t_number', METHOD, 5, 3, marks=['d1', 'e3', 'c5', 'd4']),
            talk('count', METHOD,
                 marks=['a2', 'b1', 'c1', 'd1', 'e1', 'a1',
                        'b4', 'c5', 'd4', 'e3', 'f3', 'b5']),
            talk('rule', METHOD, marks=['e3', 'd1'],
                 arrows=['c1d1', 'd5c5', 'd5d4']),
            demo('d_number', METHOD, 'Kd1 Kc5 Ke2 Kd5 Ke3 Ke5 d4+ Kd5 Kd3',
                 notes={1: {'marks': ['d1', 'e3']},
                        3: {'marks': ['e2']},
                        9: {'marks': ['c3']}}),
            move('numberMove', DANCE, 'Ke1 Ke3 Kd1', accept='win'),
        ]},
        {'id': 'opposition', 'steps': [
            think('t_rosch', ROSCH, 3, 2, marks=['e1', 'e2', 'e3', 'f3']),
            talk('rosch', ROSCH, marks=['d3', 'f3', 'd2', 'f2', 'd1', 'f1'],
                 arrows=['e2f2']),
            demo('d_rosch', ROSCH, 'Kf2 Kd3 Kf3 Kd2 Kf2 Kd1 Kf1', goal='draw',
                 notes={1: {'marks': ['e3', 'f3']},
                        3: {'marks': ['d3', 'f3']},
                        5: {'marks': ['d2', 'f2']},
                        7: {'marks': ['d1', 'f1']}}),
            talk('triangle', TRI, marks=['d2', 'b2', 'b3', 'f3'],
                 arrows=['d2c2', 'c2b3', 'b3b2']),
            move('roschMove', ROSCH_MIRROR, 'Kc2 Ke3 Kc3 Ke2 Kc2 Ke1 Kc1',
                 accept='hold', goal='draw'),
        ]},
        {'id': 'lasker', 'steps': [
            think('t_lasker', LASKER, 3, 2, marks=['b5', 'h5']),
            talk('laskerKeys', LASKER, marks=['b5', 'h5', 'c4', 'b6'],
                 arrows=['a1b1', 'a7b7']),
            demo('d_lasker', LASKER,
                 'Kb1 Kb7 Kc1 Kc7 Kd1 Kd8 Kc2 Kc8 Kd2 Kd7 Kc3 Kc7 Kd3 Kb6 '
                 'Ke3 Kc7 Kf3 Kd7 Kg3 Ke7 Kh4 Kf6 Kh5',
                 notes={1: {'marks': ['b1', 'c7']},
                        3: {'marks': ['c1', 'b7']},
                        5: {'marks': ['d1', 'c7']},
                        7: {'marks': ['c2', 'b8']},
                        9: {'marks': ['d2', 'c8']},
                        11: {'marks': ['c3', 'b7']},
                        13: {'marks': ['d3', 'c7']},
                        15: {'arrows': ['e3f3', 'f3g3', 'g3h4', 'h4h5']},
                        23: {'marks': ['g5', 'f5']}}),
            move('laskerMove', LASKER, 'Kb1 Kb7 Kc1', accept='win'),
        ]},
        {'id': 'defend', 'steps': [
            think('t_defend', PRVN, 3, 1, marks=['e7', 'g7']),
            talk('defend', PRVN, marks=['g2', 'f8', 'h3', 'e7', 'g3', 'f7'],
                 arrows=['f8e7', 'f8g7']),
            move('defendMove', PRVN, 'Kg2 Ke7 Kh3 Kf7 Kg3', accept='hold',
                 goal='draw'),
            talk('recap', METHOD, marks=['d1', 'e3']),
            play('finish', PRACTICE),
        ]},
    ],
    'exercises': [
        exercise('e01', 1, KP, 'Kc6 Kd8 d7', accept='win',
                 origin='wikiCorresponding'),
        exercise('e02', 2, RUELLE4, 'Kd4 Kb6 Kc4', accept='win',
                 origin='ruelle'),
        exercise('e03', 2, PEPERDE, 'Kb4 Ka8 Kc4 Kb8 Kb4', accept='hold',
                 goal='draw', origin='peperde'),
        exercise('e04', 3, MIGUEL, 'Kg1 Kf7 Kf1 Ke7 Kg2', accept='win',
                 origin='miguel'),
        exercise('e05', 3, STRAT, 'Kh1 Ke1 Kg1 Ke2 Kg2', accept='hold',
                 goal='draw', origin='strategically'),
        exercise('e06', 3, STRAT3, 'Ka6 Kc6 a4 Kc7 Ka7 Kc6 Kb8', accept='win',
                 origin='strategically'),
    ],
    'passScore': 9,
    'keyPositions': [
        {'id': 'grigoriev', 'fen': GRIG, 'ref': 'wikiCorresponding'},
        {'id': 'method', 'fen': METHOD},
        {'id': 'roschMast', 'fen': ROSCH, 'ref': 'wikiCorresponding'},
        {'id': 'triangle', 'fen': TRI, 'ref': 'wikiCorresponding'},
        {'id': 'lasker', 'fen': LASKER, 'ref': 'wikiCorresponding'},
        {'id': 'defend', 'fen': PRVN, 'ref': 'prvn16'},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
})
