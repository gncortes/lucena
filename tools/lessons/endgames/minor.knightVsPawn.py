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


def think(id_, fen, hints, **extra):
    step = {'type': 'think', 'id': id_, 'fen': fen, 'hints': hints,
            'ask': 'plan'}
    step.update(extra)
    return step


def talk(id_, fen, **extra):
    step = {'type': 'talk', 'id': id_, 'fen': fen}
    step.update(extra)
    return step


def with_ref(step, ref):
    step['ref'] = ref
    return step


# Posições-base (todas conferidas na tabela do Lichess).
FRONT = F('8/K7/8/8/8/1k6/1N1p4/8 w')          # pepellou: só Cd1
FRONT_MOVE = F('7K/8/8/1N6/8/4k3/3p4/8 w')     # própria: só Cc3
SIDE = F('8/8/8/8/5N2/8/2p4K/2k5 w')           # pepellou: só Ce2+
SIDE_MOVE = F('7K/8/8/8/8/5N2/2p1k3/8 w')      # própria: só Cd4+
AVERBAKH = F('8/6K1/8/5N2/1p6/3k4/8/8 w')      # Averbakh: só Cd6
RETREAT = F('8/8/2K5/8/6p1/4k2N/8/8 w')        # própria: só Cg5 (o recuo)
ROOK = F('K7/8/8/5N2/8/7p/8/3k4 w')            # estudo aBGuQdGP: só Ce3+
GRIG = F('8/8/K7/8/2N4p/5k2/8/8 w')            # Grigoriev: só Ce5+
TWO_C = F('7K/8/8/3N4/1p6/2p5/8/k7 w')         # própria: só Cxb4
TWO_S = F('8/8/8/8/1p6/6kp/8/K2N4 w')          # própria: só Ce3
DVORETSKY = F('8/1K6/8/8/8/3k2N1/7p/8 b')      # Dvoretsky: empate
DVORETSKY_W = F('8/1K6/8/8/3k4/6N1/7p/8 w')    # depois de 1...Rd4: Rc6/Rb6
SAC = F('8/8/8/N7/p7/2k5/8/4K3 w')             # própria: só Cc4
STAMMA = F('8/8/8/8/8/p2N4/k1K5/8 w')          # Stamma: só Cb4+
NOGUEIRAS = F('8/3N4/8/8/8/p7/k2K4/8 w')       # Nogueiras–Gongora: só Rc2
NOGUEIRAS_81 = '8/3N4/8/8/8/p7/k2K4/8 w - - 0 81'   # a mesma, lance real
KOST_POLGAR = '8/6K1/4N2P/8/8/8/4pk2/8 w - - 0 78'  # Kosteniuk–Polgar: só Cf4
FINISH = F('7K/8/2N5/8/8/8/2p1k3/8 w')         # própria: só Cd4+

src = {
    'id': 'minor.knightVsPawn',
    'module': 'minor',
    'skills': ['minor.knightVsPawn'],
    'parts': [
        {'id': 'front', 'steps': [
            think('t_front', FRONT, 2, marks=['d2'],
                  ref='studyFrontChapter'),
            talk('frontWhy', FRONT, marks=['d1', 'e3', 'f2'],
                 arrows=['b2d1']),
            demo('d_front', FRONT, 'draw',
                 'Nd1 Kc2 Nf2 Kc3 Kb6 Kd4 Kb5 Ke3 Nd1+',
                 {0: {'marks': ['d1']}, 2: {'arrows': ['f2d1']},
                  8: {'marks': ['d1']}}),
            move('frontMove', FRONT_MOVE, 'draw', 'Nc3 Kd3 Nd1',
                 ['hold', 'hold']),
        ]},
        {'id': 'side', 'steps': [
            think('t_side', SIDE, 2, marks=['c1', 'c2'],
                  ref='studySideChapter'),
            talk('sideWhy', SIDE, arrows=['f4e2', 'e2d4'],
                 marks=['c2', 'b3']),
            demo('d_side', SIDE, 'draw',
                 'Ne2+ Kd2 Nd4 c1=Q Nb3+',
                 {2: {'marks': ['c2', 'b3']},
                  4: {'arrows': ['b3c1', 'b3d2']}}),
            talk('kostPolgar', KOST_POLGAR, marks=['e2', 'e1'],
                 ref='kosteniukPolgar'),
            with_ref(move('kpgMove', KOST_POLGAR, 'win',
                          'Nf4 e1=Q Nd3+ Ke2 Nxe1', ['win'] * 3),
                     'kosteniukPolgar'),
        ]},
        {'id': 'knightPawn', 'steps': [
            think('t_averbakh', AVERBAKH, 2, marks=['b1'],
                  ref='studyAverbakhChapter'),
            talk('averbakhWhy', AVERBAKH, arrows=['f5d6', 'd6b5', 'b5a3'],
                 marks=['a3', 'b1']),
            demo('d_averbakh', AVERBAKH, 'draw',
                 'Nd6 b3 Nb5 b2 Na3 Kc3 Nb1+',
                 {4: {'arrows': ['a3b1']}, 6: {'marks': ['b1']}}),
            talk('retreatWhy', RETREAT, marks=['f2', 'f4', 'g1']),
            move('retreatMove', RETREAT, 'draw', 'Ng5 g3 Nh3 g2 Ng1',
                 ['hold'] * 3),
        ]},
        {'id': 'rookPawn', 'steps': [
            think('t_rook', ROOK, 2, marks=['h2', 'h1'],
                  ref='studyRookPawn'),
            talk('rookWhy', ROOK, marks=['g4', 'f1', 'h2'],
                 arrows=['f5e3']),
            demo('d_rook', ROOK, 'draw', 'Ne3+ Ke2 Ng4 Kf3 Nh2+',
                 {2: {'marks': ['h2']}, 4: {'marks': ['h2']}}),
            talk('grigorievWhy', GRIG, marks=['g4', 'f1', 'h2'],
                 ref='studyGrigorievChapter'),
            with_ref(move('grigMove', GRIG, 'draw',
                          'Ne5+ Kg3 Nc4 h3 Ne3 h2 Nf1+', ['hold'] * 4),
                     'studyGrigorievChapter'),
        ]},
        {'id': 'twoPawns', 'steps': [
            think('t_two', TWO_C, 2, marks=['b4', 'c3']),
            talk('twoWhy', TWO_C, arrows=['d5b4', 'b4c2'],
                 marks=['c2']),
            demo('d_two', TWO_C, 'draw', 'Nxb4 c2 Nxc2+',
                 {0: {'marks': ['c2']}}),
            talk('twoApart', TWO_S, marks=['b4', 'h3']),
            move('twoMove', TWO_S, 'draw', 'Ne3 h2 Nf1+ Kf2 Nxh2 b3 Kb2',
                 ['hold'] * 4),
        ]},
        {'id': 'king', 'steps': [
            think('t_king', DVORETSKY_W, 2, marks=['f2', 'h1'],
                  ref='studyDvoretskyChapter'),
            talk('kingWhy', DVORETSKY_W, arrows=['b7c6'],
                 marks=['f2', 'h1']),
            demo('d_king', DVORETSKY_W, 'draw',
                 'Kc6 Ke5 Kc5 Kf4 Nh1 Kf3 Kd4 Kg2 Ke3 Kxh1 Kf2',
                 {4: {'marks': ['h1']}, 10: {'marks': ['h1', 'h2']}}),
            talk('sacWhy', SAC, marks=['a3', 'b2']),
            move('sacMove', SAC, 'draw', 'Nc4 Kxc4 Kd1 a3 Kc1 a2 Kb2',
                 ['hold'] * 4),
        ]},
        {'id': 'mate', 'steps': [
            think('t_nogueiras', NOGUEIRAS_81, 2, marks=['a3'],
                  ref='nogueirasGongora'),
            talk('stammaWhy', NOGUEIRAS_81, marks=['b1', 'b2', 'b3'],
                 arrows=['d2c2'], ref='nogueirasGongora'),
            with_ref(demo('d_nogueiras', NOGUEIRAS_81, 'win',
                          'Kc2 Ka1 Nc5 Ka2 Nd3 Ka1 Nc1',
                          {2: {'marks': ['b3']}, 6: {'marks': ['a2']}}),
                     'nogueirasGongora'),
            with_ref(move('stammaMove', STAMMA, 'win', 'Nb4+ Ka1 Kc1 a2 Nc2#',
                          ['win'] * 3),
                     'wikiCheckmate'),
        ]},
        {'id': 'recap', 'steps': [
            talk('recap', FINISH, marks=['c1', 'b3']),
            talk('recapEdge', ROOK, marks=['h1', 'h2']),
            move('recapMove', SIDE_MOVE, 'draw', 'Nd4+ Kd2 Nb3+ Kc3 Nc1',
                 ['hold', ['d4b3', 'd4c2'], 'hold']),
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
        {'id': 'studyFrontChapter', 'kind': 'study', 'author': 'pepellou',
         'title': 'Knight vs pawn: Pawn in 7th rank',
         'url': 'https://lichess.org/study/PNsWZZfX/nmQ1qIVz'},
        {'id': 'studySideChapter', 'kind': 'study', 'author': 'pepellou',
         'title': 'Knight vs pawn: Lateral control',
         'url': 'https://lichess.org/study/PNsWZZfX/ZIW9MEby'},
        {'id': 'studyPerdomod', 'kind': 'study', 'author': 'perdomod',
         'title': '1.3.16 Knight Against Pawn',
         'url': 'https://lichess.org/study/eSQ6WCtQ'},
        {'id': 'studyAverbakhChapter', 'kind': 'study', 'author': 'perdomod',
         'title': '1.3.16 Knight Against Pawn: Y. Averbakh',
         'url': 'https://lichess.org/study/eSQ6WCtQ/CNI1jMBs'},
        {'id': 'studyGrigorievChapter', 'kind': 'study', 'author': 'perdomod',
         'title': '1.3.16 Knight Against Pawn: N. Grigoriev',
         'url': 'https://lichess.org/study/eSQ6WCtQ/8GFReR3K'},
        {'id': 'studyDvoretskyChapter', 'kind': 'study', 'author': 'perdomod',
         'title': '1.3.16 Knight Against Pawn: M. Dvoretsky',
         'url': 'https://lichess.org/study/eSQ6WCtQ/18HsOEp6'},
        {'id': 'studyRookPawn', 'kind': 'study', 'author': 'lePILo',
         'title': "Knight versus rook's pawn (capítulo 2)",
         'url': 'https://lichess.org/study/aBGuQdGP/mZoDwW40'},
        {'id': 'studyBijbrengen', 'kind': 'study', 'author': 'Bijbrengen',
         'title': 'Knight versus Pawn',
         'url': 'https://lichess.org/study/a7BtTngR'},
        {'id': 'studyKosteniukPolgar', 'kind': 'study', 'author': 'Bijbrengen',
         'title': 'Knight versus Pawn: Alexandra Kosteniuk - Judit Polgar',
         'url': 'https://lichess.org/study/a7BtTngR/OoxUq1Hx'},
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
         'white': 'Jesús Nogueiras', 'black': 'Maikel Gongora Reyes',
         'event': 'Campeonato Cubano, Las Tunas', 'year': 2001,
         'url': 'https://lichess.org/analysis/pgn/c4_e5_Nc3_d6_d4_exd4_Qxd4_Nc6_Qd1_g6_e4_Bg7_Bd3_Nf6_Nge2_Ng4_f3_Nge5_O-O_Be6_b3_Nxd3_Qxd3_Qd7_Bb2_O-O-O_Qd2_f5_exf5_Bxf5_Ng3_Bd4+_Kh1_Qg7_Rad1_Be5_Ba1_h5_Nd5_Bxa1_Rxa1_h4_Nxf5_gxf5_h3_Ne5_f4_Nc6_Rae1_Rde8_Rxe8+_Rxe8_Re1_Qh8_Qf2_Rxe1+_Qxe1_a5_Kh2_Kb8_Qc3_Qd4_Qxd4_Nxd4_g4_c6_Ne7_Kc7_Ng6_b5_Nxh4_a4_Nxf5_Nxb3_cxb5_cxb5_g5_Nc5_g6_Ne4_g7_Nf6_Ne7_Kd7_Nd5_Ng8_f5_Ke8_Nc7+_Kf7_Nxb5_d5_Kg3_Kxg7_Kf4_Kf6_h4_Ne7_Nd4_Ng8_Ne2_Ne7_Ng3_a3_h5_Ng8_Nf1_Nh6_Ne3_d4_Nd5+_Kf7_Kg5_Kg7_f6+_Kh7_Kf4_Nf7_Ke4_Kh6_Kxd4_Kxh5_Nb6_Kg6_Nd7_Nh6_Kd5_Kf7_Ke5_Ng4+_Kf5_Ne3+_Kg5_Nc4_Kf5_Ne3+_Kf4_Nd5+_Kg5_Ke6_Nc5+_Kf7_Ne4_Ke6_Kg6_Nf4+_Kh6_Nd5_Kg5_Nxf6_Nxf6_Ke5_Nd7+_Kd4_Kf4_Kc3_Ke3_Kb2_Kd2_Kxa2_Kc2_Ka1_Nc5_Ka2_Nd3_Ka1_Nc1#160'},
        {'id': 'chessgamesNogueiras', 'kind': 'web',
         'title': 'Chessgames.com: Jesus Nogueiras vs Maikel Gongora Reyes, '
                  'ch-CUB 2001 (PGN da partida)',
         'url': 'https://www.chessgames.com/perl/chessgame?gid=1218922'},
        {'id': 'kosteniukPolgar', 'kind': 'game',
         'white': 'Alexandra Kosteniuk', 'black': 'Judit Polgar',
         'event': 'Campeonato Mundial de Blitz, Moscou', 'year': 2009,
         'url': 'https://lichess.org/analysis/pgn/e4_c5_Nf3_e6_d4_cxd4_Nxd4_a6_Nc3_Nc6_Be2_Qc7_O-O_b5_Re1_Bb7_Nxc6_dxc6_Bf3_Bd6_g3_Ne7_Qe2_Be5_Bg2_c5_Be3_Bd4_Nd1_O-O_c3_Bxe3_Nxe3_Rad8_a4_c4_axb5_axb5_Nc2_Rd7_Nd4_Qb6_e5_Bxg2_Kxg2_Nc6_Nf3_Rd3_Qe4_h6_Ra2_Rfd8_Rea1_Qc5_Ra6_Ne7_Ra8_g6_R1a7_Qc6_Rxd8+_Rxd8_Qh4_Rd3_Qf6_Rd7_Rxd7_Qxd7_Nd4_b4_h4_h5_Qf3_bxc3_bxc3_Qc7_Qe4_Nd5_Ne2_Qc5_Qb1_Ne7_Qb8+_Kg7_Qd6_Qxd6_exd6_Nc6_d7_Kf6_Nd4_Nd8_Nb5_Ke7_Na3_Kxd7_Nxc4_f6_Kf3_Kc6_Ke4_Kc5_Kd3_Nc6_Ne3_Ne5+_Ke4_Nf7_Kd3_Nd6_Nc2_e5_Ne3_g5_Ke2_Ne4_c4_Nd6_Nd5_Ne8_Ne3_Kd4_Nf5+_Kxc4_g4_Nc7_gxh5_Ne6_h6_Nf8_hxg5_fxg5_Kf3_Kd3_Kg4_Ke2_Kxg5_Kxf2_Kf6_e4_Kf7_Nh7_Kg6_Nf8+_Kg7_Ne6+_Kf6_Nf8_Nd4_e3_Kg7_Ne6+_Nxe6_e2_Nf4#154'},
        {'id': 'tablebase', 'kind': 'tablebase',
         'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

total = sum(e['stars'] for e in src['exercises'])
src['passScore'] = -(-total * 6 // 10)
OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print(OUT, 'estrelas', total, 'mínimo', src['passScore'])
