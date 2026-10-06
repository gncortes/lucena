"""Confere uma linha (SAN) nas tabelas locais: para cada lance, quanto ele
custa em relação ao melhor, até a captura (z) e até o mate (m), em meios-lances.
Uso: check_line.py "<FEN>" "<lances em SAN>" """
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import chess  # noqa: E402
import explore_tablebase as q  # noqa: E402


def cost(board, san):
    def val(v):
        return (0, int(v[1:])) if v[0] == 'W' else (1, 0) if v == 'D' else (2, -int(v[1:]))
    san = san.rstrip('+#')
    z = {s.rstrip('+#'): val(v) for s, u, v in q.ranked_z(board)}
    m = {s.rstrip('+#'): val(v) for s, u, v in q.ranked(board)}
    out = []
    for name, table in (('z', z), ('m', m)):
        best, mine = min(table.values()), table[san]
        if mine[0] != best[0]:
            out.append(f'{name}:{"EMPATA" if mine[0] == 1 else "PERDE"}')
        else:
            out.append(f'{name}+{abs(mine[1] - best[1])}')
    same = [s for s in m if m[s] == m[san]]
    return ' '.join(out) + (f' ={len(same)}' if len(same) > 1 else '')


def check(fen, sans):
    board = chess.Board(fen)
    parts = []
    for san in sans.split():
        parts.append(f'{san}({cost(board, san)})')
        board.push_san(san.rstrip('+#'))
    print(fen, '| dtm', q.dtm(chess.Board(fen)))
    print('  ' + ' '.join(parts))
    print('  fim:', board.fen(), 'dtm', q.dtm(board))


if __name__ == '__main__':
    check(sys.argv[1], sys.argv[2])
