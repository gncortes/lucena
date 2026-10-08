"""Ajuda a escrever a fonte de uma aula de final a partir de lances em notação
algébrica (SAN), para não errar FEN nem UCI à mão. Uso: ver
`tools/lessons/endgames/queen.vsRook.philidor.py`. Quem confere a aula continua
sendo o `build_aula.py`."""
import json
from pathlib import Path

import chess

SRC = Path(__file__).resolve().parent / 'endgames'


def after(fen, sans):
    """O FEN depois dos lances `sans` (contadores zerados)."""
    board = chess.Board(fen)
    for san in sans.split():
        board.push_san(san)
    return ' '.join(board.fen().split()[:4]) + ' 0 1'


def turns(fen, sans, accept='best'):
    """As vezes do aluno: `sans` alterna lance ensinado e resposta. `accept` é
    uma regra para todas as vezes ou um mapa {número da vez: regra ou lista de
    lances em SAN}."""
    board = chess.Board(fen)
    moves = sans.split()
    out = []
    for index in range(0, len(moves), 2):
        number = index // 2 + 1
        rule = accept.get(number, 'best') if isinstance(accept, dict) else accept
        if isinstance(rule, list):
            rule = [board.parse_san(san).uci() for san in rule]
        teach = board.push_san(moves[index])
        turn = {'teach': teach.uci(), 'accept': rule}
        if index + 1 < len(moves):
            turn['reply'] = board.push_san(moves[index + 1]).uci()
        out.append(turn)
    return out


def talk(id, fen, arrows=(), marks=(), side='white'):
    """Passo de fala, visto do lado `side` (o do aluno), jogue quem jogar."""
    step = {'type': 'talk', 'id': id, 'fen': fen}
    if fen.split()[1] != side[0]:
        step['side'] = side
    if arrows:
        step['arrows'] = list(arrows)
    if marks:
        step['marks'] = list(marks)
    return step


def think(id, fen, minutes, hints, arrows=(), marks=(), side='white',
          ask='plan'):
    """Passo em que o aluno estuda a posição sozinho por `minutes`; `hints`
    é quantas dicas a fala tem. Setas e casas aparecem com a primeira dica.
    `ask` diz o que o Viktor pede: `plan` (o melhor plano) ou `line` (a
    sequência que ganha, quando há uma forçada)."""
    step = {'type': 'think', 'id': id, 'fen': fen, 'minutes': minutes,
            'hints': hints, 'ask': ask}
    if fen.split()[1] != side[0]:
        step['side'] = side
    if arrows:
        step['arrows'] = list(arrows)
    if marks:
        step['marks'] = list(marks)
    return step


def demo(id, fen, sans, goal='win', side='white', notes=None):
    """Passo em que o app joga a linha `sans` (os dois lados) e o Viktor
    explica cada lance. `notes` é {número do lance (1, 2…): {'arrows': [...],
    'marks': [...]}}."""
    board = chess.Board(fen)
    line = []
    for number, san in enumerate(sans.split(), start=1):
        entry = {'uci': board.push_san(san).uci()}
        entry.update((notes or {}).get(number, {}))
        line.append(entry)
    step = {'type': 'demo', 'id': id, 'fen': fen, 'goal': goal}
    if fen.split()[1] != side[0]:
        step['side'] = side
    step['line'] = line
    return step


def move(id, fen, sans, accept='best', goal='win'):
    return {'type': 'move', 'id': id, 'fen': fen, 'goal': goal,
            'turns': turns(fen, sans, accept)}


def play(id, fen, goal='win'):
    return {'type': 'play', 'id': id, 'fen': fen, 'goal': goal}


def exercise(id, stars, fen, sans, accept='best', goal='win', origin='own'):
    return {'id': id, 'stars': stars, 'fen': fen, 'goal': goal,
            'origin': origin, 'turns': turns(fen, sans, accept)}


def write(lesson):
    path = SRC / f"{lesson['id']}.json"
    path.write_text(json.dumps(lesson, ensure_ascii=False, indent=2) + '\n')
    print('Escrito', path)
