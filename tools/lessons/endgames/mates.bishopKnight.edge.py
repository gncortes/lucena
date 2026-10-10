"""Gera a fonte da aula mates.bishopKnight.edge (lances em SAN aqui, UCI no JSON).

Rodar: tools/.cache/venv/bin/python tools/lessons/endgames/mates.bishopKnight.edge.py
Depois: tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py mates.bishopKnight.edge

Lição refeita na T63 (2026-10-10). Os exercícios, o passScore e o practice não mudam.
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

# ---- Seirawan (Wikipedia): 1.Bg2 Rd4 2.Rd2 Re5 3.Re3 Rf5 4.Cd3 Rg5 5.Be4 Rf6 6.Rd4 ...
START = '8/8/8/8/8/4k3/8/2N1KB2 w - - 0 1'
S4 = after(START, 'Bg2 Kd4 Kd2 Ke5 Ke3 Kf5', '0 4')
S5b = after(START, 'Bg2 Kd4 Kd2 Ke5 Ke3 Kf5 Nd3 Kg5 Be4', '0 5')
S6 = after(START, 'Bg2 Kd4 Kd2 Ke5 Ke3 Kf5 Nd3 Kg5 Be4 Kf6', '0 6')
S9 = after(S6, 'Kd4 Ke6 Kc5 Ke7 Kd5 Kf6', '0 9')

# ---- posições montadas
# Longe de e05 (rei preto no centro, oposição pelo lado); 1.Be6+?? e 1.Bc6+?? entregam o bispo.
SAFE = '8/3B4/8/3k4/6K1/8/4N3/8 w - - 0 1'
HANG = after(SAFE, 'Be6+')
SAFE2 = '8/8/6B1/8/2K5/5k2/5N2/8 w - - 0 1'
ORDER = '8/5B2/2N5/8/8/2K2k2/8/8 w - - 0 1'
# Longe de e08 (rei preto na borda de cima, não em b4): 1.Bc4! tira e6 e f7.
# Prática da ordem, longe de e10 (rei, bispo, rei; o cavalo fica longe).
ORDER1 = '2B5/8/6K1/8/N4k2/8/8/8 w - - 0 1'
ORDER2 = '2K5/3Nk3/8/1B6/8/8/8/8 w - - 0 1'
TANGLE = '8/8/8/1K6/8/3k4/2N5/1B6 w - - 0 1'
TRAP = after(TANGLE, 'Ne3+')
EDGE = '7k/8/5K2/8/4BN2/8/8/8 w - - 0 1'
STALE = after(EDGE, 'Kf7')

# ---- Ljubojević–Polgár, Amber (às cegas), Monte Carlo 1994 (PGN Mentor)
# PGN da partida (PGN Mentor, PolgarJ.zip), até o mate no ply 212.
POLGAR_SAN = (
    'e4_c5_c3_d6_d4_Nf6_Bd3_g6_h3_Bg7_Nf3_O-O_O-O_Qc7_Qe2_a6_Bf4_b5_e5_Nd5_Bg3_Qb6_Nbd2_cxd4_cxd4_Nb4_Be4'
    '_d5_Bb1_a5_Nb3_a4_Nc5_N8c6_Qe3_Na5_Bf4_Nc4_Qc3_Nc6_a3_f6_exf6_Rxf6_Bg5_Rf7_Be3_Rxf3_gxf3_e5_dxe5_Bxe'
    '5_Nd3_d4_Nxe5_N4xe5_Ba2+_Kg7_Bd5_Ra6_f4_Nc4_Bxc6_dxc3_Bxb6_Rxb6_Bxb5_Rxb5_bxc3_Bxh3_Rfd1_Rb3_Rd4_Rxc'
    '3_Rad1_Bf5_Re1_Nb2_Re3_Rxe3_fxe3_Be6_e4_Bb3_Rd7+_Kf6_Rxh7_Nc4_e5+_Ke6_Rg7_Bc2_Rc7_Nxa3_Rc3_Bb3_Rc6+_'
    'Kf7_Rc7+_Kf8_Rc6_Kg7_Rc7+_Kh6_Rc6_Kg7_Rc7+_Kf8_Rc6_Bf7_Ra6_Be8_Ra7_Nc2_Kf2_a3_Ke2_Nd4+_Kd2_Nb5_Ra6_K'
    'e7_e6_Nd6_Kc2_Nc4_Kc3_Bb5_Ra7+_Kxe6_Kb4_Nd6_Rxa3_Be8_Ra5_Nb5_Kc5_Kf5_Ra8_Nc7_Rc8_Ne6+_Kd6_Ba4_Ra8_Bd'
    '1_Ra5+_Kf6_Ra1_Be2_Ra4_Bd1_Re4_Ng7_Re1_Bf3_Rf1_Be4_Re1_Kf5_Ke7_Nh5_Rg1_Nxf4_Rxg6_Nxg6+_Kd6_Kf6_Kc5_K'
    'e5_Kc4_Bd5+_Kd3_Nf4+_Ke3_Be4_Kd2_Kd4_Kc1_Kc3_Kd1_Bc2+_Ke1_Kd3_Kf2_Ke4_Kg3_Bd1_Kf2_Nd3+_Kg3_Ke3_Kh4_K'
    'f4_Kh3_Ne1_Kh4_Ng2+_Kh3_Kf3_Kh2_Kf2_Kh3_Be2_Kh2_Bg4_Kh1_Ne3_Kh2_Nf1+_Kh1_Bf3'
)
P84 = '8/4K3/6n1/5k2/4b3/8/8/8 w - - 0 84'
P88 = '8/8/8/3bk3/5n2/4K3/8/8 b - - 9 88'

parts = [
    {'id': 'build', 'steps': [
        think('t_start', START, 2, ref='wikipedia', marks=['d4', 'e4', 'd5', 'e5']),
        talk('intro', START, marks=['d4', 'e4', 'd5', 'e5']),
        demo('d_build', START, 'Bg2 Kd4 Kd2 Ke5 Ke3 Kf5', ref='wikipedia', notes={
            1: {'arrows': ['g2a8']}, 3: {'marks': ['c3', 'd3', 'e3']},
            5: {'marks': ['d4', 'e4', 'f4']}}),
        move('build2', S4, 'Nd3 Kg5 Be4', accept={1: ['Nd3'], 2: ['Be4']}, ref='wikipedia'),
    ]},
    {'id': 'pushing', 'steps': [
        think('t_push', S6, 2, ref='wikipedia'),
        talk('net', S6, ref='wikipedia',
             arrows=['e4d5', 'e4f5', 'd3c5', 'd3e5', 'd3f4', 'e3f2', 'e3f3'],
             marks=['c5', 'd5', 'e5', 'f5', 'f4', 'f3', 'f2']),
        demo('d_push', S6, 'Kd4 Ke6 Kc5 Ke7 Kd5 Kf6', ref='wikipedia', notes={
            1: {'marks': ['e3', 'e4', 'e5']}, 3: {'marks': ['d6']},
            5: {'marks': ['d6', 'e6']}}),
        move('push2', S9, 'Kd6 Kf7 Ke5 Kg7 Ke6 Kg8', accept={1: ['Kd6'], 2: ['Ke5'], 3: ['Ke6']},
             ref='wikipedia'),
    ]},
    {'id': 'safe', 'steps': [
        think('t_safe', SAFE, 2),
        talk('safe', SAFE, arrows=['g4f5', 'd7e6'], marks=['e4', 'e5', 'e6']),
        demo('d_hang', HANG, 'Kxe6', goal='draw', side='white'),
        move('safe1', SAFE, 'Kf5 Kc5 Be6', accept={2: ['Be6']}),
        move('safe2', SAFE2, 'Ne4'),
    ]},
    {'id': 'order', 'steps': [
        think('t_order', ORDER, 2),
        talk('order', ORDER, marks=['e3', 'e4', 'e5']),
        demo('d_wrongOrder', ORDER, 'Be6 Ke4', notes={2: {'marks': ['e4']}}),
        move('order1', ORDER1, 'Kf6 Ke4 Be6 Kd4 Kf5'),
        move('order2', ORDER2, 'Bc4 Kd6 Kd8'),
    ]},
    {'id': 'untangle', 'steps': [
        think('t_untangle', TANGLE, 2),
        talk('untangle', TANGLE, arrows=['b1d3'], marks=['c2']),
        demo('d_tangleTrap', TRAP, 'Kxe3', goal='draw', side='white'),
        move('untangle1', TANGLE, 'Na3+ Kd4 Nc4'),
    ]},
    {'id': 'polgar', 'steps': [
        think('t_polgar', P88, 2, ref='polgar', side='black'),
        talk('polgar', P88, ref='polgar', side='black', marks=['c3', 'e3']),
        demo('d_polgar', P84, 'Kd6 Kf6 Kc5 Ke5 Kc4 Bd5+ Kd3 Nf4+ Ke3', side='black',
             ref='polgar#166', notes={8: {'arrows': ['f4d3']}, 9: {'marks': ['c3']}}),
        move('polgarNet', P88, 'Be4 Kd2 Kd4 Kc1 Kc3', ref='polgar',
             side='black'),
    ]},
    {'id': 'edge', 'steps': [
        think('t_edge', EDGE, 2),
        talk('stalemate', STALE, side='white', marks=['g8', 'g7', 'h7']),
        move('edge1', EDGE, 'Bd5'),
        talk('recap', S6, marks=['c5', 'd5', 'e5', 'f5', 'f4', 'f3', 'f2']),
        {'type': 'play', 'id': 'finish', 'fen': S6.rsplit(' ', 2)[0] + ' 0 1', 'goal': 'win'},
    ]},
]

REFERENCES = [{'id': 'wikipedia',
  'kind': 'web',
  'title': 'Bishop and knight checkmate (Wikipedia)',
  'url': 'https://en.wikipedia.org/wiki/Bishop_and_knight_checkmate'},
 {'id': 'polgar',
  'kind': 'game',
  'white': 'Ljubomir Ljubojević',
  'black': 'Judit Polgár',
  'event': 'torneio Amber (às cegas), Monte Carlo',
  'year': 1994,
  'url': 'https://lichess.org/analysis/pgn/' + POLGAR_SAN + '#175'},
 {'id': 'pgnmentor',
  'kind': 'web',
  'title': 'PGN Mentor: Polgar, Judit',
  'url': 'https://www.pgnmentor.com/players/PolgarJ.zip'},
 {'id': 'practice',
  'kind': 'study',
  'author': 'arex',
  'title': '(BETA) Lichess Practice: Checkmating with a Knight and Bishop',
  'url': 'https://lichess.org/study/ByhlXnmM'},
 {'id': 'schnabelwolke',
  'kind': 'study',
  'author': 'Schnabelwolke',
  'title': 'Endings / Technique: Mating with Bishop and Knight',
  'url': 'https://lichess.org/study/KPZZVr1H'},
 {'id': 'zarate',
  'kind': 'study',
  'author': 'Gabriel Zárate',
  'title': 'A+C. Método de la W y Método Deletang.',
  'url': 'https://lichess.org/study/PZZ1RLdX'},
 {'id': 'muller',
  'kind': 'book',
  'author': 'Karsten Müller e Frank Lamprecht',
  'title': 'Fundamental Chess Endings',
  'publisher': 'Gambit Publications',
  'year': 2001},
 {'id': 'tablebase',
  'kind': 'tablebase',
  'title': 'Lichess tablebase (Syzygy)',
  'url': 'https://tablebase.lichess.ovh'}]

KEY_POSITIONS = [{'id': 'start', 'fen': '8/8/8/8/8/4k3/8/2N1KB2 w - - 0 1', 'ref': 'wikipedia'},
 {'id': 'wall', 'fen': '8/8/8/6k1/4B3/3NK3/8/8 b - - 0 1', 'ref': 'wikipedia'},
 {'id': 'polgar', 'fen': '8/8/8/3bk3/5n2/4K3/8/8 b - - 9 88', 'ref': 'polgar'},
 {'id': 'centre', 'fen': '8/8/8/8/4k3/8/6K1/6BN w - - 0 1', 'ref': 'schnabelwolke'},
 {'id': 'far', 'fen': 'B7/8/8/8/3k4/8/8/N6K w - - 0 1', 'ref': 'zarate'}]

EXERCISES = [{'id': 'e04',
  'stars': 1,
  'fen': '8/8/8/8/2k1K3/8/1B6/3N4 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'b2d4', 'accept': 'best'}]},
 {'id': 'e07',
  'stars': 1,
  'fen': '8/B2N4/8/8/1k6/8/2K5/8 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'c2d3', 'accept': 'best'}]},
 {'id': 'e05',
  'stars': 2,
  'fen': '8/8/8/5B2/8/6k1/4K3/3N4 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'e2e3', 'accept': 'best'}]},
 {'id': 'e06',
  'stars': 2,
  'fen': '8/8/1K4N1/8/2k5/4B3/8/8 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'g6f4', 'accept': 'best'}]},
 {'id': 'e11',
  'stars': 2,
  'fen': '8/8/B2N4/3k4/8/8/8/K7 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'd6f7', 'accept': 'best', 'reply': 'auto'}, {'teach': 'a6c4', 'accept': 'best'}]},
 {'id': 'e08',
  'stars': 3,
  'fen': '8/8/8/8/1k1K4/8/4B3/4N3 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'e2c4', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'd4c3', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'e1c2', 'accept': 'best'}]},
 {'id': 'e10',
  'stars': 3,
  'fen': '8/8/8/2k5/5N2/1K6/B7/8 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'b3c3', 'accept': 'best', 'reply': 'c5d6'},
            {'teach': 'f4g6', 'accept': 'best', 'reply': 'd6c5'},
            {'teach': 'a2c4', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'c3b4', 'accept': 'best'}]},
 {'id': 'e09',
  'stars': 3,
  'fen': '8/8/8/8/4K3/2k5/1N6/B7 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'b2d3', 'accept': 'best', 'reply': 'c3c4'},
            {'teach': 'a1d4', 'accept': 'best', 'reply': 'c4b5'},
            {'teach': 'e4d5', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'd5c6', 'accept': 'best'}]}]

new = {'id': 'mates.bishopKnight.edge', 'module': 'mates', 'skills': ['mate.bishopKnight'], 'parts': parts,
       'exercises': EXERCISES, 'passScore': 11, 'keyPositions': KEY_POSITIONS,
       'practice': {'fen': '8/8/3N4/3B4/4K3/7k/8/8 w - - 0 1',
 'goal': 'win',
 'positionId': 'knightBishop.knightBishopVsKing.0001'}, 'references': REFERENCES}
OUT.write_text(json.dumps(new, ensure_ascii=False, indent=2) + '\n')
print('ok', OUT)
