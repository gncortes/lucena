"""Gera `rook.cutOff.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.cutOff.py`
e depois o `build_aula.py rook.cutOff`. O aluno joga de brancas, sempre
para ganhar. Lição refeita na T61 (2026-10-10): sete partes, uma ideia por
parte, com Uhlmann-Gulko (Niksic 1978) na parte `behind`."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)


def ref(step, reference):
    """O passo vem de uma partida ou estudo (`id` ou `id#ply`)."""
    step['ref'] = reference
    return step


# Corte de uma coluna com o peão na quinta: só Td1 ganha (Rd7 empataria).
KEY1 = '5r2/8/2k5/4P3/4K3/8/8/R7 w - - 0 1'
KEY1B = '5r2/8/2k5/4P3/4K3/8/8/R7 b - - 0 1'
# Regra dos cinco: peão na quarta; só Tc1 (duas colunas) ganha, Td1 empata.
KEY2 = '4r3/8/8/1k6/4P3/4K3/8/R7 w - - 0 1'
ONEFILE = after(KEY2, 'Rd1 Kc5')
FIVE = '3r4/8/8/6k1/3P4/3K4/8/5R2 w - - 0 1'   # Wikipedia / mKkvnoxi
# O tempo do peão (própria): só 1.e4 ganha; 1.Rf4? empata.
TEMPO = '7r/8/8/1k6/8/4PK2/8/2R5 w - - 0 1'
TEMPO_LATE = after(TEMPO, 'Kf4 Rf8+')
# Corte pela fileira (de la Villa 10.17, via Wikipedia), depois de 1...Ta8.
VILLA = '1r6/8/8/2R5/1P1k4/1K6/8/8 b - - 0 1'
RANK = after(VILLA, 'Ra8')
RANK2 = after(RANK, 'Rc6 Rb8 Ra6 Kd5 Ka4 Kc4 Rc6+ Kd5 b5 Ra8+ Kb4 Rb8')
# Corte imperfeito (própria): brancas jogando, só 1.Rg3 e 1.Tg5 ganham;
# pretas jogando, só 1...Tg8 empata.
IMP = '5r2/8/8/R7/3k4/5P2/5K2/8 w - - 0 1'
IMP_BLACK = after('5r2/8/8/R7/3k4/5P2/5K2/8 b - - 0 1', 'Rg8')
# Corte imperfeito com peão central (própria, e14): só 1.Rc4 ganha. 1.Tc6?
# solta a coluna a (1...Ta8! e xeques pelo lado); 1.Rc3? Re4 ataca o peão.
# Depois de 1...Re4, só 2.Te6+.
IMP2 = '3r4/8/R7/5k2/3P4/3K4/8/8 w - - 0 1'
# Torre atrás do peão cortando pela fileira (própria): só 1.Td5 ganha.
BEHIND = '3r4/3P4/8/8/7k/8/8/3RK3 w - - 0 1'
# Uhlmann-Gulko, Niksic 1978, depois de 57...Rf5? (ply 114).
GULKO_GAME = '8/8/4r3/5k2/7K/4p3/8/1R6 w - - 1 58'
# Contagem do resumo (própria): só 1.Te1 e 1.Ta6 ganham; 1.Td1 empata.
RECAP_COUNT = '2r5/8/8/5k2/2P5/2K5/8/R7 w - - 0 1'
CHERON = '1r6/8/4k3/8/1P6/1K6/8/3R4 w - - 0 1'   # Wikipedia / mQHeAvFI
CAPA = '8/8/8/2k5/8/4K3/3R1P1r/8 w - - 0 1'      # Wikipedia / zJlWLhtS
CAPA2 = after(CAPA, 'Rd1 Rh8')                  # só f4 ganha
FINISH = '2r5/8/6k1/8/2P5/2K5/8/4R3 w - - 0 1'
# Pein-Ward, British Championship 1997 (Wikipedia), com as cores trocadas.
PEIN = '8/2R5/8/2P2k2/r7/3K4/8/8 w - - 0 1'
# Uhlmann-Gulko, Niksic 1978, com as cores trocadas (posição antes de 57...).
GULKO = '1r6/8/4P3/7k/8/4RK2/8/8 w - - 0 1'

# Lances das partidas (PGN Mentor e chessgames.com), para os links do Lichess.
UHLMANN_GULKO = (
    'c4_Nf6_Nc3_e6_Nf3_b6_e4_Bb7_Bd3_c5_Bc2_Nc6_d4_cxd4_Nxd4_Nxd4_Qxd4_Bc5_'
    'Qd1_Qc7_O-O_h5_g3_Ng4_Bf4_Ne5_Nb5_Qb8_Qe2_f6_Rad1_a6_Nd4_g5_Bxe5_Qxe5_'
    'Qd2_h4_b4_Bf8_Nf5_O-O-O_Nd6+_Qxd6_Qxd6_Bxd6_Rxd6_Kc7_Rd2_a5_a3_axb4_ax'
    'b4_Ra8_Rfd1_Rhd8_gxh4_gxh4_f3_Ra3_Kf2_f5_Bd3_fxe4_fxe4_Rf8+_Ke3_e5_Ke2'
    '_Rf7_Rf1_Rxf1_Kxf1_d6_Kf2_Bc8_Be2_Be6_Rc2_Rh3_c5_bxc5_bxc5_Rxh2+_Kg1_R'
    'h3_Bc4_Bxc4_Rxc4_Rd3_cxd6+_Kxd6_Ra4_Rd4_Ra6+_Ke7_Kh2_Rxe4_Kh3_Kf7_Rh6_'
    'Rf4_Rb6_e4_Kg2_Rf6_Rb4_Re6_Kh3_e3_Rb1_Kf6_Kxh4_Kf5_Kg3_Ke4_Kg2_Rg6+_Kf'
    '1_Kf3_Rb3_Ra6_Rb1_Rh6_Kg1_Rg6+')
PEIN_WARD = (
    'd4_e6_e4_d5_Nc3_Bb4_e5_c5_a3_Bxc3+_bxc3_Qa5_Bd2_Qa4_Qg4_g6_Rc1_Nc6_Nf3'
    '_h6_Qf4_c4_h4_Bd7_Nh2_Rh7_Ng4_O-O-O_Be2_Qxa3_O-O_Qe7_g3_Rf8_Nf6_Nxf6_e'
    'xf6_Qd8_Ra1_g5_Qd6_Rg8_h5_Qc7_Qxc7+_Kxc7_f4_a6_Kg2_Na7_g4_Nb5_Bf3_gxf4'
    '_Bxf4+_Kc8_Bd2_Bc6_Kg3_Kd7_Rfe1_Nd6_Bf4_Ra8_Re5_a5_g5_hxg5_Rxg5_a4_Bxd'
    '6_Kxd6_Rg7_Rh6_Rxf7_Rg8+_Rg7_Rf8_Rg6_Rxg6+_hxg6_Rxf6_Bh5_Rf8_Kh4_Ke7_K'
    'g5_Rf5+_Kh6_Be8_Rh1_Bxg6_Bxg6_Rf3_Rb1_Kf6_Rxb7_Rh3+_Bh5_Kf5_Ra7_Ke4_Rx'
    'a4_Rxc3_Bg4_Kxd4_Bxe6_Ke5_Bf7_Rxc2_Ra5_Kf6_Rxd5_Kxf7_Kg5_Ke6_Ra5_Kd6_K'
    'f4_Re2_Kf3_Re7_Kf2_Kc6_Kf3_Kb6_Rd5_c3_Rh5_c2_Rh1_Rc7_Rc1_Kb5_Ke2_Kb4_K'
    'd2_Kb3_Rh1_Kb2')

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
    {'id': 'deemiranda', 'kind': 'study', 'author': 'deemiranda29',
     'title': 'Rook endgame studies Vol. 2: Rook and Pawn vs. Rook',
     'url': 'https://lichess.org/study/yuOYmVsQ'},
    {'id': 'uhlmannGulko', 'kind': 'game', 'white': 'Wolfgang Uhlmann',
     'black': 'Boris Gulko', 'event': 'Niksic', 'year': 1978,
     'url': 'https://lichess.org/analysis/pgn/' + UHLMANN_GULKO + '#114'},
    {'id': 'uhlmannGulkoSrc', 'kind': 'web',
     'title': 'PGN Mentor: partidas de Uhlmann (Uhlmann.zip)',
     'url': 'https://www.pgnmentor.com/players/Uhlmann.zip'},
    {'id': 'peinWard', 'kind': 'game', 'white': 'Malcolm Pein',
     'black': 'Chris Ward', 'event': 'Campeonato Britânico, Hove',
     'year': 1997,
     'url': 'https://lichess.org/analysis/pgn/' + PEIN_WARD + '#119'},
    {'id': 'peinWardSrc', 'kind': 'web',
     'title': 'Pein vs Ward, British Championship 1997 (chessgames.com)',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=2280252'},
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
            think('t_cut', KEY1, 2, marks=['d7']),
            talk('cut', KEY1, arrows=['a1d1'], marks=['d8', 'd7', 'd6']),
            talk('late', KEY1B, arrows=['c6d7'], marks=['d7']),
            demo('d_cut', after(KEY1, 'Rd1'),
                 'Re8 Kf5 Rf8+ Kg5 Re8 Kf6 Rf8+ Ke7',
                 notes={2: {'arrows': ['e4f5']}, 8: {'arrows': ['f6e7']}}),
            move('m_cut', KEY1, 'Rd1 Re8 Kf5 Rf8+ Kg5',
                 accept={1: 'win', 2: 'only', 3: 'win'}),
        ]},
        {'id': 'count', 'steps': [
            think('t_count', KEY2, 2, marks=['c1', 'd1']),
            talk('five', KEY2, arrows=['a1c1'], marks=['c5', 'd5']),
            demo('d_oneFile', ONEFILE, 'Kf4 Rf8+ Kg5 Re8 Kf5 Rf8+',
                 goal='draw',
                 notes={2: {'arrows': ['e8f8']}, 4: {'marks': ['e5']}}),
            ref(demo('d_five', FIVE, 'Kc4 Rc8+ Kb5 Rd8 Kc5',
                 notes={1: {'arrows': ['d3c4']}, 3: {'arrows': ['c4b5']},
                        5: {'arrows': ['b5c5']}}), 'five'),
            move('m_five', KEY2, 'Rc1 Kb6 Kf4 Rf8+ Kg5',
                 accept={1: 'win', 2: 'only', 3: 'win'}),
        ]},
        {'id': 'tempo', 'steps': [
            think('t_tempo', TEMPO, 2, marks=['e8']),
            talk('tempo', TEMPO, arrows=['e3e4'], marks=['e8']),
            demo('d_tempoLate', TEMPO_LATE, 'Kg4 Re8 Kf4 Rf8+', goal='draw',
                 notes={2: {'marks': ['e4']}}),
            move('m_tempo', TEMPO, 'e4 Rf8+ Ke3 Re8 Kf4',
                 accept={1: 'only', 2: 'win', 3: 'win'}),
        ]},
        {'id': 'rank', 'steps': [
            ref(think('t_rank', RANK, 2, marks=['c5', 'd5']), 'wikiRookPawn'),
            ref(talk('rank', RANK, arrows=['c5h5'], marks=['b4', 'd4']),
                'wikiRookPawn'),
            ref(demo('d_rank', RANK, 'Rc6 Rb8 Ra6 Kd5 Ka4 Kc4 Rc6+ Kd5 b5',
                     notes={3: {'arrows': ['c6a6']}, 5: {'arrows': ['b3a4']},
                            7: {'arrows': ['a6c6']},
                            9: {'arrows': ['b4b5']}}), 'wikiRookPawn'),
            move('m_rank', RANK2, 'Rc7 Kd6 Ra7 Kd5 Ka5 Kc5 Rc7+ Kd6 b6',
                 accept={1: 'only', 2: 'only', 3: 'only', 4: 'only',
                         5: 'win'}),
        ]},
        {'id': 'imperfect', 'steps': [
            think('t_imperfect', IMP, 2, marks=['f8']),
            talk('imperfect', IMP, arrows=['f2g3'], marks=['g8']),
            demo('d_imperfect', IMP_BLACK, 'f4 Ke4 f5 Rg4 f6 Rf4+',
                 goal='draw',
                 notes={2: {'arrows': ['d4e4']}, 6: {'arrows': ['g4f4']}}),
            move('m_imperfect', IMP, 'Kg3 Rg8+ Kf4',
                 accept={1: 'win', 2: 'only'}),
        ]},
        {'id': 'behind', 'steps': [
            think('t_behind', BEHIND, 2, marks=['h4', 'd8']),
            talk('behind', BEHIND, arrows=['d1d5'],
                 marks=['e5', 'f5', 'g5', 'h5']),
            demo('d_behind', BEHIND, 'Rd5 Kg3 Kd2 Kf3 Kc3',
                 notes={1: {'arrows': ['d1d5']}, 3: {'arrows': ['e1d2']},
                        5: {'arrows': ['c3c5']}}),
            ref(talk('uhlmannGulko', GULKO_GAME, marks=['e3', 'f5'],
                     side='black'), 'uhlmannGulko#114'),
            move('m_behind', BEHIND, 'Rd5 Kg3 Kd2',
                 accept={1: 'only', 2: 'win'}),
        ]},
        {'id': 'recap', 'steps': [
            talk('recap', KEY2, arrows=['a1c1']),
            move('m_recap', RECAP_COUNT, 'Re1 Kf6 Kb4',
                 accept={1: 'win', 2: 'win'}),
            ref(talk('exceptions', CHERON, arrows=['d1d8'],
                     marks=['a4', 'a5']), 'cheron'),
            ref(demo('d_cheron', CHERON, 'Rd4 Ke5 Kc3 Rc8+ Rc4 Rb8',
                     goal='draw',
                     notes={2: {'arrows': ['e5d4']}, 4: {'arrows': ['c8c3']},
                            6: {'arrows': ['b8b4']}}), 'cheron'),
            play('finish', FINISH, goal='win'),
        ]},
    ],
    'exercises': [
        exercise('e05', 1, '2r5/8/1R6/4k3/2P5/2K5/8/8 w - - 0 1',
                 'Kb4 Kd4 Rd6+', accept='win'),
        exercise('e09', 2, CAPA2, 'f4 Re8+ Kf3', accept='win',
                 origin='capablanca'),
        exercise('e11', 2, PEIN, 'Re7 Kf6 Re2', accept='win',
                 origin='peinWard'),
        exercise('e14', 2, IMP2, 'Kc4 Ke4 Re6+', accept='win'),
        exercise('e13', 3, GULKO, 'e7 Re8 Re6 Kg5 Ke4', accept='win',
                 origin='uhlmannGulko'),
    ],
    'passScore': 6,
    'keyPositions': [
        {'id': 'cut', 'fen': KEY1},
        {'id': 'count', 'fen': KEY2},
        {'id': 'five', 'fen': FIVE, 'ref': 'wikiRookPawn'},
        {'id': 'villa', 'fen': VILLA, 'ref': 'wikiRookPawn'},
        {'id': 'cheron', 'fen': CHERON, 'ref': 'wikiRookPawn'},
        {'id': 'capablanca', 'fen': CAPA, 'ref': 'wikiRookPawn'},
        {'id': 'gulko', 'fen': GULKO_GAME, 'ref': 'uhlmannGulko#114'},
    ],
    'practice': {'fen': '7r/2R5/6P1/8/8/8/K7/6k1 w - - 0 1', 'goal': 'win',
                 'positionId': 'rookPawn.rookPawnVsRook.0002'},
    'references': REFERENCES,
})
