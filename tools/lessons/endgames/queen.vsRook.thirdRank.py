"""Gera `queen.vsRook.thirdRank.json` (a fonte da aula) a partir dos lances em
SAN. Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/queen.vsRook.thirdRank.py`
e depois o `build_aula.py queen.vsRook.thirdRank`."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, exercise, move, play, talk, think,  # noqa: E402
                         write)

T = '3k4/5Q2/1r6/3K4/8/8/8/8 w - - 0 1'    # terceira fileira, torre em b6
TA = '3k4/5Q2/r7/3K4/8/8/8/8 w - - 0 1'    # terceira fileira, torre em a6
TB = after(T, 'Qf4')                        # depois de 1.Qf4, pretas jogam
F = '8/3k4/5Q2/r7/4K3/8/8/8 w - - 0 1'     # quarta fileira (Nunn)
SEVEN = '3k4/1Q6/3r4/5K2/8/8/8/8 w - - 0 1'
PONZIANI = '5k2/5r2/4Q3/6K1/8/8/8/8 b - - 0 1'
MORO = '8/8/8/8/6K1/8/6kr/4Q3 w - - 0 1'   # Morozevich-Jakovenko, lance 110
BROWNE = '2KQ4/8/8/8/2r5/2k5/8/8 w - - 0 1'
# Exercícios (T58): partidas e estudos abertos, conferidos na tabela.
ADROOD = 'k7/2r5/3Q4/1K6/8/8/8/8 w - - 0 1'     # estudo de adrood, lance 20
MORO93 = '8/8/5Q2/2K5/r7/3k4/8/8 w - - 0 1'     # Morozevich-Jakovenko, lance 93
MORO82 = '6r1/8/4K3/1k6/8/2Q5/8/8 w - - 0 1'    # Morozevich-Jakovenko, lance 82
METHURST = '8/6Q1/8/5r1k/8/4K3/8/8 w - - 0 1'   # estudo de methurst

REFERENCES = [
    {'id': 'wikipedia', 'kind': 'web',
     'title': 'Queen versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Queen_versus_rook_endgame'},
    {'id': 'pawnless', 'kind': 'web',
     'title': 'Pawnless chess endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Pawnless_chess_endgame'},
    {'id': 'moro', 'kind': 'game', 'white': 'Alexander Morozevich',
     'black': 'Dmitry Jakovenko', 'event': 'Pamplona', 'year': 2006},
    {'id': 'belle', 'kind': 'game', 'white': 'Walter Browne',
     'black': 'Belle (computador)', 'event': 'Desafio de dama contra torre, revanche',
     'year': 1978},
    {'id': 'adrood', 'kind': 'study', 'author': 'adrood',
     'title': 'Queen versus Rook endgame',
     'url': 'https://lichess.org/study/tEH40nAS'},
    {'id': 'belle1979', 'kind': 'web',
     'title': 'Stenberg, Conway e Larkins: Queen vs. Rook (1979, cópia Usenet)',
     'url': 'http://quux.org:70/Archives/usenet-a-news/NET.chess/82.01.07_sri-unix.458_net.chess.txt'},
    {'id': 'methurst', 'kind': 'study', 'author': 'methurst',
     'title': 'Queen vs Rook, Third Rank Defense',
     'url': 'https://lichess.org/study/34ArhgQa'},
    {'id': 'cgbarros', 'kind': 'study', 'author': 'cgbarros',
     'title': 'Queen  vs rook - Crappy rook moves on the third rank defense',
     'url': 'https://lichess.org/study/jW4DCegI'},
    {'id': 'parker', 'kind': 'study', 'author': 'ColinParker',
     'title': "Q vs R endgame (From Nunn's Secrets of Pawnless Endings)",
     'url': 'https://lichess.org/study/dPt5h0yM'},
    {'id': 'nunn', 'kind': 'book', 'author': 'John Nunn',
     'title': 'Secrets of Pawnless Endings', 'publisher': 'Gambit Publications',
     'year': 2002},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'queen.vsRook.thirdRank',
    'module': 'queen',
    'skills': ['queen.vsRook'],
    'parts': [
        {'id': 'third', 'steps': [
            think('t_third', T, 5, 1),
            talk('intro', T, arrows=['b6h6'],
                 marks=['a6', 'b6', 'c6', 'd6', 'e6', 'f6', 'g6', 'h6']),
            talk('seven', T, arrows=['f7f6', 'f7g6', 'd5c6', 'd5d6', 'd5e6'],
                 marks=['b6']),
            talk('quietMove', TB, arrows=['f4b8', 'f4f8', 'f4h6'],
                 marks=['a6', 'c6', 'g6', 'h6']),
            move('rg6', after(TB, 'Rg6'), 'Qf8+ Kd7 Qf7+'),
        ]},
        {'id': 'best', 'steps': [
            move('ra6', after(TB, 'Ra6'), 'Qb8+ Ke7 Qb7+'),
            move('rb7', after(TB, 'Rb7'), 'Kc6'),
            move('switch', T, 'Qf4 Kd7 Qa4+ Kc7 Qa7+ Rb7 Qc5+ Kb8 Kd6'),
            move('home',
                 after(T, 'Qf4 Kd7 Qa4+ Kc7 Qa7+ Rb7 Qc5+ Kb8 Kd6 Rg7'),
                 'Qe5 Rc7 Qf4 Kc8 Qf5+ Kb8 Qe5'),
        ]},
        {'id': 'thirdA', 'steps': [
            think('t_thirdA', TA, 5, 1),
            talk('a6', TA, arrows=['d5c5', 'c5b5'], marks=['a6']),
            move('around', TA, 'Kc5 Kc8 Qe7 Kb8 Kb5'),
            talk('fourth', F, arrows=['a5h5', 'e4d3', 'd3c3', 'c3b4'],
                 marks=['a1', 'd4']),
            move('fourthA', F,
                 'Qf7+ Kd8 Qe6 Kc7 Kd3 Rc5 Kd4 Rc1 Qe3 Rc6 Qe7+ Kb6 Kd5'),
        ]},
        {'id': 'ponziani', 'steps': [
            think('t_ponziani', PONZIANI, 5, 1),
            talk('ponziani', PONZIANI, arrows=['f7g7', 'g7h7'],
                 marks=['g6', 'h7']),
            talk('desperado', after(MORO, 'Qg3+ Kh1 Kf3'), arrows=['h2f2'],
                 marks=['g1', 'g2', 'h2']),
            move('moro', MORO, 'Qe5 Kg1 Kg3 Rg2+ Kh3', accept={1: 'only'}),
        ]},
        {'id': 'map', 'steps': [
            think('t_browne', BROWNE, 5, 1),
            talk('map', BROWNE),
            talk('recap', T, arrows=['f7f4']),
            play('finish', T),
        ]},
    ],
    'exercises': [
        exercise('e12', 1, ADROOD, 'Qd5+', origin='adrood'),
        exercise('e18', 1, MORO93, 'Qf1+ Kd2 Qf3', origin='moro'),
        exercise('e14', 2, METHURST, 'Ke4 Rf1 Qg3 Rf6 Ke5 Rf7 Qd3',
                 origin='methurst'),
        exercise('e15', 2, after(F, 'Kd4 Ra1'), 'Qf7+ Kd6 Qb3',
                 origin='wikipedia'),
        exercise('e16', 3, after(F, 'Qf7+ Kd6'), 'Qe8 Kc7 Qe6 Rb5 Kd4',
                 origin='wikipedia'),
        exercise('e19', 3, MORO82, 'Qe5+ Kc6 Qf6 Rb8 Ke7+ Kb7 Qe5 Kc8 Kd6',
                 origin='moro'),
    ],
    'passScore': 8,
    'keyPositions': [
        {'id': 'third', 'fen': T, 'ref': 'wikipedia'},
        {'id': 'thirdA', 'fen': TA, 'ref': 'wikipedia'},
        {'id': 'fourth', 'fen': F, 'ref': 'wikipedia'},
        {'id': 'ponziani', 'fen': PONZIANI, 'ref': 'wikipedia'},
        {'id': 'browne', 'fen': BROWNE, 'ref': 'belle'},
    ],
    'practice': {'fen': BROWNE, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
})
