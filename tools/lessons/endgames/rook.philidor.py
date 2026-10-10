"""Gera `rook.philidor.json` (a fonte da aula) a partir dos lances em SAN.
Rodar: `tools/.cache/venv/bin/python tools/lessons/endgames/rook.philidor.py`
e depois o `build_aula.py rook.philidor`. O aluno defende de brancas: as
posições das fontes entram espelhadas (ver `tools/check_hold.py --mirror`)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from make_source import (after, demo, exercise, move, play, talk,  # noqa: E402
                         think, write)

PH = '8/8/8/8/4pk2/R7/7r/4K3 b - - 0 1'     # Philidor, pretas jogam
PHW = '8/8/8/8/4pk2/R7/7r/4K3 w - - 0 1'    # a mesma, brancas jogam
REACH = '8/8/8/8/4pk2/8/r7/1R2K3 w - - 0 1'  # falta tomar a terceira fileira
E3 = '8/8/8/8/5k2/R3p3/7r/4K3 w - - 0 1'    # o peão pisou na terceira
# A linha da Wikipedia a partir de PH: 1...Tb2 2.Tc3 Ta2 3.Tb3 e3 4.Tb8!
E3W = after(PH, 'Rb2 Rc3 Ra2 Rb3 e3')
# T61: as posições das partes novas (conferidas na tabela).
SIDECHECK = '8/8/8/8/4pk2/R7/8/4K2r w - - 0 1'  # xeque lateral, peão de rei
SIDETRAP = '8/8/8/8/2pk4/R7/8/2K4r w - - 0 1'   # peão de bispo: Rd2? c3+
# NoseKnowsAll, "Exercise 1: Reaching the Philidor", cores trocadas
T_REACH = '8/R7/8/8/3kp3/8/7r/4K3 w - - 0 1'
T_KING = '8/8/8/8/3kp3/3r4/6K1/6R1 w - - 0 1'   # o rei primeiro: Rf2
T_EXPEL = '8/8/8/8/4p3/4k3/r7/4K2R w - - 0 1'   # o rei preto pisou: Th3+
EXPEL2 = '7R/8/8/8/4p3/5k2/r7/4K3 w - - 0 1'    # o mesmo, rei preto em f3
TRADE = after('8/8/8/8/3kp3/8/4K2R/6r1 w - - 0 1',
              'Rh3 Rg2+ Kd1 Ra2 Rg3 e3 Rg8 Ra5')
BISHOP = '6R1/8/8/8/2pk4/8/7r/3K4 w - - 0 1'
ADVANCED = '8/8/8/8/3kpR2/8/7r/4K3 w - - 0 1'
# Exercícios da régua T58 (2026-10-09).
AVOID = '8/8/8/8/3kp1R1/8/7r/4K3 w - - 0 1'      # tomar a terceira, sem pegar o peão
EXPEL = '8/8/8/8/2pk4/8/7r/3KR3 w - - 0 1'       # rei na frente, xeque na terceira
PH1777 = '8/8/8/5R2/3kp3/8/r7/4K3 w - - 0 1'     # Philidor 1777, cores trocadas
SIDE = '8/8/8/8/3pk3/R7/8/3K3r w - - 0 1'        # xeque lateral, peão de dama
KINGFIRST = '8/8/8/8/1kp5/1r6/4K3/4R3 w - - 0 1'  # rei primeiro, sem o espeto

REFERENCES = [
    {'id': 'wikipedia', 'kind': 'web', 'title': 'Philidor position (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Philidor_position'},
    {'id': 'rookPawn', 'kind': 'web',
     'title': 'Rook and pawn versus rook endgame (Wikipedia)',
     'url': 'https://en.wikipedia.org/wiki/Rook_and_pawn_versus_rook_endgame'},
    {'id': 'stripes', 'kind': 'web',
     'title': 'James Stripes: Kling and Horwitz Defense (Chess Skills)',
     'url': 'https://chessskill.blogspot.com/2024/04/kling-and-horwitz-defense.html'},
    {'id': 'practice', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Basic Rook Endgames',
     'url': 'https://lichess.org/study/pqUSUw8Y'},
    {'id': 'practice2', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Intermediate Rook Endings',
     'url': 'https://lichess.org/study/heQDnvq7'},
    {'id': 'profangel', 'kind': 'study', 'author': 'ProfAngel',
     'title': 'Rook Endings. The Philidor Position.',
     'url': 'https://lichess.org/study/a1ss97T0'},
    {'id': 'ehenkes', 'kind': 'study', 'author': 'ehenkes',
     'title': 'Ending: Rook Philidor',
     'url': 'https://lichess.org/study/imxK73yH'},
    {'id': 'yuri61', 'kind': 'study', 'author': 'Yuri61',
     'title': 'Rook Endgames: Lucena & Philidor',
     'url': 'https://lichess.org/study/dDyC6HS6'},
    {'id': 'noseknows', 'kind': 'study', 'author': 'NoseKnowsAll',
     'title': 'Rook Endgames You Must Know!',
     'url': 'https://lichess.org/study/bnboDhFM'},
    {'id': 'nunn', 'kind': 'book', 'author': 'John Nunn',
     'title': 'Secrets of Rook Endings', 'publisher': 'Gambit Publications',
     'year': 1999},
    {'id': 'practicePhilidor', 'kind': 'study', 'author': 'Lichess',
     'title': 'Lichess Practice: Basic Rook Endgames, "Philidor Position"',
     'url': 'https://lichess.org/study/pqUSUw8Y/CvqYotss'},
    {'id': 'noseknowsReach', 'kind': 'study', 'author': 'NoseKnowsAll',
     'title': 'Rook Endgames You Must Know!, "Exercise 1: Reaching the '
              'Philidor"',
     'url': 'https://lichess.org/study/bnboDhFM/7LSvVgLj'},
    {'id': 'yuri61Philidor', 'kind': 'study', 'author': 'Yuri61',
     'title': 'Rook Endgames: Lucena & Philidor, "Philidor Position - '
              'Correct Defense"',
     'url': 'https://lichess.org/study/dDyC6HS6/3pZ2cqM6'},
    {'id': 'audax6', 'kind': 'study', 'author': 'Audax6',
     'title': '14 The Philidor Position (Third Rank Defense)',
     'url': 'https://lichess.org/study/AvGk7RWH'},
    {'id': 'tablebase', 'kind': 'tablebase',
     'title': 'Lichess tablebase (Syzygy)',
     'url': 'https://tablebase.lichess.ovh'},
]


def ref(step, reference):
    """O passo com o link para a fonte da posição (T61)."""
    step['ref'] = reference
    return step


write({
    'id': 'rook.philidor',
    'module': 'rook',
    'skills': ['rook.philidor'],
    'parts': [
        # 1. A posição de Philidor: rei na casa de promoção, torre na
        # terceira, e esperar.
        {'id': 'third', 'steps': [
            ref(think('t_classic', PH, 2, side='white'), 'wikipedia'),
            ref(talk('intro', PH, arrows=['a3h3'],
                     marks=['e1', 'f3', 'g3', 'e3']), 'wikipedia'),
            ref(demo('d_wait', PH, 'Rb2 Rc3 Ra2 Rb3', goal='draw',
                     notes={1: {'arrows': ['h2b2']},
                            2: {'arrows': ['a3c3'], 'marks': ['e3', 'f3', 'g3']},
                            3: {'arrows': ['b2a2']},
                            4: {'arrows': ['c3b3']}}), 'wikipedia'),
            ref(move('take', REACH, 'Rb3 Rh2 Ra3', accept='hold',
                     goal='draw'), 'practicePhilidor'),
        ]},
        # 2. O xeque lateral: o rei fica na frente do peão.
        {'id': 'side', 'steps': [
            think('t_side', SIDECHECK, 1),
            talk('side', SIDECHECK, arrows=['e1e2'], marks=['e1', 'e2']),
            demo('d_sideTrap', after(SIDETRAP, 'Kd2'), 'c3+', goal='draw',
                 notes={1: {'arrows': ['c4c3'], 'marks': ['d3']}}),
            move('sideHold', SIDETRAP, 'Kc2 Rh2+ Kc1',
                 accept={1: 'hold', 2: 'hold'}, goal='draw'),
        ]},
        # 3. O peão pisou na terceira: torre para o fundo, xeques por trás.
        {'id': 'behind', 'steps': [
            ref(think('t_pawn', E3W, 2), 'wikipedia'),
            ref(talk('pawn', E3W, arrows=['b3b8', 'f4f3', 'a2a1'],
                     marks=['e3']), 'wikipedia'),
            ref(demo('d_behind', E3W, 'Rb8 Kf3 Rf8+ Ke4 Re8+ Kf4 Rf8+ Ke5 '
                     'Re8+', goal='draw',
                     notes={1: {'arrows': ['b3b8']},
                            2: {'arrows': ['a2a1']},
                            3: {'arrows': ['f8f3']},
                            4: {'marks': ['e3']},
                            5: {'arrows': ['e8e4']},
                            6: {'arrows': ['e8e3']},
                            7: {'arrows': ['f8f4']},
                            8: {'marks': ['e3']},
                            9: {'arrows': ['e8e5']}}), 'wikipedia'),
            ref(demo('d_passive', after(E3W, 'Rc3'), 'Kf3', goal='draw',
                     notes={1: {'arrows': ['a2a1'], 'marks': ['f3']}}),
                'wikipedia'),
            move('behind', E3, 'Ra8 Kf3 Rf8+ Ke4 Re8+ Kd3 Rd8+',
                 accept={1: 'hold', 2: 'only', 3: 'hold', 4: 'only'},
                 goal='draw'),
        ]},
        # 4. Chegar à terceira a tempo, sem o xeque cedo.
        {'id': 'reach', 'steps': [
            ref(think('t_reach', T_REACH, 2), 'noseknowsReach'),
            ref(demo('d_early', after(T_REACH, 'Rd7+'), 'Ke3', goal='draw',
                     notes={1: {'arrows': ['h2h1'], 'marks': ['e3']}}),
                'noseknowsReach'),
            ref(talk('reachWhy', T_REACH, arrows=['a7a3'],
                     marks=['e3', 'd3', 'f3']), 'noseknowsReach'),
            ref(move('reach', T_REACH, 'Ra3 e3 Ra8',
                     accept={1: ['Ra3'], 2: 'hold'}, goal='draw'),
                'noseknowsReach'),
        ]},
        # 5. Primeiro o rei, depois a torre, sem o espeto.
        {'id': 'kingFirst', 'steps': [
            think('t_king', T_KING, 2),
            demo('d_skewer', after(T_KING, 'Kf1'), 'Rd1+', goal='draw',
                 notes={1: {'arrows': ['d1g1'], 'marks': ['f1']}}),
            talk('kingWhy', T_KING, arrows=['g2f2', 'f2e1'],
                 marks=['e1']),
            move('kingFirst', T_KING, 'Kf2 Rd2+ Ke1 Rh2 Rg3',
                 accept={1: ['Kf2'], 2: ['Ke1'], 3: 'hold'}, goal='draw'),
        ]},
        # 6. O rei preto pisou na terceira: xeque na terceira que o expulsa.
        {'id': 'expel', 'steps': [
            think('t_expel', T_EXPEL, 1),
            demo('d_expel', T_EXPEL, 'Rh3+ Kd4 Rb3', goal='draw',
                 notes={1: {'arrows': ['h1h3']},
                        2: {'marks': ['d4']},
                        3: {'arrows': ['h3b3']}}),
            talk('expelWhy', T_EXPEL, arrows=['h1h3'], marks=['e3']),
            move('expel', EXPEL2, 'Rh3+ Kf4 Rb3',
                 accept={1: ['Rh3+'], 2: 'hold'}, goal='draw'),
        ]},
        # 7. A troca de torres: o rei recua reto.
        {'id': 'trade', 'steps': [
            think('t_trade', TRADE, 1),
            talk('trade', TRADE, arrows=['g8d8', 'a5d5']),
            demo('d_trade', TRADE, 'Rd8+ Rd5 Rxd5+ Kxd5', goal='draw',
                 notes={1: {'arrows': ['g8d8']},
                        2: {'arrows': ['a5d5']},
                        3: {'arrows': ['d8d5']},
                        4: {'marks': ['e1']}}),
            move('endgame', after(TRADE, 'Rd8+ Rd5 Rxd5+ Kxd5'),
                 'Ke2 Kd4 Ke1', accept={1: 'hold', 2: 'only'}, goal='draw'),
        ]},
        # 8. Qualquer peão, e o resumo.
        {'id': 'beyond', 'steps': [
            ref(think('t_bishop', BISHOP, 2, ask='line'),
                'yuri61Philidor'),
            ref(talk('bishop', BISHOP, arrows=['g8g3'], marks=['c1']),
                'yuri61Philidor'),
            ref(move('bishopMove', BISHOP, 'Rg3', accept='hold',
                     goal='draw'), 'yuri61Philidor'),
            talk('recap', PH, arrows=['a3h3', 'a3a8']),
            play('finish', REACH, goal='draw'),
        ]},
    ],
    'exercises': [
        exercise('e15', 1, AVOID, 'Rg3', accept='hold', goal='draw',
                 origin='practice'),
        exercise('e12', 2, SIDE, 'Kd2', accept='hold', goal='draw',
                 origin='audax6'),
        exercise('e11', 2, PH1777, 'Rb5 Ke3 Rb3+',
                 accept={1: 'hold', 2: 'hold'}, goal='draw',
                 origin='wikipedia'),
        exercise('e16', 3, EXPEL, 'Kc1 Kc3 Re3+',
                 accept={1: 'only', 2: 'only'}, goal='draw'),
        exercise('e14', 3, KINGFIRST, 'Kd2 Rb2+ Kc1 Rh2 Re3',
                 accept={1: 'only', 2: 'only', 3: 'hold'}, goal='draw'),
    ],
    'passScore': 7,
    'keyPositions': [
        {'id': 'classic', 'fen': PH, 'ref': 'wikipedia'},
        {'id': 'reach', 'fen': REACH, 'ref': 'practicePhilidor'},
        {'id': 'bishop', 'fen': BISHOP, 'ref': 'yuri61Philidor'},
        {'id': 'advanced', 'fen': ADVANCED, 'ref': 'practice2'},
    ],
    'practice': {'fen': REACH, 'goal': 'draw', 'positionId': None},
    'references': REFERENCES,
})
