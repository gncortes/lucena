"""Gera `pawns.reti.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/pawns.reti.py`
e depois o `build_aula.py pawns.reti`. Quase toda a aula é de empate: o aluno
defende de brancas (Réti), de pretas (Yates–Marshall) e, na parte dos
limites, ganha de pretas quando a manobra chega tarde.

Lição refeita na T61 (2026-10-10; ver docs/aulas/pawns.reti.md, "Lição
refeita"): seis partes, com a nova `piece` (uma peça no caminho) para os três
exercícios de 3 estrelas, e a partida Yates–Marshall com link (ply 119)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)


def ref(step, rid):
    """O passo com `ref` (a partida ou o estudo de onde vem a posição)."""
    step['ref'] = rid
    return step


RETI = '7K/8/k1P5/7p/8/8/8/8 w - - 0 1'           # Réti, 1921
PUSH = after(RETI, 'Kg7 h4 Kf6 h3')                # o peão corre: Ke7/Ke6
LATE = after(RETI, 'Kg7 h4 Kf6 Kb6 Ke5 h3')        # o peão corre tarde: Kd6
MARSHALL = '8/8/8/8/pK6/8/5P2/1k6 b - - 1 60'      # Yates–Marshall, ply 119
YM = 'yatesMarshall#119'
TOO_FAR = '7K/8/k1P5/8/7p/8/8/8 w - - 0 1'         # peão em h4: tarde demais
FAR = after(TOO_FAR, 'Kg7')                        # pretas jogam e ganham
FRONT = '8/1k6/3P2K1/8/7p/8/8/8 b - - 0 1'         # só Kc8: parar o peão pela frente
CLOSE_A5 = '7K/8/2P5/k6p/8/8/8/8 w - - 0 1'        # rei preto longe: c7 ganha
MIRROR = 'K7/8/5P1k/p7/8/8/8/8 w - - 0 1'          # Réti espelhado
KG8 = '6K1/8/k1P5/7p/8/8/8/8 w - - 0 1'            # rei em g8: Kf7/Kg7
# Uma peça no caminho (posições próprias, revisor T61): o primeiro passo da
# diagonal ataca o bispo que vigia a coroação.
PIECE = '8/3P4/5b2/8/1p4K1/8/8/7k w - - 0 1'       # só Kf5, Ke4, Kd3, Kc2
PIECE2 = 'k7/2P5/4b3/8/p4K2/8/8/8 w - - 0 1'       # só Ke5; Kd4, Kc3, Kb2
A7 = '8/k5K1/2P5/7p/8/8/8/8 b - - 0 1'             # rei preto em a7: perde
RETI1928 = '8/6p1/k1P2p1p/7K/8/8/8/8 w - - 0 1'    # Réti, 1928
LASKER = '8/8/6K1/ppp5/7k/1P6/1P6/8 w - - 0 1'     # Lasker–Tarrasch, 41...Kxh4
SARYCHEV = '8/1pPK3b/8/8/8/5k2/8/8 w - - 0 1'      # Sarychev
PROKES = '3K4/7p/3k4/P7/8/8/8/8 w - - 0 1'         # Prokeš
RETI_BISHOP = '5K2/k7/4P1p1/8/8/8/4b3/8 w - - 0 1'  # Réti, com bispo
RETI_ZUGZWANG = 'K7/2P5/b4k1p/3P4/6P1/8/8/8 w - - 0 1'  # Réti, d6! e Ka7

YM_URL = ('https://lichess.org/analysis/pgn/Nf3_Nf6_c4_e6_Nc3_d5_d4_Nbd7_Bg5_'
          'Bb4_e3_c5_cxd5_exd5_Bd3_cxd4_exd4_O-O_O-O_h6_Nxd5_hxg5_Nxb4_a5_Nc2_'
          'Nd5_Re1_Nf4_Ne3_g4_Nxg4_Nc5_Nge5_Ncxd3_Nxd3_Ne6_Nc5_Nxc5_dxc5_Qc7_'
          'Qd4_Rd8_Qh4_Bf5_Re5_Bg6_Qg3_Rac8_Rae1_Qc6_h4_Rd5_h5_Bxh5_Nh4_Rxe5_'
          'Rxe5_Bg6_Nxg6_Qxg6_Qh3_Rd8_Rh5_Kf8_Rh8+_Ke7_Qe3+_Qe6_Qg5+_Qf6_'
          'Qxf6+_gxf6_Rxd8_Kxd8_Kh2_Kd7_Kg3_Kc6_Kf4_Kxc5_Kf5_b5_Kxf6_Kc4_Kxf7_'
          'Kd3_g4_Kc2_g5_Kxb2_g6_Kxa2_g7_b4_g8=Q_a4_Ke6_b3_Kd5_b2_Kd4+_Ka3_'
          'Qf8+_Kb3_Qf3+_Ka2_Qd5+_Ka3_Qc5+_Ka2_Qc4+_Ka3_Qd3+_Ka2_Kc4_b1=Q_'
          'Qxb1+_Kxb1_Kb4_Kb2_Kxa4_Kc3_f4_Kd4#119')
LT_URL = ('https://lichess.org/analysis/pgn/e4_e5_Nf3_Nc6_Bb5_a6_Ba4_Nf6_O-O_'
          'Nxe4_d4_b5_Bb3_d5_dxe5_Be6_c3_Be7_Nbd2_O-O_Re1_Nc5_Bc2_d4_cxd4_Nxd4_'
          'Nxd4_Qxd4_Nb3_Nxb3_axb3_Qxd1_Rxd1_c5_Bd2_Rfd8_Ba5_Rxd1+_Rxd1_f6_Bc3_'
          'fxe5_Bxe5_Rd8_Rxd8+_Bxd8_f4_Kf7_Kf2_Bf6_Bd6_Bd4+_Kf3_Bd5+_Kg4_Ke6_'
          'Bf8_Kf7_Bd6_Bxg2_Bxh7_Ke6_Bf8_Kd5_Kg5_Bf6+_Kg6_Be4+_f5_Ke5_Bxg7_'
          'Bxf5+_Kf7_Bxg7_Bxf5_Kxf5_Kxg7_a5_h4_Kg4_Kg6_Kxh4_Kf5_Kg3_Ke4_Kf2_'
          'Kd5_Ke3_Kxc5_Kd3_Kxb5_Kc2_Kxa5_Kxb3#82')

REFERENCES = [
    {'id': 'wikiReti', 'kind': 'web',
     'title': 'Wikipedia: Réti endgame study',
     'url': 'https://en.wikipedia.org/wiki/R%C3%A9ti_endgame_study'},
    {'id': 'wikiRichard', 'kind': 'web',
     'title': 'Wikipedia: Richard Réti',
     'url': 'https://en.wikipedia.org/wiki/Richard_R%C3%A9ti'},
    {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
     'title': "Dvoretsky's Endgame Manual (6.ª edição, revista por Karsten "
              'Müller e Alex Fishbein)',
     'publisher': 'Russell Enterprises', 'year': 2025,
     'where': "Índice da amostra da editora: \"Réti's Idea\", p. 31"},
    {'id': 'pn2206', 'kind': 'study', 'author': 'pn2206',
     'title': "Richard Reti's 1921 Endgame Study",
     'url': 'https://lichess.org/study/zPksA8Uo'},
    {'id': 'flohahn22', 'kind': 'study', 'author': 'flohahn22',
     'title': 'Chess Endgames: Reti Idea',
     'url': 'https://lichess.org/study/PLK2LzXH'},
    {'id': 'carreira', 'kind': 'study', 'author': 'CarreiraChess',
     'title': "Richard Reti's Endgame Study",
     'url': 'https://lichess.org/study/Hp71MDeO'},
    {'id': 'alien2798', 'kind': 'study', 'author': 'alien2798',
     'title': 'The Reti Manoeuvre',
     'url': 'https://lichess.org/study/LOwS84ta'},
    {'id': 'drfiskeson', 'kind': 'study', 'author': 'DrFiskeson',
     'title': 'Brilliant Reti maneuver study',
     'url': 'https://lichess.org/study/liSLeKY9'},
    {'id': 'yatesMarshall', 'kind': 'game', 'white': 'Frederick Yates',
     'black': 'Frank Marshall', 'event': 'Karlsbad, rodada 9', 'year': 1929,
     'url': YM_URL},
    {'id': 'laskerTarrasch', 'kind': 'game', 'white': 'Emanuel Lasker',
     'black': 'Siegbert Tarrasch', 'event': 'São Petersburgo (preliminar)',
     'year': 1914, 'url': LT_URL},
    {'id': 'pgnmentor', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Marshall e de Lasker',
     'url': 'https://www.pgnmentor.com/files.html'},
    {'id': 'jcaselas', 'kind': 'study', 'author': 'JCaselas',
     'title': 'Prokes-Studies',
     'url': 'https://lichess.org/study/0LkYXajC'},
    {'id': 'suvkos', 'kind': 'study', 'author': 'suvkos',
     'title': 'The Reti Idea',
     'url': 'https://lichess.org/study/TLBUTcye'},
    {'id': 'tenakel', 'kind': 'study', 'author': 'Tenakel',
     'title': 'Reti-Studies',
     'url': 'https://lichess.org/study/pgf3RcVp'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'pawns.reti',
    'module': 'pawns',
    'skills': ['pawns.reti'],
    'parts': [
        {'id': 'reti', 'steps': [
            think('t_reti', RETI, 2, ask='line', marks=['d6', 'h4']),
            talk('intro', RETI, arrows=['h8g7', 'h5h1', 'a6b7'],
                 marks=['d5', 'h1', 'd1']),
            talk('diagonal', RETI, arrows=['h8h4', 'h8e5', 'e5h2', 'e5d6'],
                 marks=['e5']),
            demo('d_main', RETI, 'Kg7 h4 Kf6 Kb6 Ke5 Kxc6 Kf4',
                 goal='draw',
                 notes={1: {'arrows': ['g7f6']},
                        5: {'arrows': ['e5d6', 'e5f4']},
                        7: {'marks': ['f4'], 'arrows': ['f4h2']}}),
            move('main', RETI, 'Kg7 Kb6 Kf6 h4 Ke5 Kxc6 Kf4',
                 accept={1: 'only', 2: 'only', 3: 'only', 4: 'hold'},
                 goal='draw'),
        ]},
        {'id': 'push', 'steps': [
            think('t_push', PUSH, 1),
            talk('push', PUSH, arrows=['f6e7', 'c6c8'], marks=['d7']),
            demo('d_push', PUSH, 'Ke7 h2 c7 Kb7 Kd7 h1=Q c8=Q+', goal='draw',
                 notes={1: {'marks': ['d7', 'd8']},
                        5: {'marks': ['c8']}}),
            talk('late', LATE, arrows=['e5d6'], marks=['c7']),
            move('lateMove', LATE, 'Kd6 h2 c7 Kb7 Kd7',
                 accept='hold', goal='draw'),
        ]},
        {'id': 'marshall', 'steps': [
            ref(think('t_marshall', MARSHALL, 2, side='black',
                      marks=['a4', 'f2']), YM),
            ref(talk('marshall', MARSHALL, arrows=['b1b2', 'b2d4'],
                     marks=['a4', 'f2'], side='black'), YM),
            ref(demo('d_marshall', MARSHALL, 'Kb2 Kxa4 Kc3 f4 Kd4',
                     goal='draw', side='black',
                     notes={1: {'marks': ['a4']},
                            3: {'arrows': ['c3d4']}}), YM),
            ref(talk('wrong', MARSHALL, arrows=['b1c2', 'f2f8'], marks=['c2'],
                     side='black'), YM),
            ref(move('marshallMove', MARSHALL, 'Kb2 Kxa4 Kc3 f4 Kd4',
                     accept='hold', goal='draw'), YM),
        ]},
        {'id': 'piece', 'steps': [
            think('t_piece', PIECE, 2, marks=['d8', 'b4']),
            talk('piece', PIECE, arrows=['g4f5', 'f5c2'], marks=['f6', 'd8']),
            demo('d_piece', PIECE, 'Kf5 Be7 Ke4 b3 Kd3 b2 Kc2', goal='draw',
                 notes={1: {'marks': ['f6']},
                        2: {'arrows': ['e7d8']},
                        7: {'marks': ['b1']}}),
            move('pieceMove', PIECE2, 'Ke5 Bd7 Kd4 a3 Kc3 a2 Kb2',
                 accept={1: 'only', 2: ['Kd4'], 3: ['Kc3'], 4: ['Kb2']},
                 goal='draw'),
        ]},
        {'id': 'limits', 'steps': [
            think('t_far', FAR, 1, side='black', marks=['h4']),
            talk('far', FAR, arrows=['h4h3'], marks=['h1', 'e5', 'd7'],
                 side='black'),
            demo('d_far', FAR, 'h3 Kf6 Kb6 Ke5 h2 Kd6 h1=Q', goal='win',
                 side='black',
                 notes={4: {'arrows': ['e5d6']}, 7: {'marks': ['h1']}}),
            move('farMove', FAR, 'h3 Kf6 h2', accept='win', goal='win'),
            # O e08 (revisor, 2.ª passada): o lado forte para o peão pela
            # frente; 1...h3? 2.Rf7 e 1...Rc6? 2.Rf5 empatam.
            talk('front', FRONT, arrows=['b7c8'], marks=['d7', 'd8'],
                 side='black'),
            move('frontMove', FRONT, 'Kc8 Kf6 Kd7',
                 accept={1: 'only', 2: ['Kd7', 'Kd8']}, goal='win'),
        ]},
        {'id': 'recap', 'steps': [
            think('t_close', CLOSE_A5, 1, marks=['c7', 'c8']),
            talk('close', CLOSE_A5, arrows=['c6c7', 'a5b6'], marks=['c8']),
            talk('rules', RETI, arrows=['h8e5', 'e5d6', 'e5h2']),
            move('mirrorMove', MIRROR, 'Kb7 a4 Kc6 Kg6 Kd5 Kxf6 Kc4',
                 accept='hold', goal='draw'),
            play('finish', KG8, goal='draw'),
        ]},
    ],
    # Do mais fácil para o mais difícil (a tela segue a ordem). Cortados na
    # T58: e01, e03, e05 e e07 (repetem passos da lição), antes e02, e04, e06.
    'exercises': [
        exercise('e09', 1, RETI1928, 'Kg6 Kb6 Kxg7 h5 Kxf6',
                 accept='hold', goal='draw', origin='wikiReti'),
        exercise('e08', 2, A7, 'h4 Kf6 Kb8', accept='win', goal='win'),
        exercise('e12', 2, PROKES, 'Kc8 Kc6 Kb8 Kb5 Kb7 Kxa5 Kc6 h5 Kd5',
                 accept='hold', goal='draw', origin='jcaselas'),
        exercise('e10', 2, LASKER, 'Kf5 Kg3 Ke4 Kf2 Kd5',
                 accept='hold', goal='draw', origin='laskerTarrasch'),
        exercise('e13', 3, RETI_BISHOP,
                 'Ke7 g5 Kd6 g4 e7 Bb5 Kc5 Bd7 Kd4 g3 Ke3 g2 Kf2',
                 accept='hold', goal='draw', origin='tenakel'),
        exercise('e11', 3, SARYCHEV, 'Kc8 b5 Kd7 b4 Kd6 Bf5 Ke5',
                 accept='hold', goal='draw', origin='drfiskeson'),
        exercise('e14', 3, RETI_ZUGZWANG,
                 'd6 Ke6 d7 Kxd7 Ka7 Bc8 Kb8 Ba6 Ka7 Kxc7 Kxa6 Kd6 Kb5 Ke5 '
                 'Kc4 Kf4 Kd3', accept='hold', goal='draw', origin='tenakel'),
    ],
    'passScore': 10,
    # Só o que a lição mostra: Réti 1928, Lasker–Tarrasch e Sarychev são
    # exercícios, e a legenda deles entregaria a solução.
    'keyPositions': [
        {'id': 'reti', 'fen': RETI, 'ref': 'wikiReti'},
        {'id': 'yatesMarshall', 'fen': MARSHALL, 'ref': 'yatesMarshall'},
    ],
    'practice': {'fen': RETI, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
})
