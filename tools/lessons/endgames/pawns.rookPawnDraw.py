import json, chess, pathlib
OUT = pathlib.Path(__file__).with_suffix('.json')
def F(s): return s + ' - - 0 1'
def uci(fen, sans):
    b = chess.Board(fen); out = []
    for s in sans.split():
        m = b.parse_san(s); out.append(m.uci()); b.push(m)
    return out
def demo(id_, fen, goal, sans, notes=None, side=None, ref=None):
    us = uci(fen, sans); line = []
    for i, u in enumerate(us):
        e = {'uci': u}
        if notes and i in notes: e.update(notes[i])
        line.append(e)
    d = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': goal, 'line': line}
    if side: d['side'] = side
    if ref: d['ref'] = ref
    return d
def move(id_, fen, goal, sans, accepts, typ='move', side=None, ref=None):
    # sans: student move, reply, student, reply, ...
    us = uci(fen, sans); turns = []
    for i in range(0, len(us), 2):
        t = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us): t['reply'] = us[i + 1]
        turns.append(t)
    d = {'type': typ, 'id': id_, 'fen': fen, 'goal': goal, 'turns': turns}
    if side: d['side'] = side
    if ref: d['ref'] = ref
    return d
def think(id_, fen, hints, **kw):
    return {'type': 'think', 'id': id_, 'fen': fen, 'hints': hints, 'ask': 'plan', **kw}
def talk(id_, fen, **kw):
    return {'type': 'talk', 'id': id_, 'fen': fen, **kw}

KEYS = F('4k3/7K/8/8/8/8/7P/8 w'); KEYSB = F('4k3/7K/8/8/8/8/7P/8 b')
LOCK = F('7K/4k3/8/7P/8/8/8/8 b')
PANNO = F('8/1k6/8/8/8/7K/7P/8 w'); PANNOB = F('8/1k6/8/8/8/7K/7P/8 b')
SHOULDER = F('8/7K/8/8/4k3/7P/8/8 w'); EXC = F('5k2/8/6KP/8/8/8/8/8 w')
BEHIND = F('8/8/p7/P7/4K3/8/8/3k4 b'); BEHIND_ERR = F('8/8/p7/P7/4K3/8/3k4/8 w')
DECOY = F('8/6Kp/2k5/8/8/7P/8/8 b'); DECOY_ERR = F('8/6Kp/3k4/8/8/7P/8/8 w')
WHICH = F('8/8/3k4/6K1/7p/8/6P1/8 b')
SPARE = F('7k/2p4P/6K1/1P6/8/8/8/8 b')
BARCZA = F('8/8/8/p7/k7/4K3/8/8 w'); CONTRAST = F('8/8/8/8/p7/k7/3K4/8 b')
FINISH = F('8/8/8/4K2p/7P/8/5k2/8 w'); PRACTICE = F('8/8/8/1k6/8/5K2/7P/8 b')

PANNO_URL = ('https://lichess.org/analysis/pgn/d4_Nf6_c4_e6_Nc3_Bb4_e3_c5_Bd3_d5_Nf3_O-O_O-O_Nbd7_a3_Ba5_Qe2_a6_Rd1_dxc4_Bxc4_b5_Ba2_Bb7_Bd2_Bb6_Be1_Qb8_Rac1_Qa7_dxc5_Nxc5_Nd4_Rad8_b4_Ncd7_a4_Qa8_Nf3_bxa4_Nxa4_Ba7_Bc4_Ng4_Bxa6_Bxa6_Qxa6_Nxe3_Rd3_Ne5_Nb6_Nxf3+_gxf3_Qb8_fxe3_Rxd3_Qxd3_Qxb6_Kf2_Rd8_Qc3_h6_Qc5_Qa6_Qa5_Qxa5_bxa5_Rd3_Rc3_Rd7_Ke2_f5_Rc6_Kf7_Bb4_g5_a6_h5_Bc5_Bxc5_Rxc5_Ra7_Ra5_g4_Kf2_h4_e4_Kg6_exf5+_exf5_Ke3_Kg5_fxg4_Kxg4_Ra2_Re7+_Kf2_Ra7_Ra3_Kf4_Ra4+_Ke5_Kf3_Kd5_Kf4_Kc5_Kxf5_Kb5_Ra2_h3_Kg4_Rxa6_Rxa6_Kxa6_Kxh3_Kb7_Kg4_Kc7_Kg5#116')
BARCZA_URL = ('https://lichess.org/analysis/pgn/Nf3_Nf6_g3_g6_b3_Bg7_Bb2_O-O_Bg2_d6_d4_e5_dxe5_Nfd7_O-O_Nc6_c4_dxe5_Ne1_Nd4_Nc3_c6_Nd3_f5_e3_Ne6_Na4_Qe7_Qc1_Re8_f3_h5_Qe1_Ng5_f4_e4_Bxg7_Qxg7_Ndc5_Nxc5_Nxc5_Nf7_Rd1_b6_Na4_Be6_Qc3_Rad8_Qc2_g5_Rf2_h4_Rxd8_Rxd8_Qb2_Qg6_Bf1_gxf4_exf4_Nh6_Rg2_Kf7_gxh4_Qf6_Qxf6+_Kxf6_Be2_Bf7_Nb2_Rd4_h3_Ng8_Kf1_Ne7_h5_Rd2_Bd1_Rd8_Ke1_c5_Rd2_Rd4_a3_Nc6_Rg2_Nd8_Kf2_Ne6_Ke3_Rd8_Rg3_Rh8_Na4_Bxh5_Bxh5_Rxh5_Nc3_Nxf4_Nxe4+_fxe4_Kxf4_Rh4+_Ke3_Kf5_b4_a5_bxc5_bxc5_a4_Rh7_Kf2_Rb7_h4_Kf4_Rh3_Kg4_Rh1_Kf4_Rh3_Ke5_h5_Kd4_h6_Rh7_Rh1_Kd3_Rh5_e3+_Ke1_Rb7_Rd5+_Kxc4_Rh5_Rh7_Ke2_Kb4_Rh4+_c4_Kxe3_Kb3_Kd2_c3+_Kc1_Rf7_Rd4_Rf6_Rd8_Rf1+_Rd1_Rxd1+_Kxd1_Kb2_h7_c2+_Ke2_c1=Q_h8=Q+_Kb3_Qe8_Qc4+_Kd2_Qd5+_Ke2_Kc2_Qc8+_Kb2_Qb8+_Kc3_Qc8+_Kd4_Qh8+_Kc4_Qc8+_Kb4_Qe8_Qc4+_Kd2_Qd4+_Ke2_Qb2+_Kd3_Qc3+_Ke2_Qc2+_Ke3_Ka3_Qb5_Qxa4_Qxa4+_Kxa4#190')
PN = 'pannoNajdorf#116'; BF = 'barczaFischer#190'

src = {
 'id': 'pawns.rookPawnDraw', 'module': 'pawns', 'skills': ['pawns.rookPawnDraw'],
 'parts': [
  {'id': 'keySquares', 'steps': [
    think('t_keys', KEYS, 2, ref='audaxKeys', arrows=['e8f8']),
    talk('keys', KEYS, ref='audaxKeys', marks=['g7', 'g8'], arrows=['h7g7']),
    demo('d_keys', KEYS, 'win', 'Kg7 Ke7 h4 Ke6 h5 Kf5 h6',
         {0: {'marks': ['g7', 'g8']}, 5: {'arrows': ['f5g5']}, 6: {'marks': ['h6']}}),
    talk('lock', KEYSB, side='white', marks=['f7', 'f8'], arrows=['e8f7']),
    demo('d_lock', LOCK, 'draw', 'Kf7 h6 Kf8 h7 Kf7', {0: {'marks': ['g7', 'g8']}}),
    move('lockMove', F('7K/8/8/4k3/7P/8/8/8 b'), 'draw', 'Kf6 Kh7 Kf7 h5 Kf8', ['hold'] * 3),
  ]},
  {'id': 'race', 'steps': [
    think('t_panno', PANNO, 2, ref=PN),
    talk('panno', PANNO, ref=PN, marks=['g7', 'f8'], arrows=['h3g4', 'g4g7', 'b7e7', 'e7f8']),
    demo('d_panno', PANNO, 'win', 'Kg4 Kc7 Kg5 Kd7 Kg6 Ke7 Kg7',
         {0: {'arrows': ['g4g7']}, 1: {'arrows': ['c7e7', 'e7f8']}, 6: {'marks': ['g7']}}, ref=PN),
    move('pannoDraw', PANNOB, 'draw', 'Kc7 Kg4 Kd7 Kg5 Ke7 Kg6 Kf8', ['hold'] * 4),
  ]},
  {'id': 'kingFirst', 'steps': [
    think('t_shoulder', SHOULDER, 2, ref='audaxShoulder'),
    talk('shoulder', SHOULDER, ref='audaxShoulder', marks=['f5', 'f6', 'f7'], arrows=['h7g6']),
    demo('d_shoulder', SHOULDER, 'win', 'Kg6 Ke5 h4 Ke6 h5',
         {0: {'marks': ['f5', 'f6', 'f7']}, 3: {'marks': ['e7', 'f8']}}, ref='audaxShoulder'),
    move('keysMove', F('3k4/8/4K3/8/8/8/7P/8 w'), 'win', 'Kf7 Kd7 h4 Kd6 h5 Ke5 h6', ['win'] * 4,
         ref='audaxKeysMove'),
  ]},
  {'id': 'behind', 'steps': [
    think('t_behind', BEHIND, 3, side='black'),
    talk('behind', BEHIND, side='black', marks=['c6', 'c7'],
         arrows=['d1e2', 'e2e3', 'e3d4', 'd4d5', 'd5c6']),
    talk('behindErr', BEHIND_ERR, side='black', marks=['c3', 'd3', 'e3'], arrows=['e4d4']),
    demo('d_behind', BEHIND, 'draw', 'Ke2 Kd5 Ke3 Kc6 Kd4 Kb6 Kd5',
         {0: {'arrows': ['d1e2']}, 6: {'marks': ['c6']}}),
    move('behindMove', F('8/8/8/p7/P7/3K4/8/4k3 b'), 'draw', 'Kf2 Kc4 Ke3 Kb5 Kd4 Kxa5 Kc5', ['hold'] * 4),
  ]},
  {'id': 'decoy', 'steps': [
    think('t_decoy', DECOY, 3, side='black'),
    talk('decoy', DECOY, side='black', marks=['h5', 'f8'], arrows=['h7h5', 'c6d6', 'd6f8']),
    talk('decoyErr', DECOY_ERR, side='black', marks=['g7'], arrows=['g7h7', 'd6e7']),
    demo('d_decoy', DECOY, 'draw', 'h5 Kg6 Kd6 Kxh5 Ke7', {0: {'arrows': ['h7h5']}, 4: {'marks': ['f8']}}),
    move('decoyMove', F('8/6K1/7p/2k5/8/7P/8/8 b'), 'draw', 'h5 Kg6 Kd6 Kxh5 Ke7 Kg6 Kf8', ['hold'] * 4),
  ]},
  {'id': 'whichPawn', 'steps': [
    think('t_which', WHICH, 3, ref='dfgordonWhich'),
    talk('which', WHICH, ref='dfgordonWhich', marks=['h3', 'f8'], arrows=['h4h3']),
    demo('d_which', WHICH, 'draw', 'h3 gxh3 Ke7 Kg6 Kf8', {4: {'marks': ['f8']}}, ref='dfgordonWhich'),
    move('whichMove', F('8/8/6k1/7p/6PP/6K1/8/8 w'), 'win', 'g5 Kf5 Kf3 Kg6 Kf4 Kh7 Kf5', ['win'] * 4),
  ]},
  {'id': 'theTurn', 'steps': [
    think('t_exception', EXC, 2, ref='dfgordonException'),
    talk('exception', EXC, ref='dfgordonException', marks=['g7', 'g8'], arrows=['h6h7']),
    demo('d_spare', SPARE, 'win', 'c5 b6 c4 b7', {3: {'marks': ['h8', 'b8']}}, side='white'),
    move('spareMove', F('7k/7P/2p3K1/1P6/8/8/8/8 w'), 'win', 'b6 c5 b7 c4 b8=Q#', ['win'] * 3),
  ]},
  {'id': 'summary', 'steps': [
    talk('barcza', BARCZA, ref=BF, marks=['c1', 'b1'], arrows=['e3c1']),
    talk('barczaErr', BARCZA, ref=BF, marks=['b2', 'c1'], arrows=['e3d3', 'a4b3']),
    move('barczaMove', BARCZA, 'draw', 'Kd2 Kb3 Kc1 a4 Kb1', ['hold'] * 3, ref=BF),
    move('contrastMove', CONTRAST, 'win', 'Kb2 Kd1 a3 Kd2 a2 Kd3 a1=Q', ['win'] * 4, side='black'),
    talk('recap', KEYS, marks=['g7', 'g8', 'f8']),
    {'type': 'play', 'id': 'finish', 'fen': FINISH, 'goal': 'win', 'ref': 'dfgordonFinish'},
  ]},
 ],
 'exercises': [],
 'passScore': 11,
 'keyPositions': [
   {'id': 'keys', 'fen': KEYS, 'ref': 'audaxKeys'},
   {'id': 'lock', 'fen': LOCK},
   {'id': 'pannoNajdorf', 'fen': PANNO, 'ref': PN},
   {'id': 'shoulder', 'fen': SHOULDER, 'ref': 'audaxShoulder'},
   {'id': 'behind', 'fen': BEHIND},
   {'id': 'decoy', 'fen': DECOY},
   {'id': 'whichPawn', 'fen': WHICH, 'ref': 'dfgordonWhich'},
   {'id': 'exception', 'fen': EXC, 'ref': 'dfgordonException'},
   {'id': 'barczaFischer', 'fen': BARCZA, 'ref': BF},
 ],
 'practice': {'fen': PRACTICE, 'goal': 'draw', 'positionId': None},
 'references': [
   {'id': 'audax', 'kind': 'study', 'author': 'Audax6', 'title': "E-09 King and Rook's Pawn vs King - Always the same old two key squares", 'url': 'https://lichess.org/study/0lyQgQe7'},
   {'id': 'audaxKeys', 'kind': 'study', 'author': 'Audax6', 'title': "E-09 King and Rook's Pawn vs King: the two key squares", 'url': 'https://lichess.org/study/0lyQgQe7/2lwnV12d'},
   {'id': 'audaxKeysMove', 'kind': 'study', 'author': 'Audax6', 'title': "E-09 King and Rook's Pawn vs King: keeping the king out", 'url': 'https://lichess.org/study/0lyQgQe7/2qswyb1D'},
   {'id': 'audaxShoulder', 'kind': 'study', 'author': 'Audax6', 'title': "E-09 King and Rook's Pawn vs King: king first", 'url': 'https://lichess.org/study/0lyQgQe7/3XWgfUrA'},
   {'id': 'jonz', 'kind': 'study', 'author': 'coachJonZ', 'title': 'rook-pawn-draw', 'url': 'https://lichess.org/study/u7je0sry'},
   {'id': 'wikiKpk', 'kind': 'web', 'title': 'Wikipedia: King and pawn versus king endgame', 'url': 'https://en.wikipedia.org/wiki/King_and_pawn_versus_king_endgame'},
   {'id': 'pannoNajdorf', 'kind': 'game', 'white': 'Oscar Panno', 'black': 'Miguel Najdorf', 'event': 'Seniors-Juniors, Buenos Aires', 'year': 1968, 'url': PANNO_URL},
   {'id': 'pgnPanno', 'kind': 'web', 'title': 'PGN Mentor, partidas de Oscar Panno', 'url': 'https://www.pgnmentor.com/players/Panno.zip'},
   {'id': 'barczaFischer', 'kind': 'game', 'white': 'Gedeon Barcza', 'black': 'Bobby Fischer', 'event': 'Zurique', 'year': 1959, 'url': BARCZA_URL},
   {'id': 'pgnFischer', 'kind': 'web', 'title': 'PGN Mentor, partidas de Bobby Fischer', 'url': 'https://www.pgnmentor.com/players/Fischer.zip'},
   {'id': 'dfgordon', 'kind': 'study', 'author': 'dfgordon', 'title': 'The Rook Pawn', 'url': 'https://lichess.org/study/W02TqSN3'},
   {'id': 'dfgordonWhich', 'kind': 'study', 'author': 'dfgordon', 'title': 'The Rook Pawn: which pawn is left', 'url': 'https://lichess.org/study/W02TqSN3/Cc0Kgecf'},
   {'id': 'dfgordonException', 'kind': 'study', 'author': 'dfgordon', 'title': 'The Rook Pawn: the exception', 'url': 'https://lichess.org/study/W02TqSN3/aRQVeX9v'},
   {'id': 'dfgordonFinish', 'kind': 'study', 'author': 'dfgordon', 'title': 'The Rook Pawn: shutting the king out', 'url': 'https://lichess.org/study/W02TqSN3/HSBgqWLc'},
   {'id': 'kingof64', 'kind': 'study', 'author': 'Kingof64-Squares', 'title': 'Rook pawn', 'url': 'https://lichess.org/study/uXPBvt6C'},
   {'id': 'moravec', 'kind': 'study', 'author': 'sashaslamp', 'title': 'Moravec, Československý šach, 1952', 'url': 'https://lichess.org/study/L6v2z9bo'},
   {'id': 'grigoriev', 'kind': 'study', 'author': 'humoresque', 'title': 'Grigoriev, Nikolai', 'url': 'https://lichess.org/study/0iaDBwxT'},
   {'id': 'tablebase', 'kind': 'tablebase', 'title': 'Lichess tablebase (Syzygy)', 'url': 'https://tablebase.lichess.ovh'},
 ],
}
EX = [
 ('e10', 1, '8/8/8/8/8/8/1k5P/6K1 b', 'draw', 'jonz', 'Kc3 h4 Kd4 Kg2 Ke5', ['hold'] * 3),
 ('e12', 2, '8/5K1p/8/8/1k5P/8/8/8 b', 'draw', 'dfgordon', 'Kc5 Kg7 h5 Kg6 Kd6 Kxh5 Ke7 Kg6 Kf8', ['hold'] * 5),
 ('e13', 2, '8/7k/6p1/6K1/5P1P/8/8/8 w', 'win', 'kingof64', 'h5 gxh5 Kxh5 Kg7 Kg5 Kf7 Kf5', ['win'] * 4),
 ('e15', 3, '2k5/8/8/7p/8/8/6P1/5K2 w', 'win', 'moravec', 'Kf2 h4 Kg1 h3 g3 Kd7 Kh2', ['win'] * 4),
 ('e14', 3, '8/p7/P7/4K3/8/4k3/8/8 b', 'draw', 'dfgordon', 'Kf3 Kd6 Kf4 Kc7 Ke5 Kb7 Kd6 Kxa7 Kc7', ['hold'] * 5),
 ('e16', 3, '8/3K4/7p/p7/5k2/P6P/8/8 w', 'draw', 'grigoriev', 'a4 Kg3 Ke6 Kxh3 Kf5 h5 Kf4 h4 Kf3 Kh2 Kf2 h3 Kf1', ['hold'] * 7),
 ('e17', 3, '4k3/2p5/1p1p4/1P1K4/8/8/7P/8 w', 'win', 'grigoriev', 'Ke6 Kf8 Kf6 Kg8 Kg6 Kf8 h3 Kg8 h4 Kf8 h5 Kg8 h6 Kh8 h7 d5 Kf5', ['win'] * 9),
]
for id_, st, fen, goal, origin, sans, acc in EX:
    m = move(id_, F(fen), goal, sans, acc)
    src['exercises'].append({'id': id_, 'stars': st, 'fen': F(fen), 'goal': goal, 'origin': origin, 'turns': m['turns']})
json.dump(src, open(OUT, 'w'), ensure_ascii=False, indent=2); open(OUT, 'a').write('\n')
print(sum(e['stars'] for e in src['exercises']))
