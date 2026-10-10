"""Gera tools/lessons/endgames/pawns.protectedPasser.json (aula "O peão passado protegido").

Lances em SAN aqui, UCI no JSON. Depois de mudar, rode este arquivo e o
build_aula.py:
    tools/.cache/venv/bin/python tools/lessons/endgames/pawns.protectedPasser.py
    tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py pawns.protectedPasser
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


def turns(fen, sans, accepts):
    us = uci(fen, sans)
    out = []
    for i in range(0, len(us), 2):
        t = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us):
            t['reply'] = us[i + 1]
        out.append(t)
    return out


def move(id_, fen, goal, sans, accepts, side=None):
    d = {'type': 'move', 'id': id_, 'fen': fen, 'goal': goal,
         'turns': turns(fen, sans, accepts)}
    if side:
        d['side'] = side
    return d


# Posições-base (todas as de até 7 peças conferidas na tabela do Lichess).
TIED = F('8/4k3/8/1pP4p/1P6/4K3/8/8 w')      # Fine & Benko via Wikipedia, sem os peões de a
TIED_PUSH = F('8/4k3/2P5/1p5p/1P6/4K3/8/8 b')  # depois de 1.c6?: o peão larga a proteção
TWO = F('8/4k3/8/1pP2p2/1P6/4K3/8/8 w')       # peão preto em f5: uma casa faz as duas tarefas
TWO_B = F('8/3k4/8/1pP2p2/1P6/4K3/8/8 b')     # pretas jogam: só 1...Re7
JAKOVENKO = '8/4k3/6p1/2ppPp1p/5P1P/4K1P1/2P5/8 w - - 0 46'  # Jakovenko–Akobian, Yerevan 2000, ply 90
TWO_PASSERS = F('8/3k4/8/1pP4p/1P3p2/8/4K3/8 w')  # dois passados pretos: só 1.Rf3
BASE = F('8/8/8/pP6/Pk6/8/8/7K w')           # o rei preto ataca a base
BASE_IN = F('8/8/8/6p1/4Pk2/5P2/4K3/8 w')    # ataca a base sem sair do quadrado: só 1.Rf2
KING_PAWNS = F('5k2/8/5pPp/3K1P2/8/8/8/8 w')  # Chessforall321, cap. 4
KING_PAWNS_4 = '6k1/8/5KP1/5P2/7p/8/8/8 w - - 0 4'  # depois de 1.Rd6 Rg8 2.Re7 h5 3.Rxf6 h4
CORNER = F('8/1k6/pP6/P1K5/8/8/8/8 w')       # sexta fileira, perto do canto: empate
ROOK_TARGET = F('k7/8/8/Pp6/1P6/8/8/6K1 w')   # peão de torre protegido, mas b5 é alvo: ganha
WALKER = F('8/8/2k5/8/1Pp5/2P5/2K5/8 w')     # Walker (Wikipedia, "Key square"): empate
WALKER_B = '8/8/2k5/8/1Pp5/2P5/3K4/8 b - - 1 1'  # depois de 1.Rd2
NO_TARGET_B = F('8/8/8/3k4/1Pp5/2P5/3K4/8 b')
CONVERT = F('8/8/2k5/1pP5/1P6/4K3/8/8 w')    # depois de capturar: K+2 contra K+1
RECAP = F('8/3k4/8/1pP4p/1P6/8/5K2/8 w')     # resumo: jogar até o fim
PRACTICE = F('8/4k3/8/1pP3p1/1P6/8/4K3/8 w')

JAKOVENKO_URL = (
    'https://lichess.org/analysis/pgn/e4_e6_d4_d5_Nc3_Nf6_Bg5_Bb4_e5_h6_Bd2_Bxc3_bxc3_Ne4_Qg4_g6_Bd3_Nxd2_'
    'Kxd2_c5_Nf3_Qe7_dxc5_Qxc5_Nd4_Bd7_Rhb1_Nc6_Qf4_Na5_Nb3_Nxb3+_axb3_Rc8_Qd4_a6_Qxc5_Rxc5_b4_Rc7_b5_axb5_'
    'Ra8+_Bc8_Rxb5_Ke7_Rb8_Rd8_Rb4_Rc6_Rh4_Rh8_Ra8_Rc7_f4_Kf8_Rh3_Kg7_Be2_h5_Rd3_Bd7_Rxh8_Kxh8_Rd4_Rc5_c4_Bc6_'
    'Bf3_dxc4_Bxc6_c3+_Kd3_bxc6_h4_Kg7_g3_Ra5_Rc4_Rd5+_Ke4_c5_Rxc3_f5+_Ke3_Kf7_Rd3_Ke7_Rxd5_exd5_Kd3_Kd7_Kc3_'
    'Kc7_Kb3_Kc6_Ka4_d4_Ka5_Kd5_Kb5_c4_e6_d3_e7#90')

src = {
    'id': 'pawns.protectedPasser', 'module': 'pawns', 'skills': ['pawns.protectedPasser'],
    'parts': [
        {'id': 'tied', 'steps': [
            {'type': 'think', 'id': 't_tied', 'fen': TIED, 'hints': 2, 'ref': 'wikiPawn',
             'ask': 'plan', 'marks': ['c5', 'h5']},
            {'type': 'talk', 'id': 'square', 'fen': TIED,
             'arrows': ['b4c5'], 'marks': ['c5', 'f5', 'f8', 'c8', 'g6']},
            demo('d_tied', TIED, 'win', 'Kf4 Kf6 Kg3 Ke5 Kh4 Kd5 Kxh5',
                 {1: {'marks': ['g6']}, 4: {'arrows': ['h4h5']}, 6: {'marks': ['h5']}}),
            {'type': 'talk', 'id': 'tiedPush', 'fen': TIED_PUSH, 'side': 'white',
             'arrows': ['e7d6', 'd6c7'], 'marks': ['c6', 'b4']},
            move('tiedMove', TIED, 'win', 'Kf4 Ke6 Kg5 Kd5 Kxh5', ['win'] * 3),
        ]},
        {'id': 'twoTasks', 'steps': [
            {'type': 'think', 'id': 't_twoTasks', 'fen': TWO, 'hints': 2,
             'ask': 'plan', 'marks': ['c5', 'f5']},
            {'type': 'talk', 'id': 'twoTasksWhy', 'fen': TWO, 'side': 'black',
             'arrows': ['e6f5', 'f6f5'], 'marks': ['e6', 'f6', 'g6']},
            demo('d_twoTasks', TWO, 'draw', 'Kf4 Kf6 Kg3 Ke5 Kh4 Kf6',
                 {1: {'marks': ['f5']}, 3: {'marks': ['f4', 'd4']}, 5: {'marks': ['g5']}},
                 side='black'),
            move('twoTasksMove', TWO_B, 'draw', 'Ke7 Kf4 Kf6', ['only', 'hold']),
        ]},
        {'id': 'twoPassers', 'steps': [
            {'type': 'think', 'id': 't_jakovenko', 'fen': JAKOVENKO, 'hints': 2,
             'ref': 'gameJakovenko', 'ask': 'plan', 'marks': ['e5', 'c5', 'd5']},
            {'type': 'talk', 'id': 'jakovenkoWhy', 'fen': JAKOVENKO, 'ref': 'gameJakovenko',
             'arrows': ['e3b3'], 'marks': ['c5', 'd5', 'e5']},
            demo('d_twoPassers', TWO_PASSERS, 'win', 'Kf3 Ke6 Kxf4 Kf6 Kg3 Ke6 Kh4',
                 {0: {'marks': ['f4', 'h5']}, 4: {'arrows': ['g3h4']}, 6: {'marks': ['h5']}}),
            move('twoPassersMove', TWO_PASSERS, 'win', 'Kf3 Ke6 Kxf4', ['only', 'win']),
        ]},
        {'id': 'base', 'steps': [
            {'type': 'think', 'id': 't_base', 'fen': BASE, 'hints': 2,
             'ask': 'line', 'marks': ['a4', 'b4']},
            {'type': 'talk', 'id': 'baseWhy', 'fen': BASE,
             'arrows': ['b5b8'], 'marks': ['b6', 'b8', 'e8', 'e5']},
            demo('d_base', BASE, 'win', 'b6 Kc5 b7 Kc6 b8=Q',
                 {0: {'arrows': ['b6b8']}, 4: {'marks': ['b8']}}),
            demo('d_baseInside', BASE_IN, 'win', 'Kf2 g4 fxg4 Kxe4 Kg3',
                 {0: {'marks': ['f3']}, 4: {'arrows': ['g4g8']}}),
            move('baseInsideMove', BASE_IN, 'win', 'Kf2 Ke5 Ke3', ['only', 'win']),
        ]},
        {'id': 'kingToPawns', 'steps': [
            {'type': 'think', 'id': 't_kingToPawns', 'fen': KING_PAWNS, 'hints': 2,
             'ref': 'studyChessforall4', 'ask': 'plan', 'marks': ['g6', 'h6']},
            {'type': 'talk', 'id': 'kingToPawnsWhy', 'fen': KING_PAWNS, 'ref': 'studyChessforall4',
             'arrows': ['d5d6', 'd6e7', 'e7f6'], 'marks': ['f6']},
            demo('d_kingToPawns', KING_PAWNS_4, 'win', 'g7 h3 Kg6 h2 f6 h1=Q f7#',
                 {0: {'marks': ['f8', 'h8']}, 2: {'marks': ['f7', 'h7']}, 6: {'marks': ['g8']}}),
            move('kingToPawnsMove', KING_PAWNS, 'win', 'Kd6 Kg8 Ke7 h5 Kxf6', ['win', 'win', 'only']),
        ]},
        {'id': 'corner', 'steps': [
            {'type': 'think', 'id': 't_corner', 'fen': CORNER, 'hints': 2, 'ref': 'studyIsaacCorner',
             'ask': 'plan', 'marks': ['a8', 'b8']},
            {'type': 'talk', 'id': 'corner', 'fen': CORNER, 'marks': ['a8', 'b8', 'c7']},
            demo('d_corner', CORNER, 'draw', 'Kd6 Kb8 Kc6 Ka8 Kc7',
                 {3: {'marks': ['a8']}, 4: {'marks': ['a8', 'b8']}}),
            move('rookTargetMove', ROOK_TARGET, 'win', 'Kf2 Kb7 Ke3', ['win', 'win']),
        ]},
        {'id': 'shadow', 'steps': [
            {'type': 'think', 'id': 't_shadow', 'fen': WALKER_B, 'hints': 2, 'ref': 'wikiKeySquare',
             'ask': 'plan', 'marks': ['d4', 'e4', 'f4']},
            {'type': 'talk', 'id': 'shadowWhy', 'fen': WALKER_B, 'side': 'black', 'ref': 'wikiKeySquare',
             'arrows': ['d2d4'], 'marks': ['d4', 'e4', 'f4']},
            demo('d_shadow', WALKER, 'draw', 'Kd2 Kd5 Ke3 Ke5 Kf3 Kf5 Kg3 Ke5 Kg4 Ke4',
                 {1: {'marks': ['d4']}, 3: {'marks': ['d4', 'e4']}, 5: {'marks': ['f4']},
                  7: {'marks': ['d4', 'f4']}, 9: {'marks': ['f4']}},
                 side='black'),
            {'type': 'move', 'id': 'targetMove', 'fen': NO_TARGET_B, 'goal': 'draw',
             'turns': turns(NO_TARGET_B, 'Kd6', ['hold'])},
        ]},
        {'id': 'finish', 'steps': [
            {'type': 'talk', 'id': 'rules', 'fen': RECAP, 'arrows': ['b4c5'], 'marks': ['h5']},
            demo('d_convert', CONVERT, 'win', 'Kd4 Kb7 Kd5 Kc7 c6 Kc8 Kc5 Kc7 Kxb5',
                 {4: {'arrows': ['d5c5']}, 8: {'marks': ['b5']}}),
            move('recapMove', RECAP, 'win', 'Kg3 Ke6 Kh4', ['win'] * 2),
            {'type': 'play', 'id': 'finish', 'fen': RECAP, 'goal': 'win'},
        ]},
    ],
    'exercises': [],
    'passScore': 11,
    'keyPositions': [
        {'id': 'tied', 'fen': TIED, 'ref': 'wikiPawn'},
        {'id': 'twoTasks', 'fen': TWO},
        {'id': 'jakovenko', 'fen': JAKOVENKO, 'ref': 'gameJakovenko'},
        {'id': 'base', 'fen': BASE},
        {'id': 'kingToPawns', 'fen': KING_PAWNS, 'ref': 'studyChessforall4'},
        {'id': 'corner', 'fen': CORNER, 'ref': 'studyIsaacCorner'},
        {'id': 'shadow', 'fen': WALKER, 'ref': 'wikiKeySquare'},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win', 'positionId': None},
    'references': [
        {'id': 'dvoretsky', 'kind': 'book',
         'author': 'Mark Dvoretsky (revisão de Karsten Müller e Alex Fishbein)',
         'title': "Dvoretsky's Endgame Manual, 6ª edição", 'publisher': 'Russell Enterprises',
         'year': 2025, 'where': 'cap. 1, "The Protected Passed Pawn", p. 60 (sumário da amostra da editora)'},
        {'id': 'delaVilla', 'kind': 'book', 'author': 'Jesús de la Villa',
         'title': '100 Endgames You Must Know (4ª edição)', 'publisher': 'New In Chess',
         'year': 2015, 'where': 'Ending 89, "Protected passed pawns", p. 198 (sumário da amostra da editora)'},
        {'id': 'studyIsaac', 'kind': 'study', 'author': 'IsaacWiebeSupreme',
         'title': 'Protected Passers', 'url': 'https://lichess.org/study/u3JyT8wE'},
        {'id': 'studyChessInstitute', 'kind': 'study', 'author': 'Chess_institute',
         'title': 'Protected Passed Pawn 1', 'url': 'https://lichess.org/study/d1sMYYB6'},
        {'id': 'studyYeongyong', 'kind': 'study', 'author': 'yeongyong',
         'title': 'Protected Passed Pawn', 'url': 'https://lichess.org/study/FZJX7Vgp'},
        {'id': 'studyMatt', 'kind': 'study', 'author': 'matt_giocopiano',
         'title': 'protected passed pawns', 'url': 'https://lichess.org/study/irQ4Kfg5'},
        {'id': 'studyChessforall', 'kind': 'study', 'author': 'Chessforall321',
         'title': 'A Protected Passed Pawn', 'url': 'https://lichess.org/study/OksaggdI'},
        {'id': 'studyWilliam', 'kind': 'study', 'author': 'William2020',
         'title': 'PEON PASADO PROTEGIDO', 'url': 'https://lichess.org/study/VKpH7Sw3'},
        {'id': 'wikiPawn', 'kind': 'web', 'title': 'Wikipedia: Pawn (chess), "Passed pawn"',
         'url': 'https://en.wikipedia.org/wiki/Pawn_(chess)#Passed_pawn'},
        {'id': 'wikiPassed', 'kind': 'web', 'title': 'Wikipedia: Passed pawn, "Protected passed pawn"',
         'url': 'https://en.wikipedia.org/wiki/Passed_pawn#Protected_passed_pawn'},
        {'id': 'gameJakovenko', 'kind': 'game', 'white': 'Dmitry Jakovenko', 'black': 'Varuzhan Akobian',
         'event': 'Campeonato Mundial Júnior, Yerevan', 'year': 2000, 'url': JAKOVENKO_URL},
        {'id': 'pgnMentorAkobian', 'kind': 'web', 'title': 'PGN Mentor: partidas de Varuzhan Akobian (PGN)',
         'url': 'https://www.pgnmentor.com/players/Akobian.zip'},
        {'id': 'wikiKeySquare', 'kind': 'web',
         'title': 'Wikipedia: Key square, "Example with a protected passed pawn" (Walker)',
         'url': 'https://en.wikipedia.org/wiki/Key_square#Example_with_a_protected_passed_pawn'},
        {'id': 'studyChessforall4', 'kind': 'study', 'author': 'Chessforall321',
         'title': 'A Protected Passed Pawn: Chapter 4', 'url': 'https://lichess.org/study/OksaggdI/wG2m4yxm'},
        {'id': 'studyIsaacCorner', 'kind': 'study', 'author': 'IsaacWiebeSupreme',
         'title': 'Protected Passers: b pawn passed - 6th rank (draw)',
         'url': 'https://lichess.org/study/u3JyT8wE/vGFLB0KK'},
        {'id': 'tablebase', 'kind': 'tablebase', 'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

# (id, estrelas, fen, objetivo, origem, lances do aluno e respostas, regra por vez)
EX = [
    # O rei livre captura o passado do outro lado (b6? empata); o rei preto não pode defender f4 e ficar no quadrado.
    ('e17', 1, '8/8/8/pP2k3/P4p2/5K2/8/8 w', 'win', 'studyWilliam', 'Kg4 Ke6 Kxf4', ['win'] * 2),
    # Peão de torre protegido longe do canto ganha: o rei vai a c7 (h6? perde).
    ('e12', 1, '8/2p5/5k2/6pP/6P1/8/8/7K w', 'win', 'studyChessInstitute', 'Kg2 Ke5 Kf3', ['win'] * 2),
    # O outro lado também tem passado: só Re5 segura d4 e fica no quadrado de c5.
    ('e13', 2, '8/8/8/1pPk4/1P1p4/5K2/8/8 b', 'draw', 'studyWilliam', 'Ke5 c6 Kd6', ['only', 'hold']),
    ('e08', 2, '8/8/Pk6/1P5p/4p3/8/6K1/8 w', 'win', 'studyChessInstitute', 'Kg3 Kc7 Kf4', ['only', 'win']),
    # Passado distante perto (b5): o defensor acompanha o rei e segura, lance único a lance único.
    ('e14', 2, '8/8/8/1p2kPp1/6P1/4K3/8/8 b', 'draw', 'studyMatt', 'Kd5 Kd3 Ke5 Kc3 Kd5', ['only'] * 3),
    ('e10', 3, '8/2k5/8/8/Pp6/1P6/6K1/8 b', 'draw', 'studyIsaac', 'Kd6 Kf3 Kd5', ['only', 'only']),
    # O rei preto captura a base, mas Re2! deixa o rei branco no lugar certo para a corrida de damas.
    ('e15', 3, '8/8/7p/8/5Pk1/6P1/5K2/8 w', 'win', 'studyChessforall',
     'Ke2 h5 Ke3 Kxg3 f5 h4 f6 h3 f7 h2 f8=Q h1=Q Qg7+', ['only', 'only', 'only', 'only', 'only', 'win', 'win']),
    # Rf5! e Re6!: o rei vai ao mate em vez de correr atrás do peão de b.
    ('e16', 3, '8/6kP/5pP1/8/1p2pK2/8/8/8 w', 'win', 'studyChessforall',
     'Kf5 b3 Ke6 b2 h8=Q+ Kxh8 Kf7 b1=Q g7+ Kh7 g8=Q+', ['only'] * 6),
]
for id_, st, fen, goal, origin, sans, acc in EX:
    src['exercises'].append({'id': id_, 'stars': st, 'fen': F(fen), 'goal': goal,
                             'origin': origin, 'turns': turns(F(fen), sans, acc)})

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print('estrelas:', sum(e['stars'] for e in src['exercises']))
