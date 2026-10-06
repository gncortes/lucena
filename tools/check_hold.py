"""Confere uma linha (SAN) na tabela de finais do Lichess (com o cache do
`build_aula.py`): para cada lance de cada lado, se ele mantém o resultado da
posição e quantos lances mantêm. Serve para os finais em que o objetivo é
empatar e não há distância para comparar.

Uso:
    check_hold.py [--mirror] "<FEN>" "<lances em SAN>"

`--mirror` troca as cores e vira o tabuleiro antes (as fontes mostram o
defensor de pretas; nas aulas o aluno defende de brancas) e imprime o FEN e a
linha já espelhados."""
import importlib.util
import sys
from pathlib import Path

import chess

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    'build_aula', ROOT / '.claude/skills/aula-final/scripts/build_aula.py')
build_aula = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build_aula)
oracle = build_aula.Oracle(None)

RANK = {'win': 2, 'cursed-win': 1, 'draw': 1, 'blessed-loss': 1, 'loss': 0}


def mirror_line(fen, sans):
    """O FEN e a linha com as cores trocadas e o tabuleiro virado."""
    board = chess.Board(fen)
    mirrored = board.mirror()
    start = mirrored.fen()
    out = []
    for san in sans.split():
        move = board.parse_san(san.rstrip('!?'))
        twin = chess.Move(chess.square_mirror(move.from_square),
                          chess.square_mirror(move.to_square), move.promotion)
        out.append(mirrored.san(twin))
        board.push(move)
        mirrored.push(twin)
    return start, ' '.join(out)


def value(board):
    """O resultado para quem joga: 2 ganha, 1 empata, 0 perde."""
    if board.is_checkmate():
        return 0
    if board.is_stalemate() or board.is_insufficient_material():
        return 1
    return RANK.get(oracle.verdict(board), 1)


def keepers(board):
    """Os lances (SAN) que mantêm o resultado de quem joga (uma consulta só:
    a tabela devolve a categoria de todos os lances da posição)."""
    now = value(board)
    if chess.popcount(board.occupied) > 7:
        raise SystemExit('Mais de 7 peças: fora da tabela.')
    keep = []
    for uci, (wins, holds, _) in oracle.moves(board).items():
        if now == 0 or (now == 1 and holds) or (now == 2 and wins):
            keep.append(board.san(chess.Move.from_uci(uci)))
    return now, keep


def check(fen, sans=''):
    board = chess.Board(fen)
    names = {2: 'ganha', 1: 'empata', 0: 'perde'}
    print(fen, '|', 'brancas' if board.turn else 'pretas', names[value(board)])
    for san in sans.split():
        san = san.rstrip('!?')
        now, keep = keepers(board)
        clean = [k.rstrip('+#') for k in keep]
        mark = '' if san.rstrip('+#') in clean else ' ESTRAGA'
        total = board.legal_moves.count()
        only = f' só: {" ".join(keep)}' if len(keep) <= 4 else ''
        side = 'B' if board.turn else 'P'
        print(f'  {side} {san:7} {names[now]}, {len(keep)}/{total} mantêm'
              f'{only}{mark}')
        board.push_san(san)
    now, keep = keepers(board) if not board.is_game_over() else (value(board), [])
    print('  fim:', board.fen(), '|', names[now],
          '| mantêm:', ' '.join(keep) if len(keep) <= 12 else len(keep))


if __name__ == '__main__':
    args = sys.argv[1:]
    mirror = '--mirror' in args
    args = [a for a in args if a != '--mirror']
    fen, sans = args[0], (args[1] if len(args) > 1 else '')
    if mirror:
        fen, sans = mirror_line(fen, sans)
        print('espelhado:', fen, '|', sans)
    check(fen, sans)
