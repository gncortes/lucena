"""Gera tools/lessons/endgames/mates.twoKnightsPawn.json (fonte da aula).

Rodar com o python do venv (python-chess):
    tools/.cache/venv/bin/python tools/lessons/endgames/mates.twoKnightsPawn.py
Depois: build_aula.py mates.twoKnightsPawn (confere tudo na tabela).

O mate inteiro de dois cavalos contra peão pode passar de cem lances; a aula
ensina por etapas curtas (o porquê, a posição de Troitsky, a linha, o rei no
canto, soltar o bloqueio, o zugzwang, o triângulo do rei, o canto certo das
pretas), cada uma a partir de uma
posição já perto do fim. Todas as posições foram conferidas na tabela do
Lichess (ver docs/aulas/mates.twoKnightsPawn.md).
"""
import json
import pathlib

import chess

OUT = pathlib.Path(__file__).with_suffix('.json')

# As oito casas da linha de Troitsky (peão preto, cavalos brancos).
LINE = ['a4', 'b6', 'c5', 'd4', 'e4', 'f5', 'g6', 'h4']


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


def demo(id_, fen, goal, sans, notes=None, side=None, **extra):
    line = []
    for i, u in enumerate(uci(fen, sans)):
        entry = {'uci': u}
        if notes and i in notes:
            entry.update(notes[i])
        line.append(entry)
    step = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': goal, 'line': line}
    if side:
        step['side'] = side
    step.update(extra)
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


def think(id_, fen, hints, ask='plan', **extra):
    step = {'type': 'think', 'id': id_, 'fen': fen,
            'hints': hints, 'ask': ask}
    step.update(extra)
    return step


def talk(id_, fen, **extra):
    step = {'type': 'talk', 'id': id_, 'fen': fen}
    step.update(extra)
    return step


# Posições-base (todas conferidas na tabela do Lichess).
HELP = F('8/5K1k/8/5N2/8/3p4/3N4/8 w')        # Wikipedia: só Ce4 ou Cf3
TWO_PAWNS = F('7k/5K2/8/5N2/8/3p4/3p4/5N2 w')  # própria: só Cxd2 ganha
TROITSKY = F('7k/5K2/8/5N2/8/3p4/3N4/8 w')     # Troitsky: zugzwang recíproco
ZZ_THINK = F('7k/8/5K2/5N2/8/3p4/3N4/8 w')     # própria: só Rf7 (Troitsky, pretas jogam)
ZZ_MOVE = F('7k/8/4NK2/8/8/3p4/3N4/8 w')       # depois do erro 6...Rh8?
RE_BLOCK = F('8/5K1k/8/5N2/3p4/8/8/1N6 w')     # própria: só Cd2 (1...d3 dá HELP)
LINE_THINK = F('7k/3N4/6p1/8/5K2/7N/8/8 w')    # própria: só Cg5
LINE_TALK = F('7k/3N4/6p1/6N1/5K2/8/8/8 b')    # depois de Cg5
LINE_MOVE = F('8/8/6k1/5p2/8/6NN/6K1/8 w')     # própria: só Cf4+
DRIVE = F('6k1/8/6p1/4K1N1/4N3/8/8/8 w')       # própria: o rei vai a h8
DRIVE_MOVE = F('1k6/8/1p6/1N1K4/3N4/8/8/8 w')  # a de cima espelhada
RELEASE = F('8/4K1k1/6p1/6N1/6N1/8/8/8 w')     # DRIVE depois de 12 meios-lances
SEITZ = F('8/8/8/5n2/5P2/4n1k1/8/6K1 b')       # Znosko-Borovsky–Seitz, ply 185
HK = F('8/8/8/8/3p4/1K1N4/8/1k4N1 w')          # Horwitz e Kling, 1851
TRI = F('1k2N3/1p6/1N6/1K6/8/8/8/8 w')        # própria: triângulo do rei
TRI_MOVE = F('3N2k1/6p1/6N1/6K1/8/8/8/8 w')    # a de cima espelhada
AVERBAKH = F('8/8/3N2k1/4K3/8/7p/7N/8 w')      # Averbakh e Chekhover, 1977
CORNER = F('8/8/3NK1k1/8/8/7p/7N/8 b')         # a de cima depois de 1.Re6
KARPOV_DEMO = F('8/8/8/8/2N3p1/2K3N1/8/2k5 w')  # Topalov–Karpov, ply 140
KARPOV = F('8/8/8/8/6p1/1K1N4/4N3/1k6 b')      # Topalov–Karpov, ply 147
CURSED = F('8/8/4k3/8/1NN1p3/8/2K5/8 w')       # estudo gZKdpt9k: só depois de 50
RULES = F('6k1/8/6p1/4K3/4NN2/8/8/8 w')        # própria
PLAY = F('7k/8/6p1/4K3/4NN2/8/8/8 w')          # própria: o mate inteiro
PRACTICE = F('6k1/6p1/8/4K3/4NN2/8/8/8 w')     # estudo Q21ch5MW

URL_SEITZ = 'https://lichess.org/analysis/pgn/e4_c5_Nc3_Nc6_g3_g6_Bg2_Bg7_Nge2_d6_d3_Nf6_O-O_O-O_h3_Bd7_Kh2_Rb8_Be3_h6_Qd2_Kh7_Nd1_b5_f4_Ng8_e5_Qc7_exd6_Qxd6_Nec3_f5_a4_a6_axb5_axb5_Ra6_e6_Qf2_Bd4_Bxd4_cxd4_Ne2_Nge7_Nxd4_Qxd4_Qxd4_Nxd4_Rd6_Nxc2_Rxd7_Rfe8_Rf2_Nb4_Re2_Rbd8_Rxd8_Rxd8_Rxe6_Ng8_Re2_Rxd3_Nc3_Nf6_Nxb5_h5_Bf1_Kh6_Nc3_h4_Rg2_hxg3+_Rxg3_Rd4_Ne2_Rd2_Rb3_Nd3_Kg3_Ne4+_Kf3_Ne1+_Ke3_Nc2+_Kf3_Rxe2_Kxe2_Nd4+_Kd3_Nxb3_Kc2_Nd4+_Kd3_Ne6_Ke3_Kg7_b4_Kf6_Bd3_Nd6_Be2_Nc8_h4_Nb6_Bf3_Ke7_h5_gxh5_Bxh5_Nd5+_Kf3_Nd4+_Kg3_Nxb4_Bg6_Ke6_Kf2_Nd5_Ke1_Nf3+_Kd1_Nh4_Bxf5+_Nxf5_Kd2_Nf6_Kc3_Kd5_Kb4_Kc6_Kc4_Ne4_Kb4_Ned6_Kb3_Kc5_Kc3_Ne4+_Kd3_Kd5_Ke2_Kc4_Kf3_Nf6_Ke2_Kc3_Kd1_Ng4_Ke2_Nge3_Ke1_Kd3_Kf2_Nd5_Ke1_Nc3_Kf2_Ke4_Kf1_Kf3_Ke1_Ke3_Kf1_Nd1_Ke1_Nf2_Kf1_Nd3_Kg1_Ke2_Kg2_Nf2_Kg1_Ng4_Kg2_Nge3+_Kh2_Kf2_Kh3_Kf3_Kh2_Kg4_Kh1_Kg3_Kg1_Nh4_f5_Nf3+_Kh1_Nd1_f6_Nf2#185'
URL_KARPOV = 'https://lichess.org/analysis/pgn/d4_Nf6_c4_e6_Nf3_d5_Nc3_Be7_Bf4_O-O_e3_Nbd7_c5_c6_Bd3_b6_b4_a5_a3_Ba6_O-O_Qc8_h3_Bxd3_Qxd3_axb4_axb4_Qb7_Qc2_Rfc8_Rfb1_Bd8_Nd2_Rxa1_Rxa1_Ra8_Rxa8_Qxa8_Qa2_Qxa2_Nxa2_Ne8_Nb3_Nc7_cxb6_Nxb6_Na5_Nb5_Nxc6_Bf6_Kf1_Kf8_Ke2_Ke8_Kd3_Kd7_Na5_Be7_f3_Nc8_Kc2_h5_Kb3_Bd6_Bxd6_Ncxd6_g4_hxg4_hxg4_f5_Kc2_fxg4_fxg4_Ne4_Nb3_Nf6_Nc5+_Kd6_g5_Nh7_g6_Nf8_Kb3_Nxg6_Ka4_Na7_b5_Nc8_Ka5_e5_b6_Nxb6_Kxb6_exd4_exd4_Nh4_Nc3_Nf3_Nb5+_Ke7_Nd3_g5_Kc5_Ke6_Nc3_Kf5_Nf2_g4_Nh1_Kf4_Ne2+_Ke3_Nhg3_Kd3_Nf4+_Ke3_Nfe2_Kd3_Kxd5_Nxd4_Nxd4_Kc3_Kc5_Kd3_Nde2_Kd2_Kc4_Kc2_Nd4+_Kb2_Kb4_Ka2_Ndf5_Kb2_Ne3_Ka2_Nc4_Kb1_Kc3_Kc1_Nb2_Kb1_Nd3_Ka1_Kb3_Kb1_Ne2#147'
URL_WANG = 'https://lichess.org/analysis/pgn/d4_d5_c4_c6_Nf3_Nf6_e3_Bf5_Nc3_e6_Nh4_Be4_f3_Bg6_Qb3_Qc7_Bd2_Be7_Nxg6_hxg6_O-O-O_Nbd7_cxd5_exd5_e4_dxe4_fxe4_c5_Bc4_cxd4_Bxf7+_Kd8_Kb1_dxc3_Bxc3_Nxe4_Bxg7_Nc5_Qe3_Rh4_Rhe1_Re4_Qh3_Qf4_Qh8+_Kc7_Qxa8_Rxe1_Rxe1_Qxf7_Bc3_Qf5+_Ka1_Bf6_Qxa7_Bxc3_bxc3_Qf2_Qa5+_Kc6_Rb1_Qxg2_Qb5+_Kc7_Qa5+_b6_Qa7+_Nb7_Rd1_Qf3_Rc1_Qf4_Rd1_Nc5_Rb1_Qf6_Qa3_Ne4_Qb4_Nbc5_Qd4_Qf3_Qg7+_Nd7_Qd4_g5_Rd1_Ndc5_Rc1_Qf4_Rd1_Qxh2_Qg7+_Kc6_Qg6+_Kb7_Qf7+_Qc7_Qxc7+_Kxc7_Rg1_Nd3_Kb1_Ndf2_Kc2_g4_a4_g3_Kb3_Kc6_Kb4_Nd3+_Kc4_Ne5+_Kb4_Nf3_Rxg3_Nxg3_a5_bxa5+_Kxa5_Kc5_c4_Ne4_Ka4_Nd4_Ka5_Nc3_Ka6_Ne6_Kb7_Na4_Ka6_Nb6_Kb7_Nd7_Ka6_Nd8_Ka5_Nb6_Ka6_Kc6_c5_Nc4_Ka7_Ne6_Kb8_Nd8_Ka7_Nb7_Kb8_Na3_Ka7_Nb5+_Ka6_Nc3_Ka7_Nd5_Ka6_Nb4+_Ka7_Kc7_c6_Nc5_Ka8_Ne4_Ka7_Nd6_Ka8_Nxc6#121'

src = {
    'id': 'mates.twoKnightsPawn',
    'module': 'mates',
    'skills': ['mate.twoKnightsPawn'],
    'parts': [
        {'id': 'pawnHelps', 'steps': [
            think('t_help', HELP, 2, ask='line', marks=['h8', 'g8'],
                  ref='wikiTwoKnights'),
            talk('helpWhy', HELP, arrows=['d2e4', 'e4f6'], marks=['h8']),
            demo('d_help', HELP, 'win',
                 'Ne4 d2 Nf6+ Kh8 Ne7 d1=Q Ng6#',
                 {0: {'arrows': ['e4f6']}, 1: {'marks': ['d2']},
                  2: {'marks': ['g8', 'h7']}, 4: {'marks': ['g6']},
                  6: {'marks': ['h8']}}),
            talk('twoPawns', TWO_PAWNS, marks=['d2', 'd3']),
            move('captureMove', TWO_PAWNS, 'win',
                 'Nxd2 Kh7 Ne4 d2 Nf6+ Kh8 Ne7 d1=Q Ng6#',
                 ['only', 'best', 'best', 'best', 'only']),
        ]},
        {'id': 'line', 'steps': [
            think('t_line', LINE_THINK, 2, marks=['g6']),
            talk('lineWhy', LINE_THINK, arrows=['h3g5'], marks=LINE,
                 ref='wikiTwoKnights'),
            talk('kingBlock', LINE_THINK, arrows=['f4g5'], marks=['g5']),
            move('lineMove', LINE_MOVE, 'win', 'Nf4+', ['only']),
        ]},
        {'id': 'drive', 'steps': [
            think('t_drive', DRIVE, 2, marks=['g5', 'h8']),
            talk('driveWhy', DRIVE, arrows=['e5f6'],
                 marks=['g5', 'g6', 'f7', 'h7']),
            demo('d_drive', DRIVE, 'win',
                 'Kf6 Kf8 Nd6 Kg8 Ke7 Kg7 Ndf7 Kg8 Ne5 Kh8 Ng4 Kg7',
                 {0: {'marks': ['e7', 'f7']}, 2: {'arrows': ['d6f7']},
                  4: {'marks': ['f7', 'f8']}, 6: {'marks': ['h6', 'h8']},
                  10: {'marks': ['f6', 'h6']}}),
            move('driveMove', DRIVE_MOVE, 'win',
                 'Kc6 Kc8 Ne6 Kb8 Kd7',
                 ['best', 'best', 'best']),
        ]},
        {'id': 'release', 'steps': [
            think('t_release', RELEASE, 2, ask='line',
                  marks=['g5', 'g1']),
            talk('releaseWhy', RELEASE, arrows=['g5e6', 'g6g1'],
                 marks=['h8']),
            demo('d_seitz', SEITZ, 'win',
                 'Nh4 f5 Nf3+ Kh1 Nd1 f6 Nf2#',
                 {0: {'marks': ['f4']}, 2: {'marks': ['h1']},
                  4: {'arrows': ['d1f2'], 'marks': ['g1', 'g2', 'h2']},
                  6: {'marks': ['h1']}},
                 side='black', ref='gameSeitz#185'),
            move('releaseMove', RELEASE, 'win',
                 'Ne6+ Kh7 Kf7 Kh8 Nf6 g5 Nf8 g4 Ng6#',
                 ['only', 'best', 'best', 'best', 'only']),
        ]},
        {'id': 'zugzwang', 'steps': [
            think('t_zz', ZZ_THINK, 2, marks=['h8', 'd3'],
                  ref='wikiTwoKnights'),
            talk('zzWhy', ZZ_THINK, arrows=['f6f7'], marks=['h8', 'h7']),
            demo('d_zzDraw', TROITSKY, 'draw',
                 'Kf6 Kh7 Kf7 Kh8 Kg6 Kg8 Ng7 Kf8 Kf6 Kg8 Ne6 Kh7',
                 {11: {'marks': ['h7']}}, side='black',
                 ref='wikiTwoKnights'),
            move('zzMove', ZZ_MOVE, 'win',
                 'Kg6 Kg8 Ne4 Kh8 Nf6 d2 Ng5 d1=Q Nf7#',
                 ['only', 'only', 'best', 'best', 'only']),
            move('reBlock', RE_BLOCK, 'win', 'Nd2', ['only']),
        ]},
        {'id': 'triangle', 'steps': [
            think('t_tri', TRI, 2, marks=['b8', 'a7']),
            talk('triWhy', TRI, arrows=['b5a4', 'a4a5', 'a5b5'],
                 marks=['b5', 'a4', 'a5']),
            demo('d_tri', TRI, 'win', 'Ka4 Ka7 Ka5 Kb8 Kb5 Ka7 Nd7',
                 {0: {'marks': ['b6']}, 1: {'marks': ['a8', 'c8', 'c7']},
                  2: {'marks': ['b6']}, 4: {'marks': ['b5']},
                  6: {'marks': ['b7']}}),
            move('triMove', TRI_MOVE, 'win', 'Kh4 Kh7 Kh5 Kg8 Kg5',
                 ['only', 'only', 'only']),
        ]},
        {'id': 'corner', 'steps': [
            think('t_corner', CORNER, 2, ref='wikiTwoKnights'),
            talk('cornerWhy', CORNER, arrows=['g6g5'],
                 marks=['a8', 'b8', 'c8', 'd8', 'a7', 'b7', 'c7', 'd7',
                        'e7', 'a6', 'b6', 'c6', 'd6', 'e6', 'f6', 'b5',
                        'c5', 'd5', 'e5', 'f5', 'c4', 'd4', 'e4', 'f4']),
            demo('d_karpov', KARPOV_DEMO, 'win',
                 'Nb2 Kb1 Nd3 Ka1 Kb3 Kb1 Ne2',
                 {0: {'marks': ['d1', 'd3']}, 2: {'marks': ['c1', 'b2']},
                  4: {'marks': ['a2', 'b2']}, 6: {'marks': ['g4']}},
                 ref='gameTopalovKarpov#140'),
            move('cornerMove', CORNER, 'draw', 'Kg5 Ke5 Kg6',
                 ['hold', 'hold']),
        ]},
        {'id': 'summary', 'steps': [
            talk('rules', RULES, marks=LINE),
            talk('fifty', CURSED, marks=['e4', 'e3'], ref='studyJdiggy'),
            talk('playIntro', PLAY, marks=['g6']),
            {'type': 'play', 'id': 'finish', 'fen': PLAY, 'goal': 'win'},
        ]},
    ],
    'exercises': [
        exercise('e07', 1, F('5N1k/8/5K2/8/6N1/p7/8/8 w'), 'win',
                 'Kf7 a2 Ne5 a1=Q Neg6#', ['only', 'best', 'only']),
        # Topalov–Karpov, Monte Carlo 2000, depois de 65.Cd4+: Karpov foi
        # para b2 (perde); só Rd1 e Rd2 seguram.
        exercise('e12', 2, F('8/8/8/8/2KN2p1/6N1/2k5/8 b'), 'draw',
                 'Kd2', ['hold'], origin='gameTopalovKarpov'),
        # Wang Yue–Anand, Nice 2009 (às cegas), depois de 61.Rxa5: Anand
        # jogou 61...Rc5 (empata); Ce4 e Cd2 ganham.
        exercise('e11', 2, F('8/8/2k5/K7/8/2P2nn1/8/8 b'), 'win',
                 'Ne4', ['win'], origin='gameWangAnand'),
        exercise('e09', 3, F('8/5K2/6pk/3N4/4N3/8/8/8 w'), 'win',
                 'Ndf6 g5 Ng3 g4 Nfe4', ['best', 'only', 'only']),
        # Horwitz e Kling, 1851, depois de 1.Cgh4+ Rg1 2.Cf3+ Rh1 3.Re1 Rg2.
        exercise('e14', 3, F('8/8/8/5N2/8/5N1p/6kp/4K3 w'), 'win',
                 'Nxh2 Kxh2 Kf1 Kh1 Kf2 Kh2 Ne3 Kh1 Nf1 h2 Ng3#',
                 ['best', 'best', 'best', 'best', 'best', 'only'],
                 origin='wikiTwoKnights'),
        # Chéron, 1955: brancas jogam e passam a vez com o rei.
        exercise('e13', 3, F('8/8/8/8/2N5/6p1/k1K3N1/8 w'), 'win',
                 'Kc3 Kb1 Kd2 Ka1 Kc1 Ka2 Kc2',
                 ['best', 'best', 'best', 'best'], origin='wikiTwoKnights'),
    ],
    'passScore': 9,
    'keyPositions': [
        {'id': 'help', 'fen': HELP, 'ref': 'wikiTwoKnights'},
        {'id': 'troitsky', 'fen': TROITSKY, 'ref': 'wikiTwoKnights'},
        {'id': 'line', 'fen': LINE_TALK, 'ref': 'wikiTwoKnights'},
        {'id': 'horwitzKling', 'fen': HK, 'ref': 'wikiTwoKnights'},
        {'id': 'karpov', 'fen': KARPOV, 'ref': 'gameTopalovKarpov#147'},
        {'id': 'seitz', 'fen': SEITZ, 'ref': 'gameSeitz#185'},
        {'id': 'averbakh', 'fen': AVERBAKH, 'ref': 'wikiTwoKnights'},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win', 'positionId': None},
    'references': [
        {'id': 'muellerLamprecht', 'kind': 'book',
         'author': 'Karsten Müller e Frank Lamprecht',
         'title': 'Fundamental Chess Endings', 'publisher': 'Gambit',
         'year': 2001,
         'where': '1.5 King and Two Knights vs King and Pawn, p. 19 '
                  '(sumário da amostra da editora)'},
        {'id': 'studyAndrew', 'kind': 'study', 'author': 'andrew69314',
         'title': 'Two knights vs pawn',
         'url': 'https://lichess.org/study/Q21ch5MW'},
        {'id': 'studyJdiggy', 'kind': 'study', 'author': 'jdiggy',
         'title': 'Two Knights vs pawn',
         'url': 'https://lichess.org/study/gZKdpt9k'},
        {'id': 'wikiTwoKnights', 'kind': 'web',
         'title': 'Two knights endgame (Wikipedia)',
         'url': 'https://en.wikipedia.org/wiki/Two_knights_endgame'},
        {'id': 'wikiTroitsky', 'kind': 'web',
         'title': 'Alexey Troitsky (Wikipedia)',
         'url': 'https://en.wikipedia.org/wiki/Alexey_Troitsky'},
        {'id': 'gameSeitz', 'kind': 'game',
         'white': 'Eugene Znosko-Borovsky', 'black': 'Adolf Seitz',
         'event': 'Nice', 'year': 1931, 'url': URL_SEITZ},
        {'id': 'gameWangAnand', 'kind': 'game',
         'white': 'Wang Yue', 'black': 'Viswanathan Anand',
         'event': 'Amber (às cegas), Nice', 'year': 2009, 'url': URL_WANG},
        {'id': 'gameTopalovKarpov', 'kind': 'game',
         'white': 'Veselin Topalov', 'black': 'Anatoly Karpov',
         'event': 'Amber (rápidas), Monte Carlo', 'year': 2000,
         'url': URL_KARPOV},
        {'id': 'tablebase', 'kind': 'tablebase',
         'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print(f'escrito {OUT}')
