"""Gera a fonte da aula mates.bishopKnight.full (lances em SAN aqui, UCI no JSON).

Rodar: tools/.cache/venv/bin/python tools/lessons/endgames/mates.bishopKnight.full.py
Depois: tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py mates.bishopKnight.full

Lição refeita na T63 (2026-10-10), pelo plano docs/aulas/LICAO-mates.bishopKnight.full.md
(com os desvios registrados no dossiê). Os exercícios, o passScore e o practice não mudam.
"""
import json
from pathlib import Path

import chess

OUT = Path(__file__).with_suffix('.json')

def after(fen, sans, counters=None):
    b = chess.Board(fen)
    for s in sans.split():
        b.push_san(s)
    head = ' '.join(b.fen().split()[:4])
    return head + ' ' + (counters or '0 1')

def ucis(fen, sans):
    b = chess.Board(fen); out = []
    for s in sans.split():
        m = b.parse_san(s); out.append(m.uci()); b.push(m)
    return out

def think(id_, fen, hints, ref=None, side=None, **kw):
    d = {'type': 'think', 'id': id_, 'fen': fen, 'hints': hints, 'ask': 'plan'}
    if side: d['side'] = side
    d.update(kw)
    if ref: d['ref'] = ref
    return d

def talk(id_, fen, ref=None, side=None, **kw):
    d = {'type': 'talk', 'id': id_, 'fen': fen}
    if side: d['side'] = side
    d.update(kw)
    if ref: d['ref'] = ref
    return d

def demo(id_, fen, sans, goal='win', side=None, notes=None, ref=None):
    line = []
    for i, u in enumerate(ucis(fen, sans), start=1):
        e = {'uci': u}
        e.update((notes or {}).get(i, {}))
        line.append(e)
    d = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': goal}
    if side: d['side'] = side
    d['line'] = line
    if ref: d['ref'] = ref
    return d

def move(id_, fen, sans, accept='best', goal='win', ref=None, side=None):
    us = ucis(fen, sans); turns = []
    for i in range(0, len(us), 2):
        rule = accept.get(i // 2 + 1, 'best') if isinstance(accept, dict) else accept
        t = {'teach': us[i], 'accept': rule}
        if isinstance(rule, list):
            b = chess.Board(fen)
            for u in us[:i]: b.push_uci(u)
            t['accept'] = [b.parse_san(x).uci() for x in rule]
        if i + 1 < len(us): t['reply'] = us[i + 1]
        turns.append(t)
    d = {'type': 'move', 'id': id_, 'fen': fen, 'goal': goal, 'turns': turns}
    if side: d['side'] = side
    if ref: d['ref'] = ref
    return d

# ---- Kempinski–Epishin, Bundesliga 2000/01, 07/01/2001 (PGN do chessgames.com, gid=1533865)
KEMPINSKI_SAN = (
    'd4_Nf6_c4_g6_Nf3_Bg7_e3_O-O_b4_b6_Bb2_d6_Be2_c5_b5_Bb7_O-O_e6_Nbd2_Nbd7_a4_a5_bxa6_Rxa6_Qc2_Ra8_Rfc1'
    '_Re8_Ne1_cxd4_exd4_e5_d5_Nc5_Nd3_Nxd3_Bxd3_Rc8_Qb1_Ba6_Bf1_Bh6_Bc3_Rc5_Qb2_Bc8_Re1_Bf5_a5_bxa5_Nb3_R'
    'c8_Nxa5_Bd7_Bb4_Bf8_Qa3_Ra8_Qc3_Qb6_g3_Reb8_Reb1_Qc7_Qe1_Bf5_Rb2_Bd7_h3_Rb6_Bc3_Rxb2_Bxb2_h5_Bg2_Qc5'
    '_Bc3_Rb8_Rb1_Rxb1_Qxb1_Bf5_Qb4_Qc8_h4_Be4_Bd2_Qg4_Qb3_Qe2_Qe3_Qd1+_Qe1_Qc2_f3_Bd3_Qc1_Qa2_Qc3_e4_Nb3'
    '_Bg7_fxe4_Qb1+_Nc1_Nxe4_Qxd3_Qxd3_Nxd3_Nxd2_c5_Bd4+_Kh2_Bxc5_Kh3_Be3_g4_hxg4+_Kxg4_Kg7_Kg3_Kh6_Bh3_f'
    '5_Bg2_Bd4_Kh3_Kg7_Ne1_Bf2_Nf3_Nc4_Ng5_Kf6_Nh7+_Kg7_Ng5_Ne5_Bf1_Be3_Ne6+_Kf6_Be2_Bf2_Ng5_Be3_Ne6_Bh6_'
    'Nd4_Bc1_Kg3_Bd2_Kh3_Be3_Nc6_Nd7_Bf3_Bf2_Nd8_Nc5_Bg2_Be1_Bf3_Ba5_Nc6_Bb6_Kg3_Nb3_Bg2_Nd2_Bh1_Nf1+_Kh3'
    '_Bc5_Bf3_Nd2_Bg2_Bf2_Nd8_Nc4_Nc6_Ne3_Bf3_Be1_Bh1_Nd1_Bf3_Nf2+_Kg2_Nd3_h5_g5_Bd1_Nf4+_Kf1_Bc3_h6_Nxd5'
    '_Bb3_Ne3+_Ke2_f4_Kd3_Bb2_h7_Kg7_Bg8_Bf6_Ke4_d5+_Kf3_Kh8_Nb4_d4_Nd3_Nf5_Ke4_Ne7_Bc4_Kxh7_Nxf4_gxf4_Kx'
    'f4_Kg7_Kg4_Nc6_Kf5_Bh4_Ke4_Bf2_Bb5_Nb4_Bc4_Kf6_Be2_Ke6_Bc4+_Kd6_Be2_Kc5_Bf1_Nc6_Be2_Kb4_Bf1_Kc3_Bb5_'
    'Nb4_Bf1_d3_Bxd3_Nxd3_Kf3_Bc5_Ke4_Kc4_Kf5_Kd5_Kf6_Bd6_Kf7_Ne5+_Ke8_Ke6_Kd8_Nf7+_Kc8_Kd5_Kb7_Kc5_Ka6_B'
    'c7_Kb7_Kd6_Ka6_Kc6_Ka7_Nd6_Ka8_Bd8_Ka7_Kb5_Kb8_Kb6_Ka8_Nb7_Kb8_Bc7+_Ka8_Kc6_Ka7_Nc5_Ka8_Nd7_Ka7_Nb6_'
    'Ka6_Bb8_Ka5_Kc5_Ka6_Bd6_Kb7_Kb5_Ka7_Kc6_Ka6_Bb8_Ka5_Nd5_Ka6_Bc7_Ka7_Bb6+_Kb8_Bc5_Ka8_Nc7+_Kb8_Nb5_Ka'
    '8_Kb6_Kb8_Na7_Ka8_Ka6_Kb8_Bb6_Ka8_Nb5_Kb8_Nd6_Ka8_Kb5_Kb8_Kc6_Ka8_Bc7_Ka7_Nb7_Ka8_Nc5_Ka7_Bb6+_Ka8_B'
    'c7_Ka7_Nd7_Ka8_Bd6_Ka7_Nb6_Ka6_Bb8_Ka5_Bc7_Ka6_Nc8'
)

LICHESS = 'https://lichess.org/analysis/pgn/'

# ---- Linha de Pandolfini (Endgame Workshop, pp. 48–51, via Wikipedia): 1.Bc2 ... 22.Bg2#
P1 = '8/8/4N1B1/8/8/8/1K1k4/8 w - - 0 1'
P5 = after(P1, 'Bc2 Ke3 Kc1 Ke2 Bg6 Ke3 Kd1 Kf2', '0 5')
P9 = after(P5, 'Kd2 Kf3 Kd3 Kg4 Ke3 Kh4 Kf4 Kh3', '0 9')
P13 = after(P9, 'Bh5 Kg2 Nc5 Kf2 Ne4+ Kg2 Bg4 Kf1', '0 13')
P17 = after(P13, 'Kf3 Ke1 Ke3 Kf1 Kd2 Kg2 Ke2 Kg1', '0 17')
P20 = after(P17, 'Bh3 Kh2 Bf1 Kg1 Ng5 Kh1', '0 20')

# ---- Composições próprias (tabela: lance único no caminho mais curto)
SEAL = '7N/8/8/8/8/6k1/4B3/3K4 w - - 0 1'          # 1.Cg6! (22); 1.Bd3? e 1.Cf7, 50
ROUTE = '8/8/4N3/8/4K1k1/8/8/5B2 w - - 0 1'         # 1.Be2+! (22); 1.Bd3?, 40
LOOSE = '2N5/3k4/8/8/8/8/8/4KB2 w - - 0 1'          # 1.Bh3+! (54); Cb6+/Ca7, 60; Cd6/Ce7 empatam
LOOSE2 = '8/8/6k1/1B5N/8/2K5/8/8 w - - 0 1'         # 1.Be8+! (50); Cg3/Be2, 54

# ---- Armadilha de Rhine (Chess Life, 2000, via Wikipedia)
RHINE = '2k1B3/8/3K4/8/2N5/8/8/8 w - - 0 1'
RHINE_ERR = '2k1B3/8/1N1K4/8/8/8/8/8 b - - 1 1'     # depois de 1.Cb6+??

# ---- Kempinski–Epishin: a lição começa no ply 311 (depois de 156.Ka6), longe do e13
K156 = '1b6/8/K1k5/3n4/8/8/8/8 b - - 0 156'         # ply 311, depois de 156.Ka6
K158 = after(K156, 'Bc7 Ka7 Bb6+ Kb8', '0 158')     # ply 315: 158...Cc7! único mais rápido
START = '4k3/8/8/8/8/8/8/4KBN1 w - - 0 1'

parts = [
    {'id': 'bigNet', 'steps': [
        think('t_big', P1, 2, ref='wikipedia'),
        talk('big', P1, ref='wikipedia', arrows=['g6c2'], marks=['c1', 'h1', 'h6', 'c3']),
        demo('d_big', P1, 'Bc2 Ke3 Kc1 Ke2 Bg6 Ke3 Kd1 Kf2', ref='wikipedia', notes={
            1: {'marks': ['b1', 'd1']}, 3: {'marks': ['c2', 'd2']}, 5: {'arrows': ['b1h7']},
            8: {'marks': ['h1']}}),
        move('bigWalk', P5, 'Kd2 Kf3 Kd3 Kg4 Ke3 Kh4 Kf4', accept={3: 'only'}, ref='wikipedia'),
    ]},
    {'id': 'midNet', 'steps': [
        think('t_mid', P9, 2, ref='wikipedia'),
        talk('mid', P9, ref='wikipedia', arrows=['g6h5', 'e6c5', 'c5e4'], marks=['d2', 'f2', 'g3']),
        demo('d_mid', P9, 'Bh5 Kg2 Nc5 Kf2 Ne4+ Kg2 Bg4', ref='wikipedia', notes={
            1: {'arrows': ['d1h5'], 'marks': ['e1', 'h1', 'h4']}, 3: {'arrows': ['c5e4']},
            5: {'marks': ['d2', 'f2', 'g3']}, 7: {'marks': ['h3']}}),
        move('midWalk', P13, 'Kf3 Ke1 Ke3 Kf1 Kd2 Kg2 Ke2', accept={1: 'only', 4: 'only'},
             ref='wikipedia'),
    ]},
    {'id': 'smallNet', 'steps': [
        think('t_small', P17, 2, ref='wikipedia'),
        talk('small', P17, ref='wikipedia', arrows=['g4h3', 'f1h3'], marks=['g1', 'h1', 'h2']),
        move('smallWalk', P17, 'Bh3 Kh2 Bf1 Kg1 Ng5 Kh1', accept='only', ref='wikipedia'),
        move('mateH1', P20, 'Kf2 Kh2 Nf3+ Kh1 Bg2#', accept={1: 'best', 2: 'only', 3: 'only'},
             ref='wikipedia'),
    ]},
    {'id': 'seal', 'steps': [
        think('t_seal', SEAL, 2),
        talk('seal', SEAL, arrows=['h8g6', 'd1h5'], marks=['f4', 'h4']),
        demo('d_sealWrong', SEAL, 'Bd3 Kf4 Nf7 Ke3 Bf5 Kd4', side='white', notes={
            1: {'marks': ['f4', 'g4', 'h4']}, 2: {'marks': ['f4']}, 4: {'marks': ['e3']}, 6: {'marks': ['d4']}}),
        move('sealRight', SEAL, 'Ng6 Kf2 Kd2'),
    ]},
    {'id': 'route', 'steps': [
        think('t_route', ROUTE, 2),
        talk('route', ROUTE, arrows=['f1e2', 'd1h5'], marks=['g3', 'h3', 'h4']),
        demo('d_routeWrong', ROUTE, 'Bd3 Kh5 Ke5 Kh6 Bf5', side='white', notes={
            1: {'marks': ['h5']}, 2: {'marks': ['h5']}, 4: {'marks': ['h8']}, 5: {'marks': ['g4', 'g6']}}),
        move('routeRight', ROUTE, 'Be2+ Kg3 Bf3', accept={2: 'only'}),
    ]},
    {'id': 'loose', 'steps': [
        think('t_loose', LOOSE, 2),
        talk('loose', LOOSE, arrows=['f1h3', 'h3c8'], marks=['d7', 'c8']),
        demo('d_loose', LOOSE, 'Bh3+ Kc6 Ne7+ Kc5 Ng6 Kb4 Kd2', notes={
            1: {'arrows': ['h3c8']}, 3: {'marks': ['c6']}, 5: {'marks': ['g6']}, 7: {'marks': ['c3', 'd3']}}),
        move('loose2', LOOSE2, 'Be8+ Kf5 Kd4', accept={2: 'only'}),
    ]},
    {'id': 'rhine', 'steps': [
        think('t_rhine', RHINE, 2, ref='wikipedia'),
        talk('rhine', RHINE, ref='wikipedia', arrows=['d6e7'], marks=['b6', 'd8', 'e8']),
        demo('d_rhine', RHINE_ERR, 'Kd8 Bf7', goal='draw', side='black', ref='wikipedia', notes={
            1: {'marks': ['e8']}, 2: {'marks': ['d8']}}),
        move('rhineRight', RHINE, 'Ke7', accept=['Ke7', 'Na5', 'Ba4', 'Bb5', 'Bc6'], ref='wikipedia'),
    ]},
    {'id': 'kempinski', 'steps': [
        think('t_kempinski', K156, 2, side='black', ref='kempinski#311'),
        talk('kempinski', K156, side='black', ref='kempinski#311', arrows=['d5b4'],
             marks=['a5']),
        demo('d_kempinski', K156, 'Bc7 Ka7 Bb6+ Kb8', side='black', ref='kempinski#311', notes={
            1: {'marks': ['a7']}, 3: {'marks': ['a6', 'a8', 'b8']}, 4: {'marks': ['b8']}}),
        move('kempinskiNc7', K158, 'Nc7', accept='only', side='black', ref='kempinski#315'),
        talk('recap', START, side='white', marks=['h1', 'a8']),
        {'type': 'play', 'id': 'finish', 'fen': START, 'goal': 'win', 'ref': 'lichessPractice'},
    ]},
]

REFERENCES = [
 {
  "id": "lichessPractice",
  "kind": "study",
  "author": "arex (Lichess Practice)",
  "title": "(BETA) Lichess Practice: Checkmating with a Knight and Bishop",
  "url": "https://lichess.org/study/ByhlXnmM"
 },
 {
  "id": "wikipedia",
  "kind": "web",
  "title": "Bishop and knight checkmate (Wikipedia, em inglês)",
  "url": "https://en.wikipedia.org/wiki/Bishop_and_knight_checkmate"
 },
 {
  "id": "deletang1923",
  "kind": "web",
  "title": "Daniel Delétang, \"Mat avec le Fou et le Cavalier\", La Stratégie, fevereiro de 1923, pp. 25–32 (Wikimedia Commons)",
  "url": "https://commons.wikimedia.org/wiki/File:Daniel_Del%C3%A9tang_-_Mat_avec_le_fou_et_le_cavalier_(La_Strat%C3%A9gie,_1923).pdf"
 },
 {
  "id": "kempinski",
  "kind": "game",
  "white": "Robert Kempinski",
  "black": "Vladimir Epishin",
  "event": "Bundesliga 2000/01, Alemanha",
  "year": 2001,
  "url": LICHESS + KEMPINSKI_SAN + '#311'
 },
 {
  "id": "chessgamesKempinski",
  "kind": "web",
  "title": "chessgames.com: Robert Kempinski vs Vladimir Epishin",
  "url": "https://www.chessgames.com/perl/chessgame?gid=1533865"
 },
 {
  "id": "tablebase",
  "kind": "tablebase",
  "title": "Lichess tablebase (Syzygy)",
  "url": "https://tablebase.lichess.ovh"
 }
]

KEY_POSITIONS = [
 {
  "id": "deletangStart",
  "fen": "8/8/4N1B1/8/8/8/1K1k4/8 w - - 0 1",
  "ref": "wikipedia"
 },
 {
  "id": "net1",
  "fen": "8/8/4N1B1/8/5K2/7k/8/8 w - - 0 1",
  "ref": "wikipedia"
 },
 {
  "id": "net2",
  "fen": "8/8/8/7B/4NK2/8/6k1/8 w - - 0 1",
  "ref": "wikipedia"
 },
 {
  "id": "net3",
  "fen": "8/8/8/8/4N3/8/4K3/5Bk1 w - - 0 1",
  "ref": "wikipedia"
 },
 {
  "id": "rhineTrap",
  "fen": "2k1B3/8/3K4/8/2N5/8/8/8 w - - 0 1",
  "ref": "wikipedia"
 },
 {
  "id": "kempinski",
  "fen": "1b6/8/K1k5/3n4/8/8/8/8 b - - 0 156",
  "ref": "kempinski#311"
 },
 {
  "id": "practiceStart",
  "fen": "4k3/8/8/8/8/8/8/4KBN1 w - - 0 1",
  "ref": "lichessPractice"
 }
]

EXERCISES = [
 {
  "id": "e04",
  "stars": 1,
  "fen": "8/8/3k2K1/3B4/8/3N4/8/8 w - - 0 1",
  "goal": "win",
  "origin": "lichessPractice",
  "turns": [
   {
    "teach": "d5b3",
    "accept": "best"
   }
  ]
 },
 {
  "id": "e12",
  "stars": 1,
  "fen": "B1k5/8/1K6/8/4N3/8/8/8 w - - 0 1",
  "goal": "win",
  "origin": "own",
  "turns": [
   {
    "teach": "b6c6",
    "accept": "best"
   }
  ]
 },
 {
  "id": "e16",
  "stars": 2,
  "fen": "8/8/8/2N5/4B3/3K2k1/8/8 w - - 0 1",
  "goal": "win",
  "origin": "own",
  "turns": [
   {
    "teach": "c5e6",
    "accept": "best",
    "reply": "g3g4"
   },
   {
    "teach": "e4g6",
    "accept": "best"
   }
  ]
 },
 {
  "id": "e13",
  "stars": 2,
  "fen": "K7/2b5/2kn4/8/8/8/8/8 b - - 0 1",
  "goal": "win",
  "origin": "kempinski",
  "turns": [
   {
    "teach": "d6c4",
    "accept": "best",
    "reply": "a8a7"
   },
   {
    "teach": "c4b6",
    "accept": "best"
   }
  ]
 },
 {
  "id": "e14",
  "stars": 3,
  "fen": "8/8/8/8/2BKNk2/8/8/8 w - - 0 1",
  "goal": "win",
  "origin": "deletang1923",
  "turns": [
   {
    "teach": "c4e6",
    "accept": "best",
    "reply": "f4f3"
   },
   {
    "teach": "e6f5",
    "accept": "best",
    "reply": "f3f4"
   },
   {
    "teach": "f5g6",
    "accept": "best"
   }
  ]
 },
 {
  "id": "e15",
  "stars": 3,
  "fen": "8/8/8/2K5/5k2/8/5N2/1B6 w - - 0 1",
  "goal": "win",
  "origin": "own",
  "turns": [
   {
    "teach": "c5d4",
    "accept": "best",
    "reply": "f4f3"
   },
   {
    "teach": "f2h1",
    "accept": "best",
    "reply": "f3g2"
   },
   {
    "teach": "b1e4",
    "accept": "best"
   }
  ]
 }
]

new = {'id': 'mates.bishopKnight.full', 'module': 'mates', 'skills': ['mate.bishopKnight'], 'parts': parts,
       'exercises': EXERCISES, 'passScore': 8, 'keyPositions': KEY_POSITIONS,
       'practice': {"fen": "8/8/3N4/3B4/4K3/7k/8/8 w - - 0 1", "goal": "win", "positionId": "knightBishop.knightBishopVsKing.0001"}, 'references': REFERENCES}
OUT.write_text(json.dumps(new, ensure_ascii=False, indent=2) + '\n')
print('ok', OUT)
