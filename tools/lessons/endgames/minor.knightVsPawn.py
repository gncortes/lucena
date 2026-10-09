"""Gera tools/lessons/endgames/minor.knightVsPawn.json (fonte da aula).

Rodar com o python do venv (python-chess):
    tools/.cache/venv/bin/python tools/lessons/endgames/minor.knightVsPawn.py
Depois: build_aula.py minor.knightVsPawn (confere tudo na tabela).
"""
import json
import pathlib

import chess

OUT = pathlib.Path(__file__).with_suffix('.json')


def F(s):
    return s + ' - - 0 1'


def uci(fen, sans):
    board = chess.Board(fen)
    out = []
    for san in sans.split():
        move = board.parse_san(san)
        out.append(move.uci())
        board.push(move)
    return out


def demo(id_, fen, goal, sans, notes=None, side=None):
    line = []
    for i, u in enumerate(uci(fen, sans)):
        entry = {'uci': u}
        if notes and i in notes:
            entry.update(notes[i])
        line.append(entry)
    step = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': goal, 'line': line}
    if side:
        step['side'] = side
    return step


def turns(fen, sans, accepts):
    """sans: lance do aluno, resposta, lance do aluno, resposta..."""
    us = uci(fen, sans)
    out = []
    for i in range(0, len(us), 2):
        turn = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us):
            turn['reply'] = us[i + 1]
        out.append(turn)
    return out


def move(id_, fen, goal, sans, accepts, side=None):
    step = {'type': 'move', 'id': id_, 'fen': fen, 'goal': goal,
            'turns': turns(fen, sans, accepts)}
    if side:
        step['side'] = side
    return step


def exercise(id_, stars, fen, goal, sans, accepts, origin='own'):
    return {'id': id_, 'stars': stars, 'fen': fen, 'goal': goal,
            'origin': origin, 'turns': turns(fen, sans, accepts)}


def think(id_, fen, minutes, hints, **extra):
    step = {'type': 'think', 'id': id_, 'fen': fen, 'minutes': minutes,
            'hints': hints, 'ask': 'plan'}
    step.update(extra)
    return step


def talk(id_, fen, **extra):
    step = {'type': 'talk', 'id': id_, 'fen': fen}
    step.update(extra)
    return step


# Posições-base (todas conferidas na tabela do Lichess).
FRONT = F('8/K7/8/8/8/1k6/1N1p4/8 w')          # pepellou: só Cd1
FRONT_MOVE = F('7K/8/8/1N6/8/4k3/3p4/8 w')     # própria: só Cc3
SIDE = F('8/8/8/8/5N2/8/2p4K/2k5 w')           # pepellou: só Ce2+
SIDE_MOVE = F('7K/8/8/8/8/5N2/2p1k3/8 w')      # própria: só Cd4+
AVERBAKH = F('8/6K1/8/5N2/1p6/3k4/8/8 w')      # Averbakh: só Cd6
KP_LOSS = F('8/8/8/8/4N3/1p6/7K/1k6 b')        # pepellou: só b2 ganha
KP_MOVE = F('K7/8/8/8/8/5k2/5Np1/8 w')         # própria: só Ch3
ROOK = F('K7/8/8/5N2/8/7p/8/3k4 w')            # estudo aBGuQdGP: só Ce3+
SEVENTH = F('K7/8/8/8/8/6k1/7p/6N1 w')         # própria: o cavalo perde
ROOK_MOVE = F('K7/8/8/4N3/8/7p/5k2/8 w')       # própria: só Cg4+
DVORETSKY = F('8/1K6/8/8/8/3k2N1/7p/8 b')      # Dvoretsky: empate
DVORETSKY_W = F('8/1K6/8/8/3k4/6N1/7p/8 w')    # depois de 1...Rd4
STAMMA = F('8/8/8/8/8/p2N4/k1K5/8 w')          # Stamma: só Cb4+
NOGUEIRAS = F('8/3N4/8/8/8/p7/k2K4/8 w')       # Nogueiras–Gongora: só Rc2
FINISH = F('7K/8/2N5/8/8/8/2p1k3/8 w')         # própria: só Cd4+

src = {
    'id': 'minor.knightVsPawn',
    'module': 'minor',
    'skills': ['minor.knightVsPawn'],
    'parts': [
        {'id': 'front', 'steps': [
            think('t_front', FRONT, 5, 2, marks=['d1']),
            talk('frontWhy', FRONT, marks=['d1', 'e3', 'f2'],
                 arrows=['b2d1']),
            demo('d_front', FRONT, 'draw',
                 'Nd1 Kc2 Nf2 Kc3 Kb6 Kd4 Kb5 Ke3 Nd1+ Ke2 Nb2 Ke3 Nc4+ '
                 'Ke2 Nxd2',
                 {0: {'marks': ['d1']}, 2: {'arrows': ['f2d1']},
                  8: {'marks': ['d1']}, 10: {'arrows': ['b2d1']},
                  14: {'marks': ['d2']}}),
            move('frontMove', FRONT_MOVE, 'draw', 'Nc3 Kd3 Nd1',
                 ['hold', 'hold']),
        ]},
        {'id': 'side', 'steps': [
            think('t_side', SIDE, 3, 2, marks=['c1', 'c2']),
            talk('sideWhy', SIDE, arrows=['f4e2', 'e2d4'],
                 marks=['c2', 'b3']),
            demo('d_side', SIDE, 'draw',
                 'Ne2+ Kd2 Nd4 c1=Q Nb3+ Kc2 Nxc1',
                 {2: {'marks': ['c2', 'b3']},
                  4: {'arrows': ['b3c1', 'b3d2']}}),
            talk('sideBehind', SIDE, arrows=['f4d3', 'd3c5'],
                 marks=['c5']),
            move('sideMove', SIDE_MOVE, 'draw', 'Nd4+ Kd2 Nb3+ Kc3 Nc1',
                 ['hold', 'hold', 'hold']),
        ]},
        {'id': 'knightPawn', 'steps': [
            think('t_averbakh', AVERBAKH, 3, 2, marks=['b1']),
            talk('averbakhWhy', AVERBAKH, arrows=['f5d6', 'd6b5', 'b5a3'],
                 marks=['a3', 'b1']),
            demo('d_averbakh', AVERBAKH, 'draw',
                 'Nd6 b3 Nb5 b2 Na3 Kc3 Nb1+ Kc2 Na3+ Kb3 Nb1',
                 {4: {'arrows': ['a3b1']}, 10: {'marks': ['b1']}}),
            talk('knightPawnLoss', KP_LOSS, side='white',
                 marks=['b1', 'a3', 'c3', 'd2']),
            move('kpMove', KP_MOVE, 'draw', 'Nh3 Kg3 Ng1',
                 ['hold', 'hold']),
        ]},
        {'id': 'rookPawn', 'steps': [
            think('t_rook', ROOK, 5, 2, marks=['h2', 'h1']),
            talk('rookWhy', ROOK, marks=['g4', 'f1', 'h2'],
                 arrows=['f5e3']),
            demo('d_rook', ROOK, 'draw',
                 'Ne3+ Ke2 Ng4 Kf3 Nh2+ Kg2 Ng4 Kg3 Ne3 Kf3 Nf1',
                 {2: {'marks': ['h2']}, 4: {'marks': ['h2']},
                  8: {'arrows': ['e3f1']}, 10: {'marks': ['h2']}}),
            talk('seventh', SEVENTH, marks=['h1', 'h3', 'f3', 'e2'],
                 arrows=['g3h2']),
            move('rookMove', ROOK_MOVE, 'draw', 'Ng4+ Kg3 Ne3 h2 Nf1+',
                 ['hold', 'hold', 'hold']),
        ]},
        {'id': 'king', 'steps': [
            think('t_king', DVORETSKY, 3, 2, side='white',
                  marks=['e2', 'e4', 'f2']),
            talk('kingWhy', DVORETSKY, side='white',
                 arrows=['b7f2'], marks=['e2', 'e4', 'f2']),
            demo('d_king', DVORETSKY, 'draw',
                 'Kd4 Kc6 Ke5 Kc5 Kf4 Nh1 Kf3 Kd4 Kg2 Ke3 Kxh1 Kf2',
                 {5: {'marks': ['h1']}, 11: {'marks': ['h1', 'h2']}},
                 side='white'),
            move('kingMove', DVORETSKY_W, 'draw',
                 'Kc6 Ke5 Kc5 Kf4 Nh1 Kf3 Kd4 Kg2 Ke3 Kxh1 Kf2',
                 ['hold'] * 6),
        ]},
        {'id': 'mate', 'steps': [
            think('t_stamma', STAMMA, 3, 2, marks=['a1', 'a2']),
            talk('stammaWhy', STAMMA, marks=['a1', 'b1', 'b2'],
                 arrows=['c2b1']),
            demo('d_stamma', STAMMA, 'win', 'Nb4+ Ka1 Kc1 a2 Nc2#',
                 {0: {'marks': ['a2']}, 4: {'marks': ['a1']}}),
            talk('nogueiras', NOGUEIRAS, marks=['a3', 'a2'],
                 arrows=['d2c2']),
            move('stammaMove', NOGUEIRAS, 'win',
                 'Kc2 Ka1 Nc5 Ka2 Nd3 Ka1 Nc1 a2 Nb3#',
                 ['win'] * 5),
        ]},
        {'id': 'recap', 'steps': [
            think('t_recap', FINISH, 1, 1, marks=['c1']),
            talk('recap', FINISH, marks=['c1', 'b3']),
            talk('recapEdge', ROOK, marks=['h1', 'h2', 'a1', 'a2']),
            {'type': 'play', 'id': 'finish', 'fen': FINISH, 'goal': 'draw'},
        ]},
    ],
    'exercises': [
        # 1★: a técnica do peão de cavalo, com o cavalo vindo de outro lado
        # (casas a4/b2, e não a3/b1 como na posição de Averbakh da lição).
        exercise('e11', 1, F('8/3N4/8/8/8/1p2k3/6K1/8 w'), 'draw',
                 'Nb6 Kd3 Na4 Kc4 Nb2+', ['hold'] * 3,
                 origin='studyPerdomod'),
        exercise('e10', 1, F('8/8/7N/8/8/p7/k1K5/8 w'), 'win',
                 'Nf5 Ka1 Nd4', ['win'] * 2),
        # 2★: dois peões; só um plano segura (deixar o g correr e tomar h3).
        exercise('e12', 2, F('8/8/6N1/8/8/4K1pp/8/7k w'), 'draw',
                 'Nf4 g2 Nxh3 Kh2 Kf2', ['hold'] * 3,
                 origin='studyBijbrengen'),
        exercise('e09', 2, F('4N2k/5K2/8/8/6p1/8/8/8 w'), 'draw',
                 'Nd6 g3 Kf8 g2 Nf7+ Kh7 Ng5+', ['hold'] * 4,
                 origin='studyPerdomod'),
        # 3★: estudos publicados.
        exercise('e13', 3, F('8/7p/K7/8/8/4k3/N7/8 w'), 'draw',
                 'Nb4 h5 Nc6 Ke4 Na5 Kf3 Nc4 h4 Ne5+ Kg3 Nc4',
                 ['hold'] * 6, origin='studyBijbrengen'),
        exercise('e14', 3, F('8/8/8/1N1k4/1p6/8/7K/8 w'), 'draw',
                 'Nc7+ Kc4 Ne8 Kd3 Nd6', ['hold'] * 3,
                 origin='studyBijbrengen'),
        exercise('e15', 3, F('8/4k2N/7p/1p6/8/8/K7/8 w'), 'draw',
                 'Ka3 Kf7 Kb4 Kg6 Nf8+ Kf5 Nd7 h5 Nc5 Kg4 Kxb5',
                 ['hold'] * 6, origin='studyBijbrengen'),
        exercise('e16', 3, F('7N/2K5/8/8/7p/2k5/8/8 w'), 'draw',
                 'Nf7 Kd4 Ng5 Ke3 Kd6 Kf4 Nh3+ Kg3 Ng1 Kg2 Ne2 Kf3 Ke5',
                 ['hold'] * 7, origin='studyBijbrengen'),
    ],
    'keyPositions': [
        {'id': 'front', 'fen': FRONT, 'ref': 'studyPepellou'},
        {'id': 'side', 'fen': SIDE, 'ref': 'studyPepellou'},
        {'id': 'averbakh', 'fen': AVERBAKH, 'ref': 'studyPerdomod'},
        {'id': 'rookPawn', 'fen': ROOK, 'ref': 'studyRookPawn'},
        {'id': 'grigoriev', 'fen': F('8/8/K7/8/2N4p/5k2/8/8 w'),
         'ref': 'studyPerdomod'},
        {'id': 'dvoretsky', 'fen': DVORETSKY, 'ref': 'studyPerdomod'},
        {'id': 'stamma', 'fen': STAMMA, 'ref': 'wikiCheckmate'},
        {'id': 'nogueiras', 'fen': NOGUEIRAS, 'ref': 'nogueirasGongora'},
    ],
    'practice': {'fen': FINISH, 'goal': 'draw', 'positionId': None},
    'references': [
        {'id': 'delaVilla', 'kind': 'book', 'author': 'Jesús de la Villa',
         'title': '100 Endgames You Must Know (4ª edição)',
         'publisher': 'New In Chess', 'year': 2015,
         'where': 'cap. 3, "Knight vs. Pawn", Endings 10–15, pp. 51–58 '
                  '(sumário da amostra da editora)'},
        {'id': 'studyPepellou', 'kind': 'study',
         'author': 'Sunayana_007 (capítulos de pepellou)',
         'title': 'Knight against pawn',
         'url': 'https://lichess.org/study/PNsWZZfX'},
        {'id': 'studyPerdomod', 'kind': 'study', 'author': 'perdomod',
         'title': '1.3.16 Knight Against Pawn',
         'url': 'https://lichess.org/study/eSQ6WCtQ'},
        {'id': 'studyRookPawn', 'kind': 'study', 'author': 'lePILo',
         'title': "Knight versus rook's pawn",
         'url': 'https://lichess.org/study/aBGuQdGP'},
        {'id': 'studyBijbrengen', 'kind': 'study', 'author': 'Bijbrengen',
         'title': 'Knight versus Pawn',
         'url': 'https://lichess.org/study/a7BtTngR'},
        {'id': 'wikiKnight', 'kind': 'web',
         'title': 'Wikipedia: Knight (chess)',
         'url': 'https://en.wikipedia.org/wiki/Knight_(chess)'},
        {'id': 'wikiCheckmate', 'kind': 'web',
         'title': "Wikipedia: Checkmate (Stamma's mate)",
         'url': 'https://en.wikipedia.org/wiki/Checkmate#Stamma%27s_mate'},
        {'id': 'wikiStamma', 'kind': 'web',
         'title': 'Wikipedia: Philipp Stamma',
         'url': 'https://en.wikipedia.org/wiki/Philipp_Stamma'},
        {'id': 'nogueirasGongora', 'kind': 'game',
         'white': 'Jesús Nogueiras', 'black': 'Maikel Gongora',
         'event': 'Campeonato Cubano (citada pela Wikipedia)',
         'year': 2001},
        {'id': 'tablebase', 'kind': 'tablebase',
         'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

total = sum(e['stars'] for e in src['exercises'])
src['passScore'] = -(-total * 6 // 10)
OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print(OUT, 'estrelas', total, 'mínimo', src['passScore'])
