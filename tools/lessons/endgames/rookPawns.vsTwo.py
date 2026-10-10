"""Gera `rookPawns.vsTwo.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rookPawns.vsTwo.py`
e depois o `build_aula.py rookPawns.vsTwo`. Torre contra dois peões ligados:
sem reis (contar os passos; na quinta, atacar de lado), a torre atrás do peão
mais avançado, o rei da torre (contar as casas; o rei antes da captura), o
xeque que ganha tempo, o rei dos peões (abrigo, rei antes, ombro) e o
contorno. Dossiê, seção "Lição refeita": `docs/aulas/rookPawns.vsTwo.md`."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

SIXTH = 'K6k/8/8/8/8/5pp1/8/R7 w - - 0 1'        # peões na sexta: perde
FIFTH = 'K6k/8/8/8/5pp1/8/8/R7 w - - 0 1'        # na quinta: só Ta4
FIFTH_B = 'K6k/8/8/8/5pp1/8/8/R7 b - - 0 1'      # pretas jogando: empate
EUWE = '3r4/8/3PP3/3K4/8/8/8/7k b - - 0 1'        # estudo Anki, "Rule 2"
RECAP = 'k6K/8/8/8/1pp5/8/8/7R w - - 0 1'         # quinta, espelhada
BEHIND = '8/7k/R7/8/1p6/2p5/8/7K w - - 0 1'       # só 1.Tc6 ganha
BEHIND2 = '8/5k2/R7/8/1p6/2p5/8/7K w - - 0 1'     # o mesmo, rei em f7
KING = '7k/8/8/8/2K5/5pp1/8/R7 w - - 0 1'         # rei em c4: ganha
KING_C3 = '7k/8/8/8/8/2K2pp1/8/R7 w - - 0 1'      # rei em c3: ganha
KFIRST = '6R1/8/8/8/1p6/2k2K2/6p1/8 w - - 0 1'    # só 1.Re2 ganha
KFIRST2 = '6R1/8/8/8/1pk2K2/8/6p1/8 w - - 0 1'    # só 1.Re3 ganha
CHECKS = '8/8/6K1/8/6k1/5pp1/8/R7 w - - 0 1'      # só 1.Ta4+ empata
CHECKS2 = '8/8/2K5/8/2k5/2pp4/8/7R w - - 0 1'     # só 1.Th4+ empata
SACRIFICE = '8/8/8/8/4k3/2K5/3pp3/5R2 w - - 0 1'  # só 1.Tf4+!! empata
ESCORT = '1k6/8/7P/5KP1/8/8/8/7r w - - 0 1'       # Lichess Practice
CONNECT = '8/8/4P3/8/4KP2/8/7k/6r1 w - - 0 1'     # só 1.f5 ganha
# Shankland-Maghsoodloo, Praga 2022, lance 75 (capítulo do estudo de Anki).
SHANKLAND = '8/8/PK6/1P6/8/4k3/2r5/8 w - - 0 75'
BEFORE = '8/8/6K1/2R5/3p4/2pk4/8/8 b - - 0 1'     # só 1...Rc2 ganha
SHOULDER = 'R7/8/8/2K2kp1/5p2/8/8/8 b - - 0 1'    # só 1...Re4 empata
# Nabaty-Zelcic, Malinska 2014, lance 82 das pretas (capítulo de Anki).
NABATY = '8/3K1p2/8/6p1/2R2k2/8/8/8 b - - 0 82'
AROUND = '8/1K6/3k4/3p4/4p3/R7/8/8 w - - 0 1'     # só 1.Rb6 ganha
FINISH = '8/8/8/5k2/8/1pp5/8/4K1R1 w - - 0 1'     # desafio prático
RESOURCE = '8/8/2R5/4K1k1/8/pp6/8/8 w - - 0 1'    # Lichess Practice

ANKI = 'https://lichess.org/study/zLovcaQR/'
# Leko-Markowski, Polanica Zdroj 1998: PGN do pgnmentor.com (players/Leko.zip),
# conferido com python-chess; o ply 130 é o FEN do e14.
URL_LEKO = (
    'https://lichess.org/analysis/pgn/e4_c5_Nf3_g6_d4_Bg7_d5_Nf6_Nc3_d6_Be2_'
    'O-O_O-O_e6_Nd2_exd5_exd5_Nbd7_Nc4_Nb6_Ne3_Ne8_a4_f5_a5_Nd7_Nc4_Ne5_Bf4_'
    'Nxc4_Bxc4_g5_Bd2_h6_Qe2_Bd7_Rfe1_Nc7_Rab1_Re8_Qd3_Qf6_Nb5_Nxb5_Bxb5_'
    'Bxb5_Qxb5_Qf7_c4_Be5_Bc3_Bxc3_bxc3_f4_Re6_Rxe6_dxe6_Qxe6_Qxb7_Re8_h3_'
    'Qxc4_Qd7_Qe6_Qxa7_f3_gxf3_Qf7_Qxf7+_Kxf7_a6_Ra8_Ra1_Ke6_f4_gxf4_Kg2_Kd5_'
    'Kf3_Kc4_Ke4_Kxc3_Kd5_Kd2_Ra2+_Kd3_Ra3+_Ke2_f3_Kf2_a7_Kg3_Kc6_Kxh3_Kb7_'
    'Rf8_a8=Q_Rxa8_Rxa8_Kg3_Kc6_h5_Kxd6_Kxf3_Ke5_c4_Ra3+_Kg4_Ke4_h4_Ra8_Kg3_'
    'Rg8+_Kf2_Kxf4_h3_Ra8_Ke2_Ke4_Kf2_Kf4_Ke2_Rc8_Kd3_Kf3_h2_Rd8+_Kc2_Rh8_'
    'Kd3_Kf2_Kd2_Rxh2_c3_Kf1+_Kd1_Rh8_c2_Rd8+_Kc1_Ke2#130')

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
    {'id': 'mavens', 'kind': 'study', 'author': 'Mavens',
     'title': "Mavens's Study- Rook against Pawns",
     'url': 'https://lichess.org/study/ngG45jve'},
    {'id': 'prokesStudy', 'kind': 'study', 'author': 'beteferoce',
     'title': 'Finales de Estudio - Prokes',
     'url': 'https://lichess.org/study/tJuNkFhl'},
    {'id': 'retiStudy', 'kind': 'study', 'author': 'Tenakel',
     'title': 'Reti-Studies', 'url': 'https://lichess.org/study/pgf3RcVp'},
    {'id': 'parligras', 'kind': 'game', 'white': 'Parligras',
     'black': 'Gopal', 'event': 'Gibraltar', 'year': 2012,
     'url': 'https://lichess.org/study/I2GArVyI/QfVSrv2n'},
    {'id': 'leko', 'kind': 'game', 'white': 'Leko', 'black': 'Markowski',
     'event': 'Polanica Zdroj', 'year': 1998, 'url': URL_LEKO},
    {'id': 'nabaty', 'kind': 'game', 'white': 'Tamir Nabaty',
     'black': 'Robert Zelcic', 'event': 'Malinska', 'year': 2014,
     'url': ANKI + '90kaYakL'},
    {'id': 'gao', 'kind': 'game', 'white': 'Sam Shankland',
     'black': 'Rui Gao', 'event': 'Doha', 'year': 2014,
     'url': ANKI + 'BI51PQyC'},
    {'id': 'shankland', 'kind': 'game', 'white': 'Sam Shankland',
     'black': 'Parham Maghsoodloo', 'event': 'Praga', 'year': 2022,
     'url': ANKI + 'zdgxtSHT'},
    {'id': 'wikiEndgame', 'kind': 'web', 'title': 'Wikipedia: Chess endgame',
     'url': 'https://en.wikipedia.org/wiki/Chess_endgame'},
    {'id': 'wikiConnected', 'kind': 'web',
     'title': 'Wikipedia: Connected pawns',
     'url': 'https://en.wikipedia.org/wiki/Connected_pawns'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]


def ref(step, ref_id):
    """O passo com a referência de onde a posição vem."""
    step['ref'] = ref_id
    return step


PARTS = [
    {'id': 'count', 'steps': [
        think('t_fifth', FIFTH, 2, marks=['f4', 'g4'], ask='line'),
        talk('fifth', FIFTH, arrows=['a1a4'], marks=['f4', 'g4']),
        demo('d_fifth', FIFTH, 'Ra4 Kg7 Rxf4',
             notes={1: {'marks': ['f4', 'g4']}, 3: {'arrows': ['f4g4']}}),
        talk('sixthFifth', FIFTH_B, arrows=['f4f3', 'a1h1'],
             marks=['f3', 'g4']),
        move('recapMove', RECAP, 'Rh4 Kb7 Rxc4', accept='only'),
    ]},
    {'id': 'behind', 'steps': [
        think('t_behind', BEHIND, 2, marks=['c3']),
        talk('behind', BEHIND, arrows=['a6c6', 'c6c3'], marks=['c1']),
        demo('d_behind', BEHIND, 'Rc6 b3 Rxc3',
             notes={1: {'arrows': ['c6c3']}, 3: {'arrows': ['c3b3']}}),
        talk('behindCheck', BEHIND, arrows=['a6a7', 'h7g6', 'g6f5'],
             marks=['c3', 'b4']),
        move('behindMove', BEHIND2, 'Rc6 Ke7 Kg2',
             accept={1: 'only', 2: 'win'}),
    ]},
    {'id': 'king', 'steps': [
        think('t_king', KING, 2, marks=['f1', 'g1']),
        ref(talk('king', KING, arrows=['c4d3'], marks=['e2', 'e3']),
            'wikiEndgame'),
        demo('d_king', KING, 'Kd3 g2 Ke3',
             notes={1: {'arrows': ['d3e3']},
                    3: {'marks': ['f2', 'f3'], 'arrows': ['e3f3']}}),
        move('kingMove', KING_C3, 'Kd2 f2 Ke2 Kg7 Ra3', accept='win'),
    ]},
    {'id': 'kingFirst', 'steps': [
        think('t_kingFirst', KFIRST, 2, marks=['g2', 'b4']),
        talk('kingFirst', KFIRST, arrows=['f3e2', 'g8g2'], marks=['g1']),
        demo('d_kingFirst', KFIRST, 'Ke2 Kc2 Rxg2 b3 Ke1+',
             notes={1: {'marks': ['g1']}, 3: {'arrows': ['g2c2']},
                    5: {'arrows': ['g2c2']}}),
        talk('kingFirstGreedy', KFIRST, arrows=['g8g2', 'b4b3', 'c3c2'],
             marks=['b1']),
        move('kingFirstMove', KFIRST2, 'Ke3 Kc3 Ke2 Kc2 Rxg2 b3 Ke1+',
             accept={1: 'only', 2: 'win', 3: 'win', 4: 'win'}),
    ]},
    {'id': 'checks', 'steps': [
        think('t_checks', CHECKS, 2, marks=['f3', 'g3']),
        talk('checks', CHECKS, arrows=['a1a4'], marks=['h3']),
        demo('d_checks', CHECKS, 'Ra4+ Kh3 Rf4 f2 Kg5',
             goal='draw', notes={2: {'marks': ['g2']},
                                 3: {'arrows': ['f4f1']},
                                 5: {'arrows': ['g5g4']}}),
        move('checksMove', CHECKS2, 'Rh4+ Kb3 Rd4', accept='hold',
             goal='draw'),
        # Espelho do e17 (Prokeš) depois de 3...d2: só 1.Tf4+ empata.
        talk('sacrifice', SACRIFICE, arrows=['f1f4', 'e4f4', 'c3d2'],
             marks=['e1', 'f1']),
        move('sacrificeMove', SACRIFICE, 'Rf4+ Kxf4 Kxd2', accept='only',
             goal='draw'),
    ]},
    {'id': 'escort', 'steps': [
        think('t_escort', ESCORT, 2, marks=['h7'], ask='line'),
        talk('escort', ESCORT, arrows=['f5g6', 'g6h7'], marks=['h5']),
        demo('d_escort', ESCORT, 'Kg6 Kc7 Kh7 Kd7 g6',
             notes={1: {'arrows': ['g6h7']}, 3: {'marks': ['h8']},
                    5: {'arrows': ['g6g7']}}),
        ref(move('escortMove', SHANKLAND, 'Ka7 Rc8 b6',
                 accept={1: ['Ka7', 'Kb7'], 2: 'win'}), 'shankland#148'),
        move('connect', CONNECT, 'f5 Rf1 Ke5 Kg3 f6',
             accept={1: 'only', 2: 'win', 3: 'win'}),
        move('kingBefore', BEFORE, 'Kc2 Ra5 d3',
             accept={1: 'only', 2: 'win'}),
    ]},
    {'id': 'shoulder', 'steps': [
        think('t_shoulder', SHOULDER, 2, marks=['d4'], side='black'),
        talk('shoulder', SHOULDER, arrows=['f5e4'], marks=['d4', 'd3'],
             side='black'),
        demo('d_shoulder', SHOULDER, 'Ke4 Ra1 f3 Re1+ Kd3', goal='draw',
             side='black', notes={1: {'marks': ['d4', 'd3']},
                                  3: {'arrows': ['f3f2']}}),
        ref(talk('shoulderGame', NABATY, arrows=['f4f5'],
                 marks=['e6', 'e5'], side='black'), 'nabaty#163'),
        move('around', AROUND, 'Kb6 d4 Kb5 Kd5 Kb4',
             accept={1: 'only', 2: 'win', 3: 'win'}),
    ]},
    {'id': 'recap', 'steps': [
        talk('recap', FIFTH, arrows=['a1a4']),
        talk('rules', KING, arrows=['c4d3'], marks=['e2']),
        move('push', after(SIXTH, 'Ra3'), 'f2 Rf3 g2 Rxf2 g1=Q',
             accept='win'),
        play('finish', FINISH),
    ]},
]

EXERCISES = [
    # Parligras–Gopal, Gibraltar 2012 (no estudo de Audax6): o rei antes.
    exercise('e06', 1, '8/8/4K3/R7/1p6/pk6/8/8 b - - 0 1', 'Ka2',
             accept='only', origin='parligras'),
    # Mavens: o peão de trás anda e protege o da frente.
    exercise('e12', 1, '8/8/6P1/8/5K1P/3k4/8/4r3 w - - 0 1', 'h5',
             accept='only', origin='mavens'),
    # Audax6, cap. 3: xeque (empata) ou atacar por trás (ganha).
    exercise('e13', 2, 'K7/2k5/R7/8/5p2/6p1/8/8 w - - 0 1',
             'Rg6 Kd7 Rg4 g2 Rxg2', accept='only', origin='audax'),
    # Leko–Markowski, Polanica Zdroj 1998: peões separados, o rei toma.
    exercise('e14', 2, '7R/8/8/8/2p5/3k1K2/7p/8 w - - 0 1', 'Kf2 Kd2 Rxh2',
             accept={1: 'only', 2: 'win'}, origin='leko'),
    # Nabaty–Zelcic, Malinska 2014: o rei contorna os peões por trás.
    exercise('e16', 2, '8/4K3/8/4kpp1/2R5/8/8/8 w - - 0 1', 'Kf7 g4 Kg6',
             accept={1: 'only', 2: 'win'}, origin='nabaty'),
    # Shankland–Gao, Doha 2014: o rei dos peões barra o rei da torre.
    exercise('e15', 3, '8/R7/2K2kp1/7p/8/8/8/8 b - - 0 1',
             'Ke5 Kc5 h4 Kc4 Ke4 Rh7 g5', accept='hold', goal='draw',
             origin='gao'),
    # Prokeš, 1939: quatro lances únicos e a torre se entrega.
    exercise('e17', 3, '8/8/8/7K/2k5/3pp3/8/5R2 w - - 0 1',
             'Kg4 e2 Rc1+ Kd4 Kf3 d2 Rc4+ Kxc4 Kxe2', accept='hold',
             goal='draw', origin='prokesStudy'),
    # Réti: torre contra três peões; o rei toma o do meio, a torre muda de
    # coluna.
    exercise('e18', 3, '8/8/8/5k2/8/8/2p1p1p1/2R3K1 w - - 0 1',
             'Kf2 Ke4 Kxe2 Kd4 Rg1 Ke4 Re1',
             accept={1: 'only', 2: 'only', 3: 'win', 4: 'win'},
             origin='retiStudy'),
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
    'practice': {'fen': FINISH, 'goal': 'win', 'positionId': None},
    'references': REFERENCES,
}

if __name__ == '__main__':
    write(LESSON)
