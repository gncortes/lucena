"""Gera `queen.vsRook.approach.json` (a fonte da aula) a partir dos lances em
SAN. Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/queen.vsRook.approach.py`
e depois o `build_aula.py queen.vsRook.approach`."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, exercise, move, play, talk, think,  # noqa: E402
                         write)

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
# Exercícios (T58): posições que a lição não mostra.
NUNN70 = 'Q7/2kr4/8/2K5/8/8/8/8 b - - 0 1'   # Nunn #70, via ColinParker
ROOK_D1 = after(NUNN70, 'Rd1 Qc6+ Kb8')
# Defesa A com 3...Te1 e os três xeques da Wikipedia (4.Dd6+ 5.Da6+ 6.Db5+).
ROOK_E1 = after(S, 'Qf5+ Kd8 Kc5 Kc7 Qd5 Re1 Qd6+ Kc8 Qa6+ Kb8 Qb5+ Kc8')
DEF_B = after(S, 'Qf5+ Kd8 Kc5 Re1 Qd3+ Ke7')    # defesa B, a torre foge
# Hannes Stefánsson x Karsten Müller (1992), antes do 72º lance das brancas.
HANNES = after('8/8/8/Q4r2/4k2K/8/8/8 w - - 0 1', 'Qb4+ Kd5 Kg4 Rf6')
# Nunn #69, via ColinParker: a ameaça tripla depois de 8...Ra6.
TRIPLE = after('2Q5/3rk3/8/4K3/8/8/8/8 b - - 0 1',
               'Rd2 Qc5+ Kd7 Qb5+ Kc8 Ke6 Rc2 Kd6 Rh2 Qf5+ Kb7 Kc5 Rh6 '
               'Qf7+ Ka6')

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
    {'id': 'hannes', 'kind': 'game', 'white': 'Hannes Stefánsson',
     'black': 'Karsten Müller', 'event': 'Partida comentada por Nunn (via Wikipedia)',
     'year': 1992},
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
    'skills': ['queen.vsRook'],
    'parts': [
        {'id': 'second', 'steps': [
            think('t_second', S, 5, 1),
            talk('intro', S, marks=['c8', 'e7'], arrows=['e7e6', 'e7b7']),
            talk('stale', after(S, 'Qd6 Rb7+ Kc6 Rb6+'),
                 arrows=['c6b6', 'd6b6'], marks=['b6']),
            move('open', S, 'Qf5+ Kd8 Kc5'),
        ]},
        {'id': 'defenses', 'steps': [
            talk('fork3', S2, arrows=['d8c7', 'd8e8', 'e7e1']),
            move('a1', A, 'Qd5 Rd7 Qe5+ Kb7 Kb5'),
            move('a2', after(A, 'Qd5 Rd7 Qe5+ Kb7 Kb5 Rc7'),
                 'Qe8 Ka7 Qe4 Rb7+ Kc6 Ka8 Qd5 Ka7 Qd8'),
            move('c1', C, 'Qc8+ Kf7 Kd6 Ra7 Qc4+ Kf8 Ke6'),
            move('c2', after(C, 'Qc8+ Kf7 Kd6 Ra7 Qc4+ Kf8 Ke6 Rf7'),
                 'Qc5+ Kg8 Qd5 Rg7 Kf6+ Kh7 Qh1+ Kg8 Qh5'),
        ]},
        {'id': 'diagonal', 'steps': [
            think('t_diagonal', D, 5, 1, ask='line'),
            talk('diagonal', D, arrows=['e5b8'],
                 marks=['b8', 'c7', 'd6', 'e5']),
            move('discover', D,
                 'Qf4 Kc8 Qf5+ Kb8 Qe5 Rb7 Kc6+ Ka8 Qa1+ Kb8 Qa5',
                 accept={1: ['Qf4', 'Qd5', 'Qe3']}),
            talk('checks', N, arrows=['f7f5', 'f7g7'], marks=['g7']),
            move('quiet', N, 'Qd8 Kh7 Qd4 Rg7+ Kf6 Rg6+ Kf7'),
        ]},
        {'id': 'ladder', 'steps': [
            think('t_ladder', L, 5, 1, ask='line'),
            talk('ladder', L, arrows=['h7g7', 'e5e4'], marks=['g5', 'g3']),
            move('climb', L,
                 'Qg7+ Kh4 Qh6+ Kg4 Ke4 Rg2 Qg6+ Kh3 Qh5+ Kg3 Ke3'),
            talk('recap', S, arrows=['d5f5', 'b6c5']),
            play('finish', S),
        ]},
    ],
    'exercises': [
        exercise('e12', 1, ROOK_D1, 'Qe4 Rd7 Kc6', origin='parker'),
        exercise('e05', 2, BERGER, 'Qe5', accept={1: ['Qe5', 'Qd4']},
                 origin='wikipedia'),
        exercise('e13', 2, ROOK_E1, 'Qc4 Kc7 Qf4+ Kc8 Qg4+ Kd8 Qh4+',
                 origin='wikipedia'),
        exercise('e14', 3, DEF_B,
                 'Kd5 Kf7 Qf3+ Ke7 Qg4 Kf7 Qf4+ Ke8 Kd6 Rd1+ Ke6 Re1+ Kf6',
                 origin='wikipedia'),
        exercise('e15', 3, HANNES,
                 'Qb5+ Kd6 Kg5 Re6 Kf5 Re7 Qb6+ Kd7 Kf6', origin='hannes'),
        exercise('e16', 3, TRIPLE, 'Qf8 Rh5+ Kc6', origin='parker'),
    ],
    'passScore': 9,
    'keyPositions': [
        {'id': 'second', 'fen': S, 'ref': 'wikipedia'},
        {'id': 'diagonal', 'fen': D, 'ref': 'unto'},
        {'id': 'ladder', 'fen': L, 'ref': 'belle'},
    ],
    'practice': {'fen': S, 'goal': 'win',
                 'positionId': 'queen.queenVsRook.0002'},
    'references': REFERENCES,
})
