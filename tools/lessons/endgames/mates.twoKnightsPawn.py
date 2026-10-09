"""Gera tools/lessons/endgames/mates.twoKnightsPawn.json (fonte da aula).

Rodar com o python do venv (python-chess):
    tools/.cache/venv/bin/python tools/lessons/endgames/mates.twoKnightsPawn.py
Depois: build_aula.py mates.twoKnightsPawn (confere tudo na tabela).

O mate inteiro de dois cavalos contra peão pode passar de cem lances; a aula
ensina por etapas curtas (o porquê, a posição de Troitsky, a linha, o rei no
canto, soltar o bloqueio, a defesa das pretas), cada uma a partir de uma
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


def think(id_, fen, minutes, hints, ask='plan', **extra):
    step = {'type': 'think', 'id': id_, 'fen': fen, 'minutes': minutes,
            'hints': hints, 'ask': ask}
    step.update(extra)
    return step


def talk(id_, fen, **extra):
    step = {'type': 'talk', 'id': id_, 'fen': fen}
    step.update(extra)
    return step


# Posições-base (todas conferidas na tabela do Lichess).
HELP = F('8/5K1k/8/5N2/8/3p4/3N4/8 w')        # Wikipedia: só Ce4 ou Cf3
NO_PAWN = F('8/5K1k/8/5N2/8/8/3N4/8 w')        # a mesma, sem o peão: empate
HELP_MOVE = F('8/k1K5/8/2N5/8/4p3/4N3/8 w')    # a de cima espelhada
TROITSKY = F('7k/5K2/8/5N2/8/3p4/3N4/8 w')     # Troitsky: zugzwang recíproco
ZZ_MOVE = F('7k/8/4NK2/8/8/3p4/3N4/8 w')       # depois do erro 6...Rh8?
LINE_THINK = F('7k/3N4/6p1/8/5K2/7N/8/8 w')    # própria: só Cg5
LINE_TALK = F('7k/3N4/6p1/6N1/5K2/8/8/8 b')    # depois de Cg5
DONT_TAKE = F('6k1/8/6p1/4K3/4NN2/8/8/8 w')    # própria: Cxg6 empata
LINE_MOVE = F('8/8/6k1/5p2/8/6NN/6K1/8 w')     # própria: só Cf4+
DRIVE = F('6k1/8/6p1/4K1N1/4N3/8/8/8 w')       # própria: o rei vai a h8
DRIVE_MOVE = F('1k6/8/1p6/1N1K4/3N4/8/8/8 w')  # a de cima espelhada
RELEASE = F('8/4K1k1/6p1/6N1/6N1/8/8/8 w')     # DRIVE depois de 12 meios-lances
HK = F('8/8/8/8/3p4/1K1N4/8/1k4N1 w')          # Horwitz e Kling, 1851
PAST = F('7k/8/8/4K3/8/3p4/3N4/4N3 w')         # própria: peão além, empate
CURSED = F('8/8/4k3/8/1NN1p3/8/2K5/8 w')       # estudo gZKdpt9k: só depois de 50
DEF_MOVE = F('8/8/k7/5p2/8/1N6/6N1/5K2 b')     # própria: só f4 empata
KARPOV = F('8/8/8/8/6p1/1K1N4/4N3/1k6 b')      # Topalov–Karpov, 2000
PLAY = F('7k/8/6p1/4K3/4NN2/8/8/8 w')          # própria: o mate inteiro
PRACTICE = F('6k1/6p1/8/4K3/4NN2/8/8/8 w')     # estudo Q21ch5MW

src = {
    'id': 'mates.twoKnightsPawn',
    'module': 'mates',
    'skills': ['mate.twoKnightsPawn'],
    'parts': [
        {'id': 'pawnHelps', 'steps': [
            think('t_help', HELP, 3, 2, ask='line', marks=['h8', 'g8']),
            talk('noPawn', NO_PAWN, marks=['h8']),
            demo('d_help', HELP, 'win',
                 'Ne4 d2 Nf6+ Kh8 Ne7 d1=Q Ng6#',
                 {0: {'arrows': ['e4f6']}, 1: {'marks': ['d2']},
                  2: {'marks': ['g8', 'h7']}, 4: {'marks': ['g6']},
                  6: {'marks': ['h8']}}),
            move('helpMove', HELP_MOVE, 'win',
                 'Nd4 e2 Nc6+ Ka8 Nd7 e1=Q Nb6#',
                 ['best', 'best', 'best', 'only']),
        ]},
        {'id': 'zugzwang', 'steps': [
            think('t_zz', TROITSKY, 5, 2, marks=['d3', 'd2']),
            talk('zzWhy', TROITSKY, arrows=['d2e4', 'e4f6'],
                 marks=['h8', 'h7']),
            demo('d_zzDraw', TROITSKY, 'draw',
                 'Kf6 Kh7 Kf7 Kh8 Kg6 Kg8 Ng7 Kf8 Kf6 Kg8 Ne6 Kh7',
                 {11: {'marks': ['h7']}}, side='black'),
            move('zzMove', ZZ_MOVE, 'win',
                 'Kg6 Kg8 Ne4 Kh8 Nf6 d2 Ng5 d1=Q Nf7#',
                 ['only', 'only', 'best', 'best', 'only']),
        ]},
        {'id': 'line', 'steps': [
            think('t_line', LINE_THINK, 3, 2, marks=['g6']),
            talk('lineWhy', LINE_TALK, side='white', marks=LINE),
            talk('dontTake', DONT_TAKE, arrows=['f4g6'], marks=['g6']),
            move('lineMove', LINE_MOVE, 'win', 'Nf4+', ['only']),
        ]},
        {'id': 'drive', 'steps': [
            think('t_drive', DRIVE, 3, 2, marks=['g5', 'h8']),
            talk('driveWhy', DRIVE, arrows=['g5f7', 'g5h7'],
                 marks=['g5', 'g6']),
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
            think('t_release', RELEASE, 3, 2, ask='line',
                  marks=['g5', 'g1']),
            talk('releaseWhy', RELEASE, arrows=['g5e6', 'g6g1'],
                 marks=['h8']),
            demo('d_release', HK, 'win',
                 'Ne2 Ka1 Nb4 Kb1 Nc2 d3 Na3+ Ka1 Nc3 d2 Nc2#',
                 {0: {'marks': ['d4']}, 4: {'arrows': ['d4d3']},
                  6: {'marks': ['b1', 'b2']}, 10: {'marks': ['a1']}}),
            move('releaseMove', RELEASE, 'win',
                 'Ne6+ Kh7 Kf7 Kh8 Nf6 g5 Nf8 g4 Ng6#',
                 ['best', 'best', 'best', 'best', 'only']),
        ]},
        {'id': 'defense', 'steps': [
            think('t_def', DEF_MOVE, 1, 1, marks=['f4']),
            talk('pastLine', PAST, marks=['d3', 'd4']),
            talk('fifty', CURSED, marks=['e4', 'e3']),
            move('defMove', DEF_MOVE, 'draw', 'f4', ['hold']),
        ]},
        {'id': 'summary', 'steps': [
            talk('rules', DONT_TAKE, marks=LINE),
            talk('karpov', KARPOV, side='white', marks=['g4']),
            talk('playIntro', PLAY, marks=['g6']),
            {'type': 'play', 'id': 'finish', 'fen': PLAY, 'goal': 'win'},
        ]},
    ],
    'exercises': [
        exercise('e01', 1, F('7k/8/3N2K1/7N/8/1p6/8/8 w'), 'win',
                 'Nf6 b2 Nf7#', ['only', 'only']),
        exercise('e02', 1, F('5N1k/3N4/7K/8/8/3p4/8/8 w'), 'win',
                 'Nf6 d2 Ng6#', ['only', 'only']),
        exercise('e03', 1, F('8/8/3K3k/8/3pN3/8/8/4N3 w'), 'win',
                 'Nd3', ['only']),
        exercise('e04', 1, F('1k6/8/K2N4/2N5/2p5/8/8/8 w'), 'win',
                 'Kb6', ['only']),
        exercise('e05', 2, F('k7/2K5/3N4/8/8/4p3/4N3/8 w'), 'win',
                 'Kb6 Kb8 Nd4', ['only', 'only']),
        exercise('e06', 2, F('k7/8/8/2p5/K7/8/3N4/5N2 b'), 'draw',
                 'c4', ['hold']),
        exercise('e07', 2, F('5N1k/8/5K2/8/6N1/p7/8/8 w'), 'win',
                 'Kf7 a2 Ne5 a1=Q Neg6#', ['only', 'best', 'only']),
        exercise('e08', 2, F('3N2k1/8/6K1/2pN4/8/8/8/8 w'), 'win',
                 'Ne6 Kh8 Nf6 c4 Ng5 c3 Nf7#',
                 ['best', 'best', 'best', 'only']),
        exercise('e09', 3, F('8/5K2/6pk/3N4/4N3/8/8/8 w'), 'win',
                 'Ndf6 g5 Ng3 g4 Nfe4', ['best', 'only', 'only']),
        exercise('e10', 3, F('8/7k/5K2/5N2/8/4p3/4N3/8 w'), 'win',
                 'Kf7 Kh8 Nf4 Kh7 Ng6 e2 Nf8+ Kh8 Nh4 e1=Q Nhg6#',
                 ['best', 'best', 'best', 'best', 'best', 'only']),
    ],
    'passScore': 11,
    'keyPositions': [
        {'id': 'help', 'fen': HELP, 'ref': 'wikiTwoKnights'},
        {'id': 'troitsky', 'fen': TROITSKY, 'ref': 'wikiTwoKnights'},
        {'id': 'line', 'fen': LINE_TALK, 'ref': 'wikiTwoKnights'},
        {'id': 'horwitzKling', 'fen': HK, 'ref': 'wikiTwoKnights'},
        {'id': 'karpov', 'fen': KARPOV, 'ref': 'gameTopalovKarpov'},
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
         'event': 'Nice', 'year': 1931},
        {'id': 'gameTopalovKarpov', 'kind': 'game',
         'white': 'Veselin Topalov', 'black': 'Anatoly Karpov',
         'event': 'Amber (rápidas), Monte Carlo', 'year': 2000},
        {'id': 'tablebase', 'kind': 'tablebase',
         'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print(f'escrito {OUT}')
