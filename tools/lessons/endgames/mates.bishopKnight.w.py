"""Gera a fonte da aula mates.bishopKnight.w (lances em SAN aqui, UCI no JSON).

Rodar: tools/.cache/venv/bin/python tools/lessons/endgames/mates.bishopKnight.w.py
Depois: tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py mates.bishopKnight.w

Lição refeita na T63 (2026-10-10), pelo plano docs/aulas/LICAO-mates.bishopKnight.w.md.
Os exercícios, o passScore e o practice não mudam.
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

# ---- Partidas (PGN do chessgames.com e do estudo Lichess Practice, capítulo "Epic Failure")
SHAKED_SAN = (
    'd4_d5_c4_c6_Nc3_e5_e3_e4_Qb3_Nf6_Bd2_Be7_Nh3_b6_cxd5_cxd5_Nf4_Bb7_Bb5+_Kf8_Be2_g6_f3_Nc6_fxe4_Na5_Qd'
    '1_dxe4_O-O_Kg7_Rc1_Rc8_Nb5_a6_Na3_Rxc1_Qxc1_b5_Qe1_Nc6_Bd1_Qd6_Bb3_Nb4_Nb1_Nbd5_Nc3_Nb6_a3_Rc8_Qe2_N'
    'c4_Be1_Qd7_h3_Ne8_a4_Ned6_axb5_axb5_Ncd5_Bd8_g4_Kg8_Nc3_Bc6_Na2_Na5_Bc2_b4_Nxb4_Bb5_Qf2_Bxf1_Qxf1_Na'
    'c4_Nfd5_f5_gxf5_Qxf5_Qxf5_gxf5_Bc3_Bh4_Ba4_Kh8_Nc2_h6_Kf1_Rb8_b3_Nb6_Nxb6_Rxb6_d5+_Kh7_Bd4_Rb7_Bc5_B'
    'g3_Nd4_Rf7_Ke2_f4_exf4_Bxf4_b4_Bg3_Ne6_Rf5_Bc6_Nc4_d6_Nxd6_Bxd6_Bxd6_Bxe4_Bxb4_Bxf5+_Kh8_Kf3_h5_Kg3_'
    'Be1+_Kf4_h4_Kg5_Kg8_Kg6_Bf2_Be4_Be1_Bc6_Bf2_Be8_Be1_Bf7+_Kh8_Nd4_Bf2_Nf5_Be1_Bc4_Bf2_Kf7_Be1_Bd3_Bf2'
    '_Ne7_Bc5_Ng6+_Kh7_Nxh4+_Kh8_Kg6_Kg8_Nf5_Bf2_h4_Bxh4_Nxh4_Kf8_Kf6_Kg8_Nf3_Kf8_Ne5_Kg8_Nf7_Kf8_Bh7_Ke8'
    '_Ne5_Kd8_Ke6_Kc7_Nd7_Kc6_Bd3_Kc7_Be4_Kd8_Kd6_Ke8_Bd5_Kd8_Bf7_Kc8_Nc5'
)
KARTTUNEN_SAN = (
    'd4_Nf6_Bg5_Ne4_Bf4_d5_e3_g6_Bd3_Bg7_Bxe4_dxe4_Nd2_c5_c3_cxd4_exd4_b6_Nxe4_Qd5_f3_O-O_Ne2_Ba6_Qd2_Nc6'
    '_b3_Rfd8_O-O_f5_Nf2_h6_c4_Qf7_Bxh6_Nxd4_Nxd4_Rxd4_Qb2_Bh8_Qa3_Bb7_Bg5_Be5_Rfe1_Bd6_Qb2_Qg7_Qe2_e5_Ra'
    'd1_Rxd1_Rxd1_Bc7_Qd2_Bc6_b4_a6_b5_axb5_cxb5_Bb7_Qd7_Qxd7_Rxd7_Rc8_Kf1_Ba8_h4_Bb8_a4_Re8_Be3_e4_f4_Kf'
    '8_Nh3_Re7_Rd8+_Re8_Rxe8+_Kxe8_Bxb6_Bd5_Kf2_Bd6_Bd4_Kd7_a5_Bc4_a6_Bxb5_a7_Bc6_Kg3_Kc8_Be3_Kb7_h5_gxh5'
    '_Kh4_Bb5_Nf2_Bb4_Kxh5_Be1_Nh3_Bf1_Kg6_Bxg2_Ng5_Ba5_Kxf5_Bc7_Kg4_Bf3+_Kf5_Bg2_Nf7_Bh3+_Kg5_Be6_Nh6_Bd'
    '8+_Kg6_Ka8_f5_Bxf5+_Kxf5_Kb7_Nf7_Bc7_Kxe4_Ka8_Kd5_Kb7_Bd4_Ka8_Ng5_Kb7_Ne6_Bh2_Kc4_Bg3_Kb5_Bh2_Bb6_Bg'
    '3_Nc5+_Ka8_Ne4_Bh2_Nc3_Kb7_Bd4_Bg3_Na4_Bh2_Bf2_Bf4_Nb6_Kxa7_Nd5+_Kb7_Nxf4_Kc7_Bc5_Kb7_Nd5_Kb8_Kc6_Ka'
    '8_Nc7+_Kb8_Bd4_Kc8_Ba7_Kd8_Nd5_Ke8_Kd6_Kf7_Ne7_Kf6_Be3_Kf7_Bd4_Ke8_Ke6_Kd8_Bb6+_Ke8_Nf5_Kf8_Bc7_Ke8_'
    'Ng7+_Kf8_Kf6_Kg8_Bd6_Kh7_Nf5_Kg8_Kg6_Kh8_Bc5'
)
USHENINA_SAN = (
    'd4_d5_c4_c6_Nf3_Nf6_Qb3_dxc4_Qxc4_Bf5_g3_e6_Bg2_Nbd7_O-O_Be7_e3_O-O_Rd1_Qc7_Nc3_Bg6_h3_Rad8_Qe2_e5_e'
    '4_exd4_Nxd4_Rfe8_Bf4_Qc8_Be3_Bb4_f3_Qb8_Bf2_Bh5_Qc2_Bd6_Nce2_Bg6_a3_h5_b4_Ne5_Qb3_Nxf3+_Nxf3_Nxe4_Nh'
    '4_Nxf2_Kxf2_Bh7_Nf3_Re7_Ra2_Rde8_Rad2_Bc7_Nfd4_Bb6_Qf3_Qe5_Kg1_a5_Kh1_axb4_axb4_Qg5_h4_Qh6_Nf4_Re3_Q'
    'xh5_Rxg3_Qxh6_gxh6_Nh5_Rg6_Re2_Rxe2_Nxe2_Kf8_Bh3_Bc7_Bf5_Rd6_Rxd6_Bxd6_Bxh7_Be7_Nhf4_Bxh4_Bf5_Ke7_Nd'
    '3_Kd6_Nc3_Kc7_Kg2_Kb6_Kf3_Bf6_Ne4_Be7_Bc8_Kc7_Bg4_Kb6_Nec5_Kb5_Nxb7_Bxb4_Nxb4_Kxb4_Nd8_c5_Nxf7_c4_Ke'
    '2_Kc3_Kd1_Kb2_Nxh6_c3_Bf5_Kb3_Bc2+_Kb2_Nf5_Ka1_Ne3_Kb2_Nd5_Ka1_Ke2_Kb2_Kd3_Kc1_Ba4_Kb2_Nxc3_Ka1_Nd1_'
    'Ka2_Bc2_Ka1_Kc3_Ka2_Bb3+_Ka1_Ne3_Kb1_Nc2_Kc1_Ba2_Kd1_Nd4_Ke1_Kd3_Kf2_Bd5_Kg3_Ke3_Kg4_Be4_Kg5_Kf3_Kf6'
    '_Kf4_Kg7_Kg5_Kf7_Kf5_Kg7_Bd5_Kh6_Ne6_Kh7_Kf6_Kg8_Nf4+_Kh8_Be4_Kg8_Nh3_Kh8_Ng5_Kg8_Nf7_Kf8_Bh7_Ke8_Bf'
    '5_Kf8_Nh6_Ke8_Nf7_Kf8_Ne5_Kg8_Ng6_Kh7_Be6_Kh6_Bg8_Kh5_Ne5_Kh4_Kf5_Kg3_Bc4_Kf2_Kf4_Ke1_Ke3_Kd1_Bd3_Kc'
    '1_Nc4_Kd1_Nb6_Kc1_Na4_Kd1_Be4_Kc1_Bd3_Kd1_Nb2+_Kc1_Nc4_Kd1_Bg6_Kc1_Bf5_Kd1_Nb6_Kc1_Na4_Kd1_Nb2+_Kc1_'
    'Nc4_Kd1_Kd3_Kc1_Kc3_Kd1_Bd3'
)

LICHESS = 'https://lichess.org/analysis/pgn/'

# ---- Linha do W de Müller e Lamprecht (via Wikipedia): 1.Cf7+ ... 21.Bc6#
W0 = '7k/8/5K2/4N3/8/3B4/8/8 w - - 0 1'
M5 = after(W0, 'Nf7+ Kg8 Bf5 Kf8 Bh7 Ke8 Ne5 Kd8', '0 5')
M10 = after(M5, 'Ke6 Kc7 Nd7 Kb7 Bd3 Kc6 Be2 Kc7 Bf3 Kd8', '0 10')
M13 = after(M10, 'Kd6 Ke8 Bh5+ Kd8 Bf7 Kc8', '0 13')
M15 = after(M13, 'Nc5 Kd8 Nb7+ Kc8', '0 15')
M19 = after(M15, 'Kc6 Kb8 Kb6 Kc8 Be6+ Kb8 Nc5 Ka8', '0 19')

# ---- Shaked–Morozevich, Mundial Juvenil, Zagan 1997
S85 = '6k1/8/5K2/4N3/8/3B4/8/8 w - - 0 85'      # ply 168, depois de 84...Rg8
S89 = '8/2k4B/4K3/4N3/8/8/8/8 w - - 0 89'       # ply 176, depois de 88...Rc7
S95 = '2k5/3N1B2/3K4/8/8/8/8/8 w - - 0 95'      # ply 188, depois de 94...Rc8 (= M13)

# ---- Linha de Seirawan (Winning Chess Endings, via Wikipedia), fim da fase 2 e fase 3
SW24 = '3k4/8/4K3/1B1N4/8/8/8/8 w - - 0 24'
SW28 = after(SW24, 'Kd6 Kc8 Ke7 Kb8 Kd8 Kb7 Kd7 Kb8', '0 28')

# ---- Ushenina–Girya, Grand Prix Feminino, Genebra 2013
Z = '8/8/8/8/3N4/3K4/B4k2/8 w - - 0 82'         # ply 162, depois de 81...Rf2
ZERR = '8/8/8/3B4/3N4/3K4/5k2/8 b - - 0 82'      # ply 163, depois de 82.Bd5?

# ---- Karttunen–Rasik, Copa Europeia de Clubes, Rethymnon 2003
K87 = 'k7/8/2K5/2BN4/8/8/8/8 w - - 0 87'         # ply 172, depois de 86...Ra8
K90 = '3k4/B1N5/2K5/8/8/8/8/8 w - - 0 90'        # ply 178, depois de 89...Rd8

parts = [
    {'id': 'corner', 'steps': [
        think('t_corner', W0, 2, ref='wikipedia'),
        talk('corner', W0, arrows=['e5f7'], marks=['h8', 'a8']),
        demo('d_w', W0, 'Nf7+ Kg8 Bf5 Kf8 Bh7 Ke8 Ne5 Kd8', ref='wikipedia', notes={
            1: {'arrows': ['f7h8', 'f7d8']}, 3: {'marks': ['h7']}, 5: {'marks': ['g8']},
            7: {'marks': ['d7']}}),
        talk('shaked', S85, ref='shaked#168', marks=['f7', 'h7', 'e5']),
        move('shaked1', S85, 'Nf7 Kf8 Bh7 Ke8 Ne5', ref='shaked#168'),
    ]},
    {'id': 'thirdPoint', 'steps': [
        think('t_third', M5, 2, ref='wikipedia'),
        talk('third', M5, arrows=['f6e6', 'e5d7', 'h7d3'], marks=['b6', 'c5', 'b5', 'c4']),
        demo('d_third', M5, 'Ke6 Kc7 Nd7 Kb7 Bd3 Kc6 Be2 Kc7 Bf3 Kd8', ref='wikipedia', notes={
            1: {'marks': ['d7', 'e7']}, 3: {'marks': ['b6', 'b8', 'c5']},
            5: {'marks': ['b5', 'c4']}, 9: {'marks': ['b7', 'c6']}}),
        move('third1', S89, 'Nd7 Kb7 Bd3', ref='shaked#176'),
    ]},
    {'id': 'lastPoints', 'steps': [
        think('t_last', M10, 2, ref='wikipedia'),
        talk('last', M10, arrows=['e6d6'], marks=['c7', 'e7']),
        demo('d_last', M10, 'Kd6 Ke8 Bh5+ Kd8 Bf7 Kc8', ref='wikipedia', notes={
            1: {'marks': ['c7', 'e7']}, 3: {'marks': ['e8']}, 5: {'marks': ['e8', 'g8']}}),
        move('last1', S95, 'Nc5 Kd8 Nb7+', ref='shaked#188'),
    ]},
    {'id': 'mateB6', 'steps': [
        think('t_mate', M15, 2, ref='wikipedia'),
        talk('mateB6', M15, arrows=['d6c6'], marks=['a7', 'b7', 'c7', 'b8', 'a8']),
        demo('d_mate', M15, 'Kc6 Kb8 Kb6 Kc8 Be6+ Kb8 Nc5 Ka8', ref='wikipedia', notes={
            1: {'marks': ['b7']}, 3: {'marks': ['a7', 'c7']}, 5: {'marks': ['c8', 'd7']},
            7: {'marks': ['b7', 'a6']}}),
        move('mate1', M19, 'Bd7 Kb8 Na6+ Ka8 Bc6#', accept={1: 'best', 2: 'only', 3: 'only'},
             ref='wikipedia'),
    ]},
    {'id': 'seirawan', 'steps': [
        think('t_seirawan', SW24, 2, ref='wikipedia'),
        talk('seirawan', SW24, arrows=['e6d6', 'd5c7', 'b5c6'],
             marks=['b6', 'c7', 'e7', 'a6', 'c6', 'e8']),
        demo('d_seirawan', SW24, 'Kd6 Kc8 Ke7 Kb8 Kd8 Kb7 Kd7 Kb8', ref='wikipedia', notes={
            1: {'marks': ['c7', 'd7']}, 3: {'marks': ['d7', 'd8']}, 5: {'marks': ['c7', 'c8']},
            7: {'marks': ['c6', 'c7', 'c8']}}),
        talk('c7net', SW28, arrows=['b5a6', 'a6c8', 'd5b4'], marks=['a7', 'a8']),
        move('netC7', SW28, 'Ba6 Ka7 Bc8 Kb8 Nb4 Ka7 Kc7 Ka8 Bb7+ Ka7 Nc6#',
             accept={5: 'only', 6: 'only'}, ref='wikipedia'),
    ]},
    {'id': 'ushenina', 'steps': [
        think('t_ushenina', Z, 2, ref='ushenina#162'),
        talk('ushenina', Z, ref='ushenina#162', arrows=['d4e2'], marks=['c2', 'd4', 'e2', 'f4', 'g2']),
        demo('d_ushenina', ZERR, 'Kg3 Ke3 Kg4 Be4 Kg5 Kf3 Kf6', side='white', ref='ushenina#163', notes={
            1: {'marks': ['g3']}, 7: {'marks': ['f6']}}),
        move('ushenina1', Z, 'Ne2 Kg2 Be6', ref='ushenina#162'),
    ]},
    {'id': 'karttunen', 'steps': [
        think('t_karttunen', K87, 2, ref='karttunen#172'),
        talk('karttunen', K87, ref='karttunen#172', arrows=['d5c7'],
             marks=['c7', 'd5', 'e7', 'f5', 'g7', 'h8']),
        demo('d_karttunen', K87, 'Nc7+ Kb8 Bd4 Kc8 Ba7 Kd8', ref='karttunen#172', notes={
            1: {'arrows': ['c7a8']}, 3: {'marks': ['a7']}, 5: {'marks': ['b8']}}),
        move('karttunen1', K90, 'Nd5 Ke8 Kd6', ref='karttunen#178'),
        talk('recap', W0, marks=['a8', 'h1']),
        {'type': 'play', 'id': 'playW', 'fen': W0, 'goal': 'win'},
    ]},
]

REFERENCES = [
 {
  "id": "wikipedia",
  "kind": "web",
  "title": "Bishop and knight checkmate (Wikipedia)",
  "url": "https://en.wikipedia.org/wiki/Bishop_and_knight_checkmate"
 },
 {
  "id": "lichessPractice",
  "kind": "study",
  "author": "arex",
  "title": "(BETA) Lichess Practice: Checkmating with a Knight and Bishop",
  "url": "https://lichess.org/study/ByhlXnmM"
 },
 {
  "id": "muller",
  "kind": "book",
  "author": "Karsten Müller e Frank Lamprecht",
  "title": "Fundamental Chess Endings",
  "publisher": "Gambit Publications",
  "year": 2001
 },
 {
  "id": "delaVilla",
  "kind": "book",
  "author": "Jesús de la Villa",
  "title": "100 Endgames You Must Know",
  "publisher": "New in Chess",
  "year": 2023
 },
 {
  "id": "shaked",
  "kind": "game",
  "white": "Tal Shaked",
  "black": "Alexander Morozevich",
  "event": "World Junior Championship, Zagan",
  "year": 1997,
  "url": LICHESS + SHAKED_SAN + '#174'
 },
 {
  "id": "chessgamesShaked",
  "kind": "web",
  "title": "chessgames.com: Tal Shaked vs Alexander Morozevich",
  "url": "https://www.chessgames.com/perl/chessgame?gid=1656009"
 },
 {
  "id": "karttunen",
  "kind": "game",
  "white": "Mika Karttunen",
  "black": "Vitezslav Rasik",
  "event": "European Club Cup, Rethymnon",
  "year": 2003,
  "url": LICHESS + KARTTUNEN_SAN + '#172'
 },
 {
  "id": "chessgamesKarttunen",
  "kind": "web",
  "title": "chessgames.com: Mika Karttunen vs Vitezslav Rasik",
  "url": "https://www.chessgames.com/perl/chessgame?gid=1268604"
 },
 {
  "id": "ushenina",
  "kind": "game",
  "white": "Anna Ushenina",
  "black": "Olga Girya",
  "event": "FIDE Women's Grand Prix, Genebra",
  "year": 2013,
  "url": LICHESS + USHENINA_SAN + '#162'
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
  "id": "wStart",
  "fen": "7k/8/5K2/4N3/8/3B4/8/8 w - - 0 1",
  "ref": "wikipedia"
 },
 {
  "id": "mateCorner",
  "fen": "k7/8/NKB5/8/8/8/8/8 b - - 0 1",
  "ref": "wikipedia"
 },
 {
  "id": "shaked",
  "fen": "3k4/7B/5K2/4N3/8/8/8/8 w - - 0 88",
  "ref": "shaked#174"
 },
 {
  "id": "seirawanWall",
  "fen": "3k4/8/4K3/1B1N4/8/8/8/8 w - - 0 24",
  "ref": "wikipedia"
 },
 {
  "id": "ushenina",
  "fen": "8/8/8/8/3N4/3K4/B4k2/8 w - - 0 82",
  "ref": "ushenina#162"
 },
 {
  "id": "karttunen",
  "fen": "k7/8/2K5/2BN4/8/8/8/8 w - - 0 87",
  "ref": "karttunen#172"
 }
]

EXERCISES = [
 {
  "id": "e13",
  "stars": 1,
  "fen": "8/k1K5/3N4/8/8/8/8/5B2 w - - 0 1",
  "goal": "win",
  "origin": "own",
  "turns": [
   {
    "teach": "d6c8",
    "accept": "best",
    "reply": "a7a8"
   },
   {
    "teach": "f1g2",
    "accept": "only"
   }
  ]
 },
 {
  "id": "e14",
  "stars": 1,
  "fen": "8/8/8/8/8/1BK5/8/k2N4 w - - 0 1",
  "goal": "win",
  "origin": "ushenina",
  "turns": [
   {
    "teach": "d1e3",
    "accept": "best",
    "reply": "a1b1"
   },
   {
    "teach": "e3c2",
    "accept": "best"
   }
  ]
 },
 {
  "id": "e15",
  "stars": 2,
  "fen": "kN6/8/BK6/8/8/8/8/8 w - - 0 1",
  "goal": "win",
  "origin": "own",
  "turns": [
   {
    "teach": "b6c7",
    "accept": "best",
    "reply": "a8a7"
   },
   {
    "teach": "a6c8",
    "accept": "best",
    "reply": "a7a8"
   },
   {
    "teach": "c8b7",
    "accept": "best",
    "reply": "a8a7"
   },
   {
    "teach": "b8c6",
    "accept": "only"
   }
  ]
 },
 {
  "id": "e17",
  "stars": 2,
  "fen": "8/B3N3/3K1k2/8/8/8/8/8 w - - 0 1",
  "goal": "win",
  "origin": "karttunen",
  "turns": [
   {
    "teach": "a7e3",
    "accept": "best",
    "reply": "f6f7"
   },
   {
    "teach": "e3d4",
    "accept": "best",
    "reply": "f7e8"
   },
   {
    "teach": "d6e6",
    "accept": "best"
   }
  ]
 },
 {
  "id": "e18",
  "stars": 3,
  "fen": "8/2kN4/4K3/8/2B5/8/8/8 w - - 0 1",
  "goal": "win",
  "origin": "wikipedia",
  "turns": [
   {
    "teach": "c4b5",
    "accept": "best",
    "reply": "c7d8"
   },
   {
    "teach": "d7f6",
    "accept": "best",
    "reply": "d8c7"
   },
   {
    "teach": "f6d5",
    "accept": "best"
   }
  ]
 },
 {
  "id": "e19",
  "stars": 3,
  "fen": "8/7k/5KN1/5B2/8/8/8/8 w - - 0 1",
  "goal": "win",
  "origin": "ushenina",
  "turns": [
   {
    "teach": "f5e6",
    "accept": "best",
    "reply": "h7h6"
   },
   {
    "teach": "e6g8",
    "accept": "best",
    "reply": "h6h5"
   },
   {
    "teach": "g6e5",
    "accept": "best",
    "reply": "h5h4"
   },
   {
    "teach": "f6f5",
    "accept": "best",
    "reply": "h4g3"
   },
   {
    "teach": "e5g4",
    "accept": "best"
   }
  ]
 }
]

new = {'id': 'mates.bishopKnight.w', 'module': 'mates', 'skills': ['mate.bishopKnight'], 'parts': parts,
       'exercises': EXERCISES, 'passScore': 8, 'keyPositions': KEY_POSITIONS,
       'practice': {"fen": "8/8/3N4/3B4/4K3/7k/8/8 w - - 0 1", "goal": "win", "positionId": "knightBishop.knightBishopVsKing.0001"}, 'references': REFERENCES}
OUT.write_text(json.dumps(new, ensure_ascii=False, indent=2) + '\n')
print('ok', OUT)
