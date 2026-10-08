"""Gera `pawns.reti.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/pawns.reti.py`
e depois o `build_aula.py pawns.reti`. Quase toda a aula é de empate: o aluno
defende de brancas (Réti), de pretas (Yates–Marshall) e, na parte dos
limites, ganha de pretas quando a manobra chega tarde."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

RETI = '7K/8/k1P5/7p/8/8/8/8 w - - 0 1'           # Réti, 1921
PUSH = after(RETI, 'Kg7 h4 Kf6 h3')                # o peão corre: Ke7/Ke6
LATE = after(RETI, 'Kg7 h4 Kf6 Kb6 Ke5 h3')        # o peão corre tarde: Kd6
MARSHALL = '8/8/8/8/pK6/8/5P2/1k6 b - - 0 1'       # Yates–Marshall, 1929
MARSHALL_WRONG = after(MARSHALL, 'Kc2')            # 60...Kc2? 61.f4 ganha
TOO_FAR = '7K/8/k1P5/8/7p/8/8/8 w - - 0 1'         # peão em h4: tarde demais
FAR = after(TOO_FAR, 'Kg7')                        # pretas jogam e ganham
CLOSE_A5 = '7K/8/2P5/k6p/8/8/8/8 w - - 0 1'        # rei preto longe: c7 ganha
MIRROR = 'K7/8/5P1k/p7/8/8/8/8 w - - 0 1'          # Réti espelhado
KG8 = '6K1/8/k1P5/7p/8/8/8/8 w - - 0 1'            # rei em g8: Kf7/Kg7
KH7 = '8/7K/k1P5/7p/8/8/8/8 w - - 0 1'             # rei em h7: Kg6/Kg7
G5 = '7K/8/k1P5/6p1/8/8/8/8 w - - 0 1'             # peão de g5: só Kg7
SWAP = '8/8/8/8/7P/K1p5/8/7k b - - 0 1'            # cores trocadas
A7 = '8/k5K1/2P5/7p/8/8/8/8 b - - 0 1'             # rei preto em a7: perde
RETI1928 = '8/6p1/k1P2p1p/7K/8/8/8/8 w - - 0 1'    # Réti, 1928
LASKER = '8/8/6K1/ppp5/7k/1P6/1P6/8 w - - 0 1'     # Lasker–Tarrasch, 41...Kxh4
SARYCHEV = '8/1pPK3b/8/8/8/5k2/8/8 w - - 0 1'      # Sarychev

REFERENCES = [
    {'id': 'wikiReti', 'kind': 'web',
     'title': 'Wikipedia: Réti endgame study',
     'url': 'https://en.wikipedia.org/wiki/R%C3%A9ti_endgame_study'},
    {'id': 'wikiRichard', 'kind': 'web',
     'title': 'Wikipedia: Richard Réti',
     'url': 'https://en.wikipedia.org/wiki/Richard_R%C3%A9ti'},
    {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
     'title': "Dvoretsky's Endgame Manual (6.ª edição, revista por Karsten "
              'Müller e Alex Fishbein)',
     'publisher': 'Russell Enterprises', 'year': 2025,
     'where': "Índice da amostra da editora: \"Réti's Idea\", p. 31"},
    {'id': 'pn2206', 'kind': 'study', 'author': 'pn2206',
     'title': "Richard Reti's 1921 Endgame Study",
     'url': 'https://lichess.org/study/zPksA8Uo'},
    {'id': 'flohahn22', 'kind': 'study', 'author': 'flohahn22',
     'title': 'Chess Endgames: Reti Idea',
     'url': 'https://lichess.org/study/PLK2LzXH'},
    {'id': 'carreira', 'kind': 'study', 'author': 'CarreiraChess',
     'title': "Richard Reti's Endgame Study",
     'url': 'https://lichess.org/study/Hp71MDeO'},
    {'id': 'alien2798', 'kind': 'study', 'author': 'alien2798',
     'title': 'The Reti Manoeuvre',
     'url': 'https://lichess.org/study/LOwS84ta'},
    {'id': 'drfiskeson', 'kind': 'study', 'author': 'DrFiskeson',
     'title': 'Brilliant Reti maneuver study',
     'url': 'https://lichess.org/study/liSLeKY9'},
    {'id': 'yatesMarshall', 'kind': 'game', 'white': 'Frederick Yates',
     'black': 'Frank Marshall', 'event': 'Karlsbad, rodada 9', 'year': 1929},
    {'id': 'laskerTarrasch', 'kind': 'game', 'white': 'Emanuel Lasker',
     'black': 'Siegbert Tarrasch', 'event': 'São Petersburgo', 'year': 1914},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'pawns.reti',
    'module': 'pawns',
    'skills': ['pawns.reti'],
    'parts': [
        {'id': 'reti', 'steps': [
            think('t_reti', RETI, 5, 2, ask='line',
                  arrows=['h8e5'], marks=['d6', 'h4']),
            talk('intro', RETI, arrows=['h5h1', 'a6b7'],
                 marks=['d5', 'h1', 'd1']),
            talk('diagonal', RETI, arrows=['h8h4', 'h8e5', 'e5h2', 'e5d6'],
                 marks=['e5']),
            demo('d_main', RETI, 'Kg7 h4 Kf6 Kb6 Ke5 Kxc6 Kf4 h3 Kg3 h2 Kxh2',
                 goal='draw',
                 notes={1: {'arrows': ['g7f6']},
                        5: {'arrows': ['e5d6', 'e5f4']},
                        7: {'marks': ['f4']}}),
            move('main', RETI, 'Kg7 Kb6 Kf6 h4 Ke5 Kxc6 Kf4',
                 accept={1: 'only', 2: 'only', 3: 'only', 4: 'hold'},
                 goal='draw'),
        ]},
        {'id': 'push', 'steps': [
            think('t_push', PUSH, 3, 1, arrows=['c6c7']),
            talk('push', PUSH, arrows=['f6e7', 'c6c8'], marks=['d7']),
            demo('d_push', PUSH, 'Ke7 h2 c7 Kb7 Kd7 h1=Q c8=Q+', goal='draw',
                 notes={1: {'marks': ['d7', 'd8']},
                        5: {'marks': ['c8']}}),
            talk('late', LATE, arrows=['e5d6'], marks=['c7']),
            move('lateMove', LATE, 'Kd6 h2 c7 Kb7 Kd7',
                 accept='hold', goal='draw'),
        ]},
        {'id': 'marshall', 'steps': [
            think('t_marshall', MARSHALL, 5, 2, side='black',
                  arrows=['b1b2'], marks=['a4', 'f2']),
            talk('marshall', MARSHALL, arrows=['b1b2', 'b2c3', 'c3d4'],
                 marks=['a4', 'f2'], side='black'),
            talk('wrong', MARSHALL_WRONG, arrows=['f2f4'], marks=['c2'],
                 side='black'),
            move('marshallMove', MARSHALL, 'Kb2 Kxa4 Kc3 f4 Kd4',
                 accept='hold', goal='draw'),
        ]},
        {'id': 'limits', 'steps': [
            think('t_far', TOO_FAR, 3, 1, side='black', marks=['h4']),
            talk('far', TOO_FAR, arrows=['h4h1'], marks=['e5', 'f4'],
                 side='black'),
            talk('close', CLOSE_A5, arrows=['c6c7', 'a5b6'], marks=['c8'],
                 side='black'),
            move('farMove', FAR, 'h3 Kf6 h2', accept='win', goal='win'),
        ]},
        {'id': 'recap', 'steps': [
            talk('rules', RETI, arrows=['h8e5', 'e5d6', 'e5h2']),
            talk('mirror', MIRROR, arrows=['a8d5']),
            move('mirrorMove', MIRROR, 'Kb7 a4 Kc6 Kg6 Kd5 Kxf6 Kc4',
                 accept='hold', goal='draw'),
            play('finish', KG8, goal='draw'),
        ]},
    ],
    'exercises': [
        exercise('e01', 1, RETI, 'Kg7', accept='hold', goal='draw',
                 origin='wikiReti'),
        exercise('e02', 1, KH7, 'Kg6', accept='hold', goal='draw'),
        exercise('e03', 1, CLOSE_A5, 'c7', accept='win', goal='win'),
        exercise('e04', 1, G5, 'Kg7', accept='hold', goal='draw'),
        exercise('e05', 2, after(MIRROR, 'Kb7 a4 Kc6 a3'),
                 'Kd7 a2 f7 Kg7 Ke7', accept='hold', goal='draw'),
        exercise('e06', 2, SWAP, 'Kg2 h5 Kf3 h6 Ke3',
                 accept='hold', goal='draw'),
        exercise('e07', 2, MARSHALL_WRONG, 'f4', accept='win', goal='win',
                 origin='yatesMarshall'),
        exercise('e08', 2, A7, 'h4 Kf6 Kb8', accept='win', goal='win'),
        exercise('e09', 2, RETI1928, 'Kg6 Kb6 Kxg7 h5 Kxf6',
                 accept='hold', goal='draw', origin='wikiReti'),
        exercise('e10', 3, LASKER, 'Kf5 Kg3 Ke4 Kf2 Kd5',
                 accept='hold', goal='draw', origin='laskerTarrasch'),
        exercise('e11', 3, SARYCHEV, 'Kc8 b5 Kd7 b4 Kd6 Bf5 Ke5',
                 accept='hold', goal='draw', origin='drfiskeson'),
    ],
    'passScore': 12,
    'keyPositions': [
        {'id': 'reti', 'fen': RETI, 'ref': 'wikiReti'},
        {'id': 'reti1928', 'fen': RETI1928, 'ref': 'wikiReti'},
        {'id': 'laskerTarrasch', 'fen': LASKER, 'ref': 'laskerTarrasch'},
        {'id': 'yatesMarshall', 'fen': MARSHALL, 'ref': 'yatesMarshall'},
        {'id': 'sarychev', 'fen': SARYCHEV, 'ref': 'drfiskeson'},
    ],
    'practice': {'fen': RETI, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
})
