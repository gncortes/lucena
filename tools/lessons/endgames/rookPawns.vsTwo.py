"""Gera `rookPawns.vsTwo.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rookPawns.vsTwo.py`
e depois o `build_aula.py rookPawns.vsTwo`. Torre contra dois peões ligados:
sem reis (sexta e quinta fileira), com o rei da torre (contar as casas), com o
rei dos peões (esconder-se dos xeques) e as ameaças de mate que salvam a torre.
Dossiê: `docs/aulas/rookPawns.vsTwo.md`."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

SIXTH = 'K6k/8/8/8/8/5pp1/8/R7 w - - 0 1'        # peões na sexta: perde
FIFTH = 'K6k/8/8/8/5pp1/8/8/R7 w - - 0 1'        # na quinta: só Ta4
FIFTH_B = 'K6k/8/8/8/5pp1/8/8/R7 b - - 0 1'      # pretas jogando: empate
EUWE = '3r4/8/3PP3/3K4/8/8/8/7k b - - 0 1'        # estudo Anki, "Rule 2"
KING = '7k/8/8/8/2K5/5pp1/8/R7 w - - 0 1'         # rei em c4: ganha
KING_LATE = '7k/8/8/8/1K6/5pp1/8/R7 w - - 0 1'    # rei em b4: perde
KING_C3 = '7k/8/8/8/8/2K2pp1/8/R7 w - - 0 1'      # rei em c3: ganha
ESCORT = '1k6/8/7P/5KP1/8/8/8/7r w - - 0 1'       # Lichess Practice
ESCORT_M = '6k1/8/P7/1PK5/8/8/8/r7 w - - 0 1'     # o mesmo, espelhado
RESOURCE = '8/8/2R5/4K1k1/8/pp6/8/8 w - - 0 1'    # Lichess Practice
RESOURCE_C7 = '8/2R5/8/4K1k1/8/pp6/8/8 w - - 0 1'  # torre em c7: Tc1
TRAP = after(RESOURCE, 'Rc1 a2 Rg1+ Kh4 Kf4 Kh3 Kf3 Kh2')  # Ta1 zugzwang
RECAP = 'k6K/8/8/8/1pp5/8/8/7R w - - 0 1'         # quinta, espelhada

REFERENCES = [
    {'id': 'delaVilla', 'kind': 'book', 'author': 'Jesús de la Villa',
     'title': '100 Endgames You Must Know (4.ª edição)',
     'publisher': 'New in Chess', 'year': 2015,
     'where': 'cap. 6, "Rook vs. 2 Pawns", finais 30–32 (índice do trecho '
              'da editora)'},
    {'id': 'mullerLamprecht', 'kind': 'book',
     'author': 'Karsten Müller e Frank Lamprecht',
     'title': 'Fundamental Chess Endings', 'publisher': 'Gambit',
     'year': 2001,
     'where': '6.1 B1, "Connected Pawns" (índice da amostra da editora)'},
    {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
     'title': "Dvoretsky's Endgame Manual (5.ª edição)",
     'publisher': 'Russell Enterprises', 'year': 2020,
     'where': 'cap. 8, "Rook vs. Connected Pawns" (índice do trecho da '
              'editora)'},
    {'id': 'practice', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Intermediate Rook Endings',
     'url': 'https://lichess.org/study/heQDnvq7'},
    {'id': 'audax', 'kind': 'study', 'author': 'Audax6',
     'title': 'E-33 Rook against Pawns - The king comes first',
     'url': 'https://lichess.org/study/I2GArVyI'},
    {'id': 'anki', 'kind': 'study', 'author': 'Anki_Thief_of_Crowns',
     'title': 'Rook against Pawns',
     'url': 'https://lichess.org/study/zLovcaQR'},
    {'id': 'shankland', 'kind': 'game', 'white': 'Sam Shankland',
     'black': 'Parham Maghsoodloo', 'event': 'Praga', 'year': 2022},
    {'id': 'wikiEndgame', 'kind': 'web', 'title': 'Wikipedia: Chess endgame',
     'url': 'https://en.wikipedia.org/wiki/Chess_endgame'},
    {'id': 'wikiConnected', 'kind': 'web',
     'title': 'Wikipedia: Connected pawns',
     'url': 'https://en.wikipedia.org/wiki/Connected_pawns'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

PARTS = [
    {'id': 'sixth', 'steps': [
        think('t_sixth', SIXTH, 5, 2, arrows=['f3f1', 'g3g1'],
              marks=['f1', 'g1']),
        talk('sixth', SIXTH, arrows=['f3f1', 'g3g1'], marks=['a8', 'h8']),
        demo('d_sixth', SIXTH, 'Rf1 g2 Rg1 f2 Rxg2 f1=Q', side='black',
             notes={1: {'arrows': ['f1f3']}, 2: {'arrows': ['g2g1']},
                    4: {'marks': ['f1', 'g1']}}),
        talk('euwe', EUWE, arrows=['d6d8', 'e6e8'], marks=['d5']),
        move('push', after(SIXTH, 'Ra3'), 'f2 Rf3 g2 Rxf2 g1=Q',
             accept='win'),
    ]},
    {'id': 'fifth', 'steps': [
        think('t_fifth', FIFTH, 5, 2, arrows=['a1a4'], marks=['f4', 'g4'],
              ask='line'),
        talk('fifth', FIFTH, arrows=['a1a4', 'a4f4'], marks=['f4', 'g4']),
        talk('fifthTempo', FIFTH_B, arrows=['g4g3'], marks=['f3', 'g3']),
        move('fifthMove', FIFTH, 'Ra4 Kg7 Rxf4 g3 Rg4+',
             accept={1: 'only', 2: 'only', 3: 'win'}),
    ]},
    {'id': 'king', 'steps': [
        think('t_king', KING, 5, 2, arrows=['c4d3', 'd3e2'],
              marks=['e2', 'f1']),
        talk('king', KING, arrows=['c4d3', 'd3e2'], marks=['e2', 'e3']),
        talk('kingLate', KING_LATE, arrows=['b4c3', 'c3d2'], marks=['f1']),
        demo('d_king', KING, 'Kd3 g2 Ke3 Kg7 Kxf3 Kf6 Kxg2',
             notes={1: {'arrows': ['d3e3']}, 3: {'marks': ['f2', 'f3']},
                    5: {'arrows': ['f3g2']}}),
        move('kingMove', KING_C3, 'Kd2 f2 Ke2 Kg7 Ra3', accept='win'),
    ]},
    {'id': 'escort', 'steps': [
        think('t_escort', ESCORT, 3, 2, arrows=['f5g6', 'g6h7'],
              marks=['h7'], ask='line'),
        talk('escort', ESCORT, arrows=['h1h5'], marks=['h7', 'g6']),
        demo('d_escort', ESCORT, 'Kg6 Kc7 Kh7 Kd7 g6 Ke7 g7',
             notes={1: {'arrows': ['g6h7']}, 3: {'marks': ['h8']},
                    5: {'arrows': ['g6g7']}}),
        move('escortMove', ESCORT_M, 'Kb6 Kf7 Ka7 Rb1 b6',
             accept='only'),
    ]},
    {'id': 'resource', 'steps': [
        think('t_resource', RESOURCE, 5, 2, arrows=['c6c1', 'c1g1'],
              marks=['g5'], ask='line'),
        talk('resource', RESOURCE, arrows=['c6c1', 'c1g1'], marks=['h4']),
        demo('d_resource', RESOURCE, 'Rc1 a2 Rg1+ Kh4 Kf4 Kh3 Kf3 Kh4',
             goal='draw', notes={1: {'arrows': ['c1g1']},
                                 3: {'marks': ['h4', 'h3']},
                                 5: {'arrows': ['f4f3']}}),
        talk('resourceTrap', TRAP, arrows=['g1a1'], marks=['a2', 'h2']),
        move('resourceMove', RESOURCE_C7, 'Rc1 a2 Rg1+ Kh4 Kf4',
             accept='hold', goal='draw'),
    ]},
    {'id': 'recap', 'steps': [
        talk('recap', SIXTH, arrows=['f3f1', 'g3g1']),
        talk('rules', KING, arrows=['c4d3', 'd3e2']),
        move('recapMove', RECAP, 'Rh4 Kb7 Rxc4', accept='only'),
        play('finish', KING),
    ]},
]

EXERCISES = [
    exercise('e01', 1, 'K6k/8/8/8/5pp1/8/8/1R6 w - - 0 1', 'Rb4',
             accept='only'),
    exercise('e02', 1, '7k/8/8/3K4/8/5pp1/8/R7 w - - 0 1', 'Ke4',
             accept='win'),
    exercise('e03', 1, '7k/4K3/8/8/8/5pp1/8/R7 w - - 0 1', 'Kf7',
             accept='only'),
    exercise('e04', 1, after(SIXTH, 'Rf1'), 'g2', accept='win'),
    exercise('e05', 2, 'K7/3k4/6R1/8/5p2/6p1/8/8 w - - 0 1', 'Rg4 g2 Rxg2',
             accept='only', origin='audax'),
    exercise('e06', 2, '8/8/4K3/R7/1p6/pk6/8/8 b - - 0 1', 'Ka2',
             accept='only', origin='audax'),
    exercise('e07', 2, '8/8/PK6/1P6/8/4k3/2r5/8 w - - 0 1', 'Ka7',
             accept='win', origin='shankland'),
    exercise('e08', 2, '8/8/3R4/4K1k1/8/pp6/8/8 w - - 0 1', 'Rd1',
             accept='hold', goal='draw'),
    exercise('e09', 3, '8/8/8/2R1K1k1/8/pp6/8/8 w - - 0 1', 'Kd4+ Kf4 Kc3',
             accept={1: 'only', 2: 'win'}),
    exercise('e11', 3, '8/8/8/1K5k/5pp1/8/8/R7 w - - 0 1',
             'Kc4 g3 Kd3 Kg4 Ke2', accept='only'),
]

LESSON = {
    'id': 'rookPawns.vsTwo',
    'module': 'rookPawns',
    'skills': ['rook.vsTwoPawns'],
    'parts': PARTS,
    'exercises': EXERCISES,
    'passScore': 11,
    'keyPositions': [
        {'id': 'sixth', 'fen': SIXTH, 'ref': 'wikiEndgame'},
        {'id': 'fifth', 'fen': FIFTH},
        {'id': 'king', 'fen': KING},
        {'id': 'euwe', 'fen': EUWE, 'ref': 'anki'},
        {'id': 'escort', 'fen': ESCORT, 'ref': 'practice'},
        {'id': 'resource', 'fen': RESOURCE, 'ref': 'practice'},
    ],
    'practice': {'fen': KING, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
}

if __name__ == '__main__':
    write(LESSON)
