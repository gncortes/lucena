"""Gera tools/lessons/endgames/pawns.breakthrough.json (aula "Ruptura").

Lances em SAN aqui, UCI no JSON. Depois de mudar, rode este arquivo e o
build_aula.py:
    tools/.cache/venv/bin/python tools/lessons/endgames/pawns.breakthrough.py
    tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py pawns.breakthrough

Lição refeita na T61 (ver docs/aulas/pawns.breakthrough.md, "Lição refeita").
As posições com mais de 7 peças (três peões contra três com os dois reis, e as
duas da partida Capablanca – Edward Lasker, Londres 1913) só aparecem em
passos `think` e `talk`, que o script não julga; as afirmações das falas sobre
elas foram conferidas com o Stockfish (dossiê). Todo passo julgado (demo, move,
play, exercícios, treino) tem no máximo 7 peças e é decidido pela tabela.
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


def demo(id_, fen, goal, sans, notes=None, side=None, ref=None):
    line = []
    for i, u in enumerate(uci(fen, sans)):
        e = {'uci': u}
        if notes and i in notes:
            e.update(notes[i])
        line.append(e)
    d = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': goal, 'line': line}
    if side:
        d['side'] = side
    if ref:
        d['ref'] = ref
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


def think(id_, fen, hints, ask='plan', side=None, arrows=None,
          marks=None, ref=None):
    # Sem `minutes` (T60): o cronômetro conta para cima, sem limite.
    d = {'type': 'think', 'id': id_, 'fen': fen, 'hints': hints, 'ask': ask}
    if side:
        d['side'] = side
    if arrows:
        d['arrows'] = arrows
    if marks:
        d['marks'] = marks
    if ref:
        d['ref'] = ref
    return d


def talk(id_, fen, arrows=None, marks=None, side=None, ref=None):
    d = {'type': 'talk', 'id': id_, 'fen': fen}
    if side:
        d['side'] = side
    if arrows:
        d['arrows'] = arrows
    if marks:
        d['marks'] = marks
    if ref:
        d['ref'] = ref
    return d


def exercise(id_, stars, fen, goal, sans, accepts, origin='own'):
    return {'id': id_, 'stars': stars, 'fen': fen, 'goal': goal,
            'origin': origin, 'turns': turns(fen, sans, accepts)}


# Posições com mais de 7 peças (só think/talk; julgadas pelo Stockfish no
# dossiê).
CLASSIC = F('6k1/ppp5/8/PPP5/8/8/8/6K1 w')          # só b6 ganha
WIKI_B = F('8/5ppp/8/5PPP/8/6k1/8/6K1 b')           # só ...g6 segura
# Capablanca – Edward Lasker, Londres 1913 (estudos VsvnZu6D e Mc6kbNae).
CAPA_38 = F('8/7p/p5p1/3k2P1/3p1P1P/3K4/P7/8 w')    # depois de 38...Rd5: a3! ganha; f5? empata
CAPA_40 = F('8/7p/p7/4kpPP/3p4/3K4/P7/8 w')         # depois de 40...Re5: só h6!! ganha

# Posições julgadas pela tabela (7 peças ou menos).
AFTER_AXB6 = F('6k1/1pp5/1p6/P1P5/8/8/8/6K1 w')     # só c6
AFTER_CXB6 = F('6k1/pp6/1p6/P1P5/8/8/8/6K1 w')      # só a6
COUNT_E8 = F('4k3/1pp5/1p6/P1P5/8/8/8/6K1 w')       # só c6: o rei chega tarde
TOO_CLOSE = F('3k4/2pp4/8/1PPP4/8/8/8/6K1 w')       # só lances de rei ganham; b6, c6, d6 empatam
TOO_CLOSE_KC4 = F('3k4/2pp4/8/1PPP4/2K5/8/8/8 w')   # com o rei em c4, b6 e c6 ganham (d6 empata)
ORDER = F('8/8/1p4p1/6k1/1PP5/8/8/7K w')            # só b5 ganha; c5 empata
# Depois de 1.c5? bxc5 2.b5 (contador em 2): a corrida empata, e a dama preta
# nasce com xeque. Demo do lado das pretas (cada lance delas é o único).
ORDER_WRONG = '8/8/6p1/1Pp3k1/8/8/8/7K b - - 0 2'
SIDE_H8 = F('7k/3pp3/3p4/2P1P3/8/8/8/7K w')         # só e6
SIDE_A8 = F('k7/2pp4/3p4/2P1P3/8/8/8/K7 w')         # só c6
# Só e5 ganha: f5? perde (h4! e a dama preta nasce com xeque).
TWO_PASSERS = F('k7/8/P4p2/7p/4PP2/8/8/K7 w')
PUSH = F('8/4pp1k/4P3/5P2/8/8/8/K7 w')              # só f6 ganha; exf7? perde (Rg7)
PUSH_MOVE = F('8/k1pp4/3P4/2P5/8/8/8/7K w')          # só c6 ganha; dxc7 até perde (Rb7)
KING_FIRST = F('8/1k6/1p4p1/8/5P1P/8/8/K7 w')       # só Rb2 ganha; f5 empata
# Depois de 1.f5? gxf5 2.h5 (contador em 2): a dama preta nasce com xeque.
KING_FIRST_WRONG = '8/1k6/1p6/5p1P/8/8/8/K7 b - - 0 2'
DEF_HXG6 = F('8/5p1p/6P1/5PP1/8/6k1/8/6K1 b')       # só ...hxg6
# Depois de 1...g6 2.fxg6: o contador do lance fica em 2 para a demo narrar
# 2...fxg6 3.hxg6, na sequência do `t_defense`.
DEF_FXG6 = '8/5p1p/6P1/6PP/8/6k1/8/6K1 b - - 0 2'    # só ...fxg6 (hxg6? h6! e o peão de h passa)
DEF_KING = F('8/pp1k4/8/PPP5/8/8/8/6K1 b')          # só ...a6 segura
FINISH = F('8/1pp5/1p6/P1P5/8/8/8/2K2k2 w')         # só c6
PRACTICE = F('7k/3pp3/3p4/2P1P3/8/8/8/1K6 w')       # só e6

CAPA = 'capaLasker1913'

parts = [
    {'id': 'classic', 'steps': [
        think('t_classic', CLASSIC, 2, marks=['a8', 'b8', 'c8']),
        talk('classicWhy', CLASSIC, arrows=['b5b6', 'a7b6', 'c7b6'],
             marks=['b6']),
        demo('d_classic', AFTER_AXB6, 'win', 'c6 bxc6 a6 Kf7 a7', {
            0: {'arrows': ['c5c6'], 'marks': ['c6']},
            2: {'arrows': ['a6a8']},
            4: {'marks': ['a8', 'b7']},
        }),
        talk('otherCapture', AFTER_CXB6, arrows=['a5a6', 'c5c6'],
             marks=['a6']),
        move('classicMove', AFTER_CXB6, 'win', 'a6 bxa6 c6 b5 c7',
             ['win', 'win', 'win']),
    ]},
    {'id': 'count', 'steps': [
        think('t_count', COUNT_E8, 2, marks=['e8']),
        talk('square', COUNT_E8, arrows=['c5c6', 'a6a8', 'e8c8', 'c8b7'],
             marks=['a6', 'b7']),
        talk('capaCount', CAPA_38, arrows=['f4f5', 'h4h5', 'd5e6'],
             marks=['a3'], ref=CAPA),
        move('countMove', COUNT_E8, 'win', 'c6 bxc6 a6 Kd7 a7',
             ['win', 'win', 'win']),
    ]},
    # Quando a conta falha (o rei adversário pega o peão novo): guardar a
    # ruptura e trazer o rei. É a ideia do e08.
    {'id': 'kingInstead', 'steps': [
        think('t_tooClose', TOO_CLOSE, 2, marks=['d8']),
        talk('tooClose', TOO_CLOSE, arrows=['g1f2'], marks=['e3', 'd4']),
        demo('d_tooClose', TOO_CLOSE_KC4, 'win', 'b6 cxb6 cxb6 Kc8 Kc5 Kb7 Kd6', {
            0: {'arrows': ['b5b6'], 'marks': ['c4']},
            2: {'marks': ['b6', 'c4']},
            4: {'arrows': ['c4c5'], 'marks': ['d6']},
            6: {'arrows': ['c5d6'], 'marks': ['d7']},
        }),
        move('tooCloseMove', TOO_CLOSE, 'win', 'Kf2', ['win']),
    ]},
    {'id': 'order', 'steps': [
        think('t_order', ORDER, 2, marks=['b6']),
        talk('orderWhy', ORDER, arrows=['b4b5', 'c4c5'], marks=['b6']),
        demo('orderWrong', ORDER_WRONG, 'draw', 'c4 b6 c3 b7 c2 b8=Q c1=Q+', {
            0: {'arrows': ['c5c4'], 'marks': ['b5']},
            2: {'marks': ['c3', 'b6']},
            5: {'marks': ['b8']},
            6: {'arrows': ['c1h1'], 'marks': ['c1']},
        }, side='black'),
        move('orderMove', ORDER, 'win', 'b5 Kf4 c5 bxc5 b6',
             ['win', 'win', 'win']),
    ]},
    {'id': 'side', 'steps': [
        think('t_side', SIDE_H8, 2, marks=['h8', 'c8', 'e8']),
        talk('sideWhy', SIDE_H8, arrows=['e5e6', 'c5c8'], marks=['h8']),
        demo('d_side', SIDE_A8, 'win', 'c6 dxc6 e6 Kb7 e7', {
            0: {'arrows': ['c5c6']},
            2: {'arrows': ['e6e8'], 'marks': ['a8']},
            4: {'marks': ['e8', 'd7']},
        }),
        move('sideMove', SIDE_H8, 'win', 'e6 dxe6 c6 Kg7 c7',
             ['win', 'win', 'win']),
    ]},
    # Um rei preso a um peão passado não cuida de outro: a ruptura na outra
    # ala cria o segundo. É a ideia do e13.
    {'id': 'secondPasser', 'steps': [
        think('t_twoPassers', TWO_PASSERS, 2, marks=['a6', 'a8', 'h5']),
        talk('twoPassers', TWO_PASSERS, arrows=['e4e5', 'h5h1'],
             marks=['f6']),
        demo('d_twoPassers', TWO_PASSERS, 'win', 'e5 fxe5 f5 h4 f6 h3 f7', {
            0: {'arrows': ['e5f6'], 'marks': ['f6']},
            1: {'marks': ['f4', 'f8']},
            3: {'arrows': ['h4h1']},
            5: {'marks': ['h2', 'f7']},
            6: {'arrows': ['f7f8', 'f8a8'], 'marks': ['a8']},
        }),
        move('twoPassersMove', TWO_PASSERS, 'win', 'e5 fxe5 f5 h4 f6',
             ['win', 'win', 'win']),
    ]},
    {'id': 'pushPast', 'steps': [
        think('t_push', CAPA_40, 2, marks=['g6', 'h6'], ref=CAPA + '#80'),
        talk('pushWhy', CAPA_40, arrows=['h5h6', 'g5g6'], marks=['f6', 'h7'],
             ref=CAPA + '#80'),
        demo('d_push', PUSH, 'win', 'f6 exf6 e7 Kg7 e8=Q', {
            0: {'arrows': ['f5f6'], 'marks': ['f7']},
            2: {'arrows': ['e7e8']},
            4: {'marks': ['e8']},
        }),
        move('pushMove', PUSH_MOVE, 'win', 'c6 dxc6 d7', ['win', 'win']),
    ]},
    {'id': 'kingFirst', 'steps': [
        think('t_kingFirst', KING_FIRST, 2, marks=['b6', 'a1']),
        # Sem seta: a primeira seta deste talk seria o lance "certo" do think.
        talk('kingFirstWhy', KING_FIRST, marks=['f5', 'a1']),
        demo('d_kingFirstWrong', KING_FIRST_WRONG, 'draw',
             'f4 h6 f3 h7 f2 h8=Q f1=Q+', {
                 0: {'arrows': ['f4f1'], 'marks': ['a1']},
                 5: {'marks': ['h8']},
                 6: {'arrows': ['f1a1'], 'marks': ['f1']},
             }, side='black'),
        talk('kingFirstPath', KING_FIRST, arrows=['a1b2', 'b2c3'],
             marks=['c3', 'b6']),
        move('kingFirstMove', KING_FIRST, 'win',
             'Kb2 b5 Kc3 Ka6 f5 gxf5 h5',
             ['win', 'win', 'win', 'win']),
    ]},
    {'id': 'defense', 'steps': [
        think('t_defense', WIKI_B, 2, side='black',
              marks=['f7', 'g7', 'h7']),
        talk('defenseWhy', WIKI_B, side='black', arrows=['g7g6'],
             marks=['g6']),
        # As brancas tomaram com o peão de f: retomar com o de f.
        demo('d_defense', DEF_FXG6, 'draw', 'fxg6 hxg6 hxg6 Kf1 Kf4', {
            0: {'arrows': ['f7g6'], 'marks': ['h5', 'h7']},
            2: {'marks': ['g5', 'g6']},
            4: {'marks': ['g5']},
        }, side='black'),
        # As brancas tomaram com o peão de h: retomar com o de h.
        move('defenseMove', DEF_HXG6, 'draw', 'hxg6 fxg6 fxg6',
             ['hold', 'hold'], side='black'),
    ]},
    # Com o rei perto e sem peão do meio: encostar pela ponta e levar o rei
    # para a frente do peão que sobrar. É a ideia do e10.
    {'id': 'defenseKing', 'steps': [
        think('t_defenseKing', DEF_KING, 2, side='black',
              marks=['d7', 'a7', 'b7']),
        talk('defenseKing', DEF_KING, side='black', arrows=['a7a6', 'd7c6'],
             marks=['a6', 'c5']),
        demo('d_defenseKing', DEF_KING, 'draw',
             'a6 bxa6 bxa6 Kf2 Kc6 Ke3 Kxc5', {
                 0: {'arrows': ['a7a6'], 'marks': ['b6']},
                 2: {'marks': ['a5', 'a6', 'c5']},
                 4: {'arrows': ['c6c5']},
                 6: {'marks': ['c5']},
             }, side='black'),
        move('defenseKingMove', DEF_KING, 'draw', 'a6 b6 Kc6 Kf2 Kxc5',
             ['hold', 'hold', 'hold'], side='black'),
    ]},
    {'id': 'finish', 'steps': [
        talk('recap', CLASSIC, arrows=['b5b6']),
        talk('recapCount', TOO_CLOSE, arrows=['g1f2'], marks=['d8']),
        talk('recapPush', PUSH, arrows=['f5f6'], marks=['e7']),
        talk('recapDefense', WIKI_B, side='white', arrows=['g7g6']),
        move('recapMove', AFTER_AXB6, 'win', 'c6 bxc6 a6',
             ['win', 'win']),
        {'type': 'play', 'id': 'finish', 'fen': FINISH, 'goal': 'win'},
    ]},
]

# Exercícios (T58): um por ideia, do mais fácil para o mais difícil. Todos com
# até 7 peças, julgados pela tabela. Ids cortados (e02–e07, e09) não voltam.
exercises = [
    # 2 contra 1: desviar o vigia (estudo de BenPesoa, rei preto em d8).
    exercise('e01', 1, F('3k4/p7/P7/1P6/8/8/8/7K w'), 'win', 'b6',
             ['win'], origin='studyPesoa'),
    # Ordem: fixar primeiro (b5!), para o peão novo nascer em b6, não em b5.
    exercise('e11', 2, F('8/8/1p6/6k1/1PP5/8/8/7K w'), 'win',
             'b5 Kf4 c5 bxc5 b6', ['win', 'win', 'win'],
             origin='studyReinhold'),
    # Não tome: g6! (hxg7? perde para Rf7).
    exercise('e12', 2, F('8/p3k1pp/7P/4K1P1/8/8/8/8 w'), 'win',
             'g6 gxh6 gxh7', ['win', 'win'], origin='studyWastl'),
    # Rei perto: não romper, trazer o rei.
    exercise('e08', 2, F('2k5/1pp5/8/PPP5/8/8/8/6K1 w'), 'win', 'Kf2',
             ['win']),
    # Rei preso ao peão passado de a6: romper na outra ala (c5! e4!).
    exercise('e13', 3, F('8/2p5/P1kp4/8/2P5/4P3/3K4/8 w'), 'win',
             'c5 dxc5 e4 Kb6 e5', ['win', 'win', 'win'],
             origin='studyReinhold'),
    # Defesa: ...a6! antes de b6, e o rei vai a c8 e b8.
    exercise('e10', 3, F('8/p1pk4/8/PPP5/8/8/8/6K1 b'), 'draw',
             'a6 bxa6 Kc8 c6 Kb8', ['hold', 'hold', 'hold']),
    # Estilo de estudo: g5! (não gxh5), depois f4 e f5 com xeque no fim.
    exercise('e14', 3, F('5K1k/8/6p1/7p/6P1/8/5P2/8 w'), 'win',
             'g5 h4 f4 h3 f5', ['win', 'win', 'win'],
             origin='studyReinhold'),
    # Primeiro o rei na frente do peão de c (Rb3! Rc2! Rd1!), depois f5.
    exercise('e15', 3, F('8/8/1kp3p1/8/K4P1P/8/8/8 w'), 'win',
             'Kb3 c5 Kc2 c4 Kd1 Kc5 f5 gxf5 h5',
             ['win', 'win', 'win', 'win', 'win'], origin='studyDarkSharky'),
]

# A partida no tabuleiro de análise, parada depois de 38...Rd5 (ply 76);
# `#80` é depois de 40...Re5. PGN do estudo VsvnZu6D, conferido com
# python-chess (dossiê).
CAPA_PGN = (
    'e4_e5_Nf3_Nc6_Bb5_a6_Ba4_Nf6_O-O_Be7_Re1_b5_Bb3_d6_c3_O-O_d4_Bg4_Be3_'
    'Nxe4_Bd5_Qd7_dxe5_Ng5_Bxg5_Bxg5_Nxg5_Bxd1_e6_fxe6_Bxe6+_Qxe6_Nxe6_Rae8_'
    'Nd2_Rf6_Raxd1_Rfxe6_Kf1_Ne5_Re3_Kf7_Rde1_d5_b4_Ng4_Rxe6_Rxe6_Rxe6_Kxe6_'
    'h3_Nf6_f3_Nd7_Ke2_Kd6_Nb3_c5_bxc5+_Nxc5_Nxc5_Kxc5_Kd3_b4_f4_bxc3_Kxc3_'
    'd4+_Kd3_Kd5_g4_g6_h4_Kc5_g5_Kd5_f5_gxf5_h5_Ke5_h6')

src = {
    'id': 'pawns.breakthrough',
    'module': 'pawns',
    'skills': ['pawns.breakthrough'],
    'parts': parts,
    'exercises': exercises,
    'passScore': 12,
    'keyPositions': [
        {'id': 'classic', 'fen': CLASSIC},
        {'id': 'afterAxb6', 'fen': AFTER_AXB6},
        {'id': 'afterCxb6', 'fen': AFTER_CXB6},
        {'id': 'count', 'fen': COUNT_E8},
        {'id': 'capa', 'fen': CAPA_40, 'ref': CAPA + '#80'},
        {'id': 'order', 'fen': ORDER},
        {'id': 'side', 'fen': SIDE_H8},
        {'id': 'kingFirst', 'fen': KING_FIRST},
        {'id': 'wikiDefense', 'fen': WIKI_B, 'ref': 'wikiPassed'},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win', 'positionId': None},
    'references': [
        {'id': 'delaVilla', 'kind': 'book', 'author': 'Jesús de la Villa',
         'title': '100 Endgames You Must Know (4ª edição)',
         'publisher': 'New In Chess', 'year': 2015,
         'where': 'Ending 92, "Breakthroughs when the king is far", p. 202 '
                  '(sumário da amostra da editora)'},
        {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
         'title': "Dvoretsky's Endgame Manual (6ª edição, revista por "
                  'Karsten Müller e Alex Fishbein)',
         'publisher': 'Russell Enterprises', 'year': 2025,
         'where': 'cap. 1, seção "Breakthrough", p. 48 (sumário da amostra '
                  'da editora)'},
        {'id': CAPA, 'kind': 'game', 'white': 'José Raúl Capablanca',
         'black': 'Edward Lasker', 'event': 'partida amistosa, Londres',
         'year': 1913,
         'url': 'https://lichess.org/analysis/pgn/' + CAPA_PGN + '#76'},
        {'id': 'studySalgado', 'kind': 'study', 'author': 'SalgadoChess',
         'title': 'Finales de Peones: Rupturas',
         'url': 'https://lichess.org/study/Mc6kbNae/MrDiUsYy'},
        {'id': 'studyKirill', 'kind': 'study', 'author': 'Kirill',
         'title': 'Capablanca, Jose Raul-Lasker, Edward',
         'url': 'https://lichess.org/study/VsvnZu6D/DRuNByaO'},
        {'id': 'studyBotez', 'kind': 'study', 'author': 'alexandra_botez',
         'title': 'BREAKTHROUGH',
         'url': 'https://lichess.org/study/sWRrBd9E'},
        {'id': 'studyPesoa', 'kind': 'study', 'author': 'BenPesoa',
         'title': 'Pawn Breaks in Endgames',
         'url': 'https://lichess.org/study/gtmEM2gm'},
        {'id': 'studyDarkSkull', 'kind': 'study', 'author': 'DarkSkull',
         'title': 'pawn breakthroughs',
         'url': 'https://lichess.org/study/cvuGdHYK'},
        {'id': 'studyReinhold', 'kind': 'study', 'author': 'Reinhold53',
         'title': 'Durchbruch Schlüsselfelder',
         'url': 'https://lichess.org/study/PBs6ES3h'},
        {'id': 'studyWastl', 'kind': 'study', 'author': 'Wastl2002',
         'title': 'AT Durchbruch',
         'url': 'https://lichess.org/study/8B1x0YzU'},
        {'id': 'studyDarkSharky', 'kind': 'study', 'author': 'Dark-Sharky',
         'title': 'Pawn Breaks',
         'url': 'https://lichess.org/study/pRq9j9df'},
        {'id': 'wikiPassed', 'kind': 'web',
         'title': 'Wikipedia: Passed pawn',
         'url': 'https://en.wikipedia.org/wiki/Passed_pawn'},
        {'id': 'wikiGlossary', 'kind': 'web',
         'title': 'Wikipedia: Glossary of chess (breakthrough)',
         'url': 'https://en.wikipedia.org/wiki/Glossary_of_chess'},
        {'id': 'tablebase', 'kind': 'tablebase',
         'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print(f'gravado {OUT}')
