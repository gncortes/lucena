#!/usr/bin/env python3
"""Gera os itens próprios do teste de nível: `tools/placement/items.json`.

Nenhuma posição sai da memória de quem escreve: cada item parte de uma
posição de aula (escola em `assets/lessons/course.json` ou aulas de finais em
`tools/lessons/endgames/`), mexida por script (peça movida uma casa, tabuleiro
espelhado, cores trocadas), ou de um sorteio com semente fixa num arranjo de
material descrito aqui. A resposta de cada item é calculada:

- `squares`: as casas vêm do gerador de lances do python-chess;
- regras (`choice` de xeque, mate, afogamento, roque, en passant, material
  insuficiente): do python-chess;
- finais (veredito e lances certos): da tabela de finais do Lichess, pelo
  mesmo `Oracle` (e cache) do `build_aula.py`;
- valor das peças: do Stockfish (o lance aceito é o único que ganha material
  com folga).

A dificuldade dos itens próprios é estimada à mão, com o critério gravado em
`difficultySource` (a curva do Maia da Parte 0.7 está pendente). Depois de
gerar, rode `build_items.py`, que confere tudo de novo e monta o asset.

Uso (só no desenvolvimento):

    tools/.cache/venv/bin/python tools/placement/make_own_items.py
"""

import json
import random
import shutil
import sys
from pathlib import Path

import chess
import chess.engine

sys.path.insert(0, str(Path(__file__).resolve().parent))
from placement_chess import (ROOT, Tablebase, board_ok, mating_moves,  # noqa
                             quiet, side)

OUT = ROOT / 'tools' / 'placement' / 'items.json'
COURSE = ROOT / 'assets' / 'lessons' / 'course.json'
ENDGAMES = ROOT / 'tools' / 'lessons' / 'endgames'
SEED = 52

PIECE_NAMES = {chess.ROOK: 'rook', chess.BISHOP: 'bishop',
               chess.QUEEN: 'queen', chess.KING: 'king',
               chess.KNIGHT: 'knight', chess.PAWN: 'pawn'}

TB = Tablebase()
ITEMS = []


def sq(name):
    return chess.parse_square(name)


def squares(files='abcdefgh', ranks='12345678'):
    return [sq(f + r) for f in files for r in ranks]


def add(node, kind, fen, difficulty, why, derived, **fields):
    number = sum(1 for item in ITEMS if item['node'] == node) + 1
    item = {'id': f'own.{node}.{number}', 'node': node, 'type': kind,
            'difficulty': difficulty, 'difficultySource': f'hand: {why}',
            'fen': fen}
    item.update(fields)
    item['source'] = 'own'
    item['derivedFrom'] = derived
    ITEMS.append(item)


# --------------------------------------------------------------------------
# Posições das aulas

def school_fens():
    course = json.loads(COURSE.read_text())
    out = {}
    for module in course['modules']:
        for lesson in module['lessons']:
            for step in lesson['steps']:
                if step.get('fen'):
                    out[f"{lesson['id']}.{step['id']}"] = step['fen']
    return out


def endgame_positions(lesson_id):
    """[(origem, fen, objetivo ou None)] das posições-base, exercícios e
    treino de uma aula de final."""
    source = json.loads((ENDGAMES / f'{lesson_id}.json').read_text())
    out = []
    for key in source.get('keyPositions', []):
        out.append((f"{lesson_id} key {key['id']}", key['fen'], None))
    for exercise in source['exercises']:
        out.append((f"{lesson_id} ex {exercise['id']}", exercise['fen'],
                    exercise.get('goal', 'win')))
    practice = source.get('practice') or {}
    if practice.get('fen'):
        out.append((f'{lesson_id} practice', practice['fen'],
                    practice.get('goal', 'win')))
    return out


def variants(board):
    """A posição, espelhada, com as cores trocadas e com uma peça movida uma
    casa (todas válidas e diferentes)."""
    out = [('original', board)]
    flipped = board.transform(chess.flip_horizontal)
    out.append(('espelhada', flipped))
    out.append(('cores trocadas', board.mirror()))
    out.append(('cores trocadas e espelhada', flipped.mirror()))
    for square, piece in board.piece_map().items():
        for target in chess.SquareSet(chess.BB_KING_ATTACKS[square]):
            if board.piece_at(target):
                continue
            if piece.piece_type == chess.PAWN and chess.square_rank(
                    target) in (0, 7):
                continue
            moved = board.copy(stack=False)
            moved.remove_piece_at(square)
            moved.set_piece_at(target, piece)
            out.append((f'{piece.symbol()} {chess.square_name(square)}→'
                        f'{chess.square_name(target)}', moved))
    seen, unique = set(), []
    for label, candidate in out:
        key = candidate.board_fen() + side(candidate)
        if key in seen or not candidate.is_valid():
            continue
        seen.add(key)
        unique.append((label, candidate))
    return unique


def pick(rng, pool, count, key=None):
    """`count` itens do pool, com semente, equilibrando pela chave."""
    pool = list(pool)
    rng.shuffle(pool)
    if key is None:
        return pool[:count]
    groups = {}
    for entry in pool:
        groups.setdefault(key(entry), []).append(entry)
    out = []
    while len(out) < count and any(groups.values()):
        for name in sorted(groups):
            if groups[name] and len(out) < count:
                out.append(groups[name].pop())
    return out


# --------------------------------------------------------------------------
# 2.1 Regras

def piece_squares(board, square):
    targets = set()
    for move in board.legal_moves:
        if move.from_square == square:
            targets.add(chess.square_name(move.to_square))
    return sorted(targets)


SQUARES_ITEMS = {
    # peça: [(casa, outras peças, dificuldade, critério)]
    'rules.rook': ('R', 'pieces.rook', [
        ('a1', '', 400, 'peça sozinha no canto'),
        ('d4', '', 400, 'peça sozinha no centro'),
        ('c1', 'P:c6', 500, 'peça sozinha + 1 bloqueio próprio'),
        ('e4', 'p:e7 P:b4', 550, '+ captura e bloqueio'),
        ('h8', 'n:h3 B:e8', 550, '+ captura e bloqueio'),
        ('b2', 'p:b6 b:f2 N:b1', 600, '+ duas capturas e bloqueio'),
        ('g5', 'P:g7 P:c5 p:g2', 600, '+ captura e dois bloqueios'),
    ]),
    'rules.bishop': ('B', 'pieces.bishop', [
        ('c1', '', 400, 'peça sozinha na borda'),
        ('d4', '', 450, 'peça sozinha no centro (quatro diagonais)'),
        ('f1', 'P:e2', 500, '+ 1 bloqueio próprio'),
        ('e5', 'r:b8 P:g3', 550, '+ captura e bloqueio'),
        ('b3', 'n:d5 P:a2', 550, '+ captura e bloqueio'),
        ('g7', 'p:e5 N:h8 r:f8', 600, '+ duas capturas e bloqueio'),
        ('c4', 'P:d5 p:a6 P:b3', 600, '+ captura e dois bloqueios'),
    ]),
    'rules.queen': ('Q', 'pieces.queen', [
        ('d1', '', 450, 'peça sozinha na borda'),
        ('d4', '', 450, 'peça sozinha no centro'),
        ('a8', 'P:a5', 500, '+ 1 bloqueio próprio'),
        ('e3', 'p:e7 B:c1', 550, '+ captura e bloqueio'),
        ('f5', 'b:c8 P:f2 n:h5', 600, '+ duas capturas e bloqueio'),
        ('b6', 'P:b4 P:d6 p:e3', 650, '+ captura e dois bloqueios'),
        ('g2', 'p:g6 P:e4 b:b7 N:h1', 650, '+ duas capturas e dois bloqueios'),
    ]),
    'rules.king': ('K', 'pieces.king', [
        ('e1', '', 400, 'peça sozinha na borda'),
        ('d4', '', 400, 'peça sozinha no centro'),
        ('h1', 'P:g2', 450, '+ 1 bloqueio próprio'),
        ('e5', 'p:d6', 550, '+ captura (peão sem defesa)'),
        ('c3', 'r:a4', 700, 'casas atacadas pela torre preta (+250)'),
        ('f6', 'b:d4 P:e6', 700, 'casas atacadas pelo bispo preto (+250)'),
        ('b2', 'n:c5 p:a3', 750, 'casas atacadas pelo cavalo e captura'),
    ]),
    'rules.knight': ('N', 'pieces.knight', [
        ('b1', '', 450, 'peça sozinha na borda (cavalo: +50)'),
        ('d4', '', 500, 'peça sozinha no centro, oito casas'),
        ('g1', 'P:e2', 500, '+ 1 bloqueio próprio'),
        ('h8', '', 500, 'peça sozinha no canto, duas casas'),
        ('e5', 'P:d3 p:f7', 600, '+ captura e bloqueio'),
        ('d2', 'P:c4 P:d3 P:e2 p:f3', 650, 'cercado (o cavalo pula)'),
        ('c6', 'p:a7 p:e7 P:b4', 650, '+ duas capturas e bloqueio'),
    ]),
    'rules.pawn': ('P', 'pieces.pawn', [
        ('e2', '', 400, 'peão na casa inicial: um ou dois passos'),
        ('e4', 'p:d5', 500, '+ captura na diagonal'),
        ('e2', 'p:e4', 550, 'bloqueado na segunda casa'),
        ('d2', 'p:c3 p:e3 N:d3', 650, 'bloqueado, só captura'),
        ('e7', 'r:f8', 600, 'promoção, com captura'),
        ('a2', 'p:b3', 550, 'peão da borda: captura de um lado só'),
        ('d4', 'p:d5 n:c5 B:e5', 650, 'bloqueado; captura de um lado'),
    ]),
}


def kingless(placements, turn=chess.WHITE):
    board = chess.Board(None)
    for entry in placements:
        symbol, name = entry.split(':')
        board.set_piece_at(sq(name), chess.Piece.from_symbol(symbol))
    board.turn = turn
    return board


def rules_squares():
    for node, (symbol, lesson, rows) in SQUARES_ITEMS.items():
        for square, extras, difficulty, why in rows:
            board = kingless([f'{symbol}:{square}'] + extras.split())
            assert board_ok(board, kingless=True), (node, square)
            targets = piece_squares(board, sq(square))
            assert targets, (node, square)
            piece = PIECE_NAMES[chess.Piece.from_symbol(symbol).piece_type]
            add(node, 'squares', board.fen(), difficulty, why,
                f'{lesson}: a peça da aula em {square}',
                prompt='placementSquares', params={'piece': piece},
                squares=targets)
    # Peão preto: anda para baixo.
    board = kingless(['p:d7', 'P:c6', 'N:e6'], turn=chess.BLACK)
    add('rules.pawn', 'squares', board.fen(), 650,
        'peão preto (anda para baixo) com captura', 'pieces.pawn: peão preto',
        prompt='placementSquares', params={'piece': 'pawn'},
        squares=piece_squares(board, sq('d7')))


CAPTURES = [
    # (peça, casa, outras, dificuldade, critério)
    ('Q', 'd4', 'r:d7 n:g7 p:b2 b:a4 P:f4 p:h4', 600,
     'dama: quatro alvos, um escondido atrás da própria peça'),
    ('R', 'c3', 'p:c7 n:h3 b:a3 P:e3 q:c1', 550, 'torre: dois alvos livres'),
    ('B', 'e4', 'r:b7 p:h7 n:g2 P:c2 q:f5', 600,
     'bispo: alvos nas quatro diagonais'),
    ('N', 'e5', 'p:d7 r:f3 q:e7 b:c4 P:g6', 600,
     'cavalo: alvos em L e um alvo que não é casa de cavalo'),
    ('P', 'e4', 'p:d5 n:f5 r:e5', 550, 'peão: só captura na diagonal'),
    ('K', 'e4', 'p:d5 p:c6 n:f4 b:e3 P:d3', 750,
     'rei: não pode capturar peça defendida'),
    ('R', 'f6', 'n:f8 r:b6 p:a6 P:f3 b:h6', 600,
     'torre: o alvo atrás do primeiro não vale'),
]


def rules_capture():
    for symbol, square, extras, difficulty, why in CAPTURES:
        board = kingless([f'{symbol}:{square}'] + extras.split())
        assert board_ok(board, kingless=True), square
        targets = sorted({chess.square_name(m.to_square)
                          for m in board.legal_moves
                          if m.from_square == sq(square)
                          and board.is_capture(m)})
        assert targets, square
        piece = PIECE_NAMES[chess.Piece.from_symbol(symbol).piece_type]
        add('rules.capture', 'squares', board.fen(), difficulty, why,
            f'pieces.{piece}: a peça da aula em {square}, com alvos',
            prompt='placementCaptureSquares', params={'piece': piece},
            squares=targets)


# Posições de xeque, mate e afogamento: as das aulas, com a peça de ataque
# andando por todas as casas.
MATE_SEEDS = [
    ('pieces.check.mate', 'R5k1/5ppp/8/8/8/8/8/6K1 b - - 0 1', 'R'),
    ('pieces.stalemate.stalemate', 'k7/8/1Q6/8/8/8/8/7K b - - 0 1', 'Q'),
    ('mates.queen.alone', '3k4/3Q4/3K4/8/8/8/8/8 b - - 0 1', 'Q'),
    ('basics.queenMate key cornerStalemate', 'k7/2Q5/8/8/8/8/8/7K b - - 0 1',
     'Q'),
    ('basics.rookMate key stalemate', 'k7/1R6/2K5/8/8/8/8/8 b - - 0 1', 'R'),
    ('basics.rookMate key edgeMate', 'R2k4/8/3K4/8/8/8/8/8 b - - 0 1', 'R'),
    ('basics.twoBishops key mateCorner', '7k/8/4B1K1/4B3/8/8/8/8 b - - 0 1',
     'B'),
]


def attack_positions():
    out = []
    for origin, fen, symbol in MATE_SEEDS:
        base = chess.Board(fen)
        piece = chess.Piece.from_symbol(symbol)
        for square in base.pieces(piece.piece_type, chess.WHITE):
            for target in chess.SQUARES:
                if base.piece_at(target):
                    continue
                board = base.copy(stack=False)
                board.remove_piece_at(square)
                board.set_piece_at(target, piece)
                if not board.is_valid():
                    continue
                if board.is_checkmate():
                    state = 'mate'
                elif board.is_stalemate():
                    state = 'stalemate'
                elif board.is_check():
                    state = 'check'
                else:
                    state = 'none'
                out.append((f'{origin}: {symbol} em '
                            f'{chess.square_name(target)}', board, state))
    return out


def rules_check_stalemate(rng):
    positions = attack_positions()
    check = [p for p in positions if p[2] in ('check', 'mate', 'none')]
    for origin, board, state in pick(rng, check, 7, key=lambda p: p[2]):
        difficulty = {'check': 500, 'none': 550, 'mate': 650}[state]
        add('rules.check', 'choice', board.fen(), difficulty,
            f'{state}: xeque é imediato, mate pede olhar as fugas',
            origin, prompt='placementCheckMateNone',
            params={'side': side(board)}, options=['check', 'mate', 'none'],
            answer=state)
    stale = [p for p in positions if p[2] in ('stalemate', 'mate', 'none')]
    for origin, board, state in pick(rng, stale, 7, key=lambda p: p[2]):
        difficulty = {'stalemate': 750, 'mate': 700, 'none': 700}[state]
        add('rules.stalemate', 'choice', board.fen(), difficulty,
            f'{state}: distinguir mate de afogamento', origin,
            prompt='placementMateStalemateNone', params={'side': side(board)},
            options=['mate', 'stalemate', 'none'], answer=state)
    escapes = []
    for origin, board, state in positions:
        if state != 'check':
            continue
        king = board.king(board.turn)
        targets = sorted({chess.square_name(m.to_square)
                          for m in board.legal_moves
                          if m.from_square == king})
        if targets:
            escapes.append((origin, board, targets))
    for origin, board, targets in pick(rng, escapes, 7,
                                       key=lambda p: len(p[2]) > 1):
        difficulty = 650 if len(targets) == 1 else 750
        add('rules.outOfCheck', 'squares', board.fen(), difficulty,
            f'{len(targets)} fuga(s); errar uma conta como erro',
            origin, prompt='placementKingEscape',
            params={'side': side(board)}, squares=targets)


CASTLING = [
    # (lado, outras peças, dificuldade, critério)
    ('king', '', 550, 'roque livre'),
    ('queen', '', 600, 'roque grande livre'),
    ('king', 'B:f1', 600, 'peça própria no caminho'),
    ('king', 'b:c4', 800, 'casa de passagem (f1) atacada'),
    ('king', 'r:g8', 800, 'casa de chegada (g1) atacada'),
    ('queen', 'r:b8', 950, 'b1 atacada não impede o roque grande'),
    ('king', 'b:b4', 700, 'rei em xeque não roca'),
    ('queen', 'n:e3', 800, 'casas d1 e c2 atacadas pelo cavalo'),
    ('king', 'n:h3', 700, 'cavalo ataca só a torre: pode rocar'),
]


def rules_castling():
    for wing, extras, difficulty, why in CASTLING:
        board = chess.Board('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1')
        for entry in extras.split():
            symbol, name = entry.split(':')
            board.set_piece_at(sq(name), chess.Piece.from_symbol(symbol))
        assert board.is_valid(), extras
        move = chess.Move.from_uci('e1g1' if wing == 'king' else 'e1c1')
        answer = 'yes' if move in board.legal_moves else 'no'
        add('rules.castling', 'choice', board.fen(), difficulty,
            f'{why} ({answer})', 'rules.castling (nova): rei e torres na '
            'casa inicial', prompt='placementCanCastle',
            params={'side': 'white', 'wing': wing}, options=['yes', 'no'],
            answer=answer)


EN_PASSANT = [
    # (posição antes do último lance, último lance, dificuldade, critério)
    ('4k3/3p4/8/4P3/8/8/8/4K3 b - - 0 1', 'd7d5', 1000,
     'peão andou duas casas ao lado'),
    ('4k3/8/3p4/4P3/8/8/8/4K3 b - - 0 1', 'd6d5', 1100,
     'peão andou uma casa só: não vale'),
    ('4k3/6p1/8/4P3/8/8/8/4K3 b - - 0 1', 'g7g5', 1050,
     'peão longe, não está ao lado'),
    ('4k3/8/8/8/3p4/8/4P3/4K3 w - - 0 1', 'e2e4', 1050,
     'en passant das pretas'),
    ('4k3/1p6/8/P7/8/8/8/4K3 b - - 0 1', 'b7b5', 1000, 'peão da borda'),
    ('4k3/8/8/8/3p4/8/2P5/4K3 w - - 0 1', 'c2c3', 1100,
     'peão andou uma casa: não vale'),
    ('4k3/5p2/8/4P3/8/8/8/4K3 b - - 0 1', 'e8d7', 1150,
     'o último lance foi do rei: não vale'),
]


def rules_en_passant():
    for before, last, difficulty, why in EN_PASSANT:
        board = chess.Board(before)
        move = chess.Move.from_uci(last)
        assert move in board.legal_moves, before
        board.push(move)
        answer = 'yes' if any(board.is_en_passant(m)
                              for m in board.legal_moves) else 'no'
        add('rules.enPassant', 'choice', board.fen(), difficulty,
            f'{why} ({answer})', 'pieces.pawn: peões da aula, com o último '
            'lance', prompt='placementCanEnPassant',
            params={'side': side(board)}, options=['yes', 'no'],
            answer=answer, lastMove=last)


MATERIAL = [
    # (peças, dificuldade, critério)
    ('KN/K', 700, 'rei e cavalo não dão mate'),
    ('KB/K', 700, 'rei e bispo não dão mate'),
    ('KR/K', 600, 'rei e torre dão mate'),
    ('KP/K', 750, 'o peão pode promover'),
    ('KNN/K', 1100, 'dois cavalos: mate existe se o outro errar'),
    ('KB/KB=', 1250, 'bispos da mesma cor'),
    ('KB/KB!', 1300, 'bispos de cores diferentes: mate existe'),
    ('KB/KN', 1250, 'bispo contra cavalo: mate existe'),
]


def rules_draws(rng):
    for pieces, difficulty, why in MATERIAL:
        for _ in range(1000):
            board = chess.Board(None)
            white, black = pieces.rstrip('=!').split('/')
            free = list(chess.SQUARES)
            rng.shuffle(free)
            for symbol in white:
                board.set_piece_at(free.pop(), chess.Piece.from_symbol(symbol))
            for symbol in black:
                board.set_piece_at(free.pop(), chess.Piece.from_symbol(
                    symbol.lower()))
            bishops = [s for s, p in board.piece_map().items()
                       if p.piece_type == chess.BISHOP]
            colors = {(chess.square_file(s) + chess.square_rank(s)) % 2
                      for s in bishops}
            if pieces.endswith('=') and len(colors) != 1:
                continue
            if pieces.endswith('!') and len(colors) != 2:
                continue
            if board.is_valid() and quiet(board):
                break
        answer = 'yes' if board.is_insufficient_material() else 'no'
        add('rules.draws', 'choice', board.fen(), difficulty,
            f'{why} ({answer})', 'rules.draws (nova): material sorteado',
            prompt='placementInsufficient', params={}, options=['yes', 'no'],
            answer=answer)


VALUE = {chess.PAWN: 1, chess.KNIGHT: 3, chess.BISHOP: 3, chess.ROOK: 5,
         chess.QUEEN: 9}


def rules_piece_value(rng, engine):
    """A captura que ganha mais material, conferida pelo Stockfish."""
    made = 0
    attackers = ['Q', 'R', 'B', 'N', 'R', 'B', 'N', 'Q', 'R', 'N']
    while made < 7:
        symbol = attackers[made]
        board = chess.Board(None)
        board.set_piece_at(sq('g1'), chess.Piece.from_symbol('K'))
        board.set_piece_at(sq('g8'), chess.Piece.from_symbol('k'))
        board.set_piece_at(sq('f2'), chess.Piece.from_symbol('P'))
        board.set_piece_at(sq('g2'), chess.Piece.from_symbol('P'))
        board.set_piece_at(sq('h2'), chess.Piece.from_symbol('P'))
        board.set_piece_at(sq('f7'), chess.Piece.from_symbol('p'))
        board.set_piece_at(sq('g7'), chess.Piece.from_symbol('p'))
        board.set_piece_at(sq('h7'), chess.Piece.from_symbol('p'))
        free = [s for s in squares('abcdef', '3456') if not board.piece_at(s)]
        rng.shuffle(free)
        board.set_piece_at(free.pop(), chess.Piece.from_symbol(symbol))
        for black in rng.sample(['q', 'r', 'b', 'n', 'p'], 2) + ['p']:
            board.set_piece_at(free.pop(), chess.Piece.from_symbol(black))
        if not board.is_valid() or board.is_check():
            continue
        captures = [m for m in board.legal_moves if board.is_capture(m)]
        if len(captures) < 2:
            continue
        infos = engine.analyse(board, chess.engine.Limit(depth=14),
                               multipv=min(8, board.legal_moves.count()))
        scores = [(info['score'].pov(chess.WHITE).score(mate_score=10000),
                   info['pv'][0]) for info in infos]
        best, move = scores[0]
        second = scores[1][0] if len(scores) > 1 else -10000
        if not board.is_capture(move) or best - second < 150 or best < 150:
            continue
        if abs(best) >= 5000:
            continue
        gain = VALUE[board.piece_type_at(move.to_square)]
        made += 1
        add('rules.pieceValue', 'move', board.fen(), 650 + 25 * min(gain, 9) // 3,
            f'captura que ganha {gain} ponto(s); Stockfish: melhor por '
            f'{(best - second) / 100:.1f}', 'rules.pieceValue (nova): peças '
            'sorteadas', prompt='placementWinMaterial',
            params={'side': 'white'}, moves=[move.uci()],
            accept=[[move.uci()]])


def notation():
    for square, difficulty in (('a1', 400), ('h8', 400), ('e4', 450),
                               ('d5', 500), ('c6', 550), ('f3', 550),
                               ('b7', 600)):
        add('notation.squares', 'squares', '8/8/8/8/8/8/8/8 w - - 0 1',
            difficulty, 'canto 400; centro 450–500; casas sem referência '
            'até 600', 'notation.coordinates: tabuleiro vazio da aula',
            prompt='placementTapSquare', params={'square': square},
            squares=[square])
    fens = school_fens()
    picks = [
        ('tricks.principles.develop', 'Nf3', 750, 'lance de cavalo'),
        ('tricks.principles.rules', 'Nf6', 800, 'lance das pretas'),
        ('tricks.defendScholar.guard', 'g6', 800, 'lance de peão das pretas'),
        ('tricks.defendScholar.chase', 'Qxf6', 900, 'captura de dama'),
        ('pieces.pawn.promote', 'e8=Q', 900, 'promoção'),
        ('tricks.principles.rules', 'Nge7', 900,
         'dois cavalos podem ir: desambiguação'),
        ('rules.castling', 'O-O-O', 900, 'roque grande'),
        ('pieces.pawn.take', 'exd5', 950, 'captura de peão'),
    ]
    fens['rules.castling'] = 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'
    for origin, san, difficulty, why in picks:
        board = chess.Board(fens[origin])
        move = board.parse_san(san)
        add('notation.moves', 'move', board.fen(), difficulty, why,
            f'{origin} (escola)', prompt='placementPlayMove',
            params={'move': board.san(move), 'side': side(board)},
            moves=[move.uci()], accept=[[move.uci()]])


# --------------------------------------------------------------------------
# Finais: itens de lance pela tabela

def tablebase_move(board, goal, best_slack=2):
    """(aceitos, todos) para o objetivo, ou None se o item não presta: sem
    lance bom, lances bons demais ou o objetivo errado para a posição."""
    legal = board.legal_moves.count()
    good = TB.good_moves(board, goal)
    if not good or legal < 5:
        return None
    if len(good) <= 3:
        return sorted(good), legal
    if goal == 'win' and None not in good.values():
        shortest = min(good.values())
        best = sorted(u for u, d in good.items() if d <= shortest + best_slack)
        if len(best) <= max(2, legal // 5):
            return best, legal
    return None


def verdict_goal(board):
    result = TB.result(board)
    if result is None:
        return None
    mover = 'whiteWins' if board.turn == chess.WHITE else 'blackWins'
    if result == mover:
        return 'win'
    if result == 'draw':
        return 'draw'
    return None


def lesson_moves(node, lessons, count, base, rng, extra_check=None,
                 prefer_mates=False):
    """Itens `move` das posições de aulas de finais e das variações delas."""
    pool = []
    for lesson in lessons:
        for origin, fen, _ in endgame_positions(lesson):
            for label, board in variants(chess.Board(fen)):
                pool.append((f'{origin} ({label})', board))
    rng.shuffle(pool)
    made, seen = 0, set()
    for origin, board in pool:
        if made >= count:
            break
        key = board.board_fen() + side(board)
        if key in seen:
            continue
        seen.add(key)
        goal = verdict_goal(board)
        if goal is None:
            continue
        mates = mating_moves(board)
        if mates:
            if not prefer_mates:
                continue
            accept, prompt, why = mates, 'placementCheckmate', 'mate em um'
            difficulty = base - 150
        else:
            found = tablebase_move(board, goal)
            if found is None:
                continue
            accept, legal = found
            if extra_check and not extra_check(board, accept):
                continue
            prompt = {'win': 'placementMoveWin', 'draw': 'placementMoveDraw'}[
                goal]
            unique = len(accept) == 1
            difficulty = base + (100 if unique else 0)
            why = (f'{goal}: {len(accept)} lance(s) certo(s) de {legal}'
                   f'{" (+100, lance único)" if unique else ""}')
        made += 1
        add(node, 'move', board.fen(), difficulty,
            f'faixa do nó ({base}); {why}', origin, prompt=prompt,
            params={'side': side(board)}, moves=[accept[0]], accept=[accept])
    if made < count:
        print(f'aviso: {node} com {made} de {count} itens de lance',
              file=sys.stderr)


# --------------------------------------------------------------------------
# Finais: itens de veredito por sorteio

def sample(rng, placement, turn, tries=400, need_quiet=True, check=None):
    """Uma posição sorteada: `placement` é [(peça, casas possíveis)]."""
    for _ in range(tries):
        board = chess.Board(None)
        board.turn = turn
        ok = True
        for symbol, options in placement:
            free = [s for s in options if not board.piece_at(s)]
            if not free:
                ok = False
                break
            board.set_piece_at(rng.choice(free),
                               chess.Piece.from_symbol(symbol))
        if not ok or not board.is_valid():
            continue
        if need_quiet and not quiet(board):
            continue
        if check and not check(board):
            continue
        return board
    return None


def results(node, rng, placement, count, base, why, options,
            turns=(chess.WHITE,), tries=60, need_quiet=True, check=None,
            prompt='placementResult', derived=None):
    """Itens `choice` de resultado com as respostas equilibradas."""
    by_answer = {answer: [] for answer in options}
    for attempt in range(tries):
        turn = turns[attempt % len(turns)]
        board = sample(rng, placement, turn, need_quiet=need_quiet,
                       check=check)
        if board is None:
            continue
        answer = TB.result(board)
        if answer not in by_answer:
            continue
        if any(b.board_fen() == board.board_fen() for b in by_answer[answer]):
            continue
        by_answer[answer].append(board)
        if all(len(v) >= count for v in by_answer.values()):
            break
    chosen = []
    while len(chosen) < count and any(by_answer.values()):
        for answer in options:
            if by_answer[answer] and len(chosen) < count:
                chosen.append((answer, by_answer[answer].pop(0)))
    for answer, board in chosen:
        add(node, 'choice', board.fen(), base, f'{why} ({answer})',
            derived or f'sorteio com semente ({node})', prompt=prompt,
            params={'side': side(board)}, options=list(options),
            answer=answer)
    if len(chosen) < count:
        print(f'aviso: {node} com {len(chosen)} de {count} itens de veredito '
              f'({ {a: 0 for a in options} })', file=sys.stderr)
    return chosen


def two_options(winner='whiteWins'):
    return [winner, 'draw']


THREE = ['whiteWins', 'draw', 'blackWins']


# --------------------------------------------------------------------------
# Mates

def mates(rng):
    fens = school_fens()
    # Mate em um: posições das aulas (escola e finais) e variações.
    pool = []
    for origin in ('pieces.check.mate1', 'pieces.check.mate2',
                   'pieces.check.mate3', 'minor.rookBishop.mate',
                   'minor.rookKnight.mate', 'graduation.twoBishops.mate',
                   'technique.rookMate.mate1'):
        for label, board in variants(chess.Board(fens[origin])):
            pool.append((f'{origin} ({label})', board))
    for lesson in ('basics.queenMate', 'basics.rookMate'):
        for origin, fen, _ in endgame_positions(lesson):
            for label, board in variants(chess.Board(fen)):
                pool.append((f'{origin} ({label})', board))
    rng.shuffle(pool)
    made, seen = 0, set()
    for origin, board in pool:
        mates_ = mating_moves(board)
        key = board.board_fen()
        if not mates_ or key in seen or board.legal_moves.count() < 8:
            continue
        seen.add(key)
        made += 1
        difficulty = 450 + 50 * min(made % 4, 3)
        add('mate.inOne', 'move', board.fen(), difficulty,
            f'mate em um com {len(mates_)} mate(s) possível(is); 450–600 '
            'pela quantidade de peças e de fugas', origin,
            prompt='placementCheckmate', params={'side': side(board)},
            moves=[mates_[0]], accept=[mates_])
        if made == 4:
            break

    # Duas torres: posições sorteadas com o rei preto na borda.
    made = 0
    for _ in range(400):
        board = sample(rng, [('k', squares('abcdefgh', '8')),
                             ('K', squares('abcdefgh', '1234')),
                             ('R', squares('abcdefgh', '1234567')),
                             ('R', squares('abcdefgh', '1234567'))],
                       chess.WHITE, need_quiet=True)
        if board is None:
            continue
        mates_ = mating_moves(board)
        if mates_ and made < 3:
            accept, prompt, difficulty, why = (
                mates_, 'placementCheckmate', 550, 'mate em um de escada')
        elif not mates_ and made >= 3:
            found = tablebase_move(board, 'win', best_slack=0)
            if found is None or len(found[0]) > 4:
                continue
            accept, prompt, difficulty, why = (
                found[0], 'placementBestMove', 700,
                f'o caminho mais curto ({len(found[0])} de {found[1]} lances)')
        else:
            continue
        made += 1
        add('mate.twoRooks', 'move', board.fen(), difficulty, why,
            'mates.twoRooks (escola): torres e reis sorteados, rei preto na '
            'borda', prompt=prompt, params={'side': 'white'},
            moves=[accept[0]], accept=[accept])
        if made == 7:
            break

    # Dama, torre, dois bispos, bispo e cavalo: posições das aulas.
    lesson_moves('mate.queen', ['basics.queenMate'], 7, 750, rng,
                 prefer_mates=True)
    lesson_moves('mate.rook', ['basics.rookMate'], 7, 1150, rng)
    lesson_moves('mate.twoBishops', ['basics.twoBishops'], 7, 1450, rng)
    lesson_moves('mate.bishopKnight', ['mates.bishopKnight.w',
                                       'mates.bishopKnight.edge',
                                       'mates.bishopKnight.full'], 7, 2050,
                 rng)

    # Dois cavalos contra peão: a linha de Troitsky decide.
    def blockade(board):
        pawn = next(iter(board.pieces(chess.PAWN, chess.BLACK)))
        front = pawn - 8
        piece = board.piece_at(front)
        return piece is not None and piece.symbol() == 'N'

    placement = [('p', squares('abcdefgh', '3456')),
                 ('N', squares()), ('N', squares()),
                 ('K', squares()), ('k', squares())]
    results('mate.twoKnightsPawn', rng, placement, 7, 2400,
            'veredito pela linha de Troitsky', two_options(), tries=300,
            check=blockade, need_quiet=False)


# --------------------------------------------------------------------------
# Rei e peões

def chebyshev(a, b):
    return max(abs(chess.square_file(a) - chess.square_file(b)),
               abs(chess.square_rank(a) - chess.square_rank(b)))


def opposition_after(board, uci, distant):
    after = board.copy(stack=False)
    after.push_uci(uci)
    a, b = after.king(chess.WHITE), after.king(chess.BLACK)
    df = abs(chess.square_file(a) - chess.square_file(b))
    dr = abs(chess.square_rank(a) - chess.square_rank(b))
    gap = max(df, dr)
    if distant:
        return (df == 0 or dr == 0 or df == dr) and gap in (4, 6) or (
            df == dr == 2)
    return (df == 0 or dr == 0) and gap == 2


def king_moves_only(board, accept):
    return all(board.piece_type_at(chess.Move.from_uci(u).from_square)
               == chess.KING for u in accept)


def pawns(rng):
    # Regra do quadrado: o rei branco longe, num canto.
    def far_king(board):
        pawn = next(iter(board.pieces(chess.PAWN, chess.WHITE)))
        king = board.king(chess.WHITE)
        black = board.king(chess.BLACK)
        promote = chess.square(chess.square_file(pawn), 7)
        steps = 7 - chess.square_rank(pawn) - (
            1 if chess.square_rank(pawn) == 1 else 0)
        near = abs(chebyshev(black, promote) - steps) <= 1
        return (chebyshev(king, pawn) >= 4 and chebyshev(king, black) >= 4
                and chebyshev(black, pawn) >= 2 and near)

    by = {'whiteWins': [], 'draw': []}
    for _ in range(300):
        turn = rng.choice([chess.WHITE, chess.BLACK])
        board = sample(rng, [('P', squares('bcdefg', '2345')),
                             ('K', squares('ah', '18')), ('k', squares())],
                       turn, check=far_king)
        if board is None:
            continue
        answer = TB.result(board)
        if answer in by and len(by[answer]) < 4:
            by[answer].append(board)
        if all(len(v) >= 4 for v in by.values()):
            break
    for answer in ('whiteWins', 'draw'):
        for board in by[answer]:
            catch = 'yes' if answer == 'draw' else 'no'
            difficulty = 1000 if board.turn == chess.BLACK else 1100
            add('pawns.square', 'choice', board.fen(), difficulty,
                'regra do quadrado; com a vez das brancas conta um tempo a '
                f'menos (+100) ({catch})', 'pawns.square (escola): peão e '
                'reis sorteados, rei branco longe', prompt='placementCatchPawn',
                params={'side': side(board), 'king': 'black'},
                options=['yes', 'no'], answer=catch)

    kpk = ['basics.kingPawn', 'pawns.keySquares', 'pawns.distantOpposition']
    lesson_moves('pawns.opposition', kpk, 7, 1150, rng,
                 extra_check=lambda b, a: king_moves_only(b, a) and all(
                     opposition_after(b, u, False) for u in a))
    lesson_moves('pawns.keySquares', ['pawns.keySquares', 'basics.kingPawn'],
                 7, 1450, rng,
                 extra_check=lambda b, a: king_moves_only(b, a))
    lesson_moves('pawns.distantOpposition', kpk, 7, 1550, rng,
                 extra_check=lambda b, a: king_moves_only(b, a) and all(
                     opposition_after(b, u, True) for u in a))

    # Rei e peão contra rei: veredito.
    def near_pawn(board):
        pawn = next(iter(board.pieces(chess.PAWN, chess.WHITE)))
        return (chebyshev(board.king(chess.WHITE), pawn) <= 2
                and chebyshev(board.king(chess.BLACK), pawn) <= 3)

    results('pawns.kingPawn', rng,
            [('P', squares('bcdefg', '2345')), ('K', squares()),
             ('k', squares())], 7, 1150,
            'rei e peão contra rei: oposição e casas-chave decidem',
            two_options(), turns=(chess.WHITE, chess.BLACK), tries=200,
            check=near_pawn)

    results('pawns.rookPawnDraw', rng,
            [('P', squares('ah', '3456')), ('K', squares()),
             ('k', squares())], 7, 1450,
            'peão de torre: o rei que chega ao canto empata', two_options(),
            turns=(chess.WHITE, chess.BLACK), tries=200, check=near_pawn)

    # Corrida: cada rei longe do peão do outro.
    def racing(board):
        white = next(iter(board.pieces(chess.PAWN, chess.WHITE)))
        black = next(iter(board.pieces(chess.PAWN, chess.BLACK)))
        return (chebyshev(board.king(chess.WHITE), black) >= 4
                and chebyshev(board.king(chess.BLACK), white) >= 4)

    results('pawns.race', rng,
            [('P', squares('abc', '345')), ('p', squares('fgh', '456')),
             ('K', squares('abcd', '123')), ('k', squares('efgh', '678'))],
            4, 1500, 'corrida: contar os tempos e ver quem promove com xeque',
            THREE, tries=200, check=racing)

    # Réti: o rei branco longe dos dois peões; só o lance em diagonal salva.
    def reti_like(board, accept):
        if not king_moves_only(board, accept):
            return False
        for uci in accept:
            move = chess.Move.from_uci(uci)
            if chess.square_file(move.from_square) != chess.square_file(
                    move.to_square) and chess.square_rank(
                    move.from_square) != chess.square_rank(move.to_square):
                return True
        return False

    reti = chess.Board('7K/8/k1P5/7p/8/8/8/8 w - - 0 1')
    pool = []
    for label, board in variants(reti):
        pool.append((label, board))
        for label2, board2 in variants(board):
            pool.append((f'{label}; {label2}', board2))
    made, seen = 0, set()
    rng.shuffle(pool)
    for label, board in pool:
        key = board.board_fen() + side(board)
        if key in seen or made >= 6:
            continue
        seen.add(key)
        if verdict_goal(board) != 'draw':
            continue
        found = tablebase_move(board, 'draw')
        if found is None or not reti_like(board, found[0]):
            continue
        made += 1
        add('pawns.reti', 'move', board.fen(), 1850,
            f'manobra de Réti: {len(found[0])} lance(s) de {found[1]} '
            'empatam', f'posição de Réti (1921), conferida pela tabela '
            f'({label})', prompt='placementMoveDraw',
            params={'side': side(board)}, moves=[found[0][0]],
            accept=[found[0]])
    if made < 6:
        print(f'aviso: pawns.reti com {made} itens', file=sys.stderr)

    # Triangulação: ganhar só com um lance de rei que não avança (perder um
    # tempo); com a vez do outro lado, ganha direto.
    def triangulation(board, accept):
        if not king_moves_only(board, accept):
            return False
        for uci in accept:
            move = chess.Move.from_uci(uci)
            if chess.square_rank(move.to_square) > chess.square_rank(
                    move.from_square):
                return False
        other = board.copy(stack=False)
        other.turn = chess.BLACK
        return other.is_valid() and TB.result(other) == 'whiteWins'

    scan_moves('pawns.triangulation', rng,
               [('P', [sq('d5')]), ('p', [sq('d6')]), ('P', [sq('c4')]),
                ('K', squares('bcdef', '456')),
                ('k', squares('bcdef', '678'))],
               'win', triangulation, 6, 1750,
               'perder um tempo com o rei (triangulação)', tries=400,
               extra=[[('P', [sq('c4')]), ('p', [sq('c5')]),
                       ('K', squares('bcdef', '456')),
                       ('k', squares('abcdef', '678'))],
                      [('P', [sq('e5')]), ('p', [sq('e6')]),
                       ('P', [sq('d4')]), ('p', [sq('d5')]),
                       ('K', squares('bcdefg', '34')),
                       ('k', squares('bcdefg', '678'))]])

    # Peão passado distante e protegido: veredito.
    results('pawns.outsidePasser', rng,
            [('P', squares('ab', '34')), ('P', [sq('g4'), sq('h4')]),
             ('p', [sq('g5'), sq('h5'), sq('g6'), sq('h6')]),
             ('K', squares('cdef', '345')), ('k', squares('cdef', '567'))],
            6, 1750, 'peão passado distante: o desvio decide', two_options(),
            tries=200, need_quiet=True)
    results('pawns.protectedPasser', rng,
            [('P', [sq('d5'), sq('e5')]), ('P', [sq('c4'), sq('f4')]),
             ('p', squares('ab', '567')), ('K', squares('cdef', '34')),
             ('k', squares('bcdefg', '678'))],
            6, 1750, 'peão passado protegido contra passado distante', THREE,
            tries=200)

    # Trebuchet: zugzwang recíproco, quem joga perde. Busca completa: peões
    # bloqueados na quarta e quinta fileiras e cada rei encostado no peão do
    # outro; fica a posição em que, com qualquer lado jogando, quem joga perde.
    found = 0
    for file in 'cdef':
        white_pawn, black_pawn = sq(f'{file}4'), sq(f'{file}5')
        for king in chess.SQUARES:
            for enemy in chess.SQUARES:
                if (chebyshev(king, black_pawn) != 1
                        or chebyshev(enemy, white_pawn) != 1
                        or len({king, enemy, white_pawn, black_pawn}) < 4
                        or chebyshev(king, enemy) < 2):
                    continue
                board = chess.Board(None)
                for square, symbol in ((white_pawn, 'P'), (black_pawn, 'p'),
                                       (king, 'K'), (enemy, 'k')):
                    board.set_piece_at(square, chess.Piece.from_symbol(symbol))
                other = board.copy(stack=False)
                other.turn = chess.BLACK
                if not (board.is_valid() and other.is_valid()) or (
                        board.is_check() or other.is_check()):
                    continue
                if TB.result(board) != 'blackWins' or TB.result(
                        other) != 'whiteWins':
                    continue
                turned = board if found % 2 == 0 else other
                found += 1
                answer = TB.result(turned)
                add('pawns.trebuchet', 'choice', turned.fen(), 2100,
                    f'zugzwang recíproco: quem joga perde ({answer})',
                    'busca completa: peões bloqueados e reis encostados',
                    prompt='placementResult', params={'side': side(turned)},
                    options=THREE, answer=answer)
    if found < 6:
        print(f'aviso: pawns.trebuchet com {found} itens', file=sys.stderr)


def scan_moves(node, rng, placement, goal, check, count, base, why,
               tries=300, extra=(), turn=chess.WHITE, prompt=None):
    """Itens `move` de posições sorteadas em que os lances certos passam no
    filtro `check` (o tema do nó)."""
    placements = [placement] + list(extra)
    made, seen = 0, set()
    for attempt in range(tries):
        board = sample(rng, placements[attempt % len(placements)], turn,
                       tries=20, need_quiet=False)
        if board is None or board.is_check():
            continue
        key = board.board_fen()
        if key in seen:
            continue
        seen.add(key)
        if verdict_goal(board) != goal:
            continue
        found = tablebase_move(board, goal)
        if found is None or not check(board, found[0]):
            continue
        accept, legal = found
        made += 1
        add(node, 'move', board.fen(), base + (100 if len(accept) == 1 else 0),
            f'faixa do nó ({base}); {why}; {len(accept)} lance(s) de {legal}',
            f'sorteio com semente ({node}), conferido pela tabela',
            prompt=prompt or {'win': 'placementMoveWin',
                              'draw': 'placementMoveDraw'}[goal],
            params={'side': side(board)}, moves=[accept[0]], accept=[accept])
        if made >= count:
            break
    if made < count:
        print(f'aviso: {node} com {made} de {count} itens de lance',
              file=sys.stderr)


# --------------------------------------------------------------------------
# Dama e torre

def queen_rook(rng):
    lesson_moves('queen.vsPawn', ['queen.vsPawn'], 5, 1450, rng)
    results('queen.vsPawnDraws', rng,
            [('p', [sq('a2'), sq('c2'), sq('f2'), sq('h2')]),
             ('k', squares('abcdefgh', '12')), ('Q', squares()),
             ('K', squares('abcdefgh', '45678'))], 5, 1750,
            'dama contra peão de torre ou de bispo na sétima', two_options(),
            tries=200, need_quiet=False,
            check=lambda b: not b.is_check() and chebyshev(
                b.king(chess.BLACK),
                next(iter(b.pieces(chess.PAWN, chess.BLACK)))) == 1)
    lesson_moves('queen.vsRook', ['queen.vsRook.philidor',
                                  'queen.vsRook.approach',
                                  'queen.vsRook.thirdRank'], 5, 2050, rng)

    def fortress(board):
        pawn = next(iter(board.pieces(chess.PAWN, chess.BLACK)))
        rook = next(iter(board.pieces(chess.ROOK, chess.BLACK)))
        return bool(board.attackers(chess.BLACK, rook) & chess.BB_SQUARES[
            pawn]) and chebyshev(board.king(chess.BLACK), pawn) <= 1

    results('queen.vsRookPawn', rng,
            [('p', squares('bcdefg', '7')), ('r', squares('abcdefgh', '6')),
             ('k', squares('abcdefgh', '78')), ('Q', squares('abcdefgh', '1234')),
             ('K', squares('abcdefgh', '1234'))], 5, 2400,
            'dama contra torre e peão: a fortaleza segura?', two_options(),
            tries=300, check=fortress)
    results('queen.pawnVsQueen', rng,
            [('P', squares('bcdefg', '67')), ('Q', squares()),
             ('K', squares()), ('q', squares()), ('k', squares())], 5, 2450,
            'dama e peão contra dama', two_options(), tries=300)

    lesson_moves('rook.vsPawn', ['rookPawns.vsPawn'], 5, 1450, rng)

    def saavedra(board, accept):
        # Promover a dama não ganha (afoga ou perde a dama), e uma
        # subpromoção ganha.
        promotions = [chess.Move.from_uci(u) for u in accept
                      if chess.Move.from_uci(u).promotion]
        if not any(m.promotion in (chess.ROOK, chess.KNIGHT)
                   for m in promotions):
            return False
        return not any(m.promotion == chess.QUEEN for m in promotions)

    saavedra_items()

    def two_pawns(board):
        pawns_ = list(board.pieces(chess.PAWN, chess.BLACK))
        return abs(chess.square_file(pawns_[0]) - chess.square_file(
            pawns_[1])) == 1

    results('rook.vsTwoPawns', rng,
            [('p', squares('bcdefg', '345')), ('p', squares('bcdefg', '345')),
             ('k', squares('abcdefgh', '2345')), ('R', squares()),
             ('K', squares('abcdefgh', '5678'))], 5, 1750,
            'torre contra dois peões ligados', THREE, tries=300,
            check=two_pawns)

    lesson_moves('rook.lucena', ['rook.lucena'], 5, 1500, rng)
    lesson_moves('rook.philidor', ['rook.philidor'], 5, 1550, rng)
    lesson_moves('rook.backRank', ['rook.backRank'], 5, 1750, rng)
    lesson_moves('rook.shortSide', ['rook.shortSide'], 5, 1800, rng)

    def cut_off(board):
        pawn = next(iter(board.pieces(chess.PAWN, chess.WHITE)))
        rook = next(iter(board.pieces(chess.ROOK, chess.WHITE)))
        king = board.king(chess.BLACK)
        pf, rf, kf = (chess.square_file(pawn), chess.square_file(rook),
                      chess.square_file(king))
        return min(pf, kf) < rf < max(pf, kf)

    results('rook.cutOff', rng,
            [('P', squares('cdef', '45')), ('K', squares('bcdefg', '3456')),
             ('R', squares()), ('k', squares()), ('r', squares())], 5, 1750,
            'rei cortado por colunas: ganha ou empata?', two_options(),
            tries=300, check=cut_off)

    def frontal(board):
        pawn = next(iter(board.pieces(chess.PAWN, chess.WHITE)))
        rook = next(iter(board.pieces(chess.ROOK, chess.BLACK)))
        return (chess.square_file(rook) == chess.square_file(pawn)
                and chess.square_rank(rook) == 7)

    results('rook.frontal', rng,
            [('P', squares('cdef', '45')), ('K', squares('bcdefg', '3456')),
             ('r', squares('cdef', '8')), ('R', squares('abgh')),
             ('k', squares())], 5, 1800,
            'defesa frontal: a torre na frente do peão', two_options(),
            tries=300, check=frontal)

    results('rook.rookPawn', rng,
            [('P', [sq('a7'), sq('a6')]), ('R', [sq('a8')]),
             ('r', squares('a', '12345')), ('k', squares('bcdefgh', '5678')),
             ('K', squares('abcdefgh', '1234567'))], 5, 2050,
            'peão de torre na sétima com a torre na frente', two_options(),
            tries=300, need_quiet=False, check=lambda b: not b.is_check())

    def vancura(board):
        pawn = next(iter(board.pieces(chess.PAWN, chess.WHITE)))
        rook = next(iter(board.pieces(chess.ROOK, chess.BLACK)))
        return chess.square_rank(rook) == chess.square_rank(pawn)

    results('rook.vancura', rng,
            [('P', [sq('a6'), sq('a5')]), ('R', [sq('a8'), sq('a7')]),
             ('r', squares('cdefgh', '56')), ('k', squares('fgh', '67')),
             ('K', squares('abcdefgh', '1234'))], 5, 2100,
            'Vancura: a torre ataca o peão de lado', two_options(),
            tries=300, check=vancura)

    def behind(board, accept):
        pawn = next(iter(board.pieces(chess.PAWN, chess.WHITE)))
        for uci in accept:
            move = chess.Move.from_uci(uci)
            if board.piece_type_at(move.from_square) != chess.ROOK:
                return False
            if chess.square_file(move.to_square) != chess.square_file(pawn):
                return False
            if chess.square_rank(move.to_square) >= chess.square_rank(pawn):
                return False
        return True

    scan_moves('rook.behindPasser', rng,
               [('P', squares('abcdefgh', '456')), ('R', squares()),
                ('K', squares()), ('r', squares()), ('k', squares())],
               'win', behind, 5, 1800, 'a torre vai para trás do peão',
               tries=1500)

    results('rook.twoPawns', rng,
            [('P', [sq('f4'), sq('f5')]), ('P', [sq('h4'), sq('h5')]),
             ('R', squares()), ('K', squares('efgh', '3456')),
             ('r', squares()), ('k', squares('efgh', '678'))], 5, 2050,
            'torre e dois peões (bispo e torre) contra torre', two_options(),
            tries=300)


def saavedra_items():
    """A linha de Saavedra a partir da posição-chave da aula
    rookPawns.vsPawn: as vezes das brancas em que poucos lances ganham, e a
    posição final (só a torre ganha) espelhada e com as cores trocadas. Os
    lances das pretas são os da linha; a tabela confere cada vez."""
    key = next(fen for origin, fen, _ in endgame_positions('rookPawns.vsPawn')
               if origin.endswith('key saavedra'))
    line = ['c6c7', 'd5d6', 'b6b5', 'd6d5', 'b5b4', 'd5d4', 'b4b3', 'd4d3',
            'b3c2', 'd3d4', 'c7c8r']
    board = chess.Board(key)
    picks, final = [], None
    for index, uci in enumerate(line):
        move = chess.Move.from_uci(uci)
        assert move in board.legal_moves, (index, uci)
        if board.turn == chess.WHITE:
            good = TB.good_moves(board, 'win')
            assert uci in good, (index, uci, good)
            if len(good) <= 3:
                picks.append((f'lance {index // 2 + 1} da linha', board.copy(
                    stack=False), sorted(good)))
            if move.promotion:
                final = board.copy(stack=False)
        board.push(move)
    flipped = final.transform(chess.flip_horizontal)
    for label, extra in (('espelhada', flipped),
                         ('cores trocadas', final.mirror()),
                         ('cores trocadas e espelhada', flipped.mirror())):
        good = TB.good_moves(extra, 'win')
        promotions = [u for u in good if u[-1] in 'rn']
        assert promotions and not any(u[-1] == 'q' for u in good), label
        picks.append((f'posição final ({label})', extra, sorted(good)))
    for label, position, accept in picks[-6:]:
        underpromotes = any(u[-1] in 'rn' for u in accept)
        add('rook.saavedra', 'move', position.fen(),
            1850 if underpromotes else 1750,
            f'Saavedra: {len(accept)} lance(s) ganham'
            f'{"; a dama afoga e só a torre ganha" if underpromotes else ""}',
            f'rookPawns.vsPawn key saavedra ({label}), conferida pela tabela',
            prompt='placementMoveWin', params={'side': side(position)},
            moves=[accept[0]], accept=[accept])


# --------------------------------------------------------------------------
# Peças menores

def bishop_color(square):
    return (chess.square_file(square) + chess.square_rank(square)) % 2


def minor(rng):
    results('minor.wrongBishop', rng,
            [('P', squares('ah', '456')), ('B', squares()), ('K', squares()),
             ('k', squares())], 5, 1450, 'bispo da cor errada com peão de '
            'torre', two_options(), turns=(chess.WHITE, chess.BLACK),
            tries=300)
    results('minor.knightVsPawn', rng,
            [('p', squares('bcdefg', '234')), ('k', squares()),
             ('N', squares()), ('K', squares())], 5, 1500,
            'o cavalo segura o peão?', ['draw', 'blackWins'],
            tries=300)

    def opposite(board):
        white = next(iter(board.pieces(chess.BISHOP, chess.WHITE)))
        black = next(iter(board.pieces(chess.BISHOP, chess.BLACK)))
        return bishop_color(white) != bishop_color(black)

    def same(board):
        return not opposite(board)

    results('minor.bishopVsPawns', rng,
            [('p', squares('bcdefg', '345')), ('p', squares('bcdefg', '345')),
             ('k', squares()), ('B', squares()), ('K', squares())], 5, 1750,
            'bispo contra dois peões', ['draw', 'blackWins', 'whiteWins'],
            tries=300)
    results('minor.oppositeBishops', rng,
            [('P', squares('bcdefg', '456')), ('P', squares('bcdefg', '456')),
             ('B', squares()), ('K', squares()), ('b', squares()),
             ('k', squares())], 5, 1800,
            'bispos de cores opostas: dois peões ganham?', two_options(),
            tries=300, check=opposite)
    results('minor.centurini', rng,
            [('P', squares('bcdefg', '567')), ('B', squares()),
             ('K', squares()), ('b', squares()), ('k', squares())], 5, 2100,
            'bispo e peão contra bispo da mesma cor', two_options(),
            tries=300, check=same)
    results('minor.knightEndings', rng,
            [('P', squares('bcdefg', '567')), ('N', squares()),
             ('K', squares()), ('n', squares()), ('k', squares())], 5, 2100,
            'cavalo e peão contra cavalo', two_options(), tries=300)
    results('minor.bishopVsKnight', rng,
            [('P', squares('bcdefg', '456')), ('B', squares()),
             ('K', squares()), ('n', squares()), ('k', squares())], 5, 2100,
            'bispo e peão contra cavalo', two_options(), tries=300)
    results('rookMinor.vsMinor', rng,
            [('R', squares()), ('K', squares()), ('b', squares()),
             ('k', squares())], 3, 2050, 'torre contra bispo: canto certo?',
            two_options(), tries=300)
    results('rookMinor.vsMinor', rng,
            [('R', squares()), ('K', squares()), ('n', squares()),
             ('k', squares())], 3, 2100, 'torre contra cavalo', two_options(),
            tries=300)
    results('rookMinor.exchange', rng,
            [('R', squares()), ('K', squares()), ('b', squares()),
             ('p', squares('bcdefg', '3456')), ('k', squares())], 5, 2400,
            'qualidade contra peça e peão: fortaleza?', THREE, tries=300)
    results('rookMinor.vsRook', rng,
            [('R', squares()), ('B', squares()), ('K', squares()),
             ('r', squares()), ('k', squares())], 5, 2450,
            'torre e bispo contra torre', two_options(), tries=300)

    # Torre com peças menores (escola): as posições das aulas e variações.
    fens = school_fens()
    pool = []
    for origin in ('minor.rookBishop.mate', 'minor.rookKnight.mate',
                   'minor.rookBishop.team', 'minor.rookKnight.team',
                   'minor.rookTwoBishops.team', 'minor.rookTwoKnights.team',
                   'minor.rookBishopKnight.team',
                   'minor.twoRooksVsKnight.defender'):
        for label, board in variants(chess.Board(fens[origin])):
            for label2, board2 in variants(board)[:6]:
                pool.append((f'{origin} ({label}; {label2})', board2))
    rng.shuffle(pool)
    made, seen = 0, set()
    for origin, board in pool:
        key = board.board_fen() + side(board)
        if key in seen or made >= 6 or chess.popcount(board.occupied) > 7:
            continue
        seen.add(key)
        mates_ = mating_moves(board)
        if mates_:
            accept, prompt, difficulty, why = (
                mates_, 'placementCheckmate', 950, 'mate em um com peça menor')
        else:
            if verdict_goal(board) != 'win':
                continue
            found = tablebase_move(board, 'win', best_slack=0)
            if found is None:
                continue
            accept, prompt, difficulty, why = (
                found[0], 'placementBestMove', 1150,
                f'caminho mais curto ({len(found[0])} de {found[1]})')
        made += 1
        add('school.minorMates', 'move', board.fen(), difficulty, why, origin,
            prompt=prompt, params={'side': side(board)}, moves=[accept[0]],
            accept=[accept])


def main():
    rng = random.Random(SEED)
    print('→ rules_squares', len(ITEMS), file=sys.stderr, flush=True)
    rules_squares()
    print('→ rules_capture', len(ITEMS), file=sys.stderr, flush=True)
    rules_capture()
    print('→ rules_check_stalemate', len(ITEMS), file=sys.stderr, flush=True)
    rules_check_stalemate(rng)
    print('→ rules_castling', len(ITEMS), file=sys.stderr, flush=True)
    rules_castling()
    print('→ rules_en_passant', len(ITEMS), file=sys.stderr, flush=True)
    rules_en_passant()
    print('→ rules_draws', len(ITEMS), file=sys.stderr, flush=True)
    rules_draws(rng)
    stockfish = shutil.which('stockfish')
    if not stockfish:
        sys.exit('Stockfish não encontrado (valor das peças).')
    engine = chess.engine.SimpleEngine.popen_uci(stockfish)
    try:
        rules_piece_value(rng, engine)
    finally:
        engine.quit()
    print('→ notation', len(ITEMS), file=sys.stderr, flush=True)
    notation()
    print('→ mates', len(ITEMS), file=sys.stderr, flush=True)
    mates(rng)
    print('→ pawns', len(ITEMS), file=sys.stderr, flush=True)
    pawns(rng)
    print('→ queen_rook', len(ITEMS), file=sys.stderr, flush=True)
    queen_rook(rng)
    print('→ minor', len(ITEMS), file=sys.stderr, flush=True)
    minor(rng)
    counts = {}
    for item in ITEMS:
        counts[item['node']] = counts.get(item['node'], 0) + 1
    OUT.write_text(json.dumps({'items': ITEMS}, ensure_ascii=False,
                              indent=1) + '\n')
    print(f'{len(ITEMS)} itens próprios em {OUT.relative_to(ROOT)}')
    for node, count in sorted(counts.items()):
        print(f'  {node}: {count}')


if __name__ == '__main__':
    main()
