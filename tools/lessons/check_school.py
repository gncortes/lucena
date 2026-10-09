#!/usr/bin/env python3
"""Confere as aulas da Escola do Viktor (`assets/lessons/course.json`).

Para todas as aulas, antigas e novas:

- todo FEN abre; posição com os dois reis é legal (`is_valid`);
- setas, casas marcadas, estrelas e casas a tocar são casas do tabuleiro;
- estrelas: só peças brancas que andam (peão é obstáculo), e cada estrela
  alcançável, uma depois da outra, na ordem dada;
- passo de lance: cada lance aceito é legal, a resposta combinada é legal;
  quando o lance ensinado dá mate, todo aceito dá mate e todo mate em um é
  aceito; nenhum lance aceito afoga, a menos que a aula diga que afoga;
- passo de jogar: posição legal e partida em andamento;
- falas: todo passo tem fala em português e em inglês, e os dois idiomas têm
  as mesmas chaves.

Além disso, as afirmações de xadrez que as falas fazem (`CLAIMS`): é mate, é
afogamento, não pode rocar, é en passant, é material insuficiente...

Uso (precisa do python-chess):

    python3 tools/lessons/check_school.py

Sai com erro e a lista dos problemas se algo não confere.
"""

import json
import sys
from pathlib import Path

import chess

ROOT = Path(__file__).resolve().parents[2]
COURSE = ROOT / 'assets' / 'lessons' / 'course.json'
TEXTS = {lang: ROOT / 'assets' / 'lessons' / lang / 'lessons.json'
         for lang in ('pt', 'en')}


def parse_uci(board, uci):
    """O lance UCI na posição, com o roque também como rei-toma-torre
    (`e1h1`), do jeito que o app aceita. Nulo se ilegal."""
    try:
        return board.parse_uci(uci)
    except ValueError:
        pass
    move = chess.Move.from_uci(uci)
    piece = board.piece_at(move.from_square)
    target = board.piece_at(move.to_square)
    if piece and target and piece.piece_type == chess.KING and \
            target == chess.Piece(chess.ROOK, piece.color):
        file = 6 if chess.square_file(move.to_square) > \
            chess.square_file(move.from_square) else 2
        king_to = chess.square(file, chess.square_rank(move.from_square))
        castle = chess.Move(move.from_square, king_to)
        if board.is_castling(castle) and castle in board.legal_moves:
            return castle
    return None


def has_both_kings(board):
    return all(len(board.pieces(chess.KING, color)) == 1
               for color in chess.COLORS)


def square_ok(name):
    try:
        chess.parse_square(name)
        return True
    except ValueError:
        return False


def mates_in_one(board):
    out = set()
    for move in board.legal_moves:
        board.push(move)
        if board.is_checkmate():
            out.add(move.uci())
        board.pop()
    return out


def stars_reachable(board, stars):
    """As estrelas, em ordem, cada uma alcançada por alguma peça branca (sem
    peão), por qualquer caminho de até 8 lances. Devolve a primeira estrela
    inalcançável, ou nula."""
    def moves(b):
        movers = chess.SquareSet(
            b.occupied_co[chess.WHITE] & ~b.pieces_mask(chess.PAWN,
                                                         chess.WHITE))
        for square in movers:
            for to in chess.SquareSet(b.attacks_mask(square)) - \
                    chess.SquareSet(b.occupied_co[chess.WHITE]):
                yield square, to
    for star in stars:
        target = chess.parse_square(star)
        seen = {board.board_fen()}
        frontier = [board]
        found = None
        for _ in range(8):
            nxt = []
            for b in frontier:
                for frm, to in moves(b):
                    moved = b.copy()
                    piece = moved.remove_piece_at(frm)
                    moved.set_piece_at(to, piece)
                    if to == target:
                        found = moved
                        break
                    if moved.board_fen() not in seen:
                        seen.add(moved.board_fen())
                        nxt.append(moved)
                if found:
                    break
            if found or not nxt:
                break
            frontier = nxt
        if not found:
            return star
        board = found
    return None


# --- O que as falas afirmam ---------------------------------------------------

def _castles(board, side):
    rank = 0 if board.turn == chess.WHITE else 7
    king_to = chess.square(6 if side == 'short' else 2, rank)
    move = chess.Move(chess.square(4, rank), king_to)
    return move in board.legal_moves and board.is_castling(move)


def _after(board, uci):
    after = board.copy()
    after.push(parse_uci(board, uci))
    return after


def _forced_line(board, line):
    """Cada lance do aluno dá xeque e a resposta combinada é a única."""
    b = board.copy()
    for turn in line:
        b.push(parse_uci(b, turn['accept'][0]))
        if not b.is_check():
            return False
        reply = turn.get('reply')
        if reply:
            if [m.uci() for m in b.legal_moves] != [reply]:
                return False
            b.push(chess.Move.from_uci(reply))
    return True


# Chave `aula.passo` -> (o que a fala afirma, a conferência). A conferência
# recebe o tabuleiro do FEN e o passo.
CLAIMS = {
    'pieces.pawn.underpromotion': (
        'a dama afoga; a torre não',
        lambda b, s: _after(b, 'c7c8q').is_stalemate()
        and [m.uci() for m in _after(b, 'c7c8r').legal_moves] == ['a7a6']),
    'pieces.pawn.rook': (
        'só a torre é aceita; a dama afoga, bispo e cavalo não ganham',
        lambda b, s: s['line'][0]['accept'] == ['c7c8r']
        and _after(b, 'c7c8q').is_stalemate()
        and _after(b, 'c7c8b').is_insufficient_material()
        and _after(b, 'c7c8n').is_insufficient_material()),
    'pieces.stalemate.stalemate': (
        'é afogamento', lambda b, s: b.is_stalemate()),
    'pieces.stalemate.defense': (
        'é afogamento: o peão da torre e o rei no canto',
        lambda b, s: b.is_stalemate()),
    # Que Rb8 é o único lance que empata foi conferido com o Stockfish (Rd8
    # e Rd7 perdem); aqui, que ele leva o rei para a frente do peão.
    'pieces.stalemate.save': (
        'o rei vai para a frente do peão da torre, a caminho do canto',
        lambda b, s: s['line'][0]['accept'] == ['c8b8']
        and _after(b, 'c8b8').king(chess.BLACK) == chess.B8
        and b.pieces(chess.PAWN, chess.WHITE) == chess.SquareSet([chess.A6])),
    'rules.captureProtect.take': (
        'a peça capturada não está protegida',
        lambda b, s: not _after(b, s['line'][0]['accept'][0]).is_attacked_by(
            chess.BLACK, chess.parse_square(s['line'][0]['accept'][0][2:4]))),
    'rules.captureProtect.protect': (
        'o cavalo de d5 está protegido pelo peão de e6',
        lambda b, s: b.is_attacked_by(chess.BLACK, chess.D5)
        and b.is_attacked_by(chess.WHITE, chess.D5)),
    'rules.captureProtect.choose': (
        'o bispo de a4 está livre; o cavalo de d5, protegido',
        lambda b, s: not b.is_attacked_by(chess.BLACK, chess.A4)
        and b.is_attacked_by(chess.BLACK, chess.D5)
        and s['line'][0]['accept'] == ['d1a4']
        and _after(b, 'd1a4').is_check()),
    'rules.captureProtect.defend': (
        'o cavalo está atacado e solto; cada lance aceito o protege',
        lambda b, s: b.is_attacked_by(chess.BLACK, chess.D4)
        and not b.is_attacked_by(chess.WHITE, chess.D4)
        and all(_after(b, uci).is_attacked_by(chess.WHITE, chess.D4)
                for uci in s['line'][0]['accept'])),
    'rules.outOfCheck.three': (
        'o rei branco está em xeque', lambda b, s: b.is_check()),
    'rules.outOfCheck.run': (
        'em xeque, só o rei pode sair: todos os lances legais são aceitos',
        lambda b, s: b.is_check()
        and {m.uci() for m in b.legal_moves} == set(s['line'][0]['accept'])
        and all(b.piece_at(m.from_square).piece_type == chess.KING
                for m in b.legal_moves)),
    'rules.outOfCheck.block': (
        'em xeque, o único lance é tapar',
        lambda b, s: b.is_check()
        and [m.uci() for m in b.legal_moves] == s['line'][0]['accept']),
    'rules.outOfCheck.capture': (
        'em xeque, o único lance é capturar quem dá xeque',
        lambda b, s: b.is_check()
        and [m.uci() for m in b.legal_moves] == s['line'][0]['accept']
        and b.is_capture(b.parse_uci(s['line'][0]['accept'][0]))),
    'rules.outOfCheck.none': (
        'sem nenhuma das três saídas: é mate', lambda b, s: b.is_checkmate()),
    'rules.castling.short': (
        'o roque pequeno é legal', lambda b, s: _castles(b, 'short')),
    'rules.castling.long': (
        'o roque grande é legal', lambda b, s: _castles(b, 'long')),
    'rules.castling.rules': (
        'o bispo de a6 vigia f1, e o rei não pode rocar por ali',
        lambda b, s: b.is_attacked_by(chess.BLACK, chess.F1)
        and not _castles(b, 'short')),
    'rules.castling.cannot': (
        'o roque pequeno é proibido (o rei passaria por f1, atacada); o '
        'grande é legal',
        lambda b, s: not _castles(b, 'short') and _castles(b, 'long')
        and b.is_attacked_by(chess.BLACK, chess.F1)
        and not b.is_check()),
    'rules.castling.moved': (
        'sem o direito ao roque, nenhum roque é legal',
        lambda b, s: not _castles(b, 'short') and not _castles(b, 'long')),
    'rules.draws.insufficient': (
        'rei e bispo contra rei: material insuficiente',
        lambda b, s: b.is_insufficient_material()),
    'rules.draws.takeLast': (
        'depois de tomar o peão, material insuficiente',
        lambda b, s: _after(b, s['line'][0]['accept'][0])
        .is_insufficient_material()),
    'rules.draws.perpetual': (
        'cada lance é xeque e a resposta é a única; volta à mesma posição',
        lambda b, s: _forced_line(b, s['line'])),
    'rules.enPassant.capture': (
        'o lance aceito é en passant',
        lambda b, s: all(b.is_en_passant(b.parse_uci(uci))
                         for uci in s['line'][0]['accept'])),
    'rules.enPassant.black': (
        'o lance aceito é en passant',
        lambda b, s: all(b.is_en_passant(b.parse_uci(uci))
                         for uci in s['line'][0]['accept'])),
    'rules.pieceValue.bigger': (
        'a torre de f5 e o cavalo de d5 estão soltos',
        lambda b, s: not b.is_attacked_by(chess.BLACK, chess.F5)
        and not b.is_attacked_by(chess.BLACK, chess.D5)),
    'rules.pieceValue.goodTrade': (
        'a torre de d5 está protegida pelo peão; dama e cavalo a atacam',
        lambda b, s: b.is_attacked_by(chess.BLACK, chess.D5)
        and chess.D1 in b.attackers(chess.WHITE, chess.D5)
        and chess.C3 in b.attackers(chess.WHITE, chess.D5)),
    'tactics.matePatterns.end': (
        'o mate sufocado, já dado', lambda b, s: b.is_checkmate()),
    # Que Re6 é o único lance que empata foi conferido com o Stockfish.
    'technique.opposition.defend': (
        'de pretas, o lance aceito toma a oposição (reis frente a frente)',
        lambda b, s: _opposition(_after(b, s['line'][0]['accept'][0]))),
}


def _turned(board):
    turned = board.copy(stack=False)
    turned.turn = not turned.turn
    return turned


def _opposition(board):
    white = board.king(chess.WHITE)
    black = board.king(chess.BLACK)
    return chess.square_file(white) == chess.square_file(black) and \
        abs(chess.square_rank(white) - chess.square_rank(black)) == 2


# Passos em que um lance aceito afoga de propósito (a aula ensina isso).
STALEMATE_OK = set()


def check():
    course = json.loads(COURSE.read_text())
    texts = {lang: json.loads(path.read_text())
             for lang, path in TEXTS.items()}
    problems = []
    seen_claims = set()
    lesson_ids = []

    for module in course['modules']:
        for key in ('module.' + module['id'],):
            for lang, all_texts in texts.items():
                if key not in all_texts:
                    problems.append(f'{lang}: falta {key}')
        for lesson in module['lessons']:
            lid = lesson['id']
            lesson_ids.append(lid)
            steps = [s for part in lesson.get('parts', [])
                     for s in part['steps']] or lesson['steps']
            ids = [s['id'] for s in steps]
            if len(ids) != len(set(ids)):
                problems.append(f'{lid}: passos com o mesmo id')
            for lang, all_texts in texts.items():
                for suffix in ('title', 'summary'):
                    if f'{lid}.{suffix}' not in all_texts:
                        problems.append(f'{lang}: falta {lid}.{suffix}')
            for step in steps:
                where = f"{lid}.{step['id']}"
                problems += [f'{where}: {p}' for p in check_step(step)]
                for lang, all_texts in texts.items():
                    if where not in all_texts:
                        problems.append(f'{lang}: falta a fala {where}')
                if where in CLAIMS:
                    seen_claims.add(where)
                    claim, test = CLAIMS[where]
                    try:
                        ok = test(chess.Board(step['fen']), step)
                    except Exception as error:  # noqa: BLE001
                        ok = False
                        claim += f' ({error!r})'
                    if not ok:
                        problems.append(f'{where}: não confere: {claim}')

    if len(lesson_ids) != len(set(lesson_ids)):
        problems.append('aulas com o mesmo id')
    for key in sorted(set(CLAIMS) - seen_claims):
        problems.append(f'{key}: afirmação sem passo no curso')
    if set(texts['pt']) != set(texts['en']):
        diff = set(texts['pt']) ^ set(texts['en'])
        problems.append(f'pt e en com chaves diferentes: {sorted(diff)}')
    return lesson_ids, problems


def check_step(step):
    problems = []
    kind = step['type']
    fen = step.get('fen')
    for arrow in step.get('arrows', []):
        if len(arrow) != 4 or not (square_ok(arrow[:2]) and
                                   square_ok(arrow[2:])):
            problems.append(f'seta {arrow} inválida')
    for mark in step.get('marks', []):
        if not square_ok(mark):
            problems.append(f'casa {mark} inválida')
    if fen is None:
        return problems if kind == 'talk' else problems + ['sem FEN']
    try:
        board = chess.Board(fen)
    except ValueError as error:
        return problems + [f'FEN não abre: {error}']

    if kind == 'talk':
        if has_both_kings(board) and not board.is_valid():
            problems.append(f'posição ilegal ({board.status()!r})')
    elif kind == 'stars':
        if board.occupied_co[chess.BLACK]:
            problems.append('estrelas só com peças brancas')
        for star in step['stars']:
            if not square_ok(star):
                problems.append(f'estrela {star} inválida')
            elif board.piece_at(chess.parse_square(star)):
                problems.append(f'estrela {star} em casa ocupada')
        if not problems:
            missing = stars_reachable(board, step['stars'])
            if missing:
                problems.append(f'estrela {missing} inalcançável')
    elif kind == 'tap':
        targets = step['targets']
        if not targets or len(set(targets)) != len(targets):
            problems.append('casas a tocar vazias ou repetidas')
        for target in targets:
            if not square_ok(target):
                problems.append(f'casa a tocar {target} inválida')
    elif kind == 'move':
        if not board.is_valid():
            return problems + [f'posição ilegal ({board.status()!r})']
        where = step['id']
        for number, turn in enumerate(step['line'], start=1):
            accept = turn['accept']
            if not accept:
                problems.append(f'vez {number}: nenhum lance aceito')
                break
            moves = {}
            for uci in accept:
                move = parse_uci(board, uci)
                if move is None:
                    problems.append(f'vez {number}: {uci} ilegal')
                else:
                    moves[uci] = move
            if len(moves) != len(accept):
                break
            results = {}
            for uci, move in moves.items():
                board.push(move)
                results[uci] = ('mate' if board.is_checkmate() else
                                'afoga' if board.is_stalemate() else '')
                board.pop()
            if results[accept[0]] == 'mate':
                mates = mates_in_one(board)
                normal = {moves[uci].uci() for uci in accept}
                if not mates <= normal:
                    problems.append(
                        f'vez {number}: mates não aceitos '
                        f'{sorted(mates - normal)}')
                not_mate = [u for u, r in results.items() if r != 'mate']
                if not_mate:
                    problems.append(
                        f'vez {number}: aceitos que não dão mate {not_mate}')
            stale = [u for u, r in results.items() if r == 'afoga']
            if stale and where not in STALEMATE_OK:
                problems.append(f'vez {number}: aceitos que afogam {stale}')
            board.push(moves[accept[0]])
            reply = turn.get('reply')
            if reply:
                move = parse_uci(board, reply)
                if move is None:
                    problems.append(f'vez {number}: resposta {reply} ilegal')
                    break
                board.push(move)
    elif kind == 'play':
        if not board.is_valid():
            problems.append(f'posição ilegal ({board.status()!r})')
        elif board.is_game_over():
            problems.append('partida já acabou')
    else:
        problems.append(f'tipo {kind} fora da escola')
    return problems


def main():
    lessons, problems = check()
    print(f'{len(lessons)} aulas:')
    for number, lesson in enumerate(lessons, start=1):
        print(f'  {number:2}. {lesson}')
    if problems:
        print('\nProblemas:', *problems, sep='\n- ')
        sys.exit(1)
    print('\nTudo confere.')


if __name__ == '__main__':
    main()
