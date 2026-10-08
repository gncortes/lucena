"""Peças comuns dos scripts do teste de nível (T52): a tabela de finais do
Lichess (o mesmo `Oracle` e o mesmo cache do `build_aula.py` da skill
`aula-final`) e conferências de posição com o python-chess."""

import importlib.util
from pathlib import Path

import chess

ROOT = Path(__file__).resolve().parents[2]
BUILD_AULA = ROOT / '.claude' / 'skills' / 'aula-final' / 'scripts' / \
    'build_aula.py'

_spec = importlib.util.spec_from_file_location('build_aula', BUILD_AULA)
build_aula = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(build_aula)

# Status que um tabuleiro sem reis (as perguntas de regra, como na escola)
# pode ter sem ser inválido.
KINGLESS_OK = (chess.STATUS_NO_WHITE_KING | chess.STATUS_NO_BLACK_KING
               | chess.STATUS_OPPOSITE_CHECK | chess.STATUS_EMPTY)

# Categorias limpas da tabela (sem a regra dos 50 lances no meio).
CLEAN = {'win', 'draw', 'loss'}


class Tablebase:
    """A tabela de finais do Lichess, com o cache em `tools/.cache/`."""

    def __init__(self):
        self._oracle = build_aula.Oracle(None)

    def probe(self, board):
        if chess.popcount(board.occupied) > 7:
            raise ValueError('mais de 7 peças: fora da tabela')
        return self._oracle._probe(board)

    def result(self, board):
        """'whiteWins', 'draw', 'blackWins' ou None (categoria não limpa)."""
        category = self.probe(board)['category']
        if category not in CLEAN:
            return None
        if category == 'draw':
            return 'draw'
        mover_wins = category == 'win'
        white_wins = mover_wins == (board.turn == chess.WHITE)
        return 'whiteWins' if white_wins else 'blackWins'

    def good_moves(self, board, goal):
        """Os lances que mantêm o objetivo ('win' ou 'draw') de quem joga, com
        a distância do mate (meios-lances) quando a tabela dá."""
        out = {}
        for move in self.probe(board)['moves']:
            category = move['category']
            if goal == 'win' and category == 'loss':
                out[move['uci']] = (abs(move['dtm'])
                                    if move['dtm'] is not None else None)
            elif goal == 'draw' and category in ('loss', 'draw'):
                out[move['uci']] = None
        return out


def board_ok(board, kingless=False):
    if kingless:
        return board.status() & ~KINGLESS_OK == 0
    return board.is_valid()


def mating_moves(board):
    out = []
    for move in board.legal_moves:
        board.push(move)
        if board.is_checkmate():
            out.append(move.uci())
        board.pop()
    return sorted(out)


def quiet(board):
    """Nenhum lado pode capturar nada e ninguém está em xeque: a pergunta de
    veredito não vira uma pergunta de peça pendurada."""
    if board.is_check():
        return False
    if any(board.is_capture(move) for move in board.legal_moves):
        return False
    other = board.copy(stack=False)
    other.turn = not other.turn
    other.ep_square = None
    if not other.is_valid() or other.is_check():
        return False
    return not any(other.is_capture(move) for move in other.legal_moves)


def side(board):
    return 'white' if board.turn == chess.WHITE else 'black'
