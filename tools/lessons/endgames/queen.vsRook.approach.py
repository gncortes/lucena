"""Gera `queen.vsRook.approach.json` (a fonte da aula) a partir dos lances em
SAN. Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/queen.vsRook.approach.py`
e depois o `build_aula.py queen.vsRook.approach`."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import after, exercise, move, play, talk, write  # noqa: E402

S = '2k5/4r3/1K6/3Q4/8/8/8/8 w - - 0 1'   # segunda fileira (Euwe)
S2 = after(S, 'Qf5+ Kd8 Kc5')              # depois de 2.Kc5, pretas jogam
A = after(S, 'Qf5+ Kd8 Kc5 Kc7')           # defesa A: o rei volta
C = after(S, 'Qf5+ Kd8 Kc5 Ke8')           # defesa C: o rei foge pelo outro lado
N = '4Q3/5rk1/8/6K1/8/8/8/8 w - - 0 1'     # Nunn: tirar os xeques
D = '1k6/2r5/3K4/4Q3/8/8/8/8 w - - 0 1'    # posição diagonal
DISCO = '8/k7/1r6/2K5/3Q4/8/8/8 w - - 0 1'
BERGER = '8/rk6/8/1KQ5/8/8/8/8 w - - 0 1'
# A escada, da revanche Browne x Belle (1978), depois de 37.Ke5 Rg3.
L = after('7Q/8/4K1k1/8/6r1/8/8/8 w - - 0 1', 'Qg8+ Kh5 Qh7+ Kg5 Ke5 Rg3')
L_END = after(L, 'Qg7+ Kh4 Qh6+ Kg4 Ke4 Rg2 Qg6+ Kh3 Qh5+ Kg3 Ke3 Rg1 '
                 'Qg5+ Kh2 Qh4+ Kg2 Ke2 Ra1')

REFERENCES = [
    {'id': 'wikipedia', 'kind': 'web',
     'title': 'Queen versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Queen_versus_rook_endgame'},
    {'id': 'belle', 'kind': 'game', 'white': 'Walter Browne',
     'black': 'Belle (computador)', 'event': 'Desafio de dama contra torre, revanche',
     'year': 1978},
    {'id': 'belle1979', 'kind': 'web',
     'title': 'Stenberg, Conway e Larkins: Queen vs. Rook (1979, cópia Usenet)',
     'url': 'http://quux.org:70/Archives/usenet-a-news/NET.chess/82.01.07_sri-unix.458_net.chess.txt'},
    {'id': 'calmodee', 'kind': 'study', 'author': 'calmodee',
     'title': 'Queen Vs. Rook Endgame (Intro)',
     'url': 'https://lichess.org/study/enHKHI2k'},
    {'id': 'unto', 'kind': 'study', 'author': 'Unto',
     'title': 'Queen vs Rook',
     'url': 'https://lichess.org/study/LTWpoOgD'},
    {'id': 'vince', 'kind': 'study', 'author': 'Coach_Vince',
     'title': 'Queen versus Rook endgame',
     'url': 'https://lichess.org/study/zfcueYR4'},
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
    'id': 'queen.vsRook.approach',
    'module': 'queen',
    'steps': [
        talk('intro', S, marks=['c8', 'e7'], arrows=['e7e6', 'e7b7']),
        talk('stale', after(S, 'Qd6 Rb7+ Kc6 Rb6+'), arrows=['c6b6', 'd6b6'],
             marks=['b6']),
        move('open', S, 'Qf5+ Kd8 Kc5'),
        talk('fork3', S2, arrows=['d8c7', 'd8e8', 'e7e1']),
        move('a1', A, 'Qd5 Rd7 Qe5+ Kb7 Kb5'),
        move('a2', after(A, 'Qd5 Rd7 Qe5+ Kb7 Kb5 Rc7'),
             'Qe8 Ka7 Qe4 Rb7+ Kc6 Ka8 Qd5 Ka7 Qd8'),
        move('c1', C, 'Qc8+ Kf7 Kd6 Ra7 Qc4+ Kf8 Ke6'),
        move('c2', after(C, 'Qc8+ Kf7 Kd6 Ra7 Qc4+ Kf8 Ke6 Rf7'),
             'Qc5+ Kg8 Qd5 Rg7 Kf6+ Kh7 Qh1+ Kg8 Qh5'),
        talk('checks', N, arrows=['f7f5', 'f7g7'], marks=['g7']),
        move('quiet', N, 'Qd8 Kh7 Qd4 Rg7+ Kf6 Rg6+ Kf7'),
        talk('diagonal', D, arrows=['e5b8'], marks=['b8', 'c7', 'd6', 'e5']),
        move('discover', D, 'Qf4 Kc8 Qf5+ Kb8 Qe5 Rb7 Kc6+ Ka8 Qa1+ Kb8 Qa5',
             accept={1: ['Qf4', 'Qd5', 'Qe3']}),
        talk('ladder', L, arrows=['h7g7', 'e5e4'], marks=['g5', 'g3']),
        move('climb', L, 'Qg7+ Kh4 Qh6+ Kg4 Ke4 Rg2 Qg6+ Kh3 Qh5+ Kg3 Ke3'),
        talk('recap', S, arrows=['d5f5', 'b6c5']),
        play('finish', S),
    ],
    'exercises': [
        exercise('e01', 1, S, 'Qf5+', origin='wikipedia'),
        exercise('e02', 1, after(S, 'Qf5+ Kd8'), 'Kc5', origin='wikipedia'),
        exercise('e03', 1, after(D, 'Qf4 Kc8 Qf5+ Kb8 Qe5 Rb7'), 'Kc6+',
                 origin='unto'),
        exercise('e04', 1, L, 'Qg7+', origin='belle'),
        exercise('e05', 2, BERGER, 'Qe5', accept={1: ['Qe5', 'Qd4']},
                 origin='wikipedia'),
        exercise('e06', 2, N, 'Qd8 Kh7 Qd4', origin='wikipedia'),
        exercise('e07', 2, DISCO, 'Qe3 Ka6 Qd3+ Ka7 Qd4',
                 accept={1: ['Qe3', 'Qf4', 'Qd5']}, origin='vince'),
        exercise('e08', 2, after(L, 'Qg7+ Kh4 Qh6+ Kg4 Ke4 Rg2'),
                 'Qg6+ Kh3 Qh5+ Kg3 Ke3', origin='belle'),
        exercise('e09', 2, L_END, 'Qe4+ Kh3 Qh7+ Kg3 Qg7+', origin='belle'),
        exercise('e10', 3, after(A, 'Qd5 Rd7 Qe5+ Kb7 Kb5 Rc7'),
                 'Qe8 Ka7 Qe4 Rb7+ Kc6', origin='wikipedia'),
        exercise('e11', 3, after(C, 'Qc8+ Kf7 Kd6 Ra7'),
                 'Qc4+ Kf8 Ke6 Rf7 Qc5+ Kg8 Qd5', origin='wikipedia'),
    ],
    'passScore': 13,
    'keyPositions': [
        {'id': 'second', 'fen': S, 'ref': 'wikipedia'},
        {'id': 'diagonal', 'fen': D, 'ref': 'unto'},
        {'id': 'ladder', 'fen': L, 'ref': 'belle'},
        {'id': 'berger', 'fen': BERGER, 'ref': 'wikipedia'},
    ],
    'practice': {'fen': S, 'goal': 'win',
                 'positionId': 'queen.queenVsRook.0002'},
    'references': REFERENCES,
})
