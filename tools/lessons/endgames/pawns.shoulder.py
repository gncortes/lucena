"""Gera tools/lessons/endgames/pawns.shoulder.json (aula "O ombro").

Lances em SAN aqui, UCI no JSON. Depois de mudar, rode este arquivo e o
build_aula.py:
    tools/.cache/venv/bin/python tools/lessons/endgames/pawns.shoulder.py
    tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py pawns.shoulder

Lição refeita na T61 (2026-10-10) pelo plano de docs/aulas/LICAO-pawns.shoulder.md.
"""
import json
import pathlib

import chess

OUT = pathlib.Path(__file__).with_suffix('.json')


def F(s):
    return s + ' - - 0 1'


def uci(fen, sans):
    b = chess.Board(fen)
    out = []
    for s in sans.split():
        m = b.parse_san(s)
        out.append(m.uci())
        b.push(m)
    return out


def demo(id_, fen, goal, sans, notes=None, side=None, ref=None):
    line = []
    for i, u in enumerate(uci(fen, sans)):
        e = {'uci': u}
        if notes and i in notes:
            e.update(notes[i])
        line.append(e)
    d = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': goal, 'line': line}
    if side:
        d['side'] = side
    if ref:
        d['ref'] = ref
    return d


def turns(fen, sans, accepts):
    us = uci(fen, sans)
    out = []
    for i in range(0, len(us), 2):
        t = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us):
            t['reply'] = us[i + 1]
        out.append(t)
    return out


def move(id_, fen, goal, sans, accepts, side=None, ref=None):
    d = {'type': 'move', 'id': id_, 'fen': fen, 'goal': goal,
         'turns': turns(fen, sans, accepts)}
    if side:
        d['side'] = side
    if ref:
        d['ref'] = ref
    return d


def think(id_, fen, hints, ref=None, **extra):
    d = {'type': 'think', 'id': id_, 'fen': fen, 'hints': hints, 'ask': 'plan'}
    if ref:
        d['ref'] = ref
    d.update(extra)
    return d


def talk(id_, fen, ref=None, **extra):
    d = {'type': 'talk', 'id': id_, 'fen': fen}
    if ref:
        d['ref'] = ref
    d.update(extra)
    return d


# Posições-base (todas conferidas na tabela do Lichess; ver docs/aulas/pawns.shoulder.md).
STAIRS = F('8/8/8/1k6/8/8/K4P2/8 w')       # sibi.m, cap. 6: só Kb3
STAIRS_B = F('8/8/8/1k6/8/8/K4P2/8 b')     # pretas na vez: empate
STAIRS_G = F('8/8/8/1k6/8/8/K5P1/8 w')     # a mesma com peão de g: só Kb3
WALL = F('8/5p2/8/8/1k2K3/8/5P2/8 w')      # TLQ2JepT, cap. 3: só Kd4
ACROSS = F('8/5K2/p6k/8/8/8/1P6/8 w')      # TLQ2JepT, cap. 4: só Kf6
CORNER = F('k7/1p6/2K5/8/8/8/4P3/8 w')     # própria: só Kc7
# Schlage–Ahues, Berlim 1921 (Wikipedia, "Willi Schlage"). Sem PGN completo em fonte
# aberta: cada passo aponta a análise pelo FEN da sua posição (schlageAhues2/3) e a
# numeração é a dos livros (1.Ke6 Kc3 2.Kd6?).
SCHLAGE0 = F('8/p4K2/P7/8/8/8/1k6/8 w')            # a posição dos livros: só Ke6
SCHLAGE2 = '8/p7/P3K3/8/8/2k5/8/8 w - - 2 2'      # depois de 1.Ke6 Kc3: só Kd5
SCHLAGE3 = '8/p7/P2K4/8/8/2k5/8/8 b - - 3 2'      # depois de 2.Kd6?: empate
AWAY = F('8/5p2/8/8/5K2/5P2/8/7k w')       # TLQ2JepT, cap. 2: só Kg3
LATER = F('8/1p6/8/5k2/3K4/8/1P6/8 w')     # dwktCh2L, cap. 2 (Mandler-lite): só Kd5
SQUARE = F('8/8/6p1/1k6/4K3/8/5P2/8 w')    # 8iCXe3Nj, cap. 5 (Duras-lite): só Kd4
RACE = F('8/8/5p2/4kP2/K7/8/P7/8 w')       # TLQ2JepT, cap. 1: só Kb5
DEFEND = F('8/5p2/1p6/1P2K2k/8/8/8/8 w')   # Grigoriev 1925 (0iaDBwxT); 1tpnHFlG, cap. 7: só Kf5 empata
DEFEND_B = F('8/5p2/1p3K2/1P5k/8/8/8/8 b')  # depois de 1.Kf6?: pretas ganham
FINISH = F('8/k7/5K2/8/8/8/2P5/8 w')       # catálogo pawn.pawnVsKing.0004

src = {
    'id': 'pawns.shoulder', 'module': 'pawns', 'skills': ['pawns.shoulder'],
    'parts': [
        # 1. A escada: rei na mesma coluna do outro, duas fileiras abaixo.
        {'id': 'between', 'steps': [
            think('t_stairs', STAIRS, 2, ref='sibi6',
                  marks=['c4', 'd3', 'e2'], arrows=['b5e2']),
            talk('stairs', STAIRS, ref='sibi6',
                 arrows=['a2b3', 'b5f1'], marks=['c4']),
            talk('stairsDraw', STAIRS_B, side='white',
                 arrows=['b5c4', 'c4d5', 'd5e5'], marks=['f2']),
            demo('d_stairs', STAIRS, 'win', 'Kb3 Kc5 Kc3 Kd5 Kd3 Ke5 Ke3',
                 {0: {'marks': ['c4']}, 2: {'marks': ['d4']},
                  4: {'marks': ['e4', 'e2']}, 6: {'marks': ['f4']}},
                 ref='sibi6'),
            move('stairsMove', STAIRS_G, 'win', 'Kb3 Kc5 Kc3 Kd5 Kd3 Ke5 Ke3',
                 ['win'] * 4, ref='sibi7'),
        ]},
        # 2. O muro numa coluna.
        {'id': 'wall', 'steps': [
            think('t_wall', WALL, 2, ref='drMkc3'),
            talk('wall', WALL, ref='drMkc3',
                 arrows=['e4d4', 'b4f8'], marks=['d4', 'd5', 'd6']),
            demo('d_wall', WALL, 'win', 'Kd4 Kb5 Kd5 Kb6 Kd6 Kb7 f4',
                 {0: {'marks': ['c5', 'c4', 'c3']}, 2: {'marks': ['c6']},
                  4: {'marks': ['c7']}, 6: {'arrows': ['f4f5']}},
                 ref='drMkc3'),
            move('wallMove', WALL, 'win', 'Kd4 Kb5 Kd5 Kb6 Kd6', ['win'] * 3),
        ]},
        # 3. Até a beira e o canto: uma casa fecha as saídas e o peão corre.
        {'id': 'edge', 'steps': [
            think('t_across', ACROSS, 2, ref='drMkc4'),
            talk('across', ACROSS, ref='drMkc4',
                 arrows=['f7f2', 'h6h2'], marks=['g5', 'g4', 'g3']),
            move('acrossMove', ACROSS, 'win',
                 'Kf6 Kh5 Kf5 Kh4 Kf4 Kh3 Kf3 Kh2 Kf2', ['win'] * 5),
            talk('corner', CORNER, arrows=['c6c7', 'e2e8'],
                 marks=['b8', 'b7', 'b6']),
            demo('d_corner', CORNER, 'win', 'Kc7 Ka7 e4 Ka6 e5 Kb5 e6',
                 {0: {'marks': ['b8', 'b7', 'b6']}, 2: {'arrows': ['e4e8']},
                  6: {'marks': ['e7', 'e8']}}),
            move('cornerMove', CORNER, 'win', 'Kc7 Ka7 e4', ['win'] * 2),
        ]},
        # 4. Schlage–Ahues, Berlim 1921: a caminho do peão, passe pelo caminho do outro rei.
        {'id': 'game', 'steps': [
            think('t_schlage', SCHLAGE2, 2, ref='schlageAhues2',
                  marks=['d6', 'd5'], arrows=['c3d4', 'd4c7']),
            talk('schlage', SCHLAGE2, ref='schlageAhues2',
                 arrows=['e6d5', 'c3b4'], marks=['d4']),
            demo('d_schlageDraw', SCHLAGE3, 'draw', 'Kd4 Kc6 Ke5 Kb7 Kd6',
                 {0: {'marks': ['d4']}, 4: {'arrows': ['d6c7']}},
                 side='black', ref='schlageAhues3'),
            demo('d_schlageWin', SCHLAGE2, 'win',
                 'Kd5 Kb4 Kc6 Ka5 Kb7 Kb5 Kxa7 Kc6 Kb8',
                 {0: {'marks': ['d4']}, 2: {'marks': ['b5', 'c5']},
                  8: {'arrows': ['a6a8']}},
                 ref='schlageAhues2'),
            move('schlageMove', SCHLAGE2, 'win',
                 'Kd5 Kb4 Kc6 Ka5 Kb7 Kb5 Kxa7 Kc6 Kb8', ['win'] * 5,
                 ref='schlageAhues2'),
        ]},
        # 5. O lance certo se afasta do alvo e não captura ainda.
        {'id': 'away', 'steps': [
            think('t_away', AWAY, 2, ref='drMkc2'),
            talk('away', AWAY, ref='drMkc2',
                 arrows=['f4g3', 'h1g2'], marks=['g2', 'f2']),
            demo('d_away', AWAY, 'win', 'Kg3 Kg1 f4 Kf1 f5 Ke2 Kf4',
                 {0: {'marks': ['g2', 'f2']}, 6: {'marks': ['e3', 'e4']}},
                 ref='drMkc2'),
            move('awayMove', AWAY, 'win', 'Kg3 Kg1 f4 Kf1 f5 Ke2 Kf4',
                 ['win'] * 4),
            demo('d_later', LATER, 'win', 'Kd5 Kf6 Kd6 Kf7 b4 Ke8 Kc7',
                 {0: {'marks': ['e5', 'e6']}, 2: {'marks': ['e7']},
                  4: {'arrows': ['b4b5']}, 6: {'marks': ['b7']}},
                 ref='papogustavo'),
            move('laterMove', LATER, 'win', 'Kd5 Kf6 Kd6 Kf7 b4', ['win'] * 3,
                 ref='papogustavo'),
        ]},
        # 6. O ombro e o quadrado: um lance faz duas coisas.
        {'id': 'square', 'steps': [
            think('t_square', SQUARE, 2, ref='easonh',
                  marks=['g6', 'g1', 'b1', 'b6']),
            talk('square', SQUARE, ref='easonh',
                 arrows=['e4d4', 'b5c4'], marks=['c4', 'c5']),
            demo('d_square', SQUARE, 'win', 'Kd4 Kc6 Ke5 g5 Kf5 g4 Kxg4',
                 {0: {'marks': ['c4', 'c5']}, 2: {'marks': ['d5', 'd6']},
                  4: {'marks': ['e6']}},
                 ref='easonh'),
            move('squareMove', SQUARE, 'win', 'Kd4 Kc6 Ke5 g5 Kf5', ['win'] * 3,
                 ref='easonh'),
            move('raceMove', RACE, 'win', 'Kb5 Kxf5 a4 Ke6 Kc6', ['win'] * 3,
                 ref='drMkc1'),
        ]},
        # 7. Quem defende também empurra; resumo; desafio prático.
        {'id': 'summary', 'steps': [
            talk('defend', DEFEND, ref='grigoriev',
                 arrows=['h5g4', 'g4f5', 'f5c5'], marks=['b5', 'f5']),
            demo('d_defendPunish', DEFEND_B, 'win',
                 'Kg4 Kxf7 Kf5 Ke7 Ke5 Kd7 Kd5',
                 {0: {'arrows': ['g4f5']}, 2: {'marks': ['e6', 'e5']},
                  6: {'arrows': ['d5c5', 'c5b5']}},
                 side='black', ref='grigorievKf6'),
            move('defendMove', DEFEND, 'draw', 'Kf5 Kh4 Kf4 Kh3 Kf3 Kh2 Kf2',
                 ['hold'] * 4, ref='grigoriev'),
            talk('recap', STAIRS, arrows=['a2b3', 'b3c3', 'c3d3']),
            {'type': 'play', 'id': 'finish', 'fen': FINISH, 'goal': 'win'},
        ]},
    ],
    'exercises': [],
    'passScore': 10,
    'keyPositions': [
        {'id': 'stairs', 'fen': STAIRS, 'ref': 'sibi6'},
        {'id': 'wall', 'fen': WALL, 'ref': 'drMkc3'},
        {'id': 'across', 'fen': ACROSS, 'ref': 'drMkc4'},
        {'id': 'corner', 'fen': CORNER},
        {'id': 'schlage', 'fen': SCHLAGE0, 'ref': 'schlageAhues'},
        {'id': 'away', 'fen': AWAY, 'ref': 'drMkc2'},
        {'id': 'later', 'fen': LATER, 'ref': 'papogustavo'},
        {'id': 'square', 'fen': SQUARE, 'ref': 'easonh'},
        {'id': 'race', 'fen': RACE, 'ref': 'drMkc1'},
        {'id': 'defend', 'fen': DEFEND, 'ref': 'grigoriev'},
    ],
    'practice': {'fen': FINISH, 'goal': 'win', 'positionId': 'pawn.pawnVsKing.0004'},
    'references': [
        {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
         'title': "Dvoretsky's Endgame Manual (6th edition, revised by Karsten Müller and Alex Fishbein)",
         'publisher': 'Russell Enterprises', 'year': 2025,
         'where': 'cap. 1, "Shouldering", p. 47 (índice da amostra da editora)'},
        {'id': 'schlageAhues', 'kind': 'game', 'white': 'Willi Schlage',
         'black': 'Carl Ahues', 'event': 'Berlim', 'year': 1921,
         'url': 'https://lichess.org/analysis/8/p4K2/P7/8/8/8/1k6/8_w_-_-_0_1'},
        {'id': 'schlageAhues2', 'kind': 'web',
         'title': 'Schlage – Ahues, Berlin 1921, after 1.Ke6 Kc3',
         'url': 'https://lichess.org/analysis/standard/8/p7/P3K3/8/8/2k5/8/8_w_-_-_2_2'},
        {'id': 'schlageAhues3', 'kind': 'web',
         'title': 'Schlage – Ahues, Berlin 1921, after 2.Kd6',
         'url': 'https://lichess.org/analysis/standard/8/p7/P2K4/8/8/2k5/8/8_b_-_-_3_2'},
        {'id': 'wikiSchlage', 'kind': 'web',
         'title': 'Wikipedia: Willi Schlage, "Schlage vs. Ahues, 1921"',
         'url': 'https://en.wikipedia.org/wiki/Willi_Schlage#Schlage_vs._Ahues,_1921'},
        {'id': 'drMkc1', 'kind': 'study', 'author': 'DrMkcTheHandsome',
         'title': 'Endgame Shouldering Away, part 1',
         'url': 'https://lichess.org/study/TLQ2JepT/ryQ3QbuS'},
        {'id': 'drMkc2', 'kind': 'study', 'author': 'DrMkcTheHandsome',
         'title': 'Endgame Shouldering Away, part 2',
         'url': 'https://lichess.org/study/TLQ2JepT/OIKNtD5a'},
        {'id': 'drMkc3', 'kind': 'study', 'author': 'DrMkcTheHandsome',
         'title': 'Endgame Shouldering Away, part 3',
         'url': 'https://lichess.org/study/TLQ2JepT/8sNJScuI'},
        {'id': 'drMkc4', 'kind': 'study', 'author': 'DrMkcTheHandsome',
         'title': 'Endgame Shouldering Away, part 4',
         'url': 'https://lichess.org/study/TLQ2JepT/OjJZI6or'},
        {'id': 'papogustavo', 'kind': 'study', 'author': 'papogustavo',
         'title': 'Shouldering, chapter 2', 'url': 'https://lichess.org/study/dwktCh2L/efzp93mj'},
        {'id': 'easonh', 'kind': 'study', 'author': 'EasonH',
         'title': 'shouldering, chapter 5', 'url': 'https://lichess.org/study/8iCXe3Nj/phS2u7AF'},
        {'id': 'zeeshan', 'kind': 'study', 'author': 'zeeshan30',
         'title': 'Shouldering', 'url': 'https://lichess.org/study/iA0o5q69'},
        {'id': 'manoj', 'kind': 'study', 'author': 'Manoj1988',
         'title': 'Shouldering', 'url': 'https://lichess.org/study/z4whjLOx'},
        {'id': 'poojakanth', 'kind': 'study', 'author': 'Poojakanth',
         'title': 'endgame study-shouldering', 'url': 'https://lichess.org/study/1tpnHFlG'},
        {'id': 'sibi', 'kind': 'study', 'author': 'sibi.m',
         'title': 'shouldering in the king and pawn endgame, chapter 10',
         'url': 'https://lichess.org/study/UDGX1K3Z/BEKrN8D8'},
        {'id': 'sibi6', 'kind': 'study', 'author': 'sibi.m',
         'title': 'shouldering in the king and pawn endgame, chapter 6',
         'url': 'https://lichess.org/study/UDGX1K3Z/t9zH8kes'},
        {'id': 'sibi7', 'kind': 'study', 'author': 'sibi.m',
         'title': 'shouldering in the king and pawn endgame, chapter 7',
         'url': 'https://lichess.org/study/UDGX1K3Z/RdopaHk4'},
        {'id': 'grigoriev', 'kind': 'study', 'author': 'humoresque',
         'title': 'Grigoriev, Nikolai: =0000.12e5h5',
         'url': 'https://lichess.org/study/0iaDBwxT/syVZGGwH'},
        {'id': 'grigorievKf6', 'kind': 'web',
         'title': 'Grigoriev 1925, after 1.Kf6',
         'url': 'https://lichess.org/analysis/standard/8/5p2/1p3K2/1P5k/8/8/8/8_b_-_-_0_1'},
        {'id': 'njswift', 'kind': 'study', 'author': 'njswift',
         'title': 'Pawn Races', 'url': 'https://lichess.org/study/OX3hApYw'},
        {'id': 'wikiKing', 'kind': 'web', 'title': 'Wikipedia: King (chess), "Shouldering"',
         'url': 'https://en.wikipedia.org/wiki/King_(chess)#Shouldering'},
        {'id': 'tablebase', 'kind': 'tablebase', 'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

# (id, estrelas, fen, objetivo, origem, lances do aluno e respostas, regra por vez)
EX = [
    ('e02', 1, '7k/6p1/6K1/8/8/8/4P3/8 w', 'win', 'sibi', 'Kf7 Kh7 e4', ['win'] * 2),
    ('e05', 2, '8/7k/8/6K1/p7/8/1P6/8 w', 'win', 'zeeshan', 'Kf6 Kh6 Ke5', ['win'] * 2),
    ('e08', 2, '8/1p6/8/8/8/3K4/P7/6k1 w', 'win', 'manoj', 'Ke2 Kg2 a4 Kg3 Ke3', ['win'] * 3),
    # Duras 1905, citado em njswift, "Pawn Races", cap. "Exercise #13".
    ('e11', 2, '8/6p1/7k/8/1K6/8/1P6/8 w', 'win', 'njswift', 'Kc5 Kg6 b4 Kf7 b5', ['win'] * 3),
    # Grigoriev 1932, citado em njswift, "Pawn Races", cap. "Exercise #18".
    ('e10', 3, '8/2p5/6K1/8/8/5k2/P7/8 w', 'win', 'njswift', 'Kf5 c5 Ke5 c4 Kd4', ['win'] * 3),
    # njswift, "Pawn Races", cap. "Exercise #5" (o estudo não dá o autor).
    ('e12', 3, '8/2p5/8/8/5K2/8/1k5P/8 w', 'win', 'njswift',
     'Ke4 Kb3 Kd4 Kb4 h4 c5+ Ke3', ['win'] * 4),
    # Mandler 1938, citado em njswift, "Pawn Races", cap. "King activity for the queen ending".
    ('e13', 3, '8/1pK5/8/8/8/8/k4P2/8 w', 'win', 'njswift', 'Kd6 Ka3 Kc5 Ka4 f4', ['win'] * 3),
]
for id_, st, fen, goal, origin, sans, acc in EX:
    src['exercises'].append({'id': id_, 'stars': st, 'fen': F(fen), 'goal': goal,
                             'origin': origin, 'turns': turns(F(fen), sans, acc)})

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print('estrelas:', sum(e['stars'] for e in src['exercises']))
