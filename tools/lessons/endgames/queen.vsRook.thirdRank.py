"""Gera `queen.vsRook.thirdRank.json` (a fonte da aula) a partir dos lances em
SAN. Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/queen.vsRook.thirdRank.py`
e depois o `build_aula.py queen.vsRook.thirdRank`."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import after, exercise, move, play, talk, write  # noqa: E402

T = '3k4/5Q2/1r6/3K4/8/8/8/8 w - - 0 1'    # terceira fileira, torre em b6
TA = '3k4/5Q2/r7/3K4/8/8/8/8 w - - 0 1'    # terceira fileira, torre em a6
TB = after(T, 'Qf4')                        # depois de 1.Qf4, pretas jogam
F = '8/3k4/5Q2/r7/4K3/8/8/8 w - - 0 1'     # quarta fileira (Nunn)
SEVEN = '3k4/1Q6/3r4/5K2/8/8/8/8 w - - 0 1'
PONZIANI = '5k2/5r2/4Q3/6K1/8/8/8/8 b - - 0 1'
MORO = '8/8/8/8/6K1/8/6kr/4Q3 w - - 0 1'   # Morozevich-Jakovenko, lance 110
BROWNE = '2KQ4/8/8/8/2r5/2k5/8/8 w - - 0 1'

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
    'steps': [
        talk('intro', T, arrows=['b6h6'],
             marks=['a6', 'b6', 'c6', 'd6', 'e6', 'f6', 'g6', 'h6']),
        talk('seven', T, arrows=['f7f6', 'f7g6', 'd5c6', 'd5d6', 'd5e6'],
             marks=['b6']),
        talk('quietMove', TB, arrows=['f4b8', 'f4f8', 'f4h6'],
             marks=['a6', 'c6', 'g6', 'h6']),
        move('rg6', after(TB, 'Rg6'), 'Qf8+ Kd7 Qf7+'),
        move('ra6', after(TB, 'Ra6'), 'Qb8+ Ke7 Qb7+'),
        move('rb7', after(TB, 'Rb7'), 'Kc6'),
        move('switch', T, 'Qf4 Kd7 Qa4+ Kc7 Qa7+ Rb7 Qc5+ Kb8 Kd6'),
        move('home', after(T, 'Qf4 Kd7 Qa4+ Kc7 Qa7+ Rb7 Qc5+ Kb8 Kd6 Rg7'),
             'Qe5 Rc7 Qf4 Kc8 Qf5+ Kb8 Qe5'),
        talk('a6', TA, arrows=['d5c5', 'c5b5'], marks=['a6']),
        move('around', TA, 'Kc5 Kc8 Qe7 Kb8 Kb5'),
        talk('fourth', F, arrows=['a5h5', 'e4d3', 'd3c3', 'c3b4'],
             marks=['a1', 'd4']),
        move('fourthA', F, 'Qf7+ Kd8 Qe6 Kc7 Kd3 Rc5 Kd4 Rc1 Qe3 Rc6 Qe7+ Kb6 Kd5'),
        talk('ponziani', PONZIANI, arrows=['f7g7', 'g7h7'], marks=['g6', 'h7']),
        talk('desperado', after(MORO, 'Qg3+ Kh1 Kf3'), arrows=['h2f2'],
             marks=['g1', 'g2', 'h2']),
        move('moro', MORO, 'Qe5 Kg1 Kg3 Rg2+ Kh3', accept={1: 'only'}),
        talk('map', BROWNE),
        talk('recap', T, arrows=['f7f4']),
        play('finish', T),
    ],
    'exercises': [
        exercise('e01', 1, T, 'Qf4', origin='wikipedia'),
        exercise('e02', 1, after(TB, 'Rg6'), 'Qf8+ Kd7 Qf7+', origin='cgbarros'),
        exercise('e03', 1, after(TB, 'Ra6'), 'Qb8+ Ke7 Qb7+', origin='cgbarros'),
        exercise('e04', 1, after(TB, 'Rb2'), 'Qf6+', origin='cgbarros'),
        exercise('e05', 2, after(TB, 'Kd7'), 'Qa4+ Kc7 Qa7+ Rb7 Qc5+',
                 origin='wikipedia'),
        exercise('e06', 2, TA, 'Kc5 Kc8 Qe7', origin='wikipedia'),
        exercise('e07', 2, MORO, 'Qe5 Kg1 Kg3', accept={1: 'only'}, origin='moro'),
        exercise('e08', 2, SEVEN, 'Qf7 Rb6 Ke5 Rc6 Kd5', origin='parker'),
        exercise('e09', 3, F, 'Qf7+ Kd8 Qe6 Kc7 Kd3', origin='wikipedia'),
        exercise('e10', 3, after(TB, 'Kc8'), 'Kc5 Ra6 Qe4 Kc7 Qe7+ Kb8 Kb5',
                 origin='wikipedia'),
        exercise('e11', 3, PONZIANI, 'Rg7+ Kf6 Rg6+', accept='hold',
                 goal='draw', origin='wikipedia'),
    ],
    'passScore': 13,
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
