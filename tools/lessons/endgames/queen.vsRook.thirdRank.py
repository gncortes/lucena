"""Gera `queen.vsRook.thirdRank.json` (a fonte da aula) a partir dos lances em
SAN. Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/queen.vsRook.thirdRank.py`
e depois o `build_aula.py queen.vsRook.thirdRank`.

Lição refeita na T61/T63 (2026-10-09): oito partes, uma ideia cada, com demo.
As posições da partida Morozevich-Jakovenko levam o número real do lance no
FEN (o contador de meios-lances fica em 0 para a tabela)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

T = '3k4/5Q2/1r6/3K4/8/8/8/8 w - - 0 1'    # terceira fileira, torre em b6
TA = '3k4/5Q2/r7/3K4/8/8/8/8 w - - 0 1'    # terceira fileira, torre em a6
F = '8/3k4/5Q2/r7/4K3/8/8/8 w - - 0 1'     # quarta fileira (Nunn)
D4 = after(F, 'Qf7+ Kd8 Qe6 Kc7 Kd4 Ra1')   # linha A de Nunn com 3.Rd4 Ta1
R = '8/8/5k2/8/4QK2/8/7r/8 w - - 0 1'      # montada: a dama atrás do rei
LOOSE = 'k7/8/1K6/8/8/6r1/8/6Q1 w - - 0 1'  # montada: torre solta, tomar afoga
PONZIANI = '5k2/5r2/4Q3/6K1/8/8/8/8 b - - 0 1'
BROWNE = '2KQ4/8/8/8/2r5/2k5/8/8 w - - 0 1'
# Morozevich-Jakovenko, Pamplona 2006 (ply da url do Lichess no comentário).
M79 = '3r4/8/1k2K3/8/2Q5/8/8/8 b - - 0 79'      # ply 157
M81 = '6r1/8/2k1K3/8/3Q4/8/8/8 w - - 0 81'      # ply 160
M99 = '8/8/8/5K2/7r/2Q5/5k2/8 w - - 0 99'       # ply 196
M110 = '8/8/8/8/6K1/8/6kr/4Q3 w - - 0 110'      # ply 218
M110B = '8/8/8/8/6K1/6Q1/7r/7k w - - 0 111'     # ply 220
# Exercícios (T58): partidas e estudos abertos, conferidos na tabela.
ADROOD = 'k7/2r5/3Q4/1K6/8/8/8/8 w - - 0 1'     # estudo de adrood, lance 20
MORO93 = '8/8/5Q2/2K5/r7/3k4/8/8 w - - 0 1'     # Morozevich-Jakovenko, lance 93
MORO82 = '6r1/8/4K3/1k6/8/2Q5/8/8 w - - 0 1'    # Morozevich-Jakovenko, lance 82
METHURST = '8/6Q1/8/5r1k/8/4K3/8/8 w - - 0 1'   # estudo de methurst

MORO_URL = ('https://lichess.org/analysis/pgn/d4_Nf6_c4_e6_Nc3_Bb4_Qc2_c5_dxc5_O-O_a3_Bxc5_Nf3_b6_e4_Nc6_Bd3_Ng4_O-O_Qc7_Nb5_Qb8_h3_Nge5_Nxe5_Nxe5_Be2_a6_Nc3_Qc7_Kh1_Bb7_f4_Nc6_Bd3_Nd4_Qd1_f5_b4_Be7_Bb2_fxe4_Bxe4_Nf5_Qd3_Bxe4_Nxe4_Rac8_Rac1_Qb7_Kh2_d5_cxd5_Qxd5_Qe2_Rxc1_Rxc1_Nd6_Rc7_Rf7_Nc3_Qf5_Bc1_b5_Rc6_Bf8_Rxa6_Rc7_Bd2_Nc4_Be1_Rd7_Nxb5_Nd6_Nc3_Qxf4+_Bg3_Qc4_Ra8_Qxe2_Nxe2_Kf7_Nd4_Nc4_Nc6_Bd6_Bxd6_Rxd6_b5_Rd5_a4_e5_Ra7+_Ke6_Rxg7_Kd6_Rxh7_e4_Rh4_Nd2_Rh6+_Kc5_Re6_e3_g4_Rd3_Kg3_Ra3_Kf4_Nf1_Re4_Ra2_Nd4_Rf2+_Ke5_Nd2_Ne6+_Kb6_Rxe3_Nc4+_Kd4_Nxe3_Kxe3_Ra2_g5_Ra3+_Kf4_Rxh3_g6_Rh8_g7_Rg8_Ke5_Ka5_Kf6_Kxa4_Nd4_Rd8_Ke7_Rxd4_g8=Q_Kxb5_Qc8_Rd5_Ke6_Rd4_Ke5_Rd3_Qc2_Rd8_Qb3+_Kc5_Qc3+_Kb5_Ke6_Kb6_Qc4_Rg8_Qd4+_Kc6_Qc3+_Kb5_Kd6_Rg6+_Kc7_Rg4_Qc6+_Kb4_Qd6+_Kc3_Kc6_Rd4_Qa3+_Kd2_Kc5_Re4_Kd5_Rg4_Qf3_Rb4_Kc5_Ra4_Qf6_Kd3_Qd6+_Ke3_Qg3+_Ke2_Qc3_Rf4_Kd5_Rg4_Ke5_Rh4_Kf5_Kf2_Qd3_Rh7_Qd4+_Kf3_Kg5_Rh2_Qf4+_Kg2_Kg4_Kg1_Qd4+_Kg2_Qd3_Kg1_Qe3+_Kf1_Qc1+_Kf2_Qd2+_Kg1_Qe1+_Kg2_Qg3+_Kh1_Kf3_Rf2+_Ke3_Re2+_Kd3_Rd2+_Kxd2')


def ref(step, where):
    """O passo vem de uma partida ou estudo: `where` é o id da referência,
    com `#ply` quando a partida está parada noutro lance."""
    step['ref'] = where
    return step


REFERENCES = [
    {'id': 'wikipedia', 'kind': 'web',
     'title': 'Queen versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Queen_versus_rook_endgame'},
    {'id': 'pawnless', 'kind': 'web',
     'title': 'Pawnless chess endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Pawnless_chess_endgame'},
    {'id': 'moro', 'kind': 'game', 'white': 'Alexander Morozevich',
     'black': 'Dmitry Jakovenko', 'event': 'XVI Magistral A, Pamplona',
     'year': 2006, 'url': MORO_URL},
    {'id': 'pgnmentor', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Morozevich (Morozevich.zip)',
     'url': 'https://www.pgnmentor.com/players/Morozevich.zip'},
    {'id': 'belle', 'kind': 'game', 'white': 'Walter Browne',
     'black': 'Belle (computador)', 'event': 'Desafio de dama contra torre, revanche',
     'year': 1978,
     'url': 'https://lichess.org/analysis/standard/2KQ4/8/8/8/2r5/2k5/8/8_w_-_-_0_1'},
    {'id': 'belleGame', 'kind': 'web',
     'title': 'Walter Browne vs Belle (Computer) (1978), chessgames.com',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=1480951'},
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
            ref(think('t_third', T, 2, marks=['a6', 'b6', 'h6']), 'wikipedia'),
            ref(talk('barrier', T,
                     arrows=['d5c6', 'd5d6', 'd5e6', 'f7f6', 'f7g6'],
                     marks=['a6', 'b6', 'h6']), 'wikipedia'),
            demo('d_fork', T, 'Qf4 Rg6 Qf8+ Kd7 Qf7+ Kd8 Qxg6', notes={
                1: {'arrows': ['f4b8', 'f4f8', 'f4h6']},
                5: {'arrows': ['f7g6']}}),
            move('ra6', after(T, 'Qf4 Ra6'), 'Qb8+ Ke7 Qb7+'),
        ]},
        {'id': 'best', 'steps': [
            think('t_best', after(T, 'Qf4 Kd7'), 2),
            talk('switch', after(T, 'Qf4 Kd7'), arrows=['f4a4', 'a4a7']),
            demo('d_switch', after(T, 'Qf4 Kd7'),
                 'Qa4+ Kc7 Qa7+ Rb7 Qc5+ Kb8 Kd6', notes={
                     3: {'arrows': ['a7c7', 'a7b6']}, 7: {'marks': ['d6']}}),
            move('home',
                 after(T, 'Qf4 Kd7 Qa4+ Kc7 Qa7+ Rb7 Qc5+ Kb8 Kd6 Rg7'),
                 'Qe5 Rc7 Qf4 Kc8 Qf5+ Kb8 Qe5'),
        ]},
        {'id': 'edge', 'steps': [
            ref(think('t_thirdA', TA, 2), 'wikipedia'),
            ref(talk('a6', TA, arrows=['d5b5'], marks=['a6']),
                'wikipedia'),
            demo('d_around', TA, 'Kc5 Kc8 Qe7 Kb8 Kb5 Ra7', notes={
                1: {'arrows': ['c5b5']}, 5: {'arrows': ['b5a6']}}),
            move('kc8', after(T, 'Qf4 Kc8'),
                 'Kc5 Ra6 Qe4 Kc7 Qe7+ Kb8 Kb5'),
        ]},
        {'id': 'fourth', 'steps': [
            ref(think('t_fourth', F, 2), 'wikipedia'),
            ref(talk('fourth', F, arrows=['a5h5'], marks=['d7']),
                'wikipedia'),
            demo('d_fourth', F, 'Qf7+ Kd8 Qe6 Kc7 Kd3 Rc5 Kd4', notes={
                3: {'marks': ['c7']}, 7: {'arrows': ['d4c5']}}),
            ref(move('m99', M99, 'Qd3 Rh7 Qd4+ Kf3 Kg5'), 'moro#196'),
        ]},
        {'id': 'diagonal', 'steps': [
            think('t_diag', D4, 2, marks=['d1', 'a4']),
            ref(talk('diag', M79, arrows=['d8g8'], marks=['e6', 'g8']),
                'moro#157'),
            demo('d_diag', D4, 'Qb3 Kd6 Qb4+ Ke6 Kc5', notes={
                1: {'arrows': ['b3d1', 'b3a4']}}),
            move('diagB', after(D4, 'Qb3 Kd7'), 'Kc4', accept='only'),
        ]},
        {'id': 'behind', 'steps': [
            ref(think('t_behind', M81, 2), 'moro#160'),
            ref(talk('behind', M81, arrows=['e6e7', 'd4g7'], marks=['g7', 'e8']),
                'moro#160'),
            demo('d_behind', R, 'Qf3 Rh7 Kg4+ Kg6 Qe4+ Kh6', notes={
                1: {'arrows': ['f3f6']}, 3: {'arrows': ['f3f6']}}),
            move('behindB', after(R, 'Qf3 Rh7 Kg4+ Kg6 Qe4+ Kh6'), 'Kf5',
                 accept='only'),
        ]},
        {'id': 'stalemate', 'steps': [
            ref(think('t_ponziani', PONZIANI, 2), 'wikipedia'),
            ref(talk('ponziani', PONZIANI, arrows=['f7g7'], marks=['e6']),
                'wikipedia'),
            ref(demo('d_desperado', M110B, 'Kf3 Rf2+ Ke3 Re2+ Kd3 Rd2+ Kxd2',
                     goal='draw', notes={2: {'arrows': ['h2f2']}}),
                'moro#220'),
            ref(move('moro', M110, 'Qe5 Kg1 Kg3 Rg2+ Kh3', accept={1: 'only'}),
                'moro#218'),
            move('loose', LOOSE, 'Qa1+ Kb8 Qh8+'),
        ]},
        {'id': 'map', 'steps': [
            ref(think('t_browne', BROWNE, 2), 'belle'),
            ref(talk('map', BROWNE), 'belle'),
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
