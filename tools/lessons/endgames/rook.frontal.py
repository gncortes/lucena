"""Gera `rook.frontal.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.frontal.py`
e depois o `build_aula.py rook.frontal`. O aluno defende de brancas: as
posições das fontes entram espelhadas (ver `tools/check_hold.py --mirror`).
As partidas (T61) vêm do chessgames.com, sem espelhar: o peão preto já desce."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play,  # noqa: E402
                         talk, think)

FRONT = '8/5r2/6k1/6p1/8/8/4K3/1R6 w - - 0 1'   # Emms: peão de cavalo
FRONTC = '8/5r2/8/6pk/8/8/4K3/1R6 w - - 0 1'   # o rei preto foi para h5
EMMS = '8/4r3/5k2/5p2/8/8/3K4/1R6 w - - 0 1'   # Emms: peão de bispo
EMMSB = '8/4r3/5k2/5p2/8/8/3K4/1R6 b - - 0 1'  # pretas jogam: Rg5! ganha
FIVE = '8/5r2/8/6k1/6p1/8/4K3/1R6 w - - 0 1'   # peão na quinta: só a troca
FIVEB = '8/5r2/8/6k1/6p1/8/4K3/1R6 b - - 0 1'
BPAWN = '8/8/1k1r4/1p6/8/4K3/8/2R5 w - - 0 1'  # prática do Lichess
FAR = '8/5r2/6k1/6p1/8/8/2K5/R7 w - - 0 1'     # rei longe: só Rd3
QUICK = '8/5r2/6k1/6p1/8/8/3K4/4R3 w - - 0 1'  # torre fora do lugar
CAPA = '8/3r1p2/4k3/8/2K5/8/8/7R w - - 0 1'    # Capablanca, torre pronta
SIDE = after('3r4/8/2k5/2p5/8/4K3/8/2R5 w - - 0 1', 'Rh1 c4')  # Yuri61
# T58: exercícios novos (posições conferidas na tabela).
STUDY = 'R7/8/8/6pk/5r2/4K3/8/8 w - - 0 1'       # emanuelrigelnuma: só Ta1
CAPA4 = after('8/5p2/4k3/8/8/2K5/7R/3r4 b - - 0 1', 'f5')  # Capablanca, f4
CENTER = '8/3r4/8/4pk2/8/2K5/8/4R3 w - - 0 1'    # peão central: só Tf1+
# GothamMath (Emms com o rei em d6), espelhada: depois de ...Te5, só Rd4!
GOTHAM = '8/8/8/4rp2/8/3K3k/8/5R2 w - - 0 1'
# Chéron 1923 (Wikipedia), espelhada: depois de 1...Td5, só Re4!
CHERON = after('3r4/8/1k6/1p6/8/4K3/8/1R6 b - - 0 1', 'Rd5')
# T61: lição refeita (posições próprias e de partidas, conferidas na tabela).
BACK = '8/3r4/8/2p5/1k6/4K3/8/2R5 w - - 0 1'     # própria: xeque ou volta
BACKX = after(BACK, 'Kf3 c4')                    # esperou: o peão passou
TAL = '8/8/6pk/1R6/4r3/2K5/8/8 w - - 2 73'       # Tal–Zaitsev, ply 144
TALX = '8/8/6pk/1R6/4r3/3K4/8/8 b - - 3 73'      # depois de 73.Rd3??
AREN = '8/8/2pr4/R7/8/1k6/4K3/8 w - - 3 69'      # Arencibia–Vladimirov, 136
ARENX = '8/8/2pr4/2R5/8/1k6/4K3/8 b - - 4 69'    # depois de 69.Tc5?
SIDE_D = '4r3/8/2k5/8/3p4/5K2/8/R7 w - - 0 1'    # própria: corte lateral
SIDE_DX = after(SIDE_D, 'Rd1 Kc5')               # torre na frente: perde
PW = '8/4r3/1k6/3R4/8/2p2K2/8/8 w - - 0 65'      # Pein–Ward, ply 128


def ref(step, reference):
    """O passo vem de uma partida ou estudo (`id` ou `id#ply`)."""
    step['ref'] = reference
    return step


REFERENCES = [
    {'id': 'rookPawn', 'kind': 'web',
     'title': 'Rook and pawn versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame'},
    {'id': 'practice2', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Intermediate Rook Endings',
     'url': 'https://lichess.org/study/heQDnvq7'},
    {'id': 'yuri61', 'kind': 'study', 'author': 'Yuri61',
     'title': 'Rook Endgames: Lucena & Philidor',
     'url': 'https://lichess.org/study/dDyC6HS6'},
    {'id': 'rigel', 'kind': 'study', 'author': 'emanuelrigelnuma',
     'title': 'finales de torre defensa frontal',
     'url': 'https://lichess.org/study/8qRywecv'},
    {'id': 'gotham', 'kind': 'study', 'author': 'GothamMath',
     'title': 'Frontal Defence',
     'url': 'https://lichess.org/study/tBm9cysU'},
    {'id': 'rfelgaer', 'kind': 'study', 'author': 'rfelgaer',
     'title': 'final torre frontal',
     'url': 'https://lichess.org/study/591qOqfS'},
    {'id': 'talZaitsev1968', 'kind': 'game', 'white': 'Mikhail Tal',
     'black': 'Igor Zaitsev', 'event': '6th Soviet Team Cup, Riga',
     'year': 1968,
     'url': 'https://lichess.org/analysis/pgn/e4_e5_Nf3_Nc6_Bb5_a6_Ba4_Nf6_O-O_Be7_Re1_b5_Bb3_O-O_a4_b4_d3_d6_Nbd2_Rb8_Nc4_Bg4_Be3_Nd7_h3_Bxf3_Qxf3_Bg5_Qg3_Bxe3_Nxe3_Na5_Bc4_Nxc4_Nxc4_Nc5_Qe3_Ne6_c3_f5_exf5_Rxf5_Qe4_Rf7_d4_Nf4_Qf3_bxc3_bxc3_exd4_cxd4_Qf6_Rad1_Rbf8_Rd2_Qg5_Rb2_Qg6_Rd1_Rf5_h4_Qe6_Ne3_Nd3_Nxf5_Nxb2_Ne7+_Qxe7_Qb3+_Kh8_Qxb2_Qxh4_Rc1_c5_dxc5_dxc5_a5_Qg5_Qc3_c4_Qxc4_Qxa5_Qc5_Qxc5_Rxc5_Kg8_f3_Ra8_Ra5_Kf7_Kf2_Ke6_Ke3_Kd6_Kd4_Kc6_Kc4_Kb6_Re5_Rc8+_Kb4_Rc6_Re7_a5+_Kb3_Rc7_Re5_Ra7_f4_Kc6_f5_Kd6_Rb5_Ke7_Rb6_a4+_Ka3_Kf7_g4_g6_Rc6_Kg7_fxg6_hxg6_Rc5_Kh6_Rd5_Ra6_Rb5_Ra8_Re5_Ra7_Rb5_Ra6_Re5_Ra8_Rb5_Rf8_Kxa4_Rf4+_Kb3_Rxg4_Kc3_Re4_Kd3_Re1#144'},
    {'id': 'talZaitsevSrc', 'kind': 'web',
     'title': 'Tal vs Zaitsev, Riga 1968 (chessgames.com)',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=1139866'},
    {'id': 'arencibiaVladimirov1991', 'kind': 'game',
     'white': 'Walter Arencibia', 'black': 'Evgeny Vladimirov',
     'event': 'Leon', 'year': 1991,
     'url': 'https://lichess.org/analysis/pgn/e4_e5_Nf3_Nf6_d4_Nxe4_Bd3_d5_Nxe5_Nd7_Nxd7_Bxd7_O-O_Qh4_c4_O-O-O_c5_g5_Nc3_Bg7_g3_Qh6_Nxe4_dxe4_Bxe4_f5_Bg2_f4_d5_Rhf8_Re1_Kb8_d6_cxd6_c6_bxc6_Re4_d5_Ra4_Ka8_Bd2_Bh3_Bh1_Qf6_gxf4_gxf4_Bxf4_Bh6_Bg3_Rd7_Bg2_Bxg2_Kxg2_d4_Qd3_Bf4_Rf1_h5_Qe4_Bxg3_hxg3_d3_Qe3_Qxb2_Rd1_Qc2_Rxd3_Rxf2+_Qxf2_Qxf2+_Kxf2_Rxd3_Rh4_Rd5_Rb4_Rb5_Rf4_Kb7_Ke3_Rd5_Rf8_Ra5_Rh8_Kb6_Kd4_Ra4+_Ke3_Ra3+_Kd4_Rxg3_Rxh5_Rg2_a3_Rg3_Rh1_Rxa3_Rb1+_Kc7_Kc4_Ra5_Rb2_a6_Rb1_Rb5_Ra1_Kb6_Ra4_a5_Kc3_Rb1_Rh4_Kb5_Rh8_Ka4_Ra8_Rc1+_Kb2_Rh1_Rb8_Rh2+_Kc3_Rh5_Kc4_Ka3_Rb3+_Ka2_Rb6_Rh1_Ra6_Rc1+_Kd3_Kb3_Rxa5_Rd1+_Ke2_Rd6_Rc5_Kb4_Rc1_c5_Rb1+_Ka3_Rc1_Rd5#136'},
    {'id': 'arencibiaVladimirovSrc', 'kind': 'web',
     'title': 'Arencibia vs Vladimirov, Leon 1991 (chessgames.com)',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=1348592'},
    {'id': 'peinWard1997', 'kind': 'game', 'white': 'Malcolm Pein',
     'black': 'Chris Ward', 'event': 'British Championship, Hove',
     'year': 1997,
     'url': 'https://lichess.org/analysis/pgn/d4_e6_e4_d5_Nc3_Bb4_e5_c5_a3_Bxc3+_bxc3_Qa5_Bd2_Qa4_Qg4_g6_Rc1_Nc6_Nf3_h6_Qf4_c4_h4_Bd7_Nh2_Rh7_Ng4_O-O-O_Be2_Qxa3_O-O_Qe7_g3_Rf8_Nf6_Nxf6_exf6_Qd8_Ra1_g5_Qd6_Rg8_h5_Qc7_Qxc7+_Kxc7_f4_a6_Kg2_Na7_g4_Nb5_Bf3_gxf4_Bxf4+_Kc8_Bd2_Bc6_Kg3_Kd7_Rfe1_Nd6_Bf4_Ra8_Re5_a5_g5_hxg5_Rxg5_a4_Bxd6_Kxd6_Rg7_Rh6_Rxf7_Rg8+_Rg7_Rf8_Rg6_Rxg6+_hxg6_Rxf6_Bh5_Rf8_Kh4_Ke7_Kg5_Rf5+_Kh6_Be8_Rh1_Bxg6_Bxg6_Rf3_Rb1_Kf6_Rxb7_Rh3+_Bh5_Kf5_Ra7_Ke4_Rxa4_Rxc3_Bg4_Kxd4_Bxe6_Ke5_Bf7_Rxc2_Ra5_Kf6_Rxd5_Kxf7_Kg5_Ke6_Ra5_Kd6_Kf4_Re2_Kf3_Re7_Kf2_Kc6_Kf3_Kb6_Rd5_c3_Rh5_c2_Rh1_Rc7_Rc1_Kb5_Ke2_Kb4_Kd2_Kb3_Rh1_Kb2#128'},
    {'id': 'peinWardSrc', 'kind': 'web',
     'title': 'Pein vs Ward, Hove 1997 (chessgames.com)',
     'url': 'https://www.chessgames.com/perl/chessgame?gid=2280252'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]

LESSON = {
    'id': 'rook.frontal',
    'module': 'rook',
    'skills': ['rook.frontal'],
    'parts': [
        {'id': 'front', 'steps': [
            ref(think('t_front', FRONTC, 2, ask='line'), 'rookPawn'),
            ref(talk('intro', FRONTC, arrows=['f7f1', 'b1h1'],
                     marks=['g4', 'g3', 'g2']), 'rookPawn'),
            ref(demo('d_checks', FRONTC, 'Rh1+ Kg4 Rg1+ Kh4 Rh1+ Kg3 Rg1+',
                     goal='draw', notes={1: {'arrows': ['h1h5']},
                                         3: {'arrows': ['g1g4']}}),
                'rookPawn'),
            ref(move('checks', FRONTC, 'Rh1+ Kg4 Rg1+ Kh3 Rxg5',
                     accept='only', goal='draw'), 'rookPawn'),
        ]},
        {'id': 'back', 'steps': [
            think('t_back', BACK, 2, ask='line'),
            talk('backWhy', BACK, arrows=['c1b1'], marks=['c5']),
            demo('d_back', BACK, 'Rb1+ Ka3 Rc1 Kb4 Rb1+ Ka5 Rc1',
                 goal='draw', notes={1: {'arrows': ['b1b4']},
                                     3: {'arrows': ['c1c5']},
                                     7: {'arrows': ['c1c5']}}),
            talk('backError', BACKX, marks=['c3', 'c2']),
            move('backPlay', BACK, 'Rb1+ Ka4 Rc1 Kb4 Rb1+ Kc3 Rc1+ Kb2 Rxc5',
                 accept={1: 'only', 2: 'only', 3: 'only', 4: 'only',
                         5: 'hold'}, goal='draw'),
        ]},
        {'id': 'first', 'steps': [
            ref(think('t_tal', TAL, 2), 'talZaitsev1968'),
            ref(talk('tal', TALX, arrows=['e4e1']), 'talZaitsev1968#145'),
            ref(demo('d_talRight', TAL, 'Rb1 g5 Kd3 Re5 Kd4 Re8 Rg1',
                     goal='draw', notes={1: {'arrows': ['b5b1']},
                                         5: {'arrows': ['d4e5']},
                                         7: {'marks': ['g4', 'g3', 'g2']}}),
                'talZaitsev1968'),
            ref(talk('knight', BPAWN, marks=['a5', 'a4', 'a3']), 'practice2'),
            ref(move('getFront', BPAWN, 'Rb1 Ka5 Ra1+ Kb4 Rb1+ Kc4 Rc1+',
                     accept='only', goal='draw'), 'practice2'),
        ]},
        {'id': 'king', 'steps': [
            ref(think('t_aren', AREN, 2), 'arencibiaVladimirov1991'),
            ref(talk('aren', ARENX, arrows=['b3b4'], marks=['d5']),
                'arencibiaVladimirov1991#137'),
            ref(demo('d_arenRight', AREN,
                     'Ke3 Kb4 Ra1 c5 Rb1+ Ka3 Rc1 Rd5 Ke4 Rd4+ Ke3',
                     goal='draw',
                     notes={1: {'arrows': ['e2e3']},
                            7: {'arrows': ['c1c5']},
                            9: {'arrows': ['e4d5']},
                            11: {'arrows': ['e3d4']}}),
                'arencibiaVladimirov1991'),
            talk('farKing', FAR, arrows=['f7d7']),
            move('far', FAR, 'Kd3 Kh5 Rh1+ Kg4 Rg1+ Kh4 Rh1+',
                 accept='only', goal='draw'),
        ]},
        {'id': 'trade', 'steps': [
            ref(think('t_emms', EMMS, 2), 'rookPawn'),
            ref(talk('emms', EMMSB, arrows=['f6g5', 'e7e5'], marks=['g5']),
                'rookPawn'),
            ref(demo('d_emms', EMMS, 'Re1 Rxe1 Kxe1 Ke5 Kf1 Ke4 Ke2',
                     goal='draw', notes={1: {'arrows': ['b1e1']},
                                         7: {'marks': ['e3']}}),
                'rookPawn'),
            talk('rule3', FIVEB, marks=['g3', 'g2']),
            move('five', FIVE, 'Rf1 Rxf1 Kxf1 Kh4 Kg2',
                 accept='only', goal='draw'),
        ]},
        {'id': 'side', 'steps': [
            think('t_side', SIDE_D, 2),
            talk('sideWhy', SIDE_D, arrows=['a1a5'],
                 marks=['b5', 'c5', 'd5']),
            talk('sideError', SIDE_DX, arrows=['c5c4', 'c4d3']),
            demo('d_side', SIDE_D, 'Ra5 d3 Kf2 d2 Ra1 Kc5 Rd1',
                 goal='draw', notes={1: {'arrows': ['a5d5']},
                                     3: {'marks': ['e1', 'e2']},
                                     5: {'marks': ['d1']}}),
            ref(talk('peinWard', PW, arrows=['d5h5'], marks=['f3', 'c3']),
                'peinWard1997'),
            move('sidePlay', SIDE_D, 'Ra5 Kd6 Kf2 d3 Ra3',
                 accept={1: 'hold', 2: 'hold', 3: 'hold'}, goal='draw'),
        ]},
        {'id': 'recap', 'steps': [
            think('t_quick', QUICK, 2),
            talk('recap', QUICK, arrows=['e1g1'], marks=['g4', 'g3', 'g2']),
            talk('when', FRONTC),
            move('quick', QUICK, 'Rg1 Kh5 Rh1+ Kg4 Rg1+ Kh3 Rxg5',
                 accept='only', goal='draw'),
            ref(play('finish', FRONT, goal='draw'), 'rookPawn'),
        ]},
    ],
    'exercises': [
        exercise('e11', 1, STUDY, 'Ra1 Kg4 Rg1+ Kh4 Rh1+', accept='only',
                 goal='draw', origin='rigel'),
        exercise('e12', 2, CAPA4, 'Rd2', accept='hold', goal='draw',
                 origin='rookPawn'),
        exercise('e08', 2, SIDE, 'Rh5 c3 Ke2 c2 Rh1',
                 accept={1: 'hold', 2: 'only', 3: 'only'}, goal='draw',
                 origin='yuri61'),
        exercise('e13', 2, CENTER, 'Rf1+ Kg4 Re1 Kf4 Rf1+ Ke4 Re1+ Kf3 Rxe5',
                 accept='only', goal='draw'),
        exercise('e14', 3, GOTHAM, 'Kd4 Re4+ Kd3 Kg4 Rg1+ Kf3 Rf1+',
                 accept='only', goal='draw', origin='gotham'),
        exercise('e15', 3, CHERON,
                 'Ke4 Kc6 Rc1+ Rc5 Rb1 Rc3 Kd4 Ra3 Rc1+ Kb6 Rc3',
                 accept={1: 'only', 2: 'hold', 3: 'only', 4: 'only',
                         5: 'only', 6: 'only'},
                 goal='draw', origin='rookPawn'),
    ],
    'passScore': 8,
    'keyPositions': [
        {'id': 'front', 'fen': FRONT, 'ref': 'rookPawn'},
        {'id': 'emms', 'fen': EMMS, 'ref': 'rookPawn'},
        {'id': 'bpawn', 'fen': BPAWN, 'ref': 'practice2'},
        {'id': 'tal', 'fen': TAL, 'ref': 'talZaitsev1968'},
        {'id': 'arencibia', 'fen': AREN, 'ref': 'arencibiaVladimirov1991'},
        {'id': 'side', 'fen': SIDE_D},
        {'id': 'capa', 'fen': CAPA, 'ref': 'rookPawn'},
    ],
    'practice': {'fen': FRONT, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
}

OUT = Path(__file__).with_suffix('.json')
OUT.write_text(json.dumps(LESSON, ensure_ascii=False, indent=2) + '\n')
print('Escrito', OUT)
