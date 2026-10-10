"""Gera `pawns.correspondingSquares.json` (a fonte da aula) a partir dos
lances em SAN. Rodar:
`tools/.cache/venv/bin/python tools/lessons/endgames/pawns.correspondingSquares.py`
e depois o `build_aula.py pawns.correspondingSquares`. O aluno joga de brancas
em toda a aula: o primeiro par (rei e peão), as portas de Grigoriev, o método,
a vez (triangulação e o canto), Lasker–Reichhelm, a partida Firouzja–Carlsen
(2020) e a defesa do estudo de prvn16. Só a parte de Lasker–Reichhelm (9
peças) é julgada pelo Stockfish; o resto, pela tabela. Exercícios: uma posição
por ideia, nenhuma da lição (regra da T58). Lição refeita na T61 (2026-10-10)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

# O primeiro par (rei e peão contra rei): d6 com d8, b6 com b8.
PAIR = '3k4/8/2P5/2K5/8/8/8/8 w - - 0 1'              # Rd6 ou Rb6 ganham
PAIR_WRONG = '3k4/8/2PK4/8/8/8/8/8 w - - 0 1'         # o par com a vez branca
# Grigoriev, 1924 (pela Wikipedia, "Corresponding squares"): peões c3, d3, c2.
# Pares: a2–b4, b1–c5, c1–d4, d1–e3, e1–f3, a1–b5; portas e2/f2 e a3/b3.
GRIG = '8/8/8/8/5k2/2pP4/2P5/4K3 w - - 0 1'           # Re1 × Rf4: Re2/Rf2
GRIG_PAIR = '8/8/8/8/8/2pP1k2/2P5/4K3 w - - 0 1'      # Re1 × Rf3: empate
ENTER = '8/8/8/8/5k2/2pP4/2P1K3/8 w - - 0 1'          # Re2 × Rf4: só Rf2
METHOD = '8/8/8/3k4/8/2pP4/2P5/2K5 w - - 0 1'         # Rc1 × Rd5: só Rd1
DANCE = '8/8/8/8/8/2pP1k2/2P5/5K2 w - - 0 1'          # Rf1 × Rf3: só Re1
PRACTICE = '8/8/8/1k6/8/2pP4/2P5/2K5 w - - 0 1'       # Rc1 × Rb5: só Rd1
# Rösch–Mast, 1995 (pela Wikipedia): pares f3–d3, f2–d2, f1–d1 (a oposição).
ROSCH = '8/8/8/5p2/4k3/7p/4K2P/8 w - - 0 1'           # só Rf2 empata
# Firouzja–Carlsen, 8th Norway Chess, Stavanger 2020 (PGN Mentor, Carlsen.zip).
FIR_START = '5k2/8/5p2/4p3/4P3/6K1/8/8 w - - 6 65'    # ply 128
FIR = '8/8/3k1p2/4p3/4P3/3K4/8/8 w - - 14 69'         # ply 136: só 69.Rd2
FIR_ERR = '8/8/3k1p2/4p3/4P3/2K5/8/8 b - - 15 69'     # ply 137: 69.Rc3?
# Strategically_Endgam, cap. "1-7 B", depois de 1...Rc7: o canto, sem tempo.
CORNER = '8/2k5/1p6/1K6/P1P5/8/8/8 w - - 0 1'         # empate
TRI = '8/8/8/1p6/1P6/3P1k2/3K4/8 w - - 0 1'           # Grigoriev: triangulação
# Lasker e Reichhelm, 1901 (pela Wikipedia): 9 peças, julgada pelo Stockfish.
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
# Estudo de miguel_angel_jodraza no Lichess, capítulo 5: só Rg1 ganha (a
# oposição distante vale nas colunas f e g; nas colunas d e e os pares somem).
MIGUEL = '8/6k1/3p4/3P4/2P5/8/8/7K w - - 0 1'
# Müller e Lamprecht (pela Wikipedia, "Key square"); veio do e17 de
# pawns.keySquares (2026-10-10): 8 peças, julgada pelo Stockfish; cada lance
# preto da linha é o único que empata (1...Rh6!!, o par certo).
MULLER = '8/6k1/1K3p2/4p1p1/4P1P1/5P2/8/8 b - - 0 1'
# A ideia do e04 numa estrutura uma fileira abaixo (segunda passada,
# 2026-10-10; a do e04 com outros reis repetia o exercício): perto dos peões
# o par pula duas colunas; só Rf2/Rf1 ganham, e contra Re6 só Rg1/Rg2/Rg3.
# Rd1, Rd2, Re2 e depois Re2/Re3 (na coluna do rei preto) empatam.
FAR = '8/8/3k4/3p4/3P4/2P5/8/4K3 w - - 0 1'

# Os lances da partida, do PGN Mentor (Carlsen.zip), conferidos com python-chess.
FIR_SANS = (
    'Nf3_Nf6_g3_c5_Bg2_Nc6_O-O_e5_e4_d6_c3_g6_d4_cxd4_cxd4_Bg4_dxe5_dxe5_'
    'Nc3_Bg7_h3_Bxf3_Qxd8+_Rxd8_Bxf3_O-O_Kg2_Nd4_Bg5_h6_Bxf6_Bxf6_Nd5_Rd6_'
    'Rac1_Bd8_Rfd1_Kg7_Ne3_Ra6_a3_h5_Nc4_Bf6_h4_Rc8_Ne3_Rac6_Rxc6_Rxc6_Rd3_'
    'Bd8_Bd1_Rc1_Bb3_b5_Rd1_Rc8_Ba2_a5_Rd3_a4_Kf1_Bb6_Rc3_Rxc3_bxc3_Nb3_Ke1_'
    'Bc5_Nc2_Nc1_Bd5_Nd3+_Ke2_Nxf2_Bc6_f6_Ne3_Nh1_Nf1_Bxa3_Bxb5_Bb2_Bxa4_'
    'Bxc3_Kf3_Bd4_g4_hxg4+_Kxg4_Nf2+_Kf3_Kh6_Ng3_Nd3_Be8_Nf4_Ne2_Ne6_Bf7_'
    'Nc5_Ng3_Bc3_h5_Be1_Bxg6_Bxg3_Kxg3_Kg5_Kf3_Nb3_Bf7_Nd4+_Kg3_Ne2+_Kf3_'
    'Nf4_Kg3_Nxh5+_Bxh5_Kxh5_Kh3_Kh6_Kh4_Kg7_Kg3_Kf8_Kf2_Ke7_Ke2_Ke8_Ke3_'
    'Kd7_Kd3_Kd6_Kc3_Kc5')

REFERENCES = [
    {'id': 'wikiCorresponding', 'kind': 'web',
     'title': 'Wikipedia: Corresponding squares',
     'url': 'https://en.wikipedia.org/wiki/Corresponding_squares'},
    {'id': 'wikiKeySquare', 'kind': 'web', 'title': 'Wikipedia: Key square',
     'url': 'https://en.wikipedia.org/wiki/Key_square'},
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
     'url': 'https://lichess.org/study/yPvKBvaX/Eas7qwb4'},
    {'id': 'grigorievStudy', 'kind': 'study', 'author': 'Caicara',
     'title': 'Corresponding Squares, capítulo 1 (Grigoriev, 1924)',
     'url': 'https://lichess.org/study/BRZgQrGn/rFDt0PpZ'},
    {'id': 'laskerStudy', 'kind': 'study', 'author': 'Caicara',
     'title': 'Corresponding Squares, capítulo 3 (Lasker e Reichhelm, 1901)',
     'url': 'https://lichess.org/study/BRZgQrGn/bDZm8JDC'},
    {'id': 'strategicallyB', 'kind': 'study', 'author': 'Strategically_Endgam',
     'title': 'Corresponding squares, capítulo "1-7 B"',
     'url': 'https://lichess.org/study/nlUKrO0X/dURU9K2M'},
    {'id': 'firouzjaCarlsen', 'kind': 'game', 'white': 'Alireza Firouzja',
     'black': 'Magnus Carlsen',
     'event': '8th Norway Chess, Stavanger, rodada 9', 'year': 2020,
     'url': 'https://lichess.org/analysis/pgn/' + FIR_SANS + '#136'},
    {'id': 'pgnMentorCarlsen', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Magnus Carlsen',
     'url': 'https://www.pgnmentor.com/players/Carlsen.zip'},
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

def ref(step, source):
    """Aponta o passo para a referência de onde a posição vem (T61)."""
    step['ref'] = source
    return step


write({
    'id': 'pawns.correspondingSquares',
    'module': 'pawns',
    'skills': ['pawns.correspondingSquares'],
    'parts': [
        {'id': 'pair', 'steps': [
            think('t_pair', PAIR, 2, marks=['d8']),
            talk('pair', PAIR, arrows=['c5d6', 'c5b6'],
                 marks=['d6', 'd8', 'b6', 'b8']),
            demo('d_pairWrong', PAIR_WRONG, 'c7+ Kc8 Kc6', goal='draw',
                 notes={1: {'marks': ['d6', 'd8']},
                        3: {'marks': ['c8']}}),
            move('pairMove', PAIR, 'Kd6 Kc8 c7 Kb7 Kd7', accept='win'),
        ]},
        {'id': 'doors', 'steps': [
            ref(think('t_doors', GRIG, 2, marks=['d4', 'c3']),
                'grigorievStudy'),
            ref(talk('doors', GRIG, arrows=['e1e2', 'e1f2'],
                     marks=['e2', 'f2', 'a3', 'b3']), 'grigorievStudy'),
            ref(demo('d_enter', GRIG, 'Ke2 Kf5 Ke3 Ke5 d4+ Kd5 Kd3',
                     notes={1: {'marks': ['e2', 'f2']},
                            5: {'arrows': ['d3d4']},
                            7: {'marks': ['c3']}}), 'grigorievStudy'),
            move('enter', ENTER, 'Kf2', accept='win'),
        ]},
        {'id': 'number', 'steps': [
            think('t_number', METHOD, 3, marks=['e2', 'f2', 'a3', 'b3']),
            talk('count', METHOD, arrows=['c1d1'],
                 marks=['e2', 'f2', 'd1', 'e1', 'e3', 'f3']),
            ref(demo('d_count', GRIG_PAIR, 'Kd1 Ke3 Kc1 Kd4 Kb1 Kc5 Ka2 Kb4',
                     goal='draw',
                     notes={2: {'marks': ['d1', 'e3']},
                            4: {'marks': ['c1', 'd4']},
                            6: {'marks': ['b1', 'c5']},
                            8: {'marks': ['a2', 'b4']}}), 'grigorievStudy'),
            talk('rule', METHOD, marks=['e3', 'd1'],
                 arrows=['c1d1', 'd5c5', 'd5d4']),
            move('numberMove', DANCE, 'Ke1 Ke3 Kd1', accept='win'),
        ]},
        {'id': 'tempo', 'steps': [
            ref(think('t_tri', TRI, 2, marks=['d2', 'f3']),
                'wikiCorresponding'),
            ref(talk('triangle', TRI, marks=['d2', 'b2', 'b3', 'f3'],
                     arrows=['d2c2', 'c2b3', 'b3b2']), 'wikiCorresponding'),
            ref(demo('d_tri', TRI, 'Kc2 Kf4 Kb3 Kf3 Kb2 Kf4 Kc2 Kf3 Kd2',
                     notes={1: {'marks': ['c2', 'f4']},
                            3: {'marks': ['b3', 'f3']},
                            5: {'marks': ['b2', 'f3']},
                            9: {'marks': ['d2', 'f3']}}),
                'wikiCorresponding'),
            ref(demo('d_corner', CORNER, 'Ka6 Kc6 Ka7 Kc7 Ka8 Kc8',
                     goal='draw',
                     notes={2: {'marks': ['a6', 'c6']},
                            4: {'marks': ['a7', 'c7']},
                            6: {'marks': ['a8', 'c8']}}), 'strategicallyB'),
            move('triMove', TRI, 'Kc2 Kf4 Kb3 Kf3 Kb2', accept='win'),
        ]},
        {'id': 'lasker', 'steps': [
            ref(think('t_lasker', LASKER, 2, marks=['b5', 'h5']),
                'laskerStudy'),
            ref(talk('laskerKeys', LASKER, marks=['b5', 'h5', 'c4', 'b6'],
                     arrows=['a1b1', 'a7b7']), 'laskerStudy'),
            ref(demo('d_lasker', LASKER,
                     'Kb1 Kb7 Kc1 Kc7 Kd1 Kd8 Kc2 Kc8 Kd2 Kd7 Kc3 Kc7 Kd3',
                     notes={1: {'marks': ['b1', 'c7']},
                            3: {'marks': ['c1', 'b7']},
                            5: {'marks': ['d1', 'c7']},
                            7: {'marks': ['c2', 'b8']},
                            9: {'marks': ['d2', 'c8']},
                            11: {'marks': ['c3', 'b7']},
                            13: {'marks': ['d3', 'c7'],
                                 'arrows': ['d3c4', 'd3e3']}}),
                'laskerStudy'),
            move('laskerMove', LASKER, 'Kb1 Kb7 Kc1', accept='win'),
        ]},
        {'id': 'game', 'steps': [
            ref(think('t_game', FIR, 2, marks=['d6']), 'firouzjaCarlsen'),
            ref(talk('game', FIR, arrows=['d3d2', 'd6c5'],
                     marks=['d6', 'd2', 'c5', 'c3', 'b5', 'b3']),
                'firouzjaCarlsen'),
            ref(demo('d_game', FIR_START, 'Kf2 Ke7 Ke2 Ke8 Ke3 Kd7 Kd3 Kd6',
                     goal='draw',
                     notes={1: {'marks': ['f8', 'f2']},
                            3: {'marks': ['e7', 'e2']},
                            5: {'marks': ['e8', 'e3']},
                            7: {'marks': ['d7', 'd3']},
                            8: {'marks': ['d6', 'd2']}}),
                'firouzjaCarlsen#128'),
            ref(talk('gameError', FIR_ERR,
                     arrows=['d6c5', 'c5b4', 'b4c4', 'c4c3', 'c3d4'],
                     marks=['c3', 'c5', 'e4']), 'firouzjaCarlsen#137'),
            ref(move('gameMove', FIR, 'Kd2 Kc5 Kc3 Kb5 Kb3', accept='hold',
                     goal='draw'), 'firouzjaCarlsen'),
            move('gameFar', FAR, 'Kf2 Ke6 Kg2', accept='win'),
        ]},
        {'id': 'defend', 'steps': [
            ref(think('t_defend', PRVN, 1, marks=['e7', 'g7']), 'prvn16'),
            ref(talk('defend', PRVN, marks=['g2', 'f8', 'h3', 'e7', 'g3', 'f7'],
                     arrows=['f3g2', 'f8e7', 'f8f7']), 'prvn16'),
            ref(move('defendMove', PRVN, 'Kg2 Ke7 Kh3 Kf7 Kg3', accept='hold',
                     goal='draw'), 'prvn16'),
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
        exercise('e06', 3, STRAT3, 'Ka6 Kc6 a4 Kc7 Ka7 Kc6 Kb8', accept='win',
                 origin='strategically'),
        exercise('e07', 3, MULLER,
                 'Kh6 Kc7 Kg7 Kb7 Kh7 Kb8 Kh8 Kc8 Kg8 Kd7 Kh7 Ke6 Kg6',
                 accept='hold', goal='draw', origin='wikiKeySquare'),
    ],
    'passScore': 9,
    'keyPositions': [
        {'id': 'grigoriev', 'fen': GRIG, 'ref': 'grigorievStudy'},
        {'id': 'method', 'fen': METHOD},
        {'id': 'roschMast', 'fen': ROSCH, 'ref': 'wikiCorresponding'},
        {'id': 'triangle', 'fen': TRI, 'ref': 'wikiCorresponding'},
        {'id': 'lasker', 'fen': LASKER, 'ref': 'laskerStudy'},
        {'id': 'defend', 'fen': PRVN, 'ref': 'prvn16'},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
})
