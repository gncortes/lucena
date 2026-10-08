"""Gera `rook.cutOff.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.cutOff.py`
e depois o `build_aula.py rook.cutOff`. O aluno joga de brancas, quase sempre
para ganhar; o e06 é o único exercício de defesa."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

# Corte de uma coluna com o peão na quinta: só Td1 ganha (Rd7 empataria).
KEY1 = '5r2/8/2k5/4P3/4K3/8/8/R7 w - - 0 1'
KEY1B = '5r2/8/2k5/4P3/4K3/8/8/R7 b - - 0 1'
# Regra dos cinco: peão na quarta; só Tc1 (duas colunas) ganha, Td1 empata.
KEY2 = '4r3/8/8/1k6/4P3/4K3/8/R7 w - - 0 1'
ONEFILE = after(KEY2, 'Rd1 Kc5')
FIVE = '3r4/8/8/6k1/3P4/3K4/8/5R2 w - - 0 1'   # Wikipedia / mKkvnoxi
# Corte pela fileira (de la Villa 10.17, via Wikipedia), depois de 1...Ta8.
VILLA = '1r6/8/8/2R5/1P1k4/1K6/8/8 b - - 0 1'
RANK = after(VILLA, 'Ra8')
RANK2 = after(RANK, 'Rc6 Rb8 Ra6 Kd5 Ka4 Kc4 Rc6+ Kd5 b5 Ra8+ Kb4 Rb8')
# Os xeques pelo lado, na linha do KEY1.
SIDE = after(KEY1, 'Rd1 Re8 Kf5 Rf8+ Kg5 Re8 Kf6 Rf8+ Ke7 Rh8 e6 Rh7+')
LUCENA = after(SIDE, 'Kf8 Rh8+ Kg7 Rh2 e7 Re2 Kf7 Rf2+ Ke8 Kc7')
CHERON = '1r6/8/4k3/8/1P6/1K6/8/3R4 w - - 0 1'   # Wikipedia / mQHeAvFI
DEFEND = '3r4/8/4k3/4p3/1K6/8/8/4R3 w - - 0 1'   # KEY2 depois de Td1, espelhada
CAPA = '8/8/8/2k5/8/4K3/3R1P1r/8 w - - 0 1'      # Wikipedia / zJlWLhtS
CAPA2 = after(CAPA, 'Rd1 Rh8')                  # só f4 ganha
FINISH = '2r5/8/6k1/8/2P5/2K5/8/4R3 w - - 0 1'
IMPERFECT = '1r6/8/7R/3k4/1P6/1K6/8/8 w - - 0 1'  # xuMvndqe

REFERENCES = [
    {'id': 'wikiRookPawn', 'kind': 'web',
     'title': 'Rook and pawn versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame'},
    {'id': 'audax', 'kind': 'study', 'author': 'Audax6',
     'title': 'E-37 Rook Endings 4: Ways to Cut the King Off',
     'url': 'https://lichess.org/study/NUnDsgmg'},
    {'id': 'harryFile', 'kind': 'study', 'author': 'HarryHw86',
     'title': 'Rook EndGames : Defending king is cut off along file',
     'url': 'https://lichess.org/study/XAPy8A0J'},
    {'id': 'harryRank', 'kind': 'study', 'author': 'HarryHw86',
     'title': 'Rook EndGames : Defending King is cut off along Rank',
     'url': 'https://lichess.org/study/xuMvndqe'},
    {'id': 'five', 'kind': 'study', 'author': 'bar11319',
     'title': 'rule of five rook endgame 1st example',
     'url': 'https://lichess.org/study/mKkvnoxi'},
    {'id': 'cheron', 'kind': 'study', 'author': 'bar11319',
     'title': 'Rule of five Cheron example',
     'url': 'https://lichess.org/study/mQHeAvFI'},
    {'id': 'capablanca', 'kind': 'study', 'author': 'bar11319',
     'title': 'King cut 1 line - rook endgame, Capablanca example',
     'url': 'https://lichess.org/study/zJlWLhtS'},
    {'id': 'practice2', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Intermediate Rook Endings',
     'url': 'https://lichess.org/study/heQDnvq7'},
    {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
     'title': "Dvoretsky's Endgame Manual (5th edition, revised by Karsten Müller)",
     'publisher': 'Russell Enterprises', 'year': 2020,
     'where': 'Sumário do trecho gratuito da editora: "Cutting the King Off" nos capítulos 8 e 9'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

write({
    'id': 'rook.cutOff',
    'module': 'rook',
    'skills': ['rook.cutOff'],
    'parts': [
        {'id': 'cut', 'steps': [
            think('t_cut', KEY1, 5, 2, marks=['d7']),
            talk('cut', KEY1, arrows=['a1d1'], marks=['d8', 'd7', 'd6']),
            talk('late', KEY1B, arrows=['c6d7'], marks=['d7']),
            demo('d_cut', after(KEY1, 'Rd1'),
                 'Re8 Kf5 Rf8+ Kg5 Re8 Kf6 Rf8+ Ke7 Rh8 e6',
                 notes={2: {'arrows': ['e4f5']}, 8: {'arrows': ['f6e7']},
                        10: {'arrows': ['e5e6']}}),
            move('m_cut', KEY1, 'Rd1 Re8 Kf5 Rf8+ Kg5',
                 accept={1: 'win', 2: 'only', 3: 'win'}),
        ]},
        {'id': 'count', 'steps': [
            think('t_count', KEY2, 5, 2, marks=['c1', 'd1']),
            talk('five', KEY2, arrows=['a1c1'], marks=['c5', 'd5']),
            talk('oneFile', ONEFILE, arrows=['c5d5'], marks=['e8']),
            demo('d_five', FIVE, 'Kc4 Rc8+ Kb5 Rd8 Kc5 Rc8+ Kb6 Rd8 Rd1 Kf6 '
                 'Kc7 Ra8 d5',
                 notes={1: {'arrows': ['d3c4']}, 3: {'arrows': ['c4b5']},
                        9: {'arrows': ['f1d1']}, 13: {'arrows': ['d4d5']}}),
            move('m_five', KEY2, 'Rc1 Kb6 Kf4 Rf8+ Kg5',
                 accept={1: 'win', 2: 'only', 3: 'win'}),
        ]},
        {'id': 'rank', 'steps': [
            think('t_rank', RANK, 5, 2, marks=['c5', 'd5']),
            talk('rank', RANK, arrows=['c5h5'], marks=['b4', 'd4']),
            demo('d_rank', RANK, 'Rc6 Rb8 Ra6 Kd5 Ka4 Kc4 Rc6+ Kd5 b5 Ra8+ Kb4',
                 notes={3: {'arrows': ['c6a6']}, 5: {'arrows': ['b3a4']},
                        7: {'arrows': ['a6c6']}, 9: {'arrows': ['b4b5']}}),
            move('m_rank', RANK2, 'Rc7 Kd6 Ra7 Kd5 Ka5 Kc5 Rc7+ Kd6 b6',
                 accept={1: 'only', 2: 'only', 3: 'only', 4: 'only',
                         5: 'win'}),
        ]},
        {'id': 'checks', 'steps': [
            think('t_checks', SIDE, 3, 2, arrows=['h7e7']),
            talk('checks', SIDE, arrows=['h7e7'], marks=['f8', 'g7']),
            demo('d_checks', SIDE, 'Kf8 Rh8+ Kg7 Rh2 e7 Re2 Kf7 Rf2+ Ke8 Kc7',
                 notes={3: {'arrows': ['f8g7']}, 5: {'arrows': ['e6e7']},
                        9: {'arrows': ['f7e8']}}),
            talk('bridge', LUCENA, arrows=['d1c1', 'c1c4'], marks=['c4']),
            move('m_bridge', LUCENA, 'Rc1+ Kb7 Rc4',
                 accept={1: 'only', 2: 'best'}),
        ]},
        {'id': 'recap', 'steps': [
            talk('recap', KEY1, arrows=['a1d1']),
            talk('exceptions', CHERON, arrows=['d1d8'], marks=['a4', 'a5']),
            talk('defend', DEFEND, arrows=['b4c4'], marks=['d5']),
            play('finish', FINISH, goal='win'),
        ]},
    ],
    'exercises': [
        exercise('e01', 1, '2r5/8/5k2/3P4/3K4/8/8/7R w - - 0 1', 'Re1',
                 accept='win'),
        exercise('e02', 1, '3r4/8/6k1/8/3P4/3K4/8/7R w - - 0 1', 'Rf1',
                 accept='win'),
        exercise('e03', 1, '3K4/3P1k2/8/8/8/8/2r5/4R3 w - - 0 1',
                 'Rf1+ Kg7 Rf4', accept={1: 'only', 2: 'best'}),
        exercise('e04', 2, SIDE, 'Kf8 Rh8+ Kg7', accept={1: 'only', 2: 'best'}),
        exercise('e05', 2, '2r5/8/1R6/4k3/2P5/2K5/8/8 w - - 0 1',
                 'Kb4 Kd4 Rd6+', accept='win'),
        exercise('e06', 2, DEFEND, 'Kc4', accept='hold', goal='draw'),
        exercise('e07', 2, IMPERFECT, 'Ka4', accept='win', origin='harryRank'),
        exercise('e08', 2, FIVE, 'Kc4 Rc8+ Kb5', accept={1: 'only', 2: 'win'},
                 origin='five'),
        exercise('e09', 3, CAPA2, 'f4 Re8+ Kf3', accept='win',
                 origin='capablanca'),
        exercise('e10', 3, KEY2, 'Rc1 Kb6 Kf4 Rf8+ Kg5 Re8 Kf5',
                 accept={1: 'win', 2: 'only', 3: 'only', 4: 'win'}),
    ],
    'passScore': 12,
    'keyPositions': [
        {'id': 'cut', 'fen': KEY1},
        {'id': 'count', 'fen': KEY2},
        {'id': 'five', 'fen': FIVE, 'ref': 'wikiRookPawn'},
        {'id': 'villa', 'fen': VILLA, 'ref': 'wikiRookPawn'},
        {'id': 'cheron', 'fen': CHERON, 'ref': 'wikiRookPawn'},
        {'id': 'capablanca', 'fen': CAPA, 'ref': 'wikiRookPawn'},
    ],
    'practice': {'fen': '7r/2R5/6P1/8/8/8/K7/6k1 w - - 0 1', 'goal': 'win',
                 'positionId': 'rookPawn.rookPawnVsRook.0002'},
    'references': REFERENCES,
})
