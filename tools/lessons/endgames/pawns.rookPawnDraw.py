import json, chess, pathlib
OUT = pathlib.Path(__file__).with_suffix('.json')
def F(s): return s + ' - - 0 1'
def uci(fen, sans):
    b = chess.Board(fen); out = []
    for s in sans.split():
        m = b.parse_san(s); out.append(m.uci()); b.push(m)
    return out
def demo(id_, fen, sans, notes=None, side=None):
    us = uci(fen, sans); line = []
    for i, u in enumerate(us):
        e = {'uci': u}
        if notes and i in notes: e.update(notes[i])
        line.append(e)
    goal = 'win' if fen.split()[1] == 'w' and 'P' in fen.split()[0] else None
    d = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': None, 'line': line}
    if side: d['side'] = side
    return d
def move(id_, fen, goal, sans, accepts, typ='move', stars=None):
    # sans: student move, reply, student, reply, ...
    us = uci(fen, sans); turns = []
    for i in range(0, len(us), 2):
        t = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us): t['reply'] = us[i + 1]
        turns.append(t)
    return {'type': typ, 'id': id_, 'fen': fen, 'goal': goal, 'turns': turns}

KEYS = F('4k3/7K/8/8/8/8/7P/8 w'); KEYSB = F('4k3/7K/8/8/8/8/7P/8 b')
LOCK = F('7K/4k3/8/7P/8/8/8/8 b')
PANNO = F('8/1k6/8/8/8/7K/7P/8 w'); PANNOB = F('8/1k6/8/8/8/7K/7P/8 b')
SHOULDER = F('8/7K/8/8/4k3/7P/8/8 w'); EXC = F('5k2/8/6KP/8/8/8/8/8 w')
BARCZA = F('8/8/8/p7/k7/4K3/8/8 w'); FINISH = F('8/8/8/1k6/8/5K2/7P/8 b')

d_keys = demo('d_keys', KEYS, 'Kg7 Ke7 h4 Ke6 h5 Kf5 h6 Kg5 h7', {0: {'marks': ['g7', 'g8']}, 8: {'marks': ['h8']}}); d_keys['goal'] = 'win'
d_lock = demo('d_lock', LOCK, 'Kf7 h6 Kf8 h7 Kf7', {0: {'marks': ['g7', 'g8']}}); d_lock['goal'] = 'draw'
d_panno = demo('d_panno', PANNO, 'Kg4 Kc7 Kg5 Kd7 Kg6 Ke7 Kg7 Ke6 h4 Kf5 h5', {0: {'arrows': ['g4g7', 'c7f8']}, 6: {'marks': ['g7']}}); d_panno['goal'] = 'win'
d_sh = demo('d_shoulder', SHOULDER, 'Kg6 Ke5 h4 Ke6 h5 Ke7 Kg7', {0: {'marks': ['f5', 'f6', 'f7']}, 6: {'marks': ['g7']}}); d_sh['goal'] = 'win'

src = {
 'id': 'pawns.rookPawnDraw', 'module': 'pawns', 'skills': ['pawns.rookPawnDraw'],
 'parts': [
  {'id': 'keySquares', 'steps': [
    {'type': 'think', 'id': 't_keys', 'fen': KEYS, 'minutes': 5, 'hints': 2, 'ask': 'plan', 'arrows': ['e8f8'], 'marks': ['g7', 'g8']},
    {'type': 'talk', 'id': 'keys', 'fen': KEYS, 'marks': ['g7', 'g8'], 'arrows': ['h7g7']},
    {'type': 'talk', 'id': 'keysLock', 'fen': KEYSB, 'side': 'white', 'marks': ['f7', 'f8'], 'arrows': ['e8f7']},
    d_keys,
    move('keysMove', F('3k4/8/4K3/8/8/8/7P/8 w'), 'win', 'Kf7 Kd7 h4 Kd6 h5 Ke5 h6', ['win'] * 4),
  ]},
  {'id': 'lock', 'steps': [
    {'type': 'think', 'id': 't_lock', 'fen': LOCK, 'minutes': 5, 'hints': 2, 'ask': 'plan'},
    {'type': 'talk', 'id': 'lock', 'fen': LOCK, 'marks': ['g7', 'g8'], 'arrows': ['e7f7']},
    d_lock,
    move('lockMove', F('7K/8/8/4k3/7P/8/8/8 b'), 'draw', 'Kf6 Kh7 Kf7 h5 Kf8', ['hold'] * 3),
  ]},
  {'id': 'race', 'steps': [
    {'type': 'think', 'id': 't_panno', 'fen': PANNO, 'minutes': 5, 'hints': 2, 'ask': 'plan'},
    {'type': 'talk', 'id': 'panno', 'fen': PANNO, 'marks': ['g7', 'g8', 'f8'], 'arrows': ['h3g4', 'b7c7']},
    d_panno,
    {'type': 'talk', 'id': 'najdorf', 'fen': PANNOB, 'side': 'black', 'marks': ['f8'], 'arrows': ['b7c7']},
    move('pannoDraw', PANNOB, 'draw', 'Kc7 Kg4 Kd7 Kg5 Ke7 Kg6 Kf8', ['hold'] * 4),
  ]},
  {'id': 'kingFirst', 'steps': [
    {'type': 'think', 'id': 't_shoulder', 'fen': SHOULDER, 'minutes': 3, 'hints': 2, 'ask': 'plan'},
    {'type': 'talk', 'id': 'shoulder', 'fen': SHOULDER, 'marks': ['f5', 'f6'], 'arrows': ['h7g6']},
    d_sh,
    {'type': 'talk', 'id': 'exception', 'fen': EXC, 'marks': ['g7'], 'arrows': ['h6h7']},
    move('exceptionMove', EXC, 'win', 'h7 Ke7 h8=Q', ['win', 'win']),
  ]},
  {'id': 'summary', 'steps': [
    {'type': 'talk', 'id': 'barcza', 'fen': BARCZA, 'marks': ['c1', 'b1'], 'arrows': ['e3c1']},
    move('barczaMove', BARCZA, 'draw', 'Kd2 Kb3 Kc1 a4 Kb1', ['hold'] * 3),
    {'type': 'talk', 'id': 'recap', 'fen': PANNOB, 'side': 'black', 'marks': ['g7', 'g8', 'f8']},
    {'type': 'play', 'id': 'finish', 'fen': FINISH, 'goal': 'draw'},
  ]},
 ],
 'exercises': [],
 'passScore': 11,
 'keyPositions': [
   {'id': 'keys', 'fen': KEYS, 'ref': 'audax'},
   {'id': 'lock', 'fen': LOCK},
   {'id': 'pannoNajdorf', 'fen': PANNO, 'ref': 'pannoNajdorf'},
   {'id': 'shoulder', 'fen': SHOULDER, 'ref': 'audax'},
   {'id': 'exception', 'fen': EXC, 'ref': 'wikiKpk'},
   {'id': 'barczaFischer', 'fen': BARCZA, 'ref': 'barczaFischer'},
 ],
 'practice': {'fen': PANNOB, 'goal': 'draw', 'positionId': None},
 'references': [
   {'id': 'audax', 'kind': 'study', 'author': 'Audax6', 'title': "E-09 King and Rook's Pawn vs King - Always the same old two key squares", 'url': 'https://lichess.org/study/0lyQgQe7'},
   {'id': 'jonz', 'kind': 'study', 'author': 'coachJonZ', 'title': 'rook-pawn-draw', 'url': 'https://lichess.org/study/u7je0sry'},
   {'id': 'wikiKpk', 'kind': 'web', 'title': 'Wikipedia: King and pawn versus king endgame', 'url': 'https://en.wikipedia.org/wiki/King_and_pawn_versus_king_endgame'},
   {'id': 'pannoNajdorf', 'kind': 'game', 'white': 'Oscar Panno', 'black': 'Miguel Najdorf', 'event': 'Seniors-Juniors, Buenos Aires', 'year': 1968},
   {'id': 'barczaFischer', 'kind': 'game', 'white': 'Gedeon Barcza', 'black': 'Bobby Fischer', 'event': 'Zurique', 'year': 1959},
   {'id': 'dfgordon', 'kind': 'study', 'author': 'dfgordon', 'title': 'The Rook Pawn', 'url': 'https://lichess.org/study/W02TqSN3'},
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
