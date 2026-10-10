"""Gera a fonte da aula minor.wrongBishop (lances em SAN aqui, UCI no JSON).

Uso: tools/.cache/venv/bin/python tools/lessons/endgames/minor.wrongBishop.py
Depois: tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py minor.wrongBishop
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


def demo(id_, fen, goal, sans, notes=None, side=None):
    line = []
    for i, u in enumerate(uci(fen, sans)):
        e = {'uci': u}
        if notes and i in notes:
            e.update(notes[i])
        line.append(e)
    d = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': goal, 'line': line}
    if side:
        d['side'] = side
    return d


def move(id_, fen, goal, sans, accepts, typ='move'):
    """sans: lance do aluno, resposta, lance do aluno, resposta, ..."""
    us = uci(fen, sans)
    turns = []
    for i in range(0, len(us), 2):
        t = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us):
            t['reply'] = us[i + 1]
        turns.append(t)
    return {'type': typ, 'id': id_, 'fen': fen, 'goal': goal, 'turns': turns}


def think(id_, fen, hints, **kw):
    d = {'type': 'think', 'id': id_, 'fen': fen, 'hints': hints, 'ask': 'plan'}
    d.update(kw)
    return d


def talk(id_, fen, **kw):
    d = {'type': 'talk', 'id': id_, 'fen': fen}
    d.update(kw)
    return d


# Partidas: PGN do pgnmentor.com (players/Fischer.zip, Karpov.zip), conferido com python-chess.
URL_FT = ('https://lichess.org/analysis/pgn/e4_c5_Nf3_Nc6_d4_cxd4_Nxd4_e6_Nb5_d6_Bf4_e5_Be3_Nf6_Bg5_Qa5+_Qd2_Nxe4_Qxa5_Nxa5_Be3_Kd7_N1c3_Nxc3_Nxc3_Kd8_Nb5_Be6_O-O-O_b6_f4_exf4_Bxf4_Nb7_Be2_Bd7_Rd2_Be7_Rhd1_Bxb5_Bxb5_Kc7_Re2_Bf6_Rde1_Rac8_Bc4_Rhf8_b4_a5_Bd5_Kb8_a3_Rfd8_Bxf7_Bc3_Bd2_d5_Rd1_d4_Bxc3_Rxc3_Kb2_d3_Kxc3_dxe2_Re1_Nd6_Bh5_Nb5+_Kb2_axb4_axb4_Rd4_c3_Rh4_Bxe2_Nd6_Rd1_Kc7_h3_Rf4_Rf1_Re4_Bd3_Re5_Rf2_h5_c4_Rg5_Kc3_Kd7_Ra2_Kc8_Kd4_Kc7_Ra7+_Kd8_c5_bxc5+_bxc5_Ne8_Ra2_Nc7_Bc4_Kd7_Rb2_Kc6_Bb3_Nb5+_Ke3_Kxc5_Kf4_Rg6_Bd1_h4_Kf5_Rh6_Kg5_Nd6_Bc2_Nf7+_Kg4_Ne5+_Kf4_Kd4_Rb4+_Kc3_Rb5_Nf7_Rc5+_Kd4_Rf5_g5+_Kg4_Ne5+_Kxg5_Rg6+_Kxh4_Rxg2_Bd1_Rg8_Bg4_Ke4_Kg3_Rg7_Rf4+_Kd5_Ra4_Ng6_Ra6_Ne5_Kf4_Rf7+_Kg5_Rg7+_Kf5_Rf7+_Rf6_Rxf6+_Kxf6_Ke4_Bc8_Kf4_h4_Nf3_h5_Ng5_Bf5_Nf3_h6_Ng5_Kg6_Nf3_h7_Ne5+_Kf6#161')
URL_KK = ('https://lichess.org/analysis/pgn/d4_d5_c4_e6_Nc3_Be7_cxd5_exd5_Bf4_Nf6_Qc2_O-O_e3_c5_dxc5_Bxc5_Nf3_Nc6_Be2_d4_exd4_Nxd4_Nxd4_Qxd4_Bg3_Be6_O-O_Rac8_Bf3_b6_Rfe1_Qb4_Be5_Bd4_a3_Qc5_Bxd4_Qxd4_Rad1_Qc5_Qa4_a5_Qd4_Qxd4_Rxd4_Rfd8_Red1_Rxd4_Rxd4_Kf8_Kf1_Ke7_Ke2_Bb3_Ke3_Rc5_Kd2_h6_Be2_Ne8_Bf3_Nf6_Rd3_Re5_h3_Rc5_Rd4_Rc8_Be2_Rc5_Bd3_h5_g3_g6_Ne2_Nd7_Re4+_Re5_Nd4_Bd5_Re2_Rxe2+_Bxe2_Nc5_Nb5_Ne4+_Ke3_Nd6_Kd4_Bc6_Nxd6_Kxd6_Bc4_Be8_h4_f6_Bg8_Kc6_Ba2_Kd6_Bd5_Ke7_Bg8_Kd6_Bb3_Ke7_Bd1_Kd6_Be2_Bd7_Bd3_Be8_Bc4_Ke7_Be2_Kd6_g4_hxg4_Bxg4_Bf7_f4_f5_Bd1_Bd5_Ba4_Bf3_Bb3_Be2_Bf7_Bh5_Kc4_Be2+_Kc3_Bh5_b4_Ke7_Bc4_Kd6_bxa5_bxa5_Kd4_Bf3_Bf1_Bd5_Be2_Bb7_Bd1_Bd5_Ke3_Kc5_Ba4_Bf7_Bd7_Kc4_a4_Kc5_Bb5_Kd5_Kd3_Kc5_Kc3_Kd6_Kd4_Bb3_Be8_Ke7_Bxg6_Bxa4_Bxf5_Kf6#163')

CORNER = F('7k/8/5K2/7P/8/8/8/5B2 w')
RIGHT = F('7k/8/5K2/7P/8/8/8/4B3 w')
RIGHT2 = F('7k/8/6KP/8/8/8/8/4B3 w')
APAWN = F('k7/8/PK6/8/8/8/8/4B3 w')
CUT = F('5k2/8/6K1/7P/8/3B4/8/8 w')
CUT2 = F('5k2/8/5K2/8/8/7P/8/3B4 w')
MEDNIS = F('5K2/5B2/7k/7P/8/8/8/8 w')
MEDNISB = F('5K2/5B2/7k/7P/8/8/8/8 b')
KINGDOOR = F('5K2/8/6k1/8/7P/8/4B3/8 w')
RACE = F('8/8/4k3/8/5K2/8/7P/3B4 b')
# Fischer-Taimanov, Vancouver 1971, partida 2: ply 161 (depois de 81.Rxf6) e 162 (depois de 81...Re4??).
TAIM = '8/8/5K2/3kn3/6B1/7P/8/8 b - - 0 81'
TAIM2 = '8/8/5K2/4n3/4k1B1/7P/8/8 w - - 1 82'
# Greco 1623 (Wikipedia, citando Averbakh), depois da troca das torres (Ta1+ Tf1 Txf1+ Rxf1); numerado a partir de 1.
GRECO = '8/8/8/5bk1/8/5B2/6PP/5K2 b - - 0 1'
# Karpov-Kasparov, Moscou 1985, partida 20: ply 163 (depois de 82.Rd4). 10 peças: só talk.
KK = '8/5b2/3k2p1/pB3p2/P2K1P1P/8/8/8 b - - 8 82'
QUIZ3 = F('5b2/3N1k2/6p1/7p/8/8/8/4K3 w')
SHIFT = F('2b5/8/2k5/pp6/8/8/3K4/3B4 w')
# Quiz 4 do ibmm depois de 1.Ba4 Rc5 2.Bxb5.
SHIFTB = '2b5/8/p7/1Bk5/8/8/3K4/8 b - - 0 2'
# Própria: 6k1/8/6PP/8/4K3/3B4/8/b7 b depois de 1...Rh8?.
PRISON = F('7k/8/6PP/8/4K3/3B4/8/b7 w')
PRISON2 = F('7k/8/6PP/8/5K2/8/4B3/b7 w')
FINISH = F('8/8/8/2k5/8/6KP/4B3/8 b')

src = {
    'id': 'minor.wrongBishop', 'module': 'minor', 'skills': ['minor.wrongBishop'],
    'parts': [
        {'id': 'corner', 'steps': [
            think('t_corner', CORNER, 2, marks=['h8']),
            talk('corner', CORNER, marks=['h8', 'g8', 'h7']),
            demo('d_corner', CORNER, 'draw', 'h6 Kg8 Kg6 Kh8 h7',
                 {2: {'marks': ['g7', 'h7']}, 4: {'marks': ['g8', 'g7']}}),
            talk('colour', RIGHT, marks=['h8', 'a8'], arrows=['e1h4']),
            demo('d_right', RIGHT, 'win', 'Kg6 Kg8 h6 Kh8 Bc3+ Kg8 h7+',
                 {4: {'arrows': ['c3h8']}, 6: {'marks': ['f8']}}),
            move('rightMove', RIGHT2, 'win', 'Bc3+ Kg8 h7+ Kf8 h8=Q+', ['win'] * 3),
        ]},
        {'id': 'cutoff', 'steps': [
            think('t_cutoff', CUT, 2, marks=['g8', 'h8']),
            talk('cutoff', CUT, marks=['g8', 'g7'], arrows=['d3c4', 'c4g8']),
            demo('d_cutoff', CUT, 'win', 'Bc4 Ke7 Kg7 Kd6 h6',
                 {0: {'arrows': ['c4g8']}, 2: {'marks': ['g7', 'g8', 'h8']}}),
            talk('kingDoor', MEDNIS, marks=['g8', 'h8', 'h7'], arrows=['f8g8'], ref='wikiWrongRookPawn'),
            demo('d_kingDoor', MEDNIS, 'win', 'Kg8 Kg5 Kg7',
                 {0: {'marks': ['h7', 'h8']}}),
            move('kingDoorMove', KINGDOOR, 'win', 'Kg8 Kf5 h5 Kg5 Kg7 Kf4 h6', ['win'] * 4),
        ]},
        {'id': 'race', 'steps': [
            think('t_mednis', MEDNISB, 2, side='black', marks=['h8'], ref='wikiWrongRookPawn'),
            talk('mednis', MEDNISB, side='black', marks=['h8', 'h7'], arrows=['h6h7'],
                 ref='wikiWrongRookPawn'),
            demo('d_mednis', MEDNISB, 'draw', 'Kh7 Ke7 Kh8 Kf6 Kh7',
                 {0: {'marks': ['h8']}}, side='black'),
            talk('tempo', RACE, side='black', marks=['h8', 'g7']),
            move('raceMove', RACE, 'draw', 'Kf6 h4 Kg6 Kg4 Kh6 Bc2 Kg7 Kg5 Kh8', ['hold'] * 5),
        ]},
        {'id': 'sacrifice', 'steps': [
            think('t_taimanov', TAIM, 2, side='black', ref='fischerTaimanov'),
            talk('taimanov', TAIM, side='black', marks=['h8'], arrows=['e5d3', 'd3f4'],
                 ref='fischerTaimanov'),
            demo('d_taimanov', TAIM, 'draw', 'Nd3 h4 Nf4 Kf5 Kd6 Kxf4 Ke7',
                 {2: {'arrows': ['f4h5']}, 4: {'arrows': ['d6f8']}}, side='black'),
            talk('taimanovGame', TAIM2, side='black', marks=['f5'], arrows=['g4c8'],
                 ref='fischerTaimanov#162'),
            dict(move('taimanovMove', TAIM, 'draw', 'Nd3 h4 Nf4 Kg5 Ke5', ['hold'] * 3),
                 ref='fischerTaimanov'),
        ]},
        {'id': 'transform', 'steps': [
            think('t_greco', GRECO, 2, side='black', marks=['h8'], ref='wikiWrongRookPawn'),
            talk('greco', GRECO, side='black', marks=['h8'], arrows=['f5h3'], ref='wikiWrongRookPawn'),
            demo('d_greco', GRECO, 'draw', 'Bh3 gxh3 Kh6', {2: {'arrows': ['h6h8']}},
                 side='black'),
            talk('karpovKasparov', KK, side='black', marks=['h8'], arrows=['f7b3'], ref='karpovKasparov'),
            dict(move('quizKnight', QUIZ3, 'draw', 'Ne5+ Kf6 Nxg6 Kxg6 Kf1', ['hold'] * 3),
                 ref='ibmmQuiz3'),
        ]},
        {'id': 'shift', 'steps': [
            think('t_shift', SHIFT, 2, marks=['a1'], ref='ibmmPractice'),
            talk('shift', SHIFT, marks=['a1', 'b5'], arrows=['d1a4'], ref='ibmmPractice'),
            demo('d_shift', SHIFT, 'draw', 'Ba4 bxa4 Kc2 a3 Kb1', {4: {'marks': ['a1']}}),
            talk('shiftWrong', SHIFTB, side='white', marks=['b1'], arrows=['a6b5'], ref='ibmmQuiz4'),
            dict(move('shiftMove', SHIFT, 'draw', 'Ba4 Kc5 Bxb5 Kxb5 Kc2', ['hold'] * 3),
                 ref='ibmmPractice'),
        ]},
        {'id': 'prison', 'steps': [
            think('t_prison', PRISON, 2, marks=['h7', 'g7', 'g8']),
            talk('prison', PRISON, marks=['g8', 'h7', 'g7'], arrows=['d3c4']),
            demo('d_prison', PRISON, 'win', 'Bc4 Bc3 Kf5 Bb2 Ke6 Bc3 Kf7',
                 {0: {'arrows': ['c4g8']}, 6: {'marks': ['g8', 'g7']}}),
            move('prisonMove', PRISON2, 'win', 'Bc4 Bb2 Kf5 Bc3 Ke6', ['win'] * 3),
        ]},
        {'id': 'summary', 'steps': [
            talk('recap', CORNER, marks=['h8']),
            talk('rules', CUT, marks=['g8', 'h8'], arrows=['d3c4']),
            talk('rules3', GRECO, side='black', marks=['h3', 'h8']),
            {'type': 'play', 'id': 'finish', 'fen': FINISH, 'goal': 'draw'},
        ]},
    ],
    'exercises': [],
    'passScore': 9,
    'keyPositions': [
        {'id': 'corner', 'fen': CORNER, 'ref': 'ibmm'},
        {'id': 'rightBishop', 'fen': RIGHT},
        {'id': 'aPawn', 'fen': APAWN, 'ref': 'wikiFortress'},
        {'id': 'cutoff', 'fen': CUT},
        {'id': 'mednis', 'fen': MEDNIS, 'ref': 'wikiWrongRookPawn'},
        {'id': 'fischerTaimanov', 'fen': TAIM, 'ref': 'fischerTaimanov'},
    ],
    'practice': {'fen': CUT2, 'goal': 'win', 'positionId': None},
    'references': [
        {'id': 'ibmm', 'kind': 'study', 'author': 'ibmm', 'title': 'ChessNetwork #17: What is a Wrong Colored Bishop?', 'url': 'https://lichess.org/study/gHNmrart'},
        {'id': 'ibmmPractice', 'kind': 'study', 'author': 'ibmm', 'title': 'ChessNetwork #17: Is this a draw? (practice)', 'url': 'https://lichess.org/study/gHNmrart/oZbVF2m3'},
        {'id': 'ibmmQuiz3', 'kind': 'study', 'author': 'ibmm', 'title': 'ChessNetwork #17: Quiz 3', 'url': 'https://lichess.org/study/gHNmrart/FQvKy8Oh'},
        {'id': 'ibmmQuiz4', 'kind': 'study', 'author': 'ibmm', 'title': 'ChessNetwork #17: Quiz 4', 'url': 'https://lichess.org/study/gHNmrart/Ht0RaVus'},
        {'id': 'studier', 'kind': 'study', 'author': 'TheStudier', 'title': 'Endings: Wrong Colored Bishop (ChessNetwork)', 'url': 'https://lichess.org/study/yed13sFE'},
        {'id': 'graupera', 'kind': 'study', 'author': 'ps503graupera', 'title': 'Pawn and Wrong Color Bishop Endings!', 'url': 'https://lichess.org/study/roslBBZl'},
        {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky', 'title': "Dvoretsky's Endgame Manual (5ª edição, revista por Karsten Müller)", 'publisher': 'Russell Enterprises', 'year': 2020, 'where': "cap. 4, 'Bishop versus Pawns': 'Bishop and Rook Pawn', p. 92 (visto no sumário)"},
        {'id': 'fce', 'kind': 'book', 'author': 'Karsten Müller e Frank Lamprecht', 'title': 'Fundamental Chess Endings', 'publisher': 'Gambit', 'year': 2001, 'where': "4.1 C, 'Wrong Rook's Pawn', p. 98 (visto no sumário)"},
        {'id': 'wikiWrongRookPawn', 'kind': 'web', 'title': 'Wikipedia: Wrong rook pawn', 'url': 'https://en.wikipedia.org/wiki/Wrong_rook_pawn'},
        {'id': 'wikiWrongBishop', 'kind': 'web', 'title': 'Wikipedia: Wrong bishop', 'url': 'https://en.wikipedia.org/wiki/Wrong_bishop'},
        {'id': 'wikiFortress', 'kind': 'web', 'title': 'Wikipedia: Fortress (chess)', 'url': 'https://en.wikipedia.org/wiki/Fortress_(chess)'},
        {'id': 'fischerTaimanov', 'kind': 'game', 'white': 'Bobby Fischer', 'black': 'Mark Taimanov', 'event': 'Candidatos, Vancouver (partida 2)', 'year': 1971, 'url': URL_FT},
        {'id': 'karpovKasparov', 'kind': 'game', 'white': 'Anatoly Karpov', 'black': 'Garry Kasparov', 'event': 'Campeonato mundial, Moscou (partida 20)', 'year': 1985, 'url': URL_KK},
        {'id': 'olaffo', 'kind': 'study', 'author': 'Olaffo', 'title': 'Wrong Bishop: A', 'url': 'https://lichess.org/study/nUe9N3D2'},
        {'id': 'perdomod', 'kind': 'study', 'author': 'perdomod', 'title': 'Wrong Bishop: A', 'url': 'https://lichess.org/study/SxoBxSv7'},
        {'id': 'tablebase', 'kind': 'tablebase', 'title': 'Lichess tablebase (Syzygy)', 'url': 'https://tablebase.lichess.ovh'},
    ],
}

EX = [
    # T58: e01-e08, e10 e e11 saíram (repetiam a lição ou outro exercício). Ids cortados não voltam.
    ('e12', 1, '8/8/8/8/p7/k7/b2K4/8 w', 'draw', 'olaffo', 'Kc2 Bb3+ Kb1', ['hold'] * 2),
    ('e09', 2, '6k1/8/6PP/5K2/2B5/2b5/8/8 b', 'draw', 'wikiWrongRookPawn', 'Kf8', ['hold']),
    ('e13', 2, '8/4K3/8/6k1/6B1/7P/8/8 w', 'win', 'olaffo', 'Kf7 Kh6 Kg8', ['win'] * 2),
    ('e14', 2, 'k7/8/PpK5/8/P7/4B3/8/8 b', 'draw', 'perdomod', 'Kb8 Bxb6 Ka8', ['hold'] * 2),
    ('e15', 2, '8/8/1p2k3/3b4/P7/8/8/6KB w', 'draw', 'perdomod', 'a5 bxa5 Kf2', ['hold'] * 2),
    ('e16', 3, '1K6/4b3/7p/P7/k7/8/8/8 w', 'draw', 'perdomod', 'a6 Bc5 Kc7 h5 Kc6', ['hold'] * 3),
    ('e17', 3, '3B1b2/6pp/8/8/8/8/2k5/1N5K w', 'draw', 'perdomod', 'Nd2 Kxd2 Bg5+ Kd1 Bh6', ['hold'] * 3),
]
for id_, st, fen, goal, origin, sans, acc in EX:
    m = move(id_, F(fen), goal, sans, acc)
    src['exercises'].append({'id': id_, 'stars': st, 'fen': F(fen), 'goal': goal,
                             'origin': origin, 'turns': m['turns']})

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print('estrelas:', sum(e['stars'] for e in src['exercises']), 'mínimo:', src['passScore'])
