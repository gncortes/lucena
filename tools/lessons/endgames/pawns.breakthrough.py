"""Gera tools/lessons/endgames/pawns.breakthrough.json (aula "Ruptura").

Lances em SAN aqui, UCI no JSON. Depois de mudar, rode este arquivo e o
build_aula.py:
    tools/.cache/venv/bin/python tools/lessons/endgames/pawns.breakthrough.py
    tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py pawns.breakthrough

As três posições de 8 peças (três peões contra três com os dois reis) só
aparecem em passos `think` e `talk`, que o script não julga; foram conferidas
com o Stockfish (ver o dossiê). Todo passo julgado (demo, move, play,
exercícios, treino) tem no máximo 7 peças e é decidido pela tabela.
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


def think(id_, fen, minutes, hints, ask='plan', side=None, arrows=None,
          marks=None):
    d = {'type': 'think', 'id': id_, 'fen': fen, 'minutes': minutes,
         'hints': hints, 'ask': ask}
    if side:
        d['side'] = side
    if arrows:
        d['arrows'] = arrows
    if marks:
        d['marks'] = marks
    return d


def talk(id_, fen, arrows=None, marks=None, side=None):
    d = {'type': 'talk', 'id': id_, 'fen': fen}
    if side:
        d['side'] = side
    if arrows:
        d['arrows'] = arrows
    if marks:
        d['marks'] = marks
    return d


def exercise(id_, stars, fen, goal, sans, accepts, origin='own'):
    return {'id': id_, 'stars': stars, 'fen': fen, 'goal': goal,
            'origin': origin, 'turns': turns(fen, sans, accepts)}


# Posições de 8 peças (só think/talk; julgadas pelo Stockfish no dossiê).
CLASSIC = F('6k1/ppp5/8/PPP5/8/8/8/6K1 w')          # só b6 ganha
WIKI = F('8/5ppp/8/5PPP/8/6k1/8/6K1 w')             # só g6 ganha
WIKI_B = F('8/5ppp/8/5PPP/8/6k1/8/6K1 b')           # só ...g6 segura

# Depois do primeiro sacrifício (7 peças, tabela).
AFTER_AXB6 = F('6k1/1pp5/1p6/P1P5/8/8/8/6K1 w')     # só c6
AFTER_CXB6 = F('6k1/pp6/1p6/P1P5/8/8/8/6K1 w')      # só a6
COUNT_E8 = F('4k3/1pp5/1p6/P1P5/8/8/8/6K1 w')       # só c6: o rei chega tarde
COUNT_D8 = F('3k4/1pp5/1p6/P1P5/8/8/8/6K1 w')       # perdida: o rei chega
SIDE_H8 = F('7k/3pp3/3p4/2P1P3/8/8/8/7K w')         # só e6
SIDE_A8 = F('k7/2pp4/3p4/2P1P3/8/8/8/K7 w')         # só c6
WIKI_HXG6 = F('8/5pp1/6p1/5P1P/8/6k1/8/6K1 w')      # só f6
WIKI_FXG6 = F('8/6pp/6p1/5P1P/8/6k1/8/6K1 w')       # só h6
DEF_HXG6 = F('8/5p1p/6P1/5PP1/8/6k1/8/6K1 b')       # só ...hxg6
DEF_FXG6 = F('8/5p1p/6P1/6PP/8/6k1/8/6K1 b')        # só ...fxg6
FINISH = F('8/1pp5/1p6/P1P5/8/8/8/2K2k2 w')         # só c6
PRACTICE = F('7k/3pp3/3p4/2P1P3/8/8/8/1K6 w')       # só e6

parts = [
    {'id': 'classic', 'steps': [
        think('t_classic', CLASSIC, 5, 2, arrows=None, marks=['a8', 'b8', 'c8']),
        talk('classicWhy', CLASSIC, arrows=['b5b6', 'a7b6', 'c7b6'],
             marks=['b6']),
        demo('d_classic', AFTER_AXB6, 'win', 'c6 bxc6 a6 Kf7 a7 Ke7 a8=Q', {
            0: {'arrows': ['c5c6'], 'marks': ['c6']},
            2: {'arrows': ['a6a8']},
            6: {'marks': ['a8']},
        }),
        talk('otherCapture', AFTER_CXB6, arrows=['a5a6', 'c5c6'],
             marks=['a6']),
        move('classicMove', AFTER_CXB6, 'win', 'a6 bxa6 c6 b5 c7',
             ['win', 'win', 'win']),
    ]},
    {'id': 'count', 'steps': [
        think('t_count', COUNT_E8, 3, 2, marks=['e8']),
        talk('square', COUNT_E8, arrows=['a6a8'],
             marks=['a6', 'b6', 'c6', 'a7', 'b7', 'c7', 'a8', 'b8', 'c8']),
        talk('tooClose', COUNT_D8, arrows=['d8c7'], marks=['c8', 'c7', 'd8']),
        move('countMove', COUNT_E8, 'win', 'c6 bxc6 a6 Kd7 a7',
             ['win', 'win', 'win']),
    ]},
    {'id': 'side', 'steps': [
        think('t_side', SIDE_H8, 3, 2, marks=['h8', 'c8', 'e8']),
        talk('sideWhy', SIDE_H8, arrows=['e5e6', 'c5c8'], marks=['h8']),
        demo('d_side', SIDE_A8, 'win', 'c6 dxc6 e6 Kb7 e7 Kc8 e8=Q+', {
            0: {'arrows': ['c5c6']},
            2: {'arrows': ['e6e8'], 'marks': ['a8']},
            6: {'marks': ['e8']},
        }),
        move('sideMove', SIDE_H8, 'win', 'e6 dxe6 c6 Kg7 c7',
             ['win', 'win', 'win']),
    ]},
    {'id': 'kingside', 'steps': [
        think('t_wiki', WIKI, 5, 2, marks=['g4']),
        talk('wikiWhy', WIKI, arrows=['g3g4', 'g5g6'], marks=['f5', 'h5']),
        demo('d_wiki', WIKI_HXG6, 'win', 'f6 gxf6 h6 Kf4 h7 Kg5 h8=Q', {
            0: {'arrows': ['f5f6']},
            2: {'arrows': ['h6h8']},
            6: {'marks': ['h8']},
        }),
        move('wikiMove', WIKI_FXG6, 'win', 'h6 gxh6 f6 Kf4 f7',
             ['win', 'win', 'win']),
    ]},
    {'id': 'defense', 'steps': [
        think('t_defense', WIKI_B, 3, 2, side='black', marks=['f7', 'g7', 'h7']),
        talk('defenseWhy', WIKI_B, side='black', arrows=['g7g6'],
             marks=['g6']),
        move('defenseMove', DEF_HXG6, 'draw', 'hxg6 fxg6 fxg6',
             ['hold', 'hold'], side='black'),
        talk('sameSide', DEF_FXG6, side='black', arrows=['f7g6'],
             marks=['h5']),
        move('sameSideMove', DEF_FXG6, 'draw', 'fxg6 hxg6 hxg6',
             ['hold', 'hold'], side='black'),
    ]},
    {'id': 'finish', 'steps': [
        talk('recap', CLASSIC, arrows=['b5b6']),
        move('recapMove', AFTER_AXB6, 'win', 'c6 bxc6 a6',
             ['win', 'win']),
        talk('playIntro', FINISH, marks=['f1']),
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

src = {
    'id': 'pawns.breakthrough',
    'module': 'pawns',
    'skills': ['pawns.breakthrough'],
    'parts': parts,
    'exercises': exercises,
    'passScore': 12,
    'keyPositions': [
        {'id': 'classic', 'fen': CLASSIC, 'ref': 'studyBotez'},
        {'id': 'afterAxb6', 'fen': AFTER_AXB6},
        {'id': 'afterCxb6', 'fen': AFTER_CXB6},
        {'id': 'count', 'fen': COUNT_E8},
        {'id': 'side', 'fen': SIDE_H8},
        {'id': 'wiki', 'fen': WIKI, 'ref': 'wikiPassed'},
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
