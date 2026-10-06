"""Exploração de dama contra torre com as tabelas Gaviota (DTM em meios-lances)."""
import chess, chess.gaviota, functools, sys
ROOT = __import__('pathlib').Path(__file__).resolve().parents[1]
GTB = str(ROOT / 'tools' / '.cache' / 'gaviota')
tb = chess.gaviota.open_tablebase(GTB)

@functools.lru_cache(maxsize=2_000_000)
def _dtm(fen):
    b = chess.Board(fen)
    if b.is_checkmate():
        return -0.5  # quem joga está em mate
    if b.is_stalemate() or b.is_insufficient_material():
        return 0
    return tb.probe_dtm(b)

def dtm(b):
    """>0: quem joga dá mate em N meios-lances; <0: leva; 0: empate; -0.5: já está em mate."""
    return _dtm(b.fen())

def ranked(b):
    """Lances de quem joga, do melhor ao pior: (san, uci, valor para quem joga)."""
    out = []
    for m in b.legal_moves:
        san = b.san(m)
        b.push(m)
        d = dtm(b)
        b.pop()
        # valor para quem jogou: ganha se d<0 (rápido melhor), empata 0, perde d>0 (lento melhor)
        if d < 0:
            key = (0, -d)       # vitória: menor distância primeiro
            val = f'W{int(-d + 0.5) if d != -0.5 else 0}'
        elif d == 0:
            key = (1, 0); val = 'D'
        else:
            key = (2, -d); val = f'L{d}'
        out.append((key, san, m.uci(), val))
    out.sort()
    return [(s, u, v) for _, s, u, v in out]

def pv(b, n=200):
    b = b.copy()
    line = []
    while not b.is_game_over() and len(line) < n:
        r = ranked(b)
        s, u, v = r[0]
        line.append(s)
        b.push_uci(u)
    return line

def show(fen, top=6):
    b = chess.Board(fen)
    print(fen, 'dtm', dtm(b))
    print(b.unicode(empty_square='.', invert_color=True))
    for s, u, v in ranked(b)[:top]:
        print('  ', s, u, v)

if __name__ == '__main__':
    for fen in sys.argv[1:]:
        show(fen, 40)

import chess.syzygy
SYZ = str(ROOT / 'tools' / '.cache' / 'syzygy')
sz = chess.syzygy.open_tablebase(SYZ)

@functools.lru_cache(maxsize=2_000_000)
def _dtz(fen):
    b = chess.Board(fen)
    if b.is_checkmate():
        return (-2, 0)
    if b.is_stalemate() or b.is_insufficient_material():
        return (0, 0)
    return (sz.probe_wdl(b), sz.probe_dtz(b))

def dtz(b):
    """(wdl, dtz) para quem joga."""
    return _dtz(b.fen())

def ranked_z(b):
    """Lances por distância até a conversão (captura ou mate). valor: W<n>/D/L<n> em meios-lances
    contados a partir da posição atual (inclui o lance)."""
    out = []
    for m in b.legal_moves:
        san = b.san(m)
        cap = b.is_capture(m)
        b.push(m)
        w, z = dtz(b)
        mate = b.is_checkmate()
        b.pop()
        if w < 0 or mate:      # quem jogou ganha
            n = 1 if (cap or mate) else abs(z) + 1
            key = (0, n); val = f'W{n}'
        elif w == 0:
            key = (1, 0); val = 'D'
        else:
            n = 1 if cap else abs(z) + 1
            key = (2, -n); val = f'L{n}'
        out.append((key, san, m.uci(), val))
    out.sort()
    return [(s, u, v) for _, s, u, v in out]

def pv_z(b, n=200):
    """Linha em que as duas partes jogam pela distância de conversão; para na captura."""
    b = b.copy(); line = []
    while not b.is_game_over() and len(line) < n:
        s, u, v = ranked_z(b)[0]
        m = chess.Move.from_uci(u)
        cap = b.is_capture(m)
        line.append(s); b.push(m)
        if cap: break
    return line, b

def num(line, start_white=True):
    out = []; n = 1; w = start_white
    for s in line:
        if w: out.append(f'{n}.{s}')
        else:
            out.append(f'{n}...{s}' if not out else s); n += 1
        w = not w
    return ' '.join(out)
