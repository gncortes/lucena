"""Gera `rook.backRank.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.backRank.py`
e depois o `build_aula.py rook.backRank`. O aluno defende de brancas: as
posições das fontes entram espelhadas (ver `tools/check_hold.py --mirror`).

Lição refeita na T61 (ver docs/aulas/rook.backRank.md, "Lição refeita"). As
posições das partidas (Carlsen–Nakamura, Carlsen–Praggnanandhaa,
Ivanchuk–Grischuk, Aronian–Duda) entram com o FEN real: nas três primeiras
quem defende são as pretas, e o passo é visto de pretas. As demonstrações de
um erro das brancas (Rf1?, Ta1?, Th1?, e a defesa passiva contra peão de bispo)
são vistas do lado que ganha, porque o script confere os lances do lado do
passo.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

KN = '8/8/8/8/8/5kp1/r7/1R4K1 b - - 0 1'     # peão de cavalo, defesa passiva
KNW = after(KN, 'Kg4')                        # a mesma, brancas jogam
TRICK = '8/8/8/8/8/6pk/6r1/1R4K1 w - - 0 1'  # o truque: xeque em g2
BISHOP = '8/8/8/8/8/5pk1/1r6/R5K1 b - - 0 1'  # peão de bispo: perde
ACTIVE = '8/8/8/8/6k1/5p2/r7/1R3K2 w - - 0 1'  # o rei ainda não chegou
KNIGHT5 = '7R/8/8/8/6p1/5rk1/8/6K1 w - - 0 1'  # por trás não serve
ROOKPAWN = '8/8/8/8/8/6kp/r7/1R5K b - - 0 1'
SEVENTH = '8/8/8/8/8/8/r2kpK2/1R6 w - - 0 1'  # peão na sétima
HOMECHECK = 'R7/8/8/8/1p6/2k5/6r1/1K6 w - - 0 1'  # volta tapada: xeque antes
KF = '8/1r6/8/R5pk/8/8/8/4K3 w - - 0 1'       # primeiro o rei (só Rf1/Rf2)
STALE = '6r1/1R6/8/8/8/6k1/7p/7K w - - 0 1'   # afogamento
RP_MOVE = '8/8/8/8/8/6kp/r7/1R4K1 w - - 0 1'  # peão de torre, rei em g1
# Partidas (FEN real; PGN do PGN Mentor, conferido com python-chess).
NAKA_185 = '6k1/R7/7K/6P1/8/8/8/4r3 b - - 7 93'
PRAGG_143 = '6k1/R7/6K1/6P1/5r2/8/8/8 b - - 0 72'
GRIS_121 = '8/5k2/7K/6PR/8/6r1/8/8 b - - 0 61'
ARON_110 = '8/r7/8/8/4Rpk1/6r1/6R1/6K1 w - - 6 56'
ARON_114 = '8/8/8/8/5p2/6k1/r7/4R1K1 w - - 0 58'
# Exercícios (T58): posições que a lição não mostra.
CORNER7 = '8/8/8/8/8/6k1/r6p/1R4K1 w - - 0 1'  # peão de torre na sétima
WAITG = '8/8/8/8/6p1/7k/r7/2R3K1 w - - 0 1'    # peão de cavalo: pode esperar
EARLY = '8/8/8/8/5pk1/8/r7/2R3K1 w - - 0 1'   # dá tempo de armar Philidor
WRONG = '7R/8/8/8/6p1/5k2/r7/6K1 w - - 0 1'    # torre do lado curto
APPROACH = '8/3r4/8/4R3/6pk/8/4K3/8 w - - 0 1'  # o rei ainda não chegou
BLOCK7 = '8/8/8/8/1R6/4rk2/4p3/3K4 w - - 0 1'   # sétima, rei na frente

# Lances das partidas até o fim, para a url do Lichess (o ply vai no #).
NAKA_PGN = ('d4_Nf6_c4_e6_Nf3_d5_Nc3_Be7_Bf4_O-O_e3_c5_dxc5_Bxc5_cxd5_Nxd5_Nxd5_exd5_Bd3_Bb4+_Nd2_Nc6_O-O_Be7_Rc1_Bf6_Nf3_Qe7_h3_g6_Bb5_Bd7_Qxd5_Be6_Qe4_Bxb2_Bxc6_f5_Bg5_fxe4_Bxe7_Bxc1_Bxb7_Bxe3_Bxf8_Rxf8_fxe3_exf3_Bxf3_Rb8_a4_Rb4_Bc6_Rc4_Bb5_Re4_Rd1_a6_Bxa6_Rxa4_Bb7_Kf7_Kf2_Kf6_Bd5_Bf5_g4_Be6_Kf3_Ra5_Bxe6_Kxe6_h4_Ra2_Rb1_Ra7_Kf4_Ra4+_e4_Ra7_Rb6+_Kf7_Rc6_Rd7_g5_Ra7_Ke5_Re7+_Kd5_Rd7+_Rd6_Ra7_Rf6+_Ke7_Rc6_Rd7+_Ke5_Ra7_Rc5_Rd7_Ra5_Kf7_Ra1_Re7+_Kf4_Rb7_Ra6_Rc7_Kg4_Re7_Rf6+_Ke8_Kf4_Ra7_Rb6_Kf7_Ke5_Re7+_Kd5_Rd7+_Rd6_Ra7_Rd8_Ra5+_Kd4_Ra4+_Ke5_Ra5+_Kf4_Ra7_Rd4_Ke6_Rb4_Rf7+_Ke3_Ra7_Rb8_Re7_Rh8_Ra7_Re8+_Kf7_Rb8_Ke6_Rb6+_Kf7_Kf4_Re7_Rf6+_Ke8_h5_gxh5_e5_Rf7_Ke4_Rg7_Kf5_Rf7_Kf4_h4_Kg4_Re7_e6_Ra7_Rh6_Kf8_Kxh4_Ra4+_Kh5_Re4_Rf6+_Kg7_Rf7+_Kg8_Re7_Kf8_Rxh7_Rxe6_Rh6_Re1_Ra6_Kg7_Ra7+_Kg8_Kh6_Re6+_g6_Re8')
PRAGG_PGN = ('e4_e5_Nf3_Nc6_Bb5_a6_Ba4_Nf6_O-O_Nxe4_d4_b5_Bb3_d5_dxe5_Be6_Qe2_Be7_Rd1_O-O_c3_f5_exf6_Bxf6_Nbd2_Nc5_Bc2_Re8_Nf1_Bf7_Be3_Ne4_Ng3_Nxg3_hxg3_Ne5_Nxe5_Bxe5_a4_c6_Qd2_Qd6_Re1_Bg6_Bxg6_Qxg6_Bd4_Bxd4_Qxd4_bxa4_Qxa4_c5_Qd7_Rad8_Qc7_d4_cxd4_cxd4_Qc4+_Kh8_Rxe8+_Qxe8_Rd1_Qd7_Qxa6_d3_b4_h6_Qc4_d2_Qe2_Qd3_Qxd3_Rxd3_f3_Kh7_Kf2_Rb3_Rxd2_Rxb4_Rd5_Rb2+_Kg1_Rb7_Kh2_g6_Kh3_h5_g4_hxg4+_Kxg4_Kh6_Ra5_Rb4+_f4_Rb2_Kh3_Rb4_g3_Kg7_Kh4_Rc4_Ra7+_Kf6_Kg4_Rc3_Ra5_Rb3_Kh3_Rc3_Re5_Rc2_g4_Rc3+_Kg2_Ra3_Kf2_Kf7_Re3_Ra1_Rb3_Kg7_Kg3_Rf1_Rb7+_Kg8_Ra7_Kf8_Ra4_Rh1_Kf3_Rg1_g5_Rf1+_Ke4_Kg7_Ra7+_Kg8_Ke5_Rf2_Kf6_Rxf4+_Kxg6_Rf8_Rg7+_Kh8_Rh7+_Kg8_Rg7+_Kh8')
GRISCHUK_PGN = ('d4_Nf6_c4_e6_Nc3_Bb4_Nf3_c5_g3_cxd4_Nxd4_O-O_Bg2_d5_cxd5_Nxd5_Qb3_Qa5_Bd2_Nc6_Nxc6_bxc6_O-O_Bxc3_bxc3_Ba6_Rfd1_Qc5_e4_Bc4_Qa4_Nb6_Qb4_Qh5_Re1_c5_Qa5_Be2_Bf4_e5_Bxe5_Nc4_Qa6_Qxe5_Rxe2_Qxc3_Ree1_Nd2_Rac1_Qb4_e5_Rad8_Qxa7_c4_Re3_Rfe8_e6_fxe6_Rec3_e5_Bc6_Re7_Qe3_e4_Kg2_h6_Rd1_Rd6_Rxd2_Rxc6_Rd8+_Kh7_Rd4_Kh8_a3_Qb5_Qe2_e3_Rxe3_Rxe3_Qxe3_Rc8_Qc3_Qb7+_Kg1_Qb3_Qxb3_cxb3_Rb4_Rc1+_Kg2_Rb1_g4_g5_Rb7_b2_f3_Ra1_Rxb2_Rxa3_Rb5_Kg7_h4_gxh4_Rh5_Ra2+_Kh3_Ra3_Rf5_Kg6_Kxh4_h5_Rg5+_Kf7_Kxh5_Rxf3_Kh6_Rh3+_Rh5_Rg3_g5_Kg8_Rh1_Ra3_Rb1_Ra6+_g6_Ra8_Rb7')
ARONIAN_PGN = ('e4_c6_d4_d5_e5_Bf5_h4_h5_c4_e6_Nc3_dxc4_Bxc4_Nd7_Nge2_Nb6_Bb3_Ne7_Bg5_Qd7_O-O_Ned5_Nxd5_Nxd5_Bxd5_Qxd5_Nf4_Qb5_Nxh5_Qxb2_g4_Qc2_gxf5_Qxd1_Nxg7+_Bxg7_Raxd1_exf5_d5_cxd5_Rxd5_Bh6_Bf6_Bg7_Re1_Bxf6_exf6+_Kf8_Red1_Re8_R1d4_Rh5_Kg2_Kg8_Rd7_b5_Rxa7_Rh6_Ra6_Kh7_Rb4_Kg6_Ra5_Re4_Rbxb5_Rh5_Ra8_Rexh4_Rb6_Rh2+_Kf1_f4_Rg8+_Kf5_a4_R5h3_a5_Ra3_Kg1_Rhh3_Kg2_Rhc3_a6_Rc2_Rg7_Raa2_Rxf7_Rxf2+_Kg1_Rfc2_Rb5+_Kg4_Rg7+_Kf3_Rb3+_Ke4_Re7+_Kf5_Re1_Kxf6_Rf3_Kg5_a7_Rxa7_Rf2_Rc3_Re4_Rg3+_Rg2_Kg4_Re1_Ra2_Rxg3+_Kxg3_Kh1_Rh2+_Kg1_f3_Re3_Ra2')

LICHESS = 'https://lichess.org/analysis/pgn/'


def R(step, ref):
    """O passo com a referência de onde a posição vem."""
    step['ref'] = ref
    return step


REFERENCES = [
    {'id': 'rookPawn', 'kind': 'web',
     'title': 'Rook and pawn versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame'},
    {'id': 'chessmood', 'kind': 'web',
     'title': 'Hovhannes Gabuzyan: Theoretical Rook Endgames (ChessMood)',
     'url': 'https://chessmood.com/blog/rook-endgames'},
    {'id': 'profangel', 'kind': 'study', 'author': 'ProfAngel',
     'title': 'Rook Endings. The Philidor Position.',
     'url': 'https://lichess.org/study/a1ss97T0'},
    {'id': 'practice2', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Intermediate Rook Endings',
     'url': 'https://lichess.org/study/heQDnvq7'},
    {'id': 'nunn', 'kind': 'book', 'author': 'John Nunn',
     'title': 'Secrets of Rook Endings', 'publisher': 'Gambit Publications',
     'year': 1999},
    {'id': 'hemanth', 'kind': 'study', 'author': 'Hemanthsankar',
     'title': 'Back rank defence',
     'url': 'https://lichess.org/study/gfxJ7lIx'},
    {'id': 'wiebe', 'kind': 'study', 'author': 'IsaacWiebeSupreme',
     'title': 'Passive Defense with Knight Pawn',
     'url': 'https://lichess.org/study/y4SCg9WL'},
    {'id': 'naka', 'kind': 'game', 'white': 'Magnus Carlsen',
     'black': 'Hikaru Nakamura', 'event': 'Sinquefield Cup, Saint Louis',
     'year': 2017, 'url': LICHESS + NAKA_PGN + '#185'},
    {'id': 'pragg', 'kind': 'game', 'white': 'Magnus Carlsen',
     'black': 'Rameshbabu Praggnanandhaa', 'event': 'Norway Chess, Stavanger',
     'year': 2024, 'url': LICHESS + PRAGG_PGN + '#143'},
    {'id': 'grischuk', 'kind': 'game', 'white': 'Vassily Ivanchuk',
     'black': 'Alexander Grischuk', 'event': 'Linares', 'year': 2009,
     'url': LICHESS + GRISCHUK_PGN + '#121'},
    {'id': 'aronian', 'kind': 'game', 'white': 'Levon Aronian',
     'black': 'Jan-Krzysztof Duda',
     'event': 'Chess.com Play-In Match (online)', 'year': 2024,
     'url': LICHESS + ARONIAN_PGN + '#110'},
    {'id': 'pgnmentor', 'kind': 'web',
     'title': 'PGN Mentor: arquivos de partidas por jogador',
     'url': 'https://www.pgnmentor.com/files.html'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'rook.backRank',
    'module': 'rook',
    'skills': ['rook.backRank'],
    'parts': [
        # 1. Peão de cavalo: esperar na primeira fileira.
        {'id': 'wait', 'steps': [
            R(think('t_knight', KN, 3, 2), 'rookPawn'),
            talk('room', KN, arrows=['b1h1'], marks=['h1', 'h2', 'h3']),
            R(demo('naka', NAKA_185, 'Re6+ g6 Re8', goal='draw',
                   side='black', notes={3: {'marks': ['e8', 'g8']}}),
              'naka#185'),
            move('wait', KNW, 'Rc1 Kh3 Rb1 g2 Re1',
                 accept='hold', goal='draw'),
        ]},
        # 2. O xeque ao lado do rei: para o canto.
        {'id': 'corner', 'steps': [
            think('t_trick', TRICK, 1, 2, ask='line'),
            talk('corner', TRICK, arrows=['g1h1'], marks=['h1', 'h2']),
            demo('cornerDemo', TRICK, 'Kh1 Rh2+ Kg1', goal='draw',
                 notes={1: {'marks': ['h1']}, 3: {'marks': ['g1']}}),
            demo('fOne', TRICK, 'Kf1 Kh2 Rb3 Rf2+ Ke1 g2', goal='draw',
                 side='black', notes={2: {'marks': ['g1']},
                                      6: {'arrows': ['g2g1']}}),
            R(demo('pragg', PRAGG_143, 'Rf8 Rg7+ Kh8 Rh7+ Kg8', goal='draw',
                   side='black', notes={1: {'marks': ['f8']}}),
              'pragg#143'),
            move('trick', KNW, 'Rc1 Kh3 Rb1 Rg2+ Kh1 Rh2+ Kg1',
                 accept={1: 'hold', 2: 'hold', 3: 'only', 4: 'only'},
                 goal='draw'),
        ]},
        # 3. Peão de torre: o canto e o afogamento.
        {'id': 'rookPawn', 'steps': [
            think('t_rookPawn', ROOKPAWN, 1, 1),
            talk('rookPawn', ROOKPAWN, marks=['h1']),
            talk('stalemate', STALE, marks=['h1', 'g1', 'g2']),
            demo('stale', STALE, 'Rg7+ Rxg7', goal='draw',
                 notes={1: {'arrows': ['b7g7']}}),
            move('rookPawnMove', RP_MOVE, 'Kh1 h2 Rc1',
                 accept={1: ['Kh1'], 2: 'hold'}, goal='draw'),
        ]},
        # 4. Chegar à defesa: primeiro o rei.
        {'id': 'kingFirst', 'steps': [
            think('t_kingFirst', KF, 3, 2, ask='line'),
            talk('kingFirst', KF, arrows=['e1f2', 'f2g1'], marks=['g1']),
            demo('raOne', KF, 'Ra1 Rf7 Ke2 Rf5', goal='draw', side='black',
                 notes={2: {'arrows': ['f7f1']}}),
            R(demo('grischuk', GRIS_121, 'Kg8 Rh1 Ra3 Rb1 Ra6+ g6 Ra8',
                   goal='draw', side='black',
                   notes={1: {'marks': ['g8']}, 7: {'marks': ['a8']}}),
              'grischuk#121'),
            move('kingFirstMove', KF, 'Kf2 Rb2+ Kg1 Kh4 Ra1',
                 accept={1: ['Kf1', 'Kf2'], 2: 'hold', 3: 'hold'},
                 goal='draw'),
        ]},
        # 5. Voltar para casa sem tirar o canto do rei.
        {'id': 'home', 'steps': [
            think('t_home', KNIGHT5, 3, 2),
            talk('behind', KNIGHT5, arrows=['h8a8', 'a8a1'], marks=['h1']),
            demo('hOne', KNIGHT5, 'Rh1 Ra3 Kf1 Kf3 Ke1 Ra1+ Kd2 Rxh1',
                 goal='draw', side='black',
                 notes={2: {'arrows': ['a3a1']}}),
            demo('homeCheck', HOMECHECK, 'Rc8+ Kb3 Rc1', goal='draw',
                 notes={1: {'arrows': ['c8c3']}, 3: {'marks': ['a1']}}),
            move('home', KNIGHT5, 'Ra8 Rb3 Ra1',
                 accept={1: 'hold', 2: 'only'}, goal='draw'),
        ]},
        # 6. Peão de bispo: a mesma defesa perde.
        {'id': 'bishop', 'steps': [
            think('t_bishop', BISHOP, 3, 2),
            talk('file', BISHOP, arrows=['b2h2'], marks=['h1', 'h2']),
            demo('bishopDemo', BISHOP, 'Rg2+ Kf1 Rh2 Kg1 f2+ Kf1 Rh1+',
                 goal='win', side='black',
                 notes={3: {'arrows': ['h2h1']}, 7: {'arrows': ['h1a1']}}),
            R(demo('aronianEnd', ARON_114, 'Kh1 Rh2+ Kg1 f3 Re3 Ra2',
                   goal='win', side='black'), 'aronian#114'),
            R(move('aronianFix', ARON_110, 'Re8',
                   accept={1: ['Ree2', 'Re5', 'Re6', 'Re8']}, goal='draw'),
              'aronian#110'),
        ]},
        # 7. Sair a tempo.
        {'id': 'active', 'steps': [
            R(think('t_free', ACTIVE, 1, 2, ask='line'), 'rookPawn'),
            talk('free', ACTIVE, arrows=['g4g3', 'b1b8']),
            demo('activeDemo', ACTIVE, 'Rb8 Kg3 Rg8+ Kf4 Rf8+ Ke3 Re8+',
                 goal='draw'),
            talk('thirdRank', ACTIVE, marks=['b3', 'b8']),
            move('active', ACTIVE, 'Rb8 Kg3 Rg8+ Kf4 Rf8+',
                 accept={1: 'hold', 2: 'only', 3: 'hold'}, goal='draw'),
        ]},
        # 8. Peão na sétima, e o resumo.
        {'id': 'seventh', 'steps': [
            R(think('t_seventh', SEVENTH, 3, 2, ask='line'), 'rookPawn'),
            talk('seventh', SEVENTH, arrows=['b1e1'], marks=['e1']),
            demo('gOne', after(SEVENTH, 'Re1 Kd3'),
                 'Rg1 Ra5 Kf3 Rf5+ Kg4 Rf1', goal='draw', side='black',
                 notes={4: {'arrows': ['f5f1']}, 6: {'marks': ['e1']}}),
            move('seventhMove', SEVENTH, 'Re1 Kd3 Rb1 Kd2 Re1',
                 accept='only', goal='draw'),
            talk('recap', KN, arrows=['b1h1']),
            play('finish', KNW, goal='draw'),
        ]},
    ],
    'exercises': [
        exercise('e11', 1, CORNER7, 'Kh1 Ra3 Rb3+',
                 accept={1: 'only', 2: 'hold'}, goal='draw', origin='hemanth'),
        exercise('e15', 1, WAITG, 'Rb1', accept='hold', goal='draw',
                 origin='own'),
        exercise('e10', 2, EARLY, 'Rc3 f3 Rc8 Kg3 Rg8+',
                 accept={1: 'hold', 2: 'hold', 3: 'only'}, goal='draw',
                 origin='chessmood'),
        exercise('e12', 2, WRONG, 'Rf8+ Kg3 Rf1 Rg2+ Kh1', accept='only',
                 goal='draw', origin='own'),
        exercise('e14', 3, APPROACH, 'Kf2 Rd2+ Kg1 Kh3 Re3+ g3 Re1',
                 accept={1: 'only', 2: 'only', 3: 'hold', 4: 'only'},
                 goal='draw', origin='wiebe'),
        exercise('e16', 3, BLOCK7, 'Ke1 Rc3 Rb1 Ra3 Rc1 Rb3 Ra1',
                 accept='only', goal='draw', origin='own'),
    ],
    'passScore': 8,
    'keyPositions': [
        {'id': 'knight', 'fen': KN, 'ref': 'rookPawn'},
        {'id': 'trick', 'fen': TRICK, 'ref': 'rookPawn'},
        {'id': 'bishop', 'fen': BISHOP, 'ref': 'rookPawn'},
        {'id': 'seventh', 'fen': SEVENTH, 'ref': 'rookPawn'},
    ],
    'practice': {'fen': KNW, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
})
