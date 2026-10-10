"""Gera `queen.vsRook.philidor.json` (a fonte da aula) a partir dos lances em
SAN. Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/queen.vsRook.philidor.py`
e depois o `build_aula.py queen.vsRook.philidor`.

Lição refeita na T63 (ver docs/aulas/queen.vsRook.philidor.md, "Lição refeita").
As partidas vêm do PGN Mentor (players/<Sobrenome>.zip) e foram reproduzidas
com python-chess; o ply de cada passo está no `ref`."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

B = '1k6/1r6/2K5/Q7/8/8/8/8 b - - 0 1'  # Philidor, pretas jogam
W = '1k6/1r6/2K5/Q7/8/8/8/8 w - - 0 1'  # Philidor, brancas jogam

# Partidas (PGN Mentor), em SAN separado por _ para a url do Lichess.
LICHESS = 'https://lichess.org/analysis/pgn/'
GELFAND_PGN = 'Nf3_Nf6_c4_e6_d4_d5_g3_Be7_Bg2_O-O_O-O_dxc4_Qc2_a6_a4_Bd7_Qxc4_Bc6_Bg5_Bd5_Qd3_Be4_Qe3_Nbd7_Nc3_Bc6_Qd3_h6_Bxf6_Nxf6_e4_b6_Rfd1_Bb7_d5_Bc5_Ne5_exd5_Nxd5_Nxd5_exd5_Qf6_Nd7_Qxf2+_Kh1_Rfd8_Rf1_Qe3_Qf5_Qe7_Nxc5_bxc5_Rae1_Qd7_Qxd7_Rxd7_Rc1_Bxd5_Rxc5_Bxg2+_Kxg2_Rd2+_Rf2_Rxf2+_Kxf2_Rb8_Rc2_Rb4_Ke3_Rxa4_Rxc7_Rb4_Rc2_a5_Kd2_a4_Rc8+_Kh7_Kc3_Rb3+_Kc2_Rf3_Ra8_Rf2+_Kc3_Rxh2_Rxa4_Rh3_b4_Rxg3+_Kc4_h5_Ra1_h4_b5_Re3_b6_Re8_b7_Rb8_Rb1_g5_Kd5_h3_Ke4_h2_Kf5_Rxb7_Rh1_Rb2_Kxg5_Kg7_Kg4_Kg6_Kg3_Kg5_Rf1_f5_Kh3_Rf2_Ra1_Re2_Rh1_Kf4_Rf1+_Ke4_Kg3_Ke5_Ra1_f4+_Kf3_Ra2_Rh1_Rb2_Kg4_Rf2_Kh3_Ke4_Re1+_Kd3_Ra1_Rd2_Ra3+_Kc2_Ra2+_Kb1_Rxd2_h1=Q+_Kg4_Kc1_Rd3_Qe4_Rf3_Kd2_Rxf4_Qg6+_Kf3_Kd3_Kf2_Qg5_Kf3_Qg1_Rf5_Qe3+_Kg4_Ke4_Rf8_Qg1+_Kh5_Qg7_Rf1_Qe5+_Kg4_Qe6+_Kg5_Qg8+_Kh4_Qg6_Kh3_Ke3_Kh4_Qh7+_Kg3_Qg8+_Kh3_Qg5_Kh2_Ke2_Rg1_Qf4+_Kh3_Qh6+_Kg3_Qe3+_Kh2_Kf2_Rg2+_Kf1_Rg4_Qe5+_Kh3_Kf2_Kh4_Kf3_Rg6_Qe7+_Kh5_Kf4_Kh6_Qh4+_Kg7_Kf5_Rh6_Qe7+_Kg8_Kg5_Rh7_Qe8+_Kg7_Qe5+_Kf7_Qd5+_Kg7_Qd6_Kg8_Kg6_Rg7+_Kf6_Rf7+_Ke6_Kg7_Qg3+_Kf8_Qh4_Kg8_Qg5+_Rg7_Qd8+_Kh7_Qh4+_Kg8_Qh5_Ra7_Qg6+_Kh8_Qf6+_Rg7_Qh6+_Kg8_Qh2_Rg6+_Ke7_Rg7+_Ke8_Rg6_Qh5_Kg7_Ke7'
CARLSEN_PGN = 'e4_e5_Bc4_Nf6_d3_c6_Nf3_d5_Bb3_a5_a4_Bb4+_c3_Bd6_exd5_cxd5_Bg5_Be6_Na3_Nc6_Nb5_Bb8_Qe2_O-O_O-O-O_Re8_Rhe1_h6_Bh4_d4_Qc2_Bxb3_Qxb3_Ba7_Kb1_dxc3_bxc3_Bb6_Nd2_Bc5_Bxf6_Qxf6_Nc7_Qg6_Ne4_Be7_Re3_Kh8_Nxa8_Rxa8_Rg3_Qh5_Rf3_Rf8_Ng3_Qg6_Nf5_Bg5_g4_Bf4_h3_Rb8_Kc2_Na7_Qd5_f6_Rb1_Qe8_Qxa5_Nc6_Qc7_Qg8_Rb3_Rc8_Qxb7_Na5_Ne7_Nxb7_Nxg8_Rc7_Nxf6_gxf6_d4_Kg7_Rb5_Nd6_Rc5_Ra7_a5_Ne4_Rb5_Ng5_Rd3_e4_Rd1_Nxh3_Rf1_Kg6_c4_Bc7_Ra1_Nxf2_a6_Bf4_Rb7_Ra8_Re7_Nxg4_Rxe4_Kf5_Re7_h5_a7_h4_Rh7_Bg3_Kc3_Kg6_Rb7_h3_c5_h2_c6_Nf2_c7_Bxc7_Rxc7_h1=Q_Rxh1_Nxh1_d5_Ng3_Kd4_Kf5_d6_Ke6_d7_Nf5+_Kd3_Nd6_Rc8_Rxa7_d8=Q_Nxc8_Qxc8+_Rd7+_Ke4_Ke7_Qc5+_Ke6_Qc4+_Ke7_Kf5_Kd6_Kxf6_Rc7_Qd4+_Kc6_Ke6_Kb7_Qb4+_Kc8_Qb5_Rb7_Qc6+_Kb8_Kd6_Ka7_Qc5+_Kb8_Qa5_Ra7_Qb6+_Rb7_Qd8+_Ka7_Qa5+_Kb8_Kc6_Rh7_Qb4+_Ka7_Qa3+_Kb8_Qb3+'
SVIDLER_PGN = 'Nf3_Nf6_c4_g6_Nc3_d5_Qa4+_Bd7_Qb3_dxc4_Qxc4_a6_e4_b5_Qe2_Bc8_d4_Bg7_g3_c5_dxc5_O-O_Bg2_Be6_e5_Nfd7_O-O_Nxc5_Rd1_Nbd7_Nd4_Bc4_Qe3_Nxe5_Nc6_Nxc6_Rxd8_Raxd8_Qxc5_Bxc3_Bxc6_Rd1+_Kg2_Bf6_Bb7_Bf1+_Kf3_Rfd8_Be4_Re1_Qc2_Bg7_g4_h5_gxh5_f5_Bb7_gxh5_Qc7_Be2+_Kg3_Rg1+_Bg2_Rd3+_Be3_Rxa1_Qc8+_Kf7_Qxf5+_Bf6_h4_Rxe3+_fxe3_Bg4_Qh7+_Bg7_Be4_Kf8_Bg6_Rxa2_Bxh5_Bxh5_Qxh5_Rxb2_Qf5+_Bf6_e4_Rc2_h5_Rc3+_Kg2_Rc2+_Kf3_Rc3+_Ke2_b4_h6_Rc2+_Ke3_Rh2_Qg6_b3_h7_Bg7_e5_Rh6_Qf5+_Ke8_Kd2_e6_Qe4_Kf7_Kc3_Rh5_Kxb3_Rxe5_Qh4_Rd5_h8=Q_Bxh8_Qxh8_a5_Kc4_Rf5_Kd4_Rd5+_Ke4_Rf5_Qh7+_Ke8_Qg7_Rd5_Qf6_Kd7_Qf7+_Kd6_Qe8_Re5+_Kf4_Rf5+_Kg4_Ke5_Qd8_a4_Qa5+_Kf6_Qxa4_Ke7_Qa7+_Kd6_Qb8+_Kd7_Qb7+_Kd6_Qc8_Ke7_Qc7+_Ke8_Qd6_Kf7_Qd7+_Kf6_Qe8_Rg5+_Kh4_Rf5_Qf8+_Kg6_Qe7_Re5_Kg4_Re4+_Kf3_Re1_Qh4_Re5_Qe7_Re1_Kf4_Rf1+_Ke5_Re1+_Kd6_Rd1+_Kc6_Re1_Qh4_Re5_Kd6_Rh5_Qe4+_Kg7_Kxe6_Rh6+_Ke7_Rg6_Qd4+_Kg8_Qe5_Rg1_Qd5+_Kh7_Qd3+_Kg8_Kf6_Rg7_Qd5+_Kh7_Qh1+_Kg8_Qh5_Ra7_Qd5+'
ARONIAN_PGN = 'd4_Nf6_Nf3_g6_Bf4_Bg7_Nc3_d5_Nb5_Na6_e3_O-O_h3_c6_Nc3_Nc7_Be2_b6_O-O_Bb7_Bh2_c5_a4_a5_Ne5_Nd7_Nxd7_Qxd7_Bg4_e6_Qd2_Bc6_b3_Rfc8_Ne2_cxd4_Nxd4_b5_axb5_Nxb5_c3_Nxd4_exd4_a4_b4_Bb5_Rfc1_a3_Be2_Qc6_Bxb5_Qxb5_Bd6_Rc6_Bc5_Rca6_Ra2_Qc4_Qe2_Qxe2_Rxe2_a2_Ra1_Ra3_Rc2_Bf8_Kf1_e5_Bxf8_Kxf8_dxe5_Ke7_Ke2_Ke6_f4_d4_cxd4_Kd5_Rd2_Kc4_d5_Kxb4_d6_Kb3_Kf3_Kc3_Rf2_h5_Kg3_Kd4+_Kh4_Kd5_Kg5_Ke6_g4_hxg4_hxg4_R3a5_Re2_f6+_Kxg6_Rg8+_Kh6_Rxg4_f5+_Kxf5_e6_Ra8_Rf1+_Rf4_Rxf4+_Kxf4_Rxa2_Rxa2_e7_Rd2_e8=Q_Rxd6_Qe7_Rd4_Qxf6+_Ke3_Kg5_Rd5+_Kg4_Rd4+_Kg3_Rd3_Qe5+_Kd2+_Kf2_Kc2_Qc5+_Rc3_Qf5+_Kb2_Ke2_Rc2+_Kd3_Rc3+_Kd2_Rb3_Qe5+_Kb1_Qd4_Rh3_Qb6+_Ka1_Qf6+_Ka2_Qe6+_Rb3_Kc2_Ka1_Qa6+'
IVANCHUK_PGN = 'e4_c5_Nf3_e6_d4_cxd4_Nxd4_Nc6_Nc3_Qc7_Be3_a6_Bd3_Nf6_O-O_Ne5_h3_Bc5_Kh1_d6_f4_Ned7_Qe1_Qb6_Na4_Qb4_Qxb4_Bxb4_Nb3_b5_Nb6_Nxb6_Bxb6_Nd7_Bd4_e5_c3_Bc5_fxe5_Bxd4_cxd4_dxe5_d5_Nf6_Nc5_Ke7_a4_Bd7_a5_Rhc8_b4_Rc7_Rf3_Be8_Be2_Nd7_Rc3_Kd6_Rac1_Raa7_Kg1_Nf6_Kf2_Bd7_Rf3_Bc8_Ke3_Ne8_Rcf1_f6_Rg3_Ke7_Bh5_g6_Bg4_Nd6_Bxc8_Rxc8_Rgf3_Rf8_g4_Rf7_Kd3_Ra8_R3f2_Rff8_h4_Rf7_Rf3_Rc8_R1f2_Rc7_h5_gxh5_gxh5_f5_exf5_e4+_Nxe4_Nxe4_Re3_Kd6_Rxe4_Kxd5_f6_Kd6_Rf5_Rc6_Kd4_Rc4+_Ke3_Rc6_Kd4_Rc4+_Ke3_Rc6_Kf4_h6_Rd4+_Ke6_Re4+_Kd6_Kf3_Rc3+_Kg4_Rc8_Rf1_Rg8+_Kh4_Rgf8_Rd1+_Kc7_Re7+_Rxe7_fxe7_Rf4+_Kg3_Re4_Rf1_Kd7_Rf6_Kxe7_Rxh6_Rxb4_Rxa6_Ra4_Ra7+_Kf8_a6_Kg8_h6_Kh8_Kf3_b4_Ke4_b3+_Kd3_b2_Kc2_Rb4_Kb1_Rb6_h7_Rb4_Rc7_Ra4_Rc8+_Kxh7_Rc6_Rb4_a7_Ra4_Rc7+_Kg6_Kxb2_Kf6_Kb3_Ra1_Kb4_Ke6_Kb5_Kd6_Rc6+_Kd5_Ra6_Rb1+_Ka5_Kc5_Rc6+_Kxc6_a8=Q+_Kc7_Qa7+_Rb7_Qc5+_Kb8_Ka6_Rd7_Qe5+_Kc8_Kb6_Kd8_Kc6_Rf7_Qg5+_Ke8_Kd6_Kf8_Ke6_Rh7_Qf6+_Kg8_Qg6+_Rg7_Qe8+_Kh7_Kf6_Rg4_Qh5+_Kg8_Qxg4+'

GELFAND = '5R2/8/8/7K/4k3/8/8/6q1 b - - 0 1'      # ply 169, depois de 85.Rh5
CARLSEN = '1k6/7r/2K5/Q7/8/8/8/8 w - - 0 1'       # ply 180, depois de 90...Th7
SVIDLER = '6k1/6r1/5K2/8/8/3Q4/8/8 w - - 0 1'     # ply 206, depois de 103...Tg7
SVIDLER_G = '6k1/6r1/5K2/7Q/8/8/8/8 b - - 0 1'    # ply 211, depois de 106.Dh5
ARONIAN_76 = '8/8/5Q2/8/8/7r/k2K4/8 w - - 0 1'    # ply 150, depois de 75...Ra2
ARONIAN = '8/8/4Q3/8/8/1r6/2K5/k7 w - - 0 1'      # ply 154, depois de 77...Ra1
ARONIAN_77 = '8/8/4Q3/8/8/1r6/k2K4/8 w - - 0 77'  # ply 152, depois de 76...Tb3?
IVANCHUK = '1k6/1r6/K7/2Q5/8/8/8/8 b - - 0 1'     # ply 197, depois de 99.Ra6
IVANCHUK_100 = '1k6/3r4/K7/2Q5/8/8/8/8 w - - 0 1'  # ply 198, depois de 99...Td7

FORK = '8/Q7/8/4k3/7r/8/2K5/8 w - - 0 1'          # montada: garfo na coluna e
QUIET = '8/2Q5/5K2/7k/8/7r/8/8 w - - 0 1'         # montada: lance calmo
QUIET2 = '4k1r1/8/3K4/8/8/8/8/Q7 w - - 0 1'       # montada: lance calmo
LADDER = '5Q2/8/8/r7/4K3/8/4k3/8 w - - 0 1'       # montada: escada aberta
SQUEEZE = after(W, 'Qa6 Rc7+')                    # 1.Da6? Tc7+ (Averbakh)
DRAW = '1k6/2r5/QK6/8/8/8/8/8 b - - 0 1'          # depois de 2.Rb6?? (Averbakh)


def ref(step, rid):
    step['ref'] = rid
    return step


REFERENCES = [
    {'id': 'wikipedia', 'kind': 'web',
     'title': 'Queen versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Queen_versus_rook_endgame'},
    {'id': 'pawnless', 'kind': 'web',
     'title': 'Pawnless chess endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Pawnless_chess_endgame'},
    {'id': 'gelfandSvidler', 'kind': 'game', 'white': 'Boris Gelfand',
     'black': 'Peter Svidler',
     'event': 'Campeonato Mundial da FIDE (eliminatória), Moscou',
     'year': 2001, 'url': LICHESS + GELFAND_PGN + '#169'},
    {'id': 'gelfandSvidlerCg', 'kind': 'web',
     'title': 'Boris Gelfand vs Peter Svidler (2001), chessgames.com',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=1210725'},
    {'id': 'carlsenLe', 'kind': 'game', 'white': 'Magnus Carlsen',
     'black': 'Le Tuan Minh',
     'event': 'Julius Baer Generation Cup (online)',
     'year': 2024, 'url': LICHESS + CARLSEN_PGN + '#180'},
    {'id': 'svidlerHowell', 'kind': 'game', 'white': 'Peter Svidler',
     'black': 'David Howell', 'event': '5.º NH Chess Tournament, Amsterdã',
     'year': 2010, 'url': LICHESS + SVIDLER_PGN + '#206'},
    {'id': 'aronianMvl', 'kind': 'game', 'white': 'Levon Aronian',
     'black': 'Maxime Vachier-Lagrave',
     'event': 'Copa do Mundo da FIDE, Tbilisi, semifinal (desempate)',
     'year': 2017, 'url': LICHESS + ARONIAN_PGN + '#154'},
    {'id': 'worldcup2017', 'kind': 'web',
     'title': 'Chess World Cup 2017 (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Chess_World_Cup_2017'},
    {'id': 'ivanchukLautier', 'kind': 'game', 'white': 'Vassily Ivanchuk',
     'black': 'Joël Lautier', 'event': 'Horgen', 'year': 1995,
     'url': LICHESS + IVANCHUK_PGN + '#197'},
    {'id': 'pgnmentor', 'kind': 'web',
     'title': 'PGN Mentor: partidas por jogador (Gelfand, Carlsen, Svidler, '
              'Aronian, Ivanchuk)',
     'url': 'https://www.pgnmentor.com/files.html'},
    {'id': 'calmodee', 'kind': 'study', 'author': 'calmodee',
     'title': 'Queen Vs. Rook Endgame (Intro)',
     'url': 'https://lichess.org/study/enHKHI2k'},
    {'id': 'unto', 'kind': 'study', 'author': 'Unto',
     'title': 'Queen vs Rook',
     'url': 'https://lichess.org/study/LTWpoOgD'},
    {'id': 'nunn', 'kind': 'book', 'author': 'John Nunn',
     'title': 'Secrets of Pawnless Endings', 'publisher': 'Gambit Publications',
     'year': 2002},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'queen.vsRook.philidor',
    'module': 'queen',
    'skills': ['queen.vsRook'],
    'parts': [
        # 1. A posição e o zugzwang.
        {'id': 'philidor', 'steps': [
            ref(think('t_philidor', B, 2, marks=['a7', 'a8', 'c7']),
                'wikipedia'),
            ref(talk('intro', B, arrows=['a5a8', 'c6c7'],
                     marks=['a7', 'a8', 'c7']), 'wikipedia'),
            talk('near', B, arrows=['b7a7', 'b7d7', 'b7b4']),
            demo('d_near', B, 'Ra7 Qd8#',
                 notes={1: {'marks': ['a7']},
                        2: {'arrows': ['d8b8'], 'marks': ['c7']}}),
            move('pin', after(B, 'Kc8'), 'Qa6 Kb8 Qxb7#', accept='only'),
        ]},
        # 2. O garfo: Gelfand-Svidler, e a prática numa posição aberta.
        {'id': 'fork', 'steps': [
            ref(think('t_fork', GELFAND, 2, marks=['h5', 'f8'], side='black',
                      ask='line'), 'gelfandSvidler#169'),
            ref(talk('far', GELFAND, arrows=['c5h5', 'c5f8'], marks=['c5'],
                     side='black'), 'gelfandSvidler#169'),
            ref(demo('d_fork', GELFAND, 'Qc5+ Kg4 Qxf8', side='black',
                     notes={1: {'arrows': ['c5h5', 'c5f8']}}),
                'gelfandSvidler#169'),
            move('m_fork', FORK, 'Qe7+ Kf4 Qxh4+'),
        ]},
        # 3. A escada: Carlsen-Le Tuan Minh.
        {'id': 'ladder', 'steps': [
            ref(think('t_ladder', CARLSEN, 2, marks=['h7']), 'carlsenLe#180'),
            ref(talk('carlsen', CARLSEN, arrows=['b1h7', 'b1b8'],
                     marks=['b1']), 'carlsenLe#180'),
            ref(demo('d_ladder', CARLSEN, 'Qb4+ Ka7 Qa3+ Kb8 Qb3+',
                     notes={1: {'arrows': ['b4b8']}, 3: {'arrows': ['a3a7']},
                            5: {'arrows': ['b3b8']}}), 'carlsenLe#180'),
            move('m_ladder', LADDER, 'Qf3+ Kd2 Qd3+ Kc1 Qc3+ Kb1 Qxa5', accept='only'),
        ]},
        # 4. Passar a vez: Svidler-Howell.
        {'id': 'triangle', 'steps': [
            ref(think('t_triangle', SVIDLER, 2, marks=['f6', 'g7', 'g8']),
                'svidlerHowell#206'),
            ref(talk('white', SVIDLER, marks=['h5']), 'svidlerHowell#206'),
            ref(demo('d_triangle', SVIDLER, 'Qd5+ Kh7 Qh1+ Kg8 Qh5',
                     notes={1: {'arrows': ['d5g8']}, 3: {'arrows': ['h1h7']},
                            5: {'marks': ['h5']}}), 'svidlerHowell#206'),
            move('triangle', W, 'Qe5+ Ka8 Qa1+ Kb8 Qa5',
                 accept={1: ['Qe5+', 'Qd5']}),
        ]},
        # 5. O lance calmo que cria o zugzwang.
        {'id': 'quiet', 'steps': [
            think('t_quiet', QUIET, 2, marks=['g4', 'g5', 'g6', 'h4', 'h6']),
            talk('quiet', QUIET, arrows=['c7f4', 'f4h4', 'f4h6']),
            demo('d_quiet', QUIET, 'Qf4 Rf3 Qxf3+',
                 notes={1: {'marks': ['g4', 'h4', 'g5', 'h6']},
                        2: {'arrows': ['f3f4']}, 3: {'arrows': ['f3h5']}}),
            move('m_quiet', QUIET2, 'Qf6 Rg6 Qxg6+'),
        ]},
        # 6. Antes de capturar, conte as casas: Aronian-Vachier-Lagrave.
        # A prática é 77.Rc2! (atacar a peça cravada com o rei), e não o
        # 78.Da6+ do fim: este seria o 2.º lance do e11 (e do e15).
        {'id': 'stalemate', 'steps': [
            ref(think('t_stalemate', ARONIAN, 2, marks=['a1', 'b3']),
                'aronianMvl#154'),
            ref(talk('stale', ARONIAN, arrows=['e6b3'],
                     marks=['a2', 'b1', 'b2']), 'aronianMvl#154'),
            ref(demo('d_check', ARONIAN, 'Qa6+ Ra3 Qxa3#',
                     notes={1: {'arrows': ['a6a1']}, 2: {'marks': ['a3']},
                            3: {'marks': ['a1']}}),
                'aronianMvl#154'),
            ref(demo('d_aronian', ARONIAN_76, 'Qe6+ Rb3',
                     notes={1: {'arrows': ['e6a2']}, 2: {'arrows': ['e6a2']}}),
                'aronianMvl#150'),
            ref(move('m_pin', ARONIAN_77, 'Kc2', accept=['Kc2']),
                'aronianMvl#152'),
        ]},
        # 7. Não apertar demais: a torre desesperada (Averbakh).
        {'id': 'squeeze', 'steps': [
            ref(think('t_squeeze', SQUEEZE, 2, marks=['b6', 'd6', 'b5', 'd5']),
                'wikipedia'),
            ref(talk('squeeze', SQUEEZE, arrows=['c6b6'],
                     marks=['a7', 'a8', 'b7', 'c8']),
                'wikipedia'),
            ref(demo('d_desperado', DRAW, 'Rc6+ Kb5 Rxa6 Kxa6', goal='draw',
                     notes={1: {'arrows': ['c6b6']}, 3: {'arrows': ['c6a6']}}),
                'wikipedia'),
            ref(demo('d_stale', DRAW, 'Rc6+ Kxc6', goal='draw',
                     notes={2: {'marks': ['a7', 'a8', 'b7', 'c7', 'c8']}}),
                'wikipedia'),
            ref(move('m_squeeze', SQUEEZE, 'Kd6', accept='win'), 'wikipedia'),
        ]},
        # 8. O falso Philidor (Ivanchuk-Lautier), o resumo e o desafio.
        {'id': 'falseKing', 'steps': [
            ref(think('t_false', IVANCHUK, 2, marks=['a6', 'c6']),
                'ivanchukLautier#197'),
            ref(talk('false', IVANCHUK, arrows=['b7d7'], marks=['a6', 'c6']),
                'ivanchukLautier#197'),
            ref(demo('d_false', IVANCHUK_100, 'Qe5+ Kc8 Kb6 Kd8 Kc6',
                     notes={1: {'arrows': ['e5b8']}, 3: {'marks': ['b6']},
                            5: {'marks': ['c6']}}), 'ivanchukLautier#198'),
            talk('recap', B, marks=['c6', 'a5', 'b7', 'b8']),
            play('finish', W),
        ]},
    ],
    'exercises': [
        exercise('e02', 1, after(B, 'Rb2'), 'Qe5+ Ka8 Qxb2',
                 origin='calmodee'),
        exercise('e11', 2, after('1k6/1r6/K7/2Q5/8/8/8/8 b - - 0 1', 'Rc7'),
                 'Qe5 Ka8 Qe8+', origin='calmodee'),
        exercise('e12', 2, after(B, 'Rf7 Qb4+ Kc8'), 'Qd6 Rf6 Qxf6',
                 origin='wikipedia'),
        exercise('e13', 2, '6k1/6r1/5Q2/8/8/8/8/7K b - - 0 1', 'Rh7+ Kg1 Rg7+',
                 accept='hold', goal='draw', origin='wikipedia'),
        exercise('e09', 3, after(B, 'Rb3'),
                 'Qe5+ Ka7 Qg7+ Ka8 Qg8+ Ka7 Qxb3', origin='calmodee'),
        exercise('e15', 3, '1k6/2r5/1K6/8/8/8/8/7Q w - - 0 1', 'Qh2 Ka8 Kxc7'),
        exercise('e14', 3, '7k/5Q2/8/6r1/8/1K6/8/8 b - - 0 1', 'Rg3+ Ka2 Rg2+',
                 accept='hold', goal='draw', origin='wikipedia'),
    ],
    'passScore': 10,
    'keyPositions': [
        {'id': 'black', 'fen': B, 'ref': 'wikipedia'},
        {'id': 'white', 'fen': W, 'ref': 'wikipedia'},
        {'id': 'corner', 'fen': SVIDLER_G, 'ref': 'svidlerHowell#211'},
        {'id': 'false', 'fen': IVANCHUK, 'ref': 'ivanchukLautier#197'},
        {'id': 'draw', 'fen': DRAW, 'ref': 'wikipedia'},
    ],
    'practice': {'fen': '1rk5/4Q3/K7/8/8/8/8/8 w - - 0 1', 'goal': 'win',
                 'positionId': 'queen.queenVsRook.0001'},
    'references': REFERENCES,
})
