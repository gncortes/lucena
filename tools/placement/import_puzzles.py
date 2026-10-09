#!/usr/bin/env python3
"""Importa puzzles do banco aberto do Lichess para o teste de nível (T52).

Fonte: https://database.lichess.org/#puzzles (licença CC0). O CSV vem
comprimido em zstd (~250 MB) e fica fora do repositório, em `tools/.cache/`:

    curl -L -o tools/.cache/puzzles/lichess_db_puzzle.csv.zst \\
        https://database.lichess.org/lichess_db_puzzle.csv.zst

O script lê o CSV em fluxo (`zstd -dc`), filtra pelos temas do mapa de
habilidades, por `RatingDeviation` baixo e por `NbPlays` e `Popularity` altos,
liga cada puzzle a um nó do mapa (pelos temas e pelo material) e sorteia, com
semente fixa, uma cota por nó e por faixa de rating (amostragem de
reservatório: o mesmo CSV dá sempre a mesma amostra).

Grava `tools/placement/lichess_items.json` só com o que o app usa: id, FEN já
com o primeiro lance aplicado (a posição que o jogador vê; o primeiro lance é
do adversário e vai em `lastMove`), a solução em UCI (lances do jogador e
respostas alternados), os lances aceitos em cada vez do jogador, o rating como
dificuldade e os temas. Todo lance é conferido com o python-chess.

Uso (só no desenvolvimento, com o python-chess):

    python3 tools/placement/import_puzzles.py [--csv caminho.csv.zst]
"""

import argparse
import csv
import io
import json
import random
import subprocess
import sys
from pathlib import Path

import chess

ROOT = Path(__file__).resolve().parents[2]
CSV = ROOT / 'tools' / '.cache' / 'puzzles' / 'lichess_db_puzzle.csv.zst'
OUT = ROOT / 'tools' / 'placement' / 'lichess_items.json'
SEED = 52

# Deslocamento entre o rating dos puzzles do Lichess e a escala do rating de
# finais do app (Maia). Provisório: 0 até a simulação da Parte 4.5 ajustar.
RATING_OFFSET = 0

# Filtros de qualidade (T52, 3.2). Os temas raros relaxam um pouco.
MAX_DEVIATION = 80
MIN_POPULARITY = 85
MIN_PLAYS = 500
RARE = {'enPassant', 'castling', 'underPromotion'}
RARE_MIN_POPULARITY = 75
RARE_MIN_PLAYS = 150
# No máximo três lances do jogador: o teste não é uma maratona de puzzle.
MAX_PLAYER_MOVES = 3

MAP_THEMES = {
    'mateIn1', 'mateIn2', 'backRankMate', 'smotheredMate', 'fork', 'pin',
    'skewer', 'discoveredAttack', 'deflection', 'attraction', 'zugzwang',
    'promotion', 'underPromotion', 'advancedPawn', 'endgame', 'pawnEndgame',
    'rookEndgame', 'queenEndgame', 'bishopEndgame', 'knightEndgame',
    'queenRookEndgame', 'enPassant', 'castling',
}

# Faixas de rating do sorteio: (início, fim) inclusive.
BANDS = [(400, 799), (800, 1199), (1200, 1599), (1600, 1999), (2000, 2399),
         (2400, 2899)]

# Cota por nó: quantos puzzles em cada faixa de BANDS.
QUOTAS = {
    'mate.inOne': [4, 4, 2, 0, 0, 0],
    'mate.patterns': [0, 2, 3, 2, 1, 0],
    'rules.enPassant': [0, 2, 2, 1, 0, 0],
    'rules.castling': [0, 0, 2, 2, 1, 0],
    'tactics.basic': [1, 2, 3, 3, 2, 1],
    'tactics.endgame': [0, 1, 2, 3, 3, 2],
    'pawns.race': [0, 0, 2, 2, 1, 1],
    'pawns.breakthrough': [0, 0, 1, 2, 2, 1],
    'rook.practical': [0, 0, 1, 2, 2, 2],
    'minor.knightVsPawn': [0, 1, 2, 2, 1, 0],
    'minor.knightEndings': [0, 0, 1, 2, 2, 1],
    'minor.bishopVsPawns': [0, 0, 1, 2, 2, 1],
    'minor.oppositeBishops': [0, 0, 1, 2, 2, 1],
    'minor.bishopVsKnight': [0, 0, 1, 2, 2, 1],
    'queen.pawnVsQueen': [0, 0, 0, 1, 2, 2],
    'rookMinor.vsMinor': [0, 0, 0, 1, 2, 2],
}

VALUES = {chess.PAWN: 1, chess.KNIGHT: 3, chess.BISHOP: 3, chess.ROOK: 5,
          chess.QUEEN: 9}


def pieces(board, color):
    """As peças de um lado, sem rei e sem peões, como lista de tipos."""
    return sorted(piece.piece_type for piece in board.piece_map().values()
                  if piece.color == color
                  and piece.piece_type not in (chess.KING, chess.PAWN))


def bishops_opposite(board):
    white = board.pieces(chess.BISHOP, chess.WHITE)
    black = board.pieces(chess.BISHOP, chess.BLACK)
    if len(white) != 1 or len(black) != 1:
        return None
    color = lambda squares: (chess.square_file(next(iter(squares)))
                             + chess.square_rank(next(iter(squares)))) % 2
    return color(white) != color(black)


def node_of(themes, board, first):
    """O nó do mapa de um puzzle, pelos temas e pelo material, ou None.

    `board` é a posição que o jogador vê; `first` é o primeiro lance dele."""
    if 'enPassant' in themes:
        return 'rules.enPassant'
    if 'castling' in themes:
        return 'rules.castling'
    if 'mateIn1' in themes:
        return 'mate.inOne'
    if 'mateIn2' in themes or {'backRankMate', 'smotheredMate'} & themes:
        return 'mate.patterns'
    if 'endgame' not in themes:
        if {'fork', 'pin', 'skewer', 'discoveredAttack'} & themes:
            return 'tactics.basic'
        return None
    me, other = board.turn, not board.turn
    mine, theirs = pieces(board, me), pieces(board, other)
    white, black = pieces(board, chess.WHITE), pieces(board, chess.BLACK)
    mover = board.piece_type_at(first.from_square)
    if 'pawnEndgame' in themes and not white and not black:
        if mover == chess.PAWN and 'sacrifice' in themes:
            return 'pawns.breakthrough'
        if mover == chess.PAWN and {'promotion', 'advancedPawn'} & themes:
            return 'pawns.race'
        return None
    if 'rookEndgame' in themes and white == black == [chess.ROOK]:
        return 'rook.practical'
    if 'knightEndgame' in themes:
        if white == black == [chess.KNIGHT]:
            return 'minor.knightEndings'
        if sorted([white, black]) == [[], [chess.KNIGHT]]:
            return 'minor.knightVsPawn'
    if 'bishopEndgame' in themes:
        if sorted([white, black]) == [[], [chess.BISHOP]]:
            return 'minor.bishopVsPawns'
        if white == black == [chess.BISHOP] and bishops_opposite(board):
            return 'minor.oppositeBishops'
    if sorted([white, black]) == [[chess.KNIGHT], [chess.BISHOP]]:
        return 'minor.bishopVsKnight'
    if 'queenEndgame' in themes:
        pawns = len(board.pieces(chess.PAWN, chess.WHITE)) + len(
            board.pieces(chess.PAWN, chess.BLACK))
        if white == black == [chess.QUEEN] and pawns <= 2:
            return 'queen.pawnVsQueen'
    if sorted([white, black]) in ([[chess.KNIGHT], [chess.ROOK]],
                                  [[chess.BISHOP], [chess.ROOK]]):
        return 'rookMinor.vsMinor'
    if {'deflection', 'attraction', 'underPromotion', 'promotion',
            'advancedPawn'} & themes and len(mine) + len(theirs) <= 4:
        return 'tactics.endgame'
    return None


def line_of(fen, moves):
    """Confere a solução e monta (posição vista, último lance, linha, aceitos).

    Todo lance do jogador é único, salvo o que dá mate: aí vale qualquer mate
    (regra dos puzzles do Lichess)."""
    board = chess.Board(fen)
    first = chess.Move.from_uci(moves[0])
    if first not in board.legal_moves:
        return None
    board.push(first)
    shown = board.fen()
    accept = []
    for index, uci in enumerate(moves[1:]):
        move = chess.Move.from_uci(uci)
        if move not in board.legal_moves:
            return None
        if index % 2 == 0:
            board.push(move)
            mates = board.is_checkmate()
            board.pop()
            if mates:
                accept.append(sorted(
                    m.uci() for m in board.legal_moves
                    if board.gives_check(m) and _mates(board, m)))
            else:
                accept.append([uci])
        board.push(move)
    return shown, moves[0], moves[1:], accept


def _mates(board, move):
    board.push(move)
    mate = board.is_checkmate()
    board.pop()
    return mate


def band_index(rating):
    for index, (low, high) in enumerate(BANDS):
        if low <= rating <= high:
            return index
    return None


def rows(path):
    process = subprocess.Popen(['zstd', '-dc', str(path)],
                               stdout=subprocess.PIPE)
    reader = csv.DictReader(io.TextIOWrapper(process.stdout, encoding='utf-8'))
    yield from reader
    process.wait()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--csv', type=Path, default=CSV)
    parser.add_argument('--limit', type=int, default=0,
                        help='para em N linhas (só para testar o script)')
    args = parser.parse_args()
    if not args.csv.exists():
        sys.exit(f'CSV não encontrado: {args.csv}. Baixe com o curl do '
                 'cabeçalho deste script.')

    rng = random.Random(SEED)
    # Reservatório por (nó, faixa): [vistos, amostra].
    pools = {}
    read = kept = 0
    for row in rows(args.csv):
        read += 1
        if args.limit and read > args.limit:
            break
        themes = set(row['Themes'].split())
        if not themes & MAP_THEMES:
            continue
        rare = bool(themes & RARE)
        if int(row['RatingDeviation']) > MAX_DEVIATION:
            continue
        if int(row['Popularity']) < (RARE_MIN_POPULARITY if rare
                                     else MIN_POPULARITY):
            continue
        if int(row['NbPlays']) < (RARE_MIN_PLAYS if rare else MIN_PLAYS):
            continue
        moves = row['Moves'].split()
        if len(moves) < 2 or (len(moves) - 1 + 1) // 2 > MAX_PLAYER_MOVES:
            continue
        board = chess.Board(row['FEN'])
        first = chess.Move.from_uci(moves[0])
        if first not in board.legal_moves:
            continue
        board.push(first)
        node = node_of(themes, board, chess.Move.from_uci(moves[1]))
        if node not in QUOTAS:
            continue
        rating = int(row['Rating'])
        band = band_index(rating)
        if band is None or QUOTAS[node][band] == 0:
            continue
        kept += 1
        size = QUOTAS[node][band]
        seen, sample = pools.setdefault((node, band), [0, []])
        seen += 1
        pools[(node, band)][0] = seen
        entry = (row['PuzzleId'], row['FEN'], moves, rating, sorted(themes))
        if len(sample) < size:
            sample.append(entry)
        else:
            slot = rng.randrange(seen)
            if slot < size:
                sample[slot] = entry
        if read % 500000 == 0:
            print(f'{read} linhas, {kept} candidatos', file=sys.stderr)

    items, missing = [], []
    for node, quota in QUOTAS.items():
        for band, size in enumerate(quota):
            sample = pools.get((node, band), [0, []])[1]
            if len(sample) < size:
                missing.append(f'{node} {BANDS[band]}: {len(sample)} de {size}')
            for puzzle_id, fen, moves, rating, themes in sorted(sample):
                checked = line_of(fen, moves)
                if checked is None:
                    sys.exit(f'{puzzle_id}: solução ilegal')
                shown, last, line, accept = checked
                side = 'white' if chess.Board(shown).turn else 'black'
                mate = 'mate' in themes
                items.append({
                    'id': f'lichess.{puzzle_id}',
                    'node': node,
                    'type': 'move',
                    'difficulty': rating + RATING_OFFSET,
                    'difficultySource': (f'lichess: rating {rating} + '
                                         f'{RATING_OFFSET} (deslocamento '
                                         'provisório, Parte 4.5)'),
                    'fen': shown,
                    'lastMove': last,
                    'prompt': ('placementCheckmate' if mate
                               else 'placementBestMove'),
                    'params': {'side': side},
                    'moves': line,
                    'accept': accept,
                    'source': 'lichess',
                    'themes': themes,
                })
    out = {
        'sources': ('Puzzles do banco aberto do Lichess '
                    '(https://database.lichess.org/#puzzles), licença CC0. '
                    f'Filtros: RatingDeviation <= {MAX_DEVIATION}, Popularity '
                    f'>= {MIN_POPULARITY}, NbPlays >= {MIN_PLAYS} (temas raros '
                    f'{sorted(RARE)}: {RARE_MIN_POPULARITY} e '
                    f'{RARE_MIN_PLAYS}); semente {SEED}.'),
        'items': items,
    }
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1) + '\n')
    print(f'{read} linhas lidas, {kept} candidatos, {len(items)} puzzles '
          f'gravados em {OUT.relative_to(ROOT)}')
    if missing:
        print('Faixas sem puzzles suficientes:', *missing, sep='\n- ')


if __name__ == '__main__':
    main()
