"""Gera tools/lessons/endgames/pawns.outsidePasser.json (aula "O peão passado distante").

Lances em SAN aqui, UCI no JSON. Depois de mudar, rode este arquivo e o
build_aula.py:
    tools/.cache/venv/bin/python tools/lessons/endgames/pawns.outsidePasser.py
    tools/.cache/venv/bin/python .claude/skills/aula-final/scripts/build_aula.py pawns.outsidePasser
"""
import json
import pathlib

import chess

OUT = pathlib.Path(__file__).with_suffix('.json')


def F(s):
    return s + ' - - 0 1'


def uci(fen, sans):
    b = chess.Board(fen)
    out = []
    for s in sans.split():
        m = b.parse_san(s)
        out.append(m.uci())
        b.push(m)
    return out


def demo(id_, fen, goal, sans, notes=None, side=None):
    line = []
    for i, u in enumerate(uci(fen, sans)):
        e = {'uci': u}
        if notes and i in notes:
            e.update(notes[i])
        line.append(e)
    d = {'type': 'demo', 'id': id_, 'fen': fen, 'goal': goal, 'line': line}
    if side:
        d['side'] = side
    return d


def turns(fen, sans, accepts):
    us = uci(fen, sans)
    out = []
    for i in range(0, len(us), 2):
        t = {'teach': us[i], 'accept': accepts[i // 2]}
        if i + 1 < len(us):
            t['reply'] = us[i + 1]
        out.append(t)
    return out


def move(id_, fen, goal, sans, accepts, side=None):
    d = {'type': 'move', 'id': id_, 'fen': fen, 'goal': goal,
         'turns': turns(fen, sans, accepts)}
    if side:
        d['side'] = side
    return d


def ex(id_, stars, fen, sans, accepts, origin='own', goal='win'):
    return {'id': id_, 'stars': stars, 'fen': fen, 'goal': goal,
            'origin': origin, 'turns': turns(fen, sans, accepts)}


# Posições-base (todas conferidas na tabela do Lichess; ver o dossiê).
DECOY = F('8/8/8/3kp3/P5p1/3K2P1/8/8 w')        # própria: a5, Ke3... ganham
PF = F('8/8/8/6p1/3p1k2/P2K1P2/8/8 w')          # própria: só a4; Kxd4? perde
PF_MISTAKE = '8/8/8/6p1/3K1k2/P4P2/8/8 b - - 0 1'  # depois de 1.Kxd4?
ESC = F('8/2p1k3/6K1/1p3P2/1P6/8/8/8 w')        # própria: f6+, Kg5, Kg7; depois só f7
ESC_MISTAKE = '8/2p2k2/5P2/1p3K2/1P6/8/8/8 w - - 3 3'  # depois de 1.f6+ Kf8 2.Kf5? Kf7 (empate)
DOWN = F('8/p6k/1p6/5p2/1P6/6KP/8/8 w')         # fabian1999 ex. 2, cores trocadas: só b5
RACE = '8/p7/1p6/1P3p1k/5K2/8/8/8 w - - 0 5'    # DOWN depois de 1.b5 ... 4...Kxh5
DEF = F('8/8/5k2/3K4/2pP3p/2P5/8/8 w')          # própria: só Ke4 empata
DEF_MISTAKE = '8/8/5k2/8/2KP3p/2P5/8/8 b - - 0 1'  # depois de 1.Kxc4?
PROT = F('8/8/4k3/1pP4p/1P6/4K3/8/8 w')         # Fine & Benko (Wikipedia), sem os peões de a
PASS = F('8/8/5k2/2p4p/1P6/2PK4/8/8 w')         # própria: só b5; bxc5 empata
PASS_MISTAKE = '8/8/5k2/2P4p/8/2PK4/8/8 b - - 0 1'  # depois de 1.bxc5?
# Fischer–Larsen, Denver 1971 (PGN Mentor): plies 76, 80 e 91 da partida.
FL76 = '5k2/5p2/6p1/B6p/P7/3K2P1/1b5P/8 w - - 1 39'
FL80 = '8/4kp2/6p1/7p/P7/2K3P1/7P/8 w - - 1 41'
FL91 = '8/Pk6/4Kpp1/8/7p/6P1/7P/8 b - - 1 46'
FISCHER = F('8/5p2/3k2p1/8/P2K4/6P1/8/8 w')     # ply 82 da partida sem os peões de h
PRACTICE = F('8/4kp2/6p1/8/P7/4K1P1/8/8 w')     # própria

FL_URL = ('https://lichess.org/analysis/pgn/e4_c5_Nf3_d6_d4_cxd4_Nxd4_Nf6_Nc3_'
          'Nc6_Bc4_e6_Bb3_Be7_Be3_O-O_O-O_Bd7_f4_Qc8_f5_Nxd4_Bxd4_exf5_Qf3_'
          'fxe4_Nxe4_Nxe4_Qxe4_Be6_Rf3_Qc6_Re1_Qxe4_Rxe4_d5_Rg3_g6_Bxd5_Bd6_'
          'Rxe6_Bxg3_Re7_Bd6_Rxb7_Rac8_c4_a5_Ra7_Bc7_g3_Rfe8_Kf1_Re7_Bf6_Re3_'
          'Bc3_h5_Ra6_Be5_Bd2_Rd3_Ke2_Rd4_Bc3_Rcxc4_Bxc4_Rxc4_Kd3_Rc5_Rxa5_'
          'Rxa5_Bxa5_Bxb2_a4_Kf8_Bc3_Bxc3_Kxc3_Ke7_Kd4_Kd6_a5_f6_a6_Kc6_a7_'
          'Kb7_Kd5_h4_Ke6#80')

src = {
    'id': 'pawns.outsidePasser', 'module': 'pawns',
    'skills': ['pawns.outsidePasser'],
    'parts': [
        {'id': 'decoy', 'steps': [
            {'type': 'think', 'id': 't_decoy', 'fen': DECOY,
             'hints': 2, 'ask': 'plan', 'marks': ['a4', 'e5', 'g4']},
            {'type': 'talk', 'id': 'decoyWhy', 'fen': DECOY,
             'arrows': ['a4a8', 'd5b6', 'd3e4'], 'marks': ['e5', 'g4']},
            demo('d_decoy', DECOY, 'win', 'a5 Kc5 a6 Kb6 Ke4 Kxa6 Kxe5',
                 notes={0: {'arrows': ['a5a8']},
                        3: {'marks': ['b6', 'e5']},
                        4: {'arrows': ['e4e5'], 'marks': ['e5']},
                        6: {'arrows': ['e5f4', 'f4g4'], 'marks': ['g4']}}),
            move('decoyMove', DECOY, 'win', 'a5 Kc5 a6 Kb6 Ke4',
                 ['win', 'win', 'win']),
        ]},
        {'id': 'pawnFirst', 'steps': [
            {'type': 'think', 'id': 't_pawnFirst', 'fen': PF,
             'hints': 3, 'ask': 'plan', 'marks': ['d4', 'f3', 'a3']},
            {'type': 'talk', 'id': 'pawnFirstWhy', 'fen': PF,
             'arrows': ['a3a8', 'f4c6'], 'marks': ['d4']},
            {'type': 'talk', 'id': 'pawnFirstMistake', 'fen': PF_MISTAKE,
             'side': 'white', 'arrows': ['f4f3', 'g5g1'], 'marks': ['a3']},
            demo('d_pawnFirst', PF, 'win', 'a4 Ke5 a5 Kd5 a6 Kc6 Kxd4',
                 notes={0: {'marks': ['d4']},
                        5: {'marks': ['c6', 'g5']},
                        6: {'arrows': ['d4e5', 'e5f5'], 'marks': ['g5']}}),
            move('pawnFirstMove', PF, 'win', 'a4 Ke5 a5 Kd5 a6 Kc6 Kxd4',
                 ['only', 'win', 'win', 'win']),
        ]},
        {'id': 'escort', 'steps': [
            {'type': 'talk', 'id': 'escortWhy', 'fen': ESC,
             'arrows': ['g6h6', 'e7f6'], 'marks': ['f5', 'f6']},
            demo('d_escort', ESC, 'win', 'f6+ Kf8 f7 Ke7 Kg7',
                 notes={0: {'marks': ['f6']},
                        2: {'marks': ['e8', 'g8']},
                        4: {'arrows': ['g7f8'], 'marks': ['f8']}}),
            {'type': 'talk', 'id': 'escortMistake', 'fen': ESC_MISTAKE,
             'side': 'white', 'arrows': ['f8f7'], 'marks': ['f7']},
            move('escortMove', ESC, 'win', 'f6+ Kf8 f7 Ke7 Kg7',
                 [['f5f6', 'g6g5', 'g6g7'], 'only', 'only']),
        ]},
        {'id': 'down', 'steps': [
            {'type': 'think', 'id': 't_down', 'fen': DOWN, 'ref': 'studyFabian',
             'hints': 3, 'ask': 'plan', 'marks': ['b4', 'a7', 'b6']},
            {'type': 'talk', 'id': 'downWhy', 'fen': DOWN, 'ref': 'studyFabian',
             'arrows': ['b4b5', 'g3f4', 'h3h8'], 'marks': ['a7', 'b6', 'f5']},
            dict(demo('d_down', DOWN, 'win',
                      'b5 Kg7 Kf4 Kf6 h4 Kg6 h5+ Kxh5',
                      notes={0: {'marks': ['a7', 'b6']},
                             2: {'marks': ['f5']},
                             6: {'arrows': ['g6h5']}}),
                 ref='studyFabian'),
            dict(demo('d_race', RACE, 'win',
                      'Kxf5 Kh4 Ke6 Kg5 Kd6 Kf5 Kc6 Ke5 Kb7',
                      notes={0: {'marks': ['h5']},
                             2: {'arrows': ['e6d6', 'd6c6', 'c6b7']},
                             8: {'arrows': ['b7a7'], 'marks': ['b6']}},
                      side='white'),
                 ref='studyFabian'),
            dict(move('downMove', DOWN, 'win', 'b5 Kg7 Kf4 Kf6 h4',
                      ['only', 'win', 'win']), ref='studyFabian'),
        ]},
        {'id': 'defense', 'steps': [
            {'type': 'think', 'id': 't_defense', 'fen': DEF,
             'hints': 3, 'ask': 'plan', 'marks': ['c4', 'h4']},
            {'type': 'talk', 'id': 'defenseWhy', 'fen': DEF,
             'arrows': ['d5e4', 'e4f3', 'f3g2'], 'marks': ['h4', 'e1']},
            {'type': 'talk', 'id': 'defenseMistake', 'fen': DEF_MISTAKE,
             'side': 'white', 'arrows': ['h4h1', 'c4e2'], 'marks': ['h1']},
            demo('d_defense', DEF, 'draw', 'Ke4 h3 Kf3 h2 Kg2 Kf5 Kxh2',
                 notes={0: {'arrows': ['e4f3']},
                        2: {'arrows': ['f3g2']},
                        6: {'marks': ['c3', 'd4']}}),
            move('defenseMove', DEF, 'draw', 'Ke4 h3 Kf3 h2 Kg2',
                 ['only', 'only', 'only']),
        ]},
        {'id': 'protected', 'steps': [
            {'type': 'think', 'id': 't_prot', 'fen': PROT, 'ref': 'wikiPawn',
             'hints': 2, 'ask': 'plan', 'marks': ['c5', 'h5']},
            {'type': 'talk', 'id': 'protWhy', 'fen': PROT, 'ref': 'wikiPawn',
             'arrows': ['b4c5', 'e3h5'], 'marks': ['c5']},
            dict(demo('d_prot', PROT, 'win', 'Kf4 Kd5 Kg5 Kc4 Kxh5',
                      notes={0: {'arrows': ['f4g5']},
                             3: {'marks': ['b4']},
                             4: {'marks': ['h5']}}), ref='wikiPawn'),
            dict(move('protMove', PROT, 'win', 'Kf4 Kd5 Kg5 Kc4 Kxh5 Kxb4 c6',
                      ['win', 'win', 'win', 'only']), ref='wikiPawn'),
        ]},
        {'id': 'pass', 'steps': [
            {'type': 'think', 'id': 't_pass', 'fen': PASS,
             'hints': 3, 'ask': 'plan', 'marks': ['b4', 'c5', 'h5']},
            {'type': 'talk', 'id': 'passWhy', 'fen': PASS,
             'arrows': ['b4b5', 'c3c4'], 'marks': ['b5']},
            demo('d_passMistake', PASS_MISTAKE, 'draw',
                 'h4 c6 h3 c7 h2 c8=Q h1=Q',
                 notes={0: {'arrows': ['h4h1']},
                        1: {'arrows': ['c6c8']}}, side='white'),
            demo('d_pass', PASS, 'win', 'b5 Ke5 c4 Kd6 Ke4 Kc7 Kf5',
                 notes={0: {'marks': ['c5']},
                        2: {'marks': ['b5']},
                        6: {'arrows': ['f5g5', 'g5h5'], 'marks': ['h5']}}),
            move('passMove', PASS, 'win', 'b5 Ke5 c4', ['only', 'only']),
        ]},
        {'id': 'fischer', 'steps': [
            {'type': 'think', 'id': 't_fischer', 'fen': FL76,
             'ref': 'fischerLarsen#76', 'hints': 3, 'ask': 'plan',
             'marks': ['a4']},
            {'type': 'talk', 'id': 'fischerTrade', 'fen': FL80,
             'ref': 'fischerLarsen#80', 'arrows': ['a4a8', 'c3d4']},
            {'type': 'talk', 'id': 'fischerEnd', 'fen': FL91,
             'ref': 'fischerLarsen#91', 'side': 'white',
             'arrows': ['e6f6'], 'marks': ['f6', 'g6']},
            {'type': 'talk', 'id': 'recap', 'fen': FISCHER},
            {'type': 'play', 'id': 'finish', 'fen': FISCHER, 'goal': 'win'},
        ]},
    ],
    'exercises': [
        ex('e11', 1, F('8/8/3k3p/3P3P/2K5/8/8/8 w'), 'Kd4 Kc7 Ke5',
           ['only', 'win'], origin='studyParca'),
        ex('e12', 2, F('8/8/4pp2/8/P7/4Pk2/8/3K4 b'), 'Ke4 a5 Kd5',
           ['only', 'only'], goal='draw'),
        ex('e08', 2, F('8/1p3k2/8/p4KP1/P7/8/8/8 w'), 'g6+ Kg7 Kg5',
           ['only', 'only'], origin='studyChessforall'),
        ex('e13', 2, F('8/8/4k1p1/7p/P5P1/3K4/8/8 b'), 'h4 Ke2 g5',
           ['only', 'only']),
        ex('e14', 3, F('8/8/8/6kp/4p3/2P1K1P1/8/8 w'),
           'c4 Kf5 c5 Ke5 c6 Kd6 Kxe4 Kxc6 Kf5',
           ['only', 'only', 'only', 'only', 'win'],
           origin='studyChessforall321'),
        ex('e15', 3, F('8/4k3/6K1/p2p4/P5P1/8/8/8 w'),
           'Kf5 Kd6 g5 Ke7 Ke5 Kf7 Kxd5 Kg6 Kc4 Kxg5 Kb5',
           ['only', 'only', 'only', 'only', 'win', 'only'],
           origin='studySlimshaggy'),
    ],
    'passScore': 8,
    'keyPositions': [
        {'id': 'decoy', 'fen': DECOY},
        {'id': 'pawnFirst', 'fen': PF},
        {'id': 'down', 'fen': DOWN, 'ref': 'studyFabian'},
        {'id': 'defense', 'fen': DEF},
        {'id': 'protected', 'fen': PROT, 'ref': 'wikiPawn'},
        {'id': 'pass', 'fen': PASS},
        {'id': 'fischerLarsen', 'fen': FL80, 'ref': 'fischerLarsen#80'},
        {'id': 'fischerSmall', 'fen': FISCHER},
    ],
    'practice': {'fen': PRACTICE, 'goal': 'win', 'positionId': None},
    'references': [
        {'id': 'dvoretsky', 'kind': 'book', 'author': 'Mark Dvoretsky',
         'title': "Dvoretsky's Endgame Manual (6ª edição, revista por Karsten "
                  'Müller e Alex Fishbein)',
         'publisher': 'Russell Enterprises', 'year': 2025,
         'where': 'cap. 1, "The Outside Passed Pawn", p. 53 (sumário da '
                  'amostra da editora)'},
        {'id': 'delaVilla', 'kind': 'book', 'author': 'Jesús de la Villa',
         'title': '100 Endgames You Must Know (4ª edição)',
         'publisher': 'New In Chess', 'year': 2015,
         'where': 'cap. 12, Ending 83, "Rook\'s pawns and one distant passed '
                  'pawn", p. 181, e Ending 90, "Distant passed pawns", p. 200 '
                  '(sumário da amostra da editora)'},
        {'id': 'studyFabian', 'kind': 'study', 'author': 'fabian1999',
         'title': 'Outside Passed Pawns, cap. "Example 2"',
         'url': 'https://lichess.org/study/NkT0n2wa/IWQOkJeH'},
        {'id': 'studyChessforall', 'kind': 'study', 'author': 'chessforall123',
         'title': 'Distant passed pawn',
         'url': 'https://lichess.org/study/65lYAbia'},
        {'id': 'studySlimshaggy', 'kind': 'study', 'author': 'slimshaggy',
         'title': 'Ptotected and distant passed pawn',
         'url': 'https://lichess.org/study/LOeqttPi'},
        {'id': 'studyChessforall321', 'kind': 'study',
         'author': 'Chessforall321', 'title': 'A Remote Passed Pawn',
         'url': 'https://lichess.org/study/dPHfVWmv'},
        {'id': 'studyParca', 'kind': 'study', 'author': 'La-Parca-Maldita',
         'title': 'Final de peones: Peones de torre y un peón pasado '
                  'alejado.',
         'url': 'https://lichess.org/study/IsRBdWIl'},
        {'id': 'studyKhelifa', 'kind': 'study', 'author': 'Khelifa',
         'title': 'Distant passed pawn',
         'url': 'https://lichess.org/study/0wXZXqKR'},
        {'id': 'wikiPassed', 'kind': 'web',
         'title': 'Wikipedia: Passed pawn',
         'url': 'https://en.wikipedia.org/wiki/Passed_pawn'},
        {'id': 'wikiEndgame', 'kind': 'web',
         'title': 'Wikipedia: Chess endgame',
         'url': 'https://en.wikipedia.org/wiki/Chess_endgame'},
        {'id': 'wikiPawn', 'kind': 'web',
         'title': 'Wikipedia: Pawn (chess)',
         'url': 'https://en.wikipedia.org/wiki/Pawn_(chess)'},
        {'id': 'fischerLarsen', 'kind': 'game', 'white': 'Bobby Fischer',
         'black': 'Bent Larsen',
         'event': 'Match de Candidatos, semifinal, 5ª partida, Denver',
         'year': 1971, 'url': FL_URL},
        {'id': 'pgnMentorFischer', 'kind': 'web',
         'title': 'PGN Mentor: partidas de Bobby Fischer',
         'url': 'https://www.pgnmentor.com/players/Fischer.zip'},
        {'id': 'wcc72', 'kind': 'web',
         'title': 'Wikipedia: World Chess Championship 1972',
         'url': 'https://en.wikipedia.org/wiki/World_Chess_Championship_1972'},
        {'id': 'tablebase', 'kind': 'tablebase',
         'title': 'Lichess tablebase (Syzygy)',
         'url': 'https://tablebase.lichess.ovh'},
    ],
}

OUT.write_text(json.dumps(src, ensure_ascii=False, indent=2) + '\n')
print(f'gravado {OUT}')
