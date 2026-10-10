"""Gera `queen.vsRook.approach.json` (a fonte da aula) a partir dos lances em
SAN. Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/queen.vsRook.approach.py`
e depois o `build_aula.py queen.vsRook.approach`.

Lição refeita na T61/T63 (2026-10-10): oito partes, uma ideia cada, com demo,
da posição mais perto de Philidor para a mais longe. As posições da partida
Hannes Stefánsson x Karsten Müller (Altensteig, 1992) levam o número real do
lance no FEN e o ply da url no `ref` do passo."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

D = '1k6/2r5/3K4/4Q3/8/8/8/8 w - - 0 1'    # posição diagonal (Unto)
DISC = after(D, 'Qf4 Kc8 Qf5+ Kb8 Qe5 Rb7')  # a diagonal com as pretas tendo jogado (lance 4)
S = '2k5/4r3/1K6/3Q4/8/8/8/8 w - - 0 1'    # segunda fileira (Euwe 1958)
A = after(S, 'Qf5+ Kd8 Kc5 Kc7')           # defesa A: o rei preto volta (lance 3)
KB5 = after(A, 'Qd5 Rd7 Qe5+ Kb7')         # o fim do demo de `kingBack` (lance 5)
ST = '2k5/3r4/2K2Q2/8/8/8/8/8 w - - 0 1'   # montada: Rb6? e a torre se oferece
N65 = '4Q3/5rk1/8/6K1/8/8/8/8 w - - 0 1'   # Nunn #65a, via ColinParker
N65B = '4Q3/6k1/8/6K1/8/8/8/5r2 w - - 0 1'  # Nunn #65b depois de 1...Tf1
TR1 = '1k6/8/K7/3r4/8/8/8/2Q5 w - - 0 1'   # montada: ameaça tripla
TR2 = '2k5/8/3K4/r7/8/8/8/6Q1 w - - 0 1'   # montada: ameaça tripla, outra geometria
# Hannes Stefánsson x Karsten Müller, Altensteig 1992 (ply da url no comentário).
H160 = '8/3Q4/2r5/2k2K2/8/8/8/8 w - - 0 81'   # ply 160
H164 = '8/1k6/2r5/4K3/3Q4/8/8/8 w - - 0 83'   # ply 164
H168 = '2k5/2r5/8/3K4/1Q6/8/8/8 w - - 0 85'   # ply 168
H176 = '4Q3/k1r5/8/1K6/8/8/8/8 w - - 0 89'    # ply 176
# Exercícios (T58): posições que a lição não mostra.
BERGER = '8/rk6/8/1KQ5/8/8/8/8 w - - 0 1'
NUNN70 = 'Q7/2kr4/8/2K5/8/8/8/8 b - - 0 1'   # Nunn #70, via ColinParker
ROOK_D1 = after(NUNN70, 'Rd1 Qc6+ Kb8')
# Defesa A com 3...Te1 e os três xeques da Wikipedia (4.Dd6+ 5.Da6+ 6.Db5+).
ROOK_E1 = after(S, 'Qf5+ Kd8 Kc5 Kc7 Qd5 Re1 Qd6+ Kc8 Qa6+ Kb8 Qb5+ Kc8')
DEF_B = after(S, 'Qf5+ Kd8 Kc5 Re1 Qd3+ Ke7')    # defesa B, a torre foge
# Hannes Stefánsson x Karsten Müller (1992), antes do 74º lance das brancas.
HANNES = after('8/8/8/Q4r2/4k2K/8/8/8 w - - 0 1', 'Qb4+ Kd5 Kg4 Rf6')
# Nunn #69, via ColinParker: a ameaça tripla depois de 8...Ra6.
TRIPLE = after('2Q5/3rk3/8/4K3/8/8/8/8 b - - 0 1',
               'Rd2 Qc5+ Kd7 Qb5+ Kc8 Ke6 Rc2 Kd6 Rh2 Qf5+ Kb7 Kc5 Rh6 '
               'Qf7+ Ka6')

HANNES_URL = ('https://lichess.org/analysis/pgn/e4_e6_d4_d5_Nc3_Bb4_e5_c5_a3_Ba5_b4_cxd4_Nb5_Bc7_f4_Bd7_Nf3_Bxb5_Bxb5+_Nc6_Bd3_Nge7_Qe2_Bb6_O-O_Nf5_Kh1_Qc7_a4_Nxb4_Bxf5_exf5_Qb5+_Nc6_Ba3_Qd7_Bd6_Na5_Qxd5_Qc6_Qa2_Qc4_Qb2_O-O-O_Rfd1_Nc6_Qb5_Na5_Nd2_Qc6_Qd3_g6_c3_dxc3_Rdc1_cxd2_Qxd2_Bc7_Rab1_Qxc1+_Qxc1_Rd7_Qe3_Nc6_Bc5_Rhd8_h3_a6_Kh2_Rd3_Qe2_Rd2_Qc4_R8d7_Qb3_Nd8_Qb4_Rc2_Be3_Rd3_Rb3_Ba5_Qa3_Rcc3_Rxc3+_Rxc3_Qe7_Rc4_e6_Rc7_exf7_Rxe7_f8=Q_Kd7_Bf2_Ne6_Qa8_Kc6_g3_Bc7_Qh8_Kd5_Kg2_Bd6_Bb6_Nc5_a5_Ne6_h4_Bc7_Qf6_Rd7_h5_Rd6_Qf7_Bxb6_Qxb7+_Kc5_axb6_Rxb6_Qxh7_gxh5_Qxf5+_Kc4_Qxh5_Nd4_Qf7+_Kd3_f5_Rb2+_Kh3_Rf2_g4_a5_Qa7_Ke4_Qxa5_Rf3+_Kh4_Nxf5+_gxf5_Rxf5_Qb4+_Kd5_Kg4_Rf6_Qe7_Re6_Qb7+_Kd4_Qd7+_Ke5_Kg5_Rd6_Qe7+_Kd5_Kf5_Rc6_Qd7+_Kc5_Ke5_Kb6_Qd4+_Kb7_Kd5_Rc7_Qb4+_Kc8_Qb5_Rh7_Qe8+_Kb7_Kc5_Rc7+_Kb5_Ka7_Qe4_Rb7+_Kc6_Ka8_Qe8+_Ka7_Qd8_Rb1_Qe7+_Kb8_Qf8+_Ka7_Qf2+_Kb8_Qh2+_Ka7_Qa2+_Kb8_Qxb1+_Kc8_Qb7+_Kd8_Qd7')


def num(fen, n):
    """O FEN com o número do lance `n`: o passo que continua o anterior
    segue a contagem (o `after()` zera o contador)."""
    return ' '.join(fen.split()[:5] + [str(n)])


def ref(step, where):
    """O passo vem de uma partida ou estudo: `where` é o id da referência,
    com `#ply` quando a partida está parada noutro lance."""
    step['ref'] = where
    return step


REFERENCES = [
    {'id': 'wikipedia', 'kind': 'web',
     'title': 'Queen versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Queen_versus_rook_endgame'},
    {'id': 'hannes', 'kind': 'game', 'white': 'Hannes Stefánsson',
     'black': 'Karsten Müller', 'event': 'Altensteig, rodada 9',
     'year': 1992, 'url': HANNES_URL},
    {'id': 'hannesGame', 'kind': 'web',
     'title': 'Hannes Stefansson vs Karsten Mueller (1992), chessgames.com',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=2211708'},
    {'id': 'untoDiag', 'kind': 'study', 'author': 'Unto',
     'title': 'Queen vs Rook: Diagonal Positions',
     'url': 'https://lichess.org/study/LTWpoOgD/so0FBgfk'},
    {'id': 'untoSecond', 'kind': 'study', 'author': 'Unto',
     'title': 'Queen vs Rook: Breaking 7th rank defense',
     'url': 'https://lichess.org/study/LTWpoOgD/hNSu4MRJ'},
    {'id': 'parker', 'kind': 'study', 'author': 'ColinParker',
     'title': "Q vs R endgame (From Nunn's Secrets of Pawnless Endings)",
     'url': 'https://lichess.org/study/dPt5h0yM'},
    {'id': 'parker65', 'kind': 'study', 'author': 'ColinParker',
     'title': 'Second Rank Defense #1, White to move (Nunn #65a)',
     'url': 'https://lichess.org/study/dPt5h0yM/zkt0FYD2'},
    {'id': 'parker65b', 'kind': 'study', 'author': 'ColinParker',
     'title': 'Second Rank Defense #1, Black to move (Nunn #65b)',
     'url': 'https://lichess.org/study/dPt5h0yM/ThIbAjaT'},
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
        {'id': 'diagonal', 'steps': [
            ref(think('t_diagonal', D, 2, ask='line'), 'untoDiag'),
            ref(talk('diagonal', D, arrows=['e5b8'],
                     marks=['b8', 'c7', 'd6', 'e5']), 'untoDiag'),
            ref(demo('d_diagonal', D, 'Qf4 Kc8 Qf5+ Kb8 Qe5 Rb7', notes={
                1: {'arrows': ['f4b8']},
                3: {'arrows': ['f5c8']},
                5: {'arrows': ['e5b8']}}), 'untoDiag'),
            move('discover', num(DISC, 4), 'Kc6+ Ka8 Qa1+ Kb8 Qa5'),
        ]},
        {'id': 'second', 'steps': [
            ref(think('t_second', S, 2), 'untoSecond'),
            ref(talk('intro', S, arrows=['e7b7', 'e7e6'], marks=['c8', 'e7']),
                'wikipedia'),
            demo('d_kc6', S, 'Qf5+ Kd8 Kc6 Re6+', notes={
                3: {'marks': ['e6']},
                4: {'arrows': ['e6c6'], 'marks': ['a6', 'b6']}}),
            ref(move('open', S, 'Qf5+ Kd8 Kc5'), 'untoSecond'),
        ]},
        {'id': 'kingBack', 'steps': [
            think('t_kingBack', num(A, 3), 2),
            # A partida chega aqui: o destino do plano, sem 89.De4 (é o e12).
            ref(talk('hannes', H176, marks=['b5', 'e8']), 'hannes#176'),
            demo('d_kingBack', num(A, 3), 'Qd5 Rd7 Qe5+ Kb7', notes={
                1: {'marks': ['b7', 'c6', 'd7']}}),
            move('m_kingBack', num(KB5, 5), 'Kb5 Rc7 Qe8 Ka7', accept='only'),
        ]},
        {'id': 'stalemate', 'steps': [
            think('t_stalemate', ST, 2),
            talk('stale', ST, arrows=['d7d6'], marks=['b6', 'b8', 'd8']),
            demo('d_trap', after(ST, 'Kb6'), 'Rd6+ Qxd6', goal='draw', notes={
                1: {'arrows': ['d6f6']},
                2: {'marks': ['b8', 'b7', 'c7', 'd7', 'd8']}}),
            move('m_pin', ST, 'Qe6 Kb8 Qxd7 Ka8 Qb7',
                 accept={1: ['Qe6', 'Qf5'], 3: 'only'}),
        ]},
        {'id': 'quiet', 'steps': [
            ref(think('t_quiet', N65, 2), 'parker65'),
            ref(talk('quiet', N65, arrows=['f7g7'], marks=['f6', 'g7']),
                'parker65'),
            ref(demo('d_quiet', N65, 'Qd8 Kh7 Qd4 Rg7+ Kf6', notes={
                3: {'arrows': ['d4g7']},
                5: {'marks': ['g6', 'f7']}}), 'parker65'),
            ref(demo('d_loose', N65B, 'Qe5+ Kf7 Qe3 Ra1', notes={
                3: {'marks': ['f2', 'f3', 'f4', 'g1']}}), 'parker65b'),
            ref(move('m_loose', num(after(N65B, 'Qe5+ Kf7 Qe3 Ra1'), 3),
                     'Qf4+ Kg8 Qc4+ Kh7 Qf7+ Kh8 Qf6+'), 'parker65b'),
        ]},
        {'id': 'triple', 'steps': [
            think('t_triple', TR1, 3),
            talk('triple', TR1, marks=['b7', 'd5']),
            demo('d_triple', TR1, 'Qc6 Ra5+ Kxa5', notes={
                1: {'arrows': ['c6b7', 'c6d5']}}),
            move('m_triple', TR2, 'Qb6 Rc5 Qxc5+', accept={1: ['Qb6']}),
        ]},
        {'id': 'center', 'steps': [
            ref(think('t_center', H160, 2), 'hannes#160'),
            ref(talk('center', H160, arrows=['f5e5'], marks=['c5']),
                'hannes#160'),
            ref(demo('d_center', H160, 'Ke5 Kb6 Qd4+ Kb7', notes={
                1: {'arrows': ['f5e5']},
                3: {'arrows': ['d4b6']}}), 'hannes#160'),
            ref(move('m_center', H164, 'Kd5 Rc7 Qb4+ Kc8',
                     accept={2: ['Qb4+', 'Qa4']}), 'hannes#164'),
        ]},
        {'id': 'walk', 'steps': [
            ref(think('t_walk', H168, 2), 'hannes#168'),
            ref(talk('walk', H168, marks=['c7', 'c8']),
                'hannes#168'),
            ref(demo('d_walk', H168, 'Qb5 Rh7 Qe8+ Kb7 Kc5 Rc7+ Kb5', notes={
                6: {'arrows': ['c7c5']}}), 'hannes#168'),
            ref(move('m_walk', H168, 'Qa4 Rd7+ Kc6 Rc7+ Kd6',
                     accept={1: ['Qa4']}), 'hannes#168'),
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
        {'id': 'diagonal', 'fen': D, 'ref': 'untoDiag'},
    ],
    'practice': {'fen': S, 'goal': 'win',
                 'positionId': 'queen.queenVsRook.0002'},
    'references': REFERENCES,
})
