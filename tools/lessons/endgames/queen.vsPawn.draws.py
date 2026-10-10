"""Gera a fonte da aula queen.vsPawn.draws (dama contra peão de torre e de
bispo na sétima). Os lances vão em SAN e viram UCI aqui; a tabela confere tudo
no build_aula.py. Uso: tools/.cache/venv/bin/python <este arquivo>

Lição refeita na T61 (2026-10-10), pelo plano em docs/aulas/LICAO-queen.vsPawn.draws.md."""
import json
import pathlib

import chess

OUT = pathlib.Path(__file__).with_suffix('.json')


def F(s, n=1, half=0):
    return f'{s} - - {half} {n}'


def uci(fen, sans):
    b = chess.Board(fen)
    out = []
    for s in sans.split():
        m = b.parse_san(s)
        out.append(m.uci())
        b.push(m)
    return out


def demo(id_, fen, goal, sans, notes=None, **kw):
    line = []
    for i, u in enumerate(uci(fen, sans)):
        e = {'uci': u}
        if notes and i in notes:
            e.update(notes[i])
        line.append(e)
    d = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': goal, 'line': line}
    d.update(kw)
    return d


def move(id_, fen, goal, sans, accepts, typ='move', **kw):
    """sans: lance do aluno, resposta, lance do aluno, resposta..."""
    us = uci(fen, sans)
    turns = []
    for i in range(0, len(us), 2):
        t = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us):
            t['reply'] = us[i + 1]
        turns.append(t)
    d = {'type': typ, 'id': id_, 'fen': fen, 'goal': goal, 'turns': turns}
    d.update(kw)
    return d


def think(id_, fen, hints, **kw):
    # Sem 'minutes': o think não tem mais limite de tempo (T60).
    d = {'type': 'think', 'id': id_, 'fen': fen, 'hints': hints,
         'ask': 'plan'}
    d.update(kw)
    return d


def talk(id_, fen, **kw):
    d = {'type': 'talk', 'id': id_, 'fen': fen}
    d.update(kw)
    return d


def game_url(movetext, ply):
    b = chess.Board()
    sans = []
    for s in movetext.split():
        s = s.split('.')[-1]  # tira o número do lance ("12.Nxe5")
        m = b.parse_san(s)
        sans.append(b.san(m))
        b.push(m)
    return 'https://lichess.org/analysis/pgn/' + '_'.join(sans) + f'#{ply}'


# Lances das partidas, do PGN do chessgames.com (os links que a Wikipedia dá).
PETROSIAN_FISCHER = """1.c4 Nf6 2.Nc3 g6 3.g3 Bg7 4.Bg2 O-O 5.Nf3 d6 6.O-O Nc6 7.d3 Nh5
8.d4 e5 9.d5 Ne7 10.e4 f5 11.exf5 gxf5 12.Nxe5 Nxg3 13.hxg3 Bxe5 14.f4 Bg7
15.Be3 Bd7 16.Bd4 Ng6 17.Re1 Rf7 18.Bf3 Qf8 19.Kf2 Re8 20.Rxe8 Qxe8 21.Bxg7
Rxg7 22.Qd4 b6 23.Rh1 a5 24.Nd1 Qf8 25.Ne3 Rf7 26.b3 Qg7 27.Qxg7+ Kxg7 28.a3
Rf8 29.Be2 Ne7 30.Bd3 h6 31.Rh5 Be8 32.Rh2 Bd7 33.Rh1 Rh8 34.Nc2 Kf6 35.Nd4
Kg7 36.Be2 Ng8 37.b4 Nf6 38.Bd3 axb4 39.axb4 Kg6 40.Ra1 Ng4+ 41.Ke2 Re8+
42.Kd2 Nf6 43.Ra6 Rb8 44.Ra7 Rc8 45.c5 bxc5 46.bxc5 dxc5 47.Nf3 Kf7 48.Ne5+
Ke7 49.Nxd7 Nxd7 50.Bxf5 Rf8 51.g4 Kd6 52.Bxd7 Kxd7 53.Ke3 Re8+ 54.Kf3 Kd6
55.Ra6+ Kxd5 56.Rxh6 c4 57.Rh1 c3 58.g5 c5 59.Rd1+ Kc4 60.g6 c2 61.Rc1 Kd3
62.f5 Rg8 63.Kf4 Kd2 64.Rxc2+ Kxc2 65.Kg5 c4 66.f6 c3 67.f7"""
VAN_WELY_LEKO = """1.d4 Nf6 2.Nf3 g6 3.Bg5 Bg7 4.Nbd2 O-O 5.c3 d6 6.e4 c5 7.dxc5
dxc5 8.Bc4 Nc6 9.O-O Qc7 10.Qe2 h6 11.Bh4 Nh5 12.Rfe1 Ne5 13.Nxe5 Bxe5 14.g3
Bh8 15.f4 Ng7 16.Qf3 Be6 17.Rad1 Rad8 18.Bxe6 Nxe6 19.f5 g5 20.fxe6 gxh4
21.Qg4+ Bg7 22.Qxh4 c4 23.Kg2 fxe6 24.Qg4 Rf6 25.Nf3 Rdf8 26.Nd4 h5 27.Qxh5
Rf2+ 28.Kh3 Qe5 29.Qxe5 Bxe5 30.Nxe6 R8f6 31.Rd8+ Kf7 32.Ng5+ Kg7 33.Rd7 Rh6+
34.Kg4 Bf6 35.Ne6+ Kf7 36.Nf4 Rh8 37.h4 Rg8+ 38.Kh3 Be5 39.Rd5 Bxf4 40.Rf5+
Ke6 41.Rxf4 Rxb2 42.h5 b5 43.Rg4 Rxg4 44.Kxg4 Rxa2 45.h6 Rh2 46.Kg5 Ke5
47.g4 a5 48.Rb1 Kxe4 49.Rxb5 a4 50.Ra5 Kd3 51.Kg6 a3 52.h7 e5 53.Rxe5 Rxh7
54.Kxh7 Kxc3 55.Ra5 Kb2 56.g5 a2 57.g6 a1=Q 58.Rxa1 Kxa1 59.g7 c3 60.g8=Q c2"""

# Parte 1: peão de torre, o canto afoga
ROOK = F('3Q4/1K6/8/8/8/8/pk6/8 w')            # Wikipedia (Seirawan): empate
ROOK_STALE = F('8/1K6/8/8/8/1Q6/p7/k7 w')      # o fim da tentativa
KERES = F('K7/8/8/1Q6/8/8/pk6/8 b', 3, 5)      # Keres, depois de 3.Db5+

# Parte 2: a dama na frente do peão
BLOCK = F('8/1K6/8/8/3Q4/8/p7/2k5 w', 2)       # a escada depois de 1...Rc1?
BLOCK_MOVE = F('1K6/8/8/3Q4/8/8/7p/5k2 w')     # própria

# Parte 3: peão de torre, o rei perto ganha
ROOK_ZONE = F('3Q4/8/8/3K4/8/8/pk6/8 w')       # Wikipedia: rei em d5 ganha
TONYRO_ZONE = F('8/8/8/K7/2Q5/8/p7/1k6 w')     # TonyRo, "RP - Winning Zone I"
ZONE_ROOK = ['a5', 'b5', 'c5', 'd5', 'a4', 'b4', 'c4', 'd4', 'e4', 'd3', 'e3',
             'd2', 'e2', 'd1', 'e1']

# Parte 4: peão de bispo, Petrosian-Fischer
PF = F('6r1/5P2/6P1/6K1/8/2p5/2k5/8 b', 67)    # depois de 67.f7 (ply 133)
BISHOP_STALE = F('8/8/8/8/4K3/1Q6/2p5/k7 w')
PF_HOLD = F('8/8/6K1/8/1Q6/8/2p5/1k6 b', 70, 1)  # análise: 69...c2 70.Db4+

# Parte 5: Lolli e o lado longo
BISHOP = F('3Q4/8/8/8/4K3/8/1kp5/8 w')         # Wikipedia (Seirawan): empate
ZONE_BISHOP = ['a4', 'b4', 'c4', 'd3', 'e3', 'd2', 'e2', 'e1']
LOLLI = F('8/8/8/8/6K1/6Q1/2p5/3k4 w')         # Lolli 1763 (Wikipedia)
BISHOP_NEAR = F('8/8/8/1K6/8/3Q4/2p5/2k5 w')   # posição de treino de Danghiangmanh

# Parte 6: o peão a mais
EXTRA = F('8/1K6/8/8/8/1Q5p/p7/k7 w')          # própria
EXTRA_MOVE = F('8/1K6/6p1/8/8/Q7/p7/1k6 w')    # própria

# Parte 7: o cavalo
KNIGHT = F('8/8/8/8/8/4K3/5p1Q/4k3 b')         # própria (varredura na tabela)
KNIGHT_MOVE = F('8/8/8/8/8/6K1/3Q1p2/6k1 b')   # própria (varredura do revisor)

# Parte 8: Van Wely-Leko e o resumo
LEKO = F('8/7K/6P1/R7/2p5/8/pk6/8 b', 57)      # depois de 57.g6 (ply 113)
LEKO_MOVE = F('8/6PK/8/8/2p5/8/8/k7 b', 59)    # depois de 59.g7 (ply 117)
VANWELY = F('6Q1/7K/8/8/8/8/2p5/k7 w', 61)     # depois de 60...c2 (ply 120)
FINISH = F('6Q1/8/8/8/5K2/8/1kp5/8 b')         # própria: as pretas defendem

# Só nas posições-base
TRAP410 = F('8/8/8/3K4/8/8/1kp1Q3/8 b')        # de la Villa 4.10
LONG = F('8/8/8/8/8/8/1K2kp2/Q7 w')            # MarioPB4: rei do lado longo
FISCHER = F('5Q2/8/6K1/8/8/8/2p5/1k6 w')       # Petrosian-Fischer, análise
PRACTICE = F('Q7/8/8/4K3/8/3k4/2p5/8 w')       # catálogo queen.queenVsPawn.0004

src = {
    'id': 'queen.vsPawn.draws', 'module': 'queen',
    'skills': ['queen.vsPawnDraws'],
    'parts': [
        {'id': 'rook', 'steps': [
            think('t_rook', ROOK, 2, marks=['a1', 'a2']),
            talk('rookWhy', ROOK_STALE, marks=['a1', 'b1', 'b2'],
                 arrows=['b3a2']),
            demo('d_rook', ROOK, 'draw',
                 'Qd4+ Kb1 Qb4+ Kc2 Qa3 Kb1 Qb3+ Ka1',
                 {1: {'marks': ['a1']}, 4: {'arrows': ['a3a2']},
                  7: {'marks': ['a1']}}),
            move('rookHold', KERES, 'draw',
                 'Kc2 Qa4+ Kb2 Qb4+ Kc2 Qa3 Kb1 Qb3+ Ka1',
                 ['hold'] * 5, ref='marioKeres'),
        ]},
        {'id': 'block', 'steps': [
            think('t_block', BLOCK, 2),
            talk('blockWhy', BLOCK, arrows=['d4a1'], marks=['a1', 'b1', 'b2']),
            demo('d_block', BLOCK, 'win', 'Qa1+ Kd2 Qxa2+',
                 {0: {'marks': ['a1', 'b1', 'b2']}}),
            move('blockMove', BLOCK_MOVE, 'win', 'Qh1+ Kf2 Qxh2+',
                 ['only', 'win']),
        ]},
        {'id': 'rookZone', 'steps': [
            think('t_rookZone', ROOK_ZONE, 2),
            talk('rookZoneWhy', ROOK_ZONE, marks=ZONE_ROOK + ['b3'],
                 arrows=['d5b3']),
            demo('d_rookZone', ROOK_ZONE, 'win', 'Kc4 a1=Q Qd2+ Kb1 Kb3',
                 {0: {'arrows': ['c4b3']}, 4: {'marks': ['c2', 'd1']}}),
            move('rookZoneMove', TONYRO_ZONE, 'win',
                 'Qb3+ Ka1 Qd1+ Kb2 Kb4 a1=Q Qd2+ Kb1 Kb3', ['best'] * 5,
                 ref='tonyroZone'),
        ]},
        {'id': 'bishop', 'steps': [
            think('t_bishop', PF, 2, side='black', ref='petrosianFischer'),
            talk('pfWhy', PF, side='black', ref='petrosianFischer',
                 arrows=['g8g6', 'c2b1'], marks=['c3', 'a1']),
            demo('d_fischer', PF, 'draw', 'Rxg6+ Kxg6 Kb1 f8=Q c2',
                 {2: {'marks': ['a1']}, 4: {'marks': ['c2']}},
                 side='black', ref='petrosianFischer'),
            talk('bishopWhy', BISHOP_STALE, side='black',
                 marks=['a1', 'a2', 'b1', 'b2'], arrows=['b3c2']),
            move('fischerHold', PF_HOLD, 'draw',
                 'Ka2 Qc3 Kb1 Qb3+ Ka1', ['hold'] * 3, side='black'),
        ]},
        {'id': 'bishopZone', 'steps': [
            think('t_lolli', LOLLI, 2, ref='wikipedia'),
            talk('bishopZoneWhy', BISHOP, marks=ZONE_BISHOP,
                 arrows=['e4d3', 'd3d2']),
            demo('d_lolli', LOLLI, 'win', 'Qb3 Kd2 Qb2 Kd1 Kf3 c1=Q Qe2#',
                 {0: {'marks': ['b1', 'c2']}, 4: {'arrows': ['g4f3']},
                  6: {'marks': ['e2', 'd1']}}, ref='wikipedia'),
            move('bishopZoneMove', BISHOP_NEAR, 'win',
                 'Kb4 Kb2 Qd2 Kb1 Kb3', ['best'] * 3),
        ]},
        {'id': 'extraPawn', 'steps': [
            think('t_extra', EXTRA, 2, marks=['h3']),
            talk('extraWhy', EXTRA, marks=['h3', 'a1', 'b1', 'b2']),
            demo('d_extra', EXTRA, 'win', 'Qc2 h2 Qc1#',
                 {0: {'marks': ['b1', 'b2']}}),
            move('extraMove', EXTRA_MOVE, 'win', 'Qb3+ Ka1 Qc2 g5 Qc1#',
                 ['best', 'only', 'only']),
        ]},
        {'id': 'knight', 'steps': [
            think('t_knight', KNIGHT, 2, side='black'),
            talk('knightWhy', KNIGHT, side='black', marks=['f1', 'e3', 'h2'],
                 arrows=['f1e3', 'f1h2']),
            demo('d_knight', KNIGHT, 'draw', 'f1=N+ Kf3 Nxh2+',
                 {0: {'arrows': ['f1e3', 'f1h2']}}, side='black'),
            move('knightMove', KNIGHT_MOVE, 'draw', 'f1=N+ Kf3 Nxd2+',
                 ['only', 'only'], side='black'),
        ]},
        {'id': 'leko', 'steps': [
            think('t_leko', LEKO, 2, side='black', ref='vanWelyLeko'),
            talk('lekoWhy', LEKO, side='black', ref='vanWelyLeko',
                 marks=['a1', 'c2'], arrows=['a2a1']),
            demo('d_leko', LEKO, 'draw', 'a1=Q Rxa1 Kxa1 g7',
                 {2: {'marks': ['a1']}}, side='black', ref='vanWelyLeko'),
            move('lekoMove', LEKO_MOVE, 'draw', 'c3 g8=Q c2',
                 ['only', 'only'], side='black', ref='vanWelyLeko#117'),
            talk('recap', VANWELY, side='black', ref='vanWelyLeko#120',
                 marks=['a1', 'c2', 'h7']),
            {'type': 'play', 'id': 'finish', 'fen': FINISH, 'goal': 'draw'},
        ]},
    ],
    'exercises': [],
    'passScore': 0,
    'keyPositions': [
        {'id': 'rookDraw', 'fen': ROOK, 'ref': 'wikipedia'},
        {'id': 'rookZone', 'fen': ROOK_ZONE, 'ref': 'wikipedia'},
        {'id': 'bishopDraw', 'fen': BISHOP, 'ref': 'wikipedia'},
        {'id': 'lolli', 'fen': LOLLI, 'ref': 'wikipedia'},
        {'id': 'trap', 'fen': TRAP410, 'ref': 'wikipedia'},
        {'id': 'longSide', 'fen': LONG, 'ref': 'mario'},
        {'id': 'vanWely', 'fen': VANWELY, 'ref': 'vanWelyLeko#120'},
        {'id': 'fischer', 'fen': FISCHER, 'ref': 'wikipedia'},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win',
                 'positionId': 'queen.queenVsPawn.0004'},
    'references': [
        {'id': 'delaVilla', 'kind': 'book', 'author': 'Jesús de la Villa',
         'title': '100 Endgames You Must Know (4th, improved edition)',
         'publisher': 'New In Chess', 'year': 2015,
         'where': "Endings 17 and 18, \"Queen vs. 7th-rank rook's pawn\" "
                  "(p. 60) and \"Queen vs. 7th-rank bishop's pawn\" (p. 62)"},
        {'id': 'wikipedia', 'kind': 'web',
         'title': 'Queen versus pawn endgame (Wikipedia)',
         'url': 'https://en.wikipedia.org/wiki/Queen_versus_pawn_endgame'},
        {'id': 'mario', 'kind': 'study', 'author': 'MarioPB4',
         'title': 'Queen vs. Promoting Pawn',
         'url': 'https://lichess.org/study/o2EZohXS'},
        {'id': 'marioKeres', 'kind': 'study', 'author': 'MarioPB4',
         'title': 'Queen vs. Promoting Pawn: Keres RP Draw',
         'url': 'https://lichess.org/study/o2EZohXS/UyKFIsEC'},
        {'id': 'dang', 'kind': 'study', 'author': 'Danghiangmanh',
         'title': 'Queen vs Pawn',
         'url': 'https://lichess.org/study/4JKLMbtH'},
        {'id': 'tonyro', 'kind': 'study', 'author': 'TonyRo',
         'title': 'Queen vs. Rook or Bishop Pawns',
         'url': 'https://lichess.org/study/kkoVo7Fy'},
        {'id': 'tonyroZone', 'kind': 'study', 'author': 'TonyRo',
         'title': 'Queen vs. Rook or Bishop Pawns: RP - Winning Zone I',
         'url': 'https://lichess.org/study/kkoVo7Fy/6ZJ9vRuK'},
        {'id': 'petrosianFischer', 'kind': 'game',
         'white': 'Tigran Petrosian', 'black': 'Bobby Fischer',
         'event': 'Interzonal de Portorož', 'year': 1958,
         'url': game_url(PETROSIAN_FISCHER, 133)},
        {'id': 'vanWelyLeko', 'kind': 'game',
         'white': 'Loek van Wely', 'black': 'Peter Leko',
         'event': 'Tilburg (Fontys)', 'year': 1996,
         'url': game_url(VAN_WELY_LEKO, 113)},
        {'id': 'chessgamesPF', 'kind': 'web',
         'title': 'Petrosian vs. Fischer, Portoroz Interzonal 1958 (chessgames.com)',
         'url': 'https://www.chessgames.com/perl/chessgame?gid=1008374'},
        {'id': 'chessgamesVWL', 'kind': 'web',
         'title': 'Van Wely vs. Leko, Tilburg 1996 (chessgames.com)',
         'url': 'https://www.chessgames.com/perl/chessgame?gid=1269889'},
        {'id': 'tablebase', 'kind': 'tablebase',
         'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

EX = [
    # id, estrelas, FEN, objetivo, origem, lances (aluno, resposta, ...), regras
    # T58 (2026-10-09): cortados e01, e02, e03, e05, e06, e07, e08, e09, e11
    # (repetiam passos ou posições-base da lição, ou um ao outro).
    ('e12', 1, '7K/8/Q7/8/8/6k1/5p2/8 w', 'win', 'tonyro', 'Qf1', ['win']),
    ('e04', 2, '8/6K1/8/8/8/8/1kp5/4Q3 b', 'draw', 'own',
     'c1=Q Qxc1+ Kxc1', ['hold', 'hold']),
    ('e13', 2, '8/8/8/8/8/1K1Q4/2p5/k7 b', 'draw', 'own', 'c1=N+', ['hold']),
    ('e10', 2, '6Q1/8/8/4K3/8/8/4kp2/8 w', 'win', 'wikipedia',
     'Qc4+ Ke1 Qe4+ Kf1 Kf4', ['win'] * 3),
    ('e14', 2, '2Q5/7p/8/1K6/8/8/5p2/6k1 w', 'win', 'wikipedia',
     'Qg4+ Kh2 Qf3 Kg1 Qg3+ Kh1 Qxf2', ['win'] * 4),
    ('e16', 3, '8/8/8/6K1/6Q1/2k5/p7/8 w', 'win', 'own',
     'Qe2 Kb3 Qe5 Kc2 Qa1', ['win'] * 3),
    ('e15', 3, '8/1Q6/7K/8/8/4k3/2p5/8 w', 'win', 'own',
     'Qg2 Kd3 Qg5 Kc3 Qc1', ['win'] * 3),
]
for id_, st, fen, goal, origin, sans, acc in EX:
    m = move(id_, F(fen), goal, sans, acc)
    src['exercises'].append({'id': id_, 'stars': st, 'fen': F(fen),
                             'goal': goal, 'origin': origin,
                             'turns': m['turns']})
total = sum(e['stars'] for e in src['exercises'])
src['passScore'] = -(-total * 6 // 10)
OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print('estrelas', total, 'mínimo', src['passScore'])
