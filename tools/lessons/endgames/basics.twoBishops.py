"""Gera `basics.twoBishops.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/basics.twoBishops.py`
e depois o `build_aula.py basics.twoBishops`.

Lição refeita na T63 (ver docs/aulas/basics.twoBishops.md, "Lição refeita").
A partida Nakamura-Sheehan vem do PGN Mentor (players/Nakamura.zip) e foi
reproduzida com python-chess; o ply de cada passo está no `ref`. As posições
montadas foram escolhidas numa tabela de rei e dois bispos contra rei (lance
ensinado único na folga de um lance) e comparadas com os exercícios."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (demo, move, play, talk, think,  # noqa: E402
                         write)

LICHESS = 'https://lichess.org/analysis/pgn/'
NAKA_PGN = 'e3_e5_Ne2_d5_Ng3_Nf6_d4_e4_c4_c6_f4_exf3_gxf3_Bd6_Nc3_O-O_Qc2_Re8_Bd2_dxc4_O-O-O_b5_e4_Be7_Be3_Qa5_Kb1_Na6_Rg1_Nb4_Qg2_g6_h4_Be6_h5_Nd3_hxg6_fxg6_Nf5_b4_Nxe7+_Rxe7_Ne2_Nxb2_Nf4_Nxd1_Nxg6_Nc3+_Ka1_Rf7_Nf4+_Bg4_Bxc4_Kf8_fxg4_Ncxe4_g5_b3_Qb2_Rb7_gxf6_Nxf6_d5_Qxa2+_Qxa2_bxa2_Bc5+_Ke8_Kxa2_cxd5_Nxd5_Nxd5_Bxd5_Rc7_Rg8+_Kd7_Rg7+_Kc8_Rxc7+_Kxc7_Bxa8_h5_Bxa7_h4_Bg1_h3_Bh1_Kd6_Bh2+_Ke6_Kb3_Kf5_Kc3_Kg4_Kd4_Kh4_Ke5_Kg4_Be4_Kh4_Kf5_Kh5_Bg3_Kh6_Be5_Kh5_Bf6_Kh6_Bf3_h2_Be5_Kh7_Bxh2_Kh6_Be5_Kh7_Kf6_Kh6_Bf4+_Kh7_Kf7_Kh8_Be3_Kh7_Be4+_Kh8_Bd4'

WALL = '8/3k4/8/3BB3/4K3/8/8/8 w - - 0 1'          # a parede (própria)
SEIRAWAN = '8/8/8/8/3k4/8/8/2BK1B2 w - - 0 1'      # Seirawan, via Wikipedia
NAKA_58 = '8/8/7k/5K2/8/5B2/7B/8 w - - 1 58'       # ply 114, depois de 57.Bxh2
NAKA_MATE = '7k/5K2/8/8/3BB3/8/8/8 b - - 14 64'    # ply 127, depois de 64.Bd4#

MATE1 = '7k/8/6K1/8/2B2B2/8/8/8 w - - 0 1'         # mate do canto em um lance
SIDE = '1k6/1B6/1K1B4/8/8/8/8/8 b - - 0 1'         # mate na casa vizinha (Fine)
EDGE_MATE = '4k3/4B3/4K3/1B6/8/8/8/8 b - - 0 1'    # mate no meio da borda (Fine)
JOIN = '8/8/5k2/2BB4/8/6K1/8/8 w - - 0 1'          # outra parede: o rei por fora
BUILD = '8/8/8/8/2k1K3/8/8/B2B4 w - - 0 1'          # bispos na 1ª fileira (própria)
EDGE3 = '3k4/8/4K3/3BB3/8/8/8/8 w - - 0 3'         # a parede, depois de 2.Re6 Rd8
BOX = '1B4k1/8/5K2/8/4B3/8/8/8 w - - 0 1'          # outra caixa no canto h8 (própria)
FAR = '8/8/B6B/8/6k1/8/8/2K5 w - - 0 1'            # bispos de longe (h1)
FAR2 = '4B3/2k5/8/8/8/K7/8/4B3 w - - 0 1'          # bispos de longe (a8)
AHEAD = '4k3/8/7K/8/7B/8/8/1B6 w - - 0 1'          # feche d7 antes do xeque
AHEAD2 = '8/8/8/2B5/8/5B2/7K/4k3 w - - 0 1'        # feche d2 e f2 antes do xeque
SILMAN = 'k7/2B5/2K5/8/2B5/8/8/8 w - - 0 1'        # Silman, via Wikipedia
APPROACH13 = '2k5/8/2BBK3/8/8/8/8/8 w - - 0 13'    # Seirawan, depois de 12.Bc6 Rc8


EXERCISES = [{'id': 'e04',
  'stars': 1,
  'fen': '7k/5K2/7B/8/8/8/8/5B2 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'h6g7', 'accept': 'best'}]},
 {'id': 'e12',
  'stars': 1,
  'fen': '8/8/8/8/5B2/3K4/8/3k1B2 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'f1e2', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'f4g3', 'accept': 'only'}]},
 {'id': 'e13',
  'stars': 2,
  'fen': '6B1/8/8/8/8/K1B5/8/3k4 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'g8c4', 'accept': 'best'}]},
 {'id': 'e14',
  'stars': 2,
  'fen': 'k1K1B3/8/3B4/8/8/8/8/8 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'e8b5', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'd6c5', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'b5c6', 'accept': 'only'}]},
 {'id': 'e15',
  'stars': 3,
  'fen': '8/8/8/8/3B4/8/8/1k1K1B2 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'f1b5', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'd1c2', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'd4c5', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'b5c4', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'c5d4', 'accept': 'only'}]},
 {'id': 'e16',
  'stars': 3,
  'fen': '8/8/8/8/5B2/8/4K3/3B3k w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'e2f3', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'd1e2', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'f3g3', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'f4e3', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'e2f3', 'accept': 'only'}]},
 {'id': 'e17',
  'stars': 3,
  'fen': '8/8/3B4/1B6/3k4/8/3K4/8 w - - 0 1',
  'goal': 'win',
  'origin': 'own',
  'turns': [{'teach': 'b5c6', 'accept': 'best', 'reply': 'auto'},
            {'teach': 'd2e3', 'accept': 'best'}]}]


def ref(step, rid):
    step['ref'] = rid
    return step


REFERENCES = [
    {'id': 'wikipedia', 'kind': 'web',
     'title': 'Checkmate: King and two bishops (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Checkmate#Two_bishops'},
    {'id': 'nakaSheehan', 'kind': 'game', 'white': 'Hikaru Nakamura',
     'black': 'Ethan Sheehan', 'event': 'Titled Tuesday (chess.com)',
     'year': 2024, 'url': LICHESS + NAKA_PGN + '#127'},
    {'id': 'pgnmentorNakamura', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Nakamura',
     'url': 'https://www.pgnmentor.com/players/Nakamura.zip'},
    {'id': 'lichessPractice', 'kind': 'web',
     'title': 'Lichess Practice: Piece Checkmates II, Two bishop mate',
     'url': 'https://lichess.org/practice/checkmates/practicestnampiececheckmatesii/Rg2cMBZ6/17sHdtD6'},
    {'id': 'seirawan', 'kind': 'book', 'author': 'Yasser Seirawan',
     'title': 'Winning Chess Endings', 'publisher': 'Everyman Chess',
     'year': 2003},
    {'id': 'silman', 'kind': 'book', 'author': 'Jeremy Silman',
     'title': "Silman's Complete Endgame Course: From Beginner to Master",
     'publisher': 'Siles Press', 'year': 2007},
    {'id': 'chesscom', 'kind': 'web',
     'title': 'Checkmate With Two Bishops (Chess.com, Chess Terms)',
     'url': 'https://www.chess.com/terms/checkmate-two-bishops-chess'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'basics.twoBishops',
    'module': 'basics',
    'skills': ['mate.twoBishops'],
    'parts': [
        # 1. O destino: os três desenhos de mate (e04, e12).
        {'id': 'mates', 'steps': [
            think('t_mates', MATE1, 2, marks=['g8', 'g7', 'h7'], ask='line'),
            ref(talk('mateCorner', NAKA_MATE, arrows=['d4h8', 'e4h7'],
                     marks=['g7', 'g8']), 'nakaSheehan#127'),
            ref(talk('mateSide', SIDE, arrows=['d6b8', 'b7a8', 'b7c8'],
                     marks=['b8']), 'wikipedia'),
            ref(talk('mateEdge', EDGE_MATE, arrows=['b5e8'],
                     marks=['d8', 'f8']), 'wikipedia'),
            move('cornerMate', MATE1, 'Be5#', accept='only'),
        ]},
        # 2. A parede e o rei na frente dela (e17).
        {'id': 'wall', 'steps': [
            think('t_wall', WALL, 2),
            talk('wall', WALL, arrows=['d5a8', 'd5g8', 'e5b8', 'e5h8'],
                 marks=['c8', 'd8', 'e8', 'f8', 'd7', 'e7']),
            demo('d_join', WALL, 'Kf5 Kc8 Ke6 Kd8',
                 notes={1: {'arrows': ['e4f5']},
                        3: {'marks': ['d7', 'e7', 'f7']},
                        4: {'marks': ['c8', 'd8', 'e8', 'f8']}}),
            move('joinMove', JOIN, 'Kf4'),
        ]},
        # 3. Montar a parede do zero: Seirawan (e17).
        {'id': 'build', 'steps': [
            ref(think('t_build', SEIRAWAN, 2), 'seirawan'),
            ref(talk('build', SEIRAWAN, marks=['c4', 'd4']), 'seirawan'),
            ref(demo('d_build', SEIRAWAN,
                     'Ke2 Ke4 Be3 Ke5 Kd3 Kd5 Bd4 Ke6 Ke4 Kd6 Bc4',
                     notes={3: {'marks': ['d4', 'f4']},
                            7: {'arrows': ['e3d4']},
                            11: {'arrows': ['f1c4'], 'marks': ['c4', 'd4']}}),
                'seirawan'),
            move('buildMove', BUILD, 'Bd4'),
        ]},
        # 4. Descer a parede até o canto e dar o mate.
        {'id': 'edge', 'steps': [
            think('t_edge', EDGE3, 2),
            talk('edgeTalk', EDGE3, arrows=['d5b7'], marks=['c8']),
            demo('d_edge', EDGE3, 'Bb7 Ke8 Bc7 Kf8 Kf6 Ke8 Bc6+ Kf8 Bd7 Kg8',
                 notes={1: {'marks': ['c8']}, 3: {'marks': ['d8', 'b8']},
                        5: {'marks': ['e7', 'f7', 'g7']},
                        9: {'marks': ['e8']},
                        10: {'marks': ['f8', 'g8', 'h8']}}),
            move('mate', BOX, 'Bd6 Kh8 Kg6 Kg8 Bd5+ Kh8 Be5#',
                 accept={4: 'only'}),
        ]},
        # 5. Os bispos prendem de longe (e13).
        {'id': 'far', 'steps': [
            think('t_far', FAR, 2),
            talk('far', FAR, arrows=['h6c1', 'b1h7'], marks=['e4', 'f5', 'g6']),
            demo('d_far', FAR, 'Bd3 Kh5 Bd2 Kh4 Be2 Kh3 Be3 Kh4 Kd2 Kh3',
                 notes={1: {'arrows': ['d3h7']},
                        3: {'marks': ['e1']},
                        5: {'marks': ['f3']},
                        7: {'marks': ['f2', 'g1']},
                        9: {'arrows': ['c1d2']}}),
            move('farMove', FAR2, 'Bb4'),
        ]},
        # 6. Feche a saída antes do xeque (e14, e15).
        {'id': 'ahead', 'steps': [
            think('t_ahead', AHEAD, 3),
            talk('ahead', AHEAD, arrows=['b1g6'], marks=['d7']),
            demo('d_check', AHEAD, 'Bg6+ Kd7',
                 notes={1: {'arrows': ['g6e8']}, 2: {'marks': ['d7']}}),
            demo('d_ahead', AHEAD, 'Bf5 Kf7 Bd7 Kf8 Kg6 Kg8',
                 notes={1: {'marks': ['d7']}, 3: {'marks': ['e8']},
                        6: {'marks': ['f8', 'g8', 'h8']}}),
            move('aheadMove', AHEAD2, 'Be3 Kf1 Kg3'),
        ]},
        # 7. Conte as casas: o afogamento e o rei por fora (e04, e16).
        {'id': 'stalemate', 'steps': [
            ref(think('t_stalemate', SILMAN, 2), 'silman'),
            ref(talk('stalemate', SILMAN, arrows=['c6b6'], marks=['b6', 'a8']),
                'silman'),
            ref(demo('d_approach', APPROACH13, 'Kd5 Kd8 Kc5 Kc8 Kb6 Kd8',
                     notes={1: {'marks': ['d8']}, 5: {'marks': ['d8']}}),
                'seirawan'),
            ref(move('waiting', SILMAN, 'Bd3 Ka7'), 'silman'),
        ]},
        # 8. Nakamura, as regras e o desafio prático.
        {'id': 'finish', 'steps': [
            talk('rules', WALL, marks=['d5', 'e5']),
            ref(talk('naka', NAKA_58, marks=['h6']), 'nakaSheehan#114'),
            ref(demo('d_naka', NAKA_58, 'Be5 Kh7 Kf6 Kh6 Bf4+ Kh7',
                     notes={1: {'marks': ['g7']}, 5: {'arrows': ['f4h6']}}),
                'nakaSheehan#114'),
            play('playWall', WALL),
            ref(play('playCenter', SEIRAWAN), 'seirawan'),
        ]},
    ],
    # Exercícios: copiados como estavam (posições, linhas, estrelas e ids).
    'exercises': EXERCISES,
    'passScore': 9,
    'keyPositions': [{'id': 'wall', 'fen': '8/3k4/8/3BB3/4K3/8/8/8 w - - 0 1'},
     {'id': 'mateCorner',
      'fen': '7k/8/4B1K1/4B3/8/8/8/8 b - - 0 1',
      'ref': 'wikipedia'},
     {'id': 'mateSide',
      'fen': '1k6/1B6/1K1B4/8/8/8/8/8 b - - 0 1',
      'ref': 'wikipedia'},
     {'id': 'stalemate',
      'fen': 'k7/2B5/2K5/8/2B5/8/8/8 w - - 0 1',
      'ref': 'silman'},
     {'id': 'seirawan',
      'fen': '8/8/8/8/3k4/8/8/2BK1B2 w - - 0 1',
      'ref': 'seirawan'}],
    'practice': {'fen': '8/8/8/4k3/8/7B/2K5/4B3 w - - 0 1', 'goal': 'win',
                 'positionId': 'bishop.twoBishopsVsKing.0001'},
    'references': REFERENCES,
})
