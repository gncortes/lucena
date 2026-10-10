"""Confere a numeração dos lances citados nas falas de uma aula de final (T61).

Regra (CLAUDE.md, "Textos das aulas de finais"): todo lance citado em passo, demo,
enunciado, dica ou solução sai numerado como nos livros: "1.Rf7!", "1...Rh7",
"2.e4", "Com 1.Rc4? ...". O lance preto logo depois do branco no mesmo par não
repete o número ("1.Df6 Rd5 2.De7"). Casa solta ("fecha g8") não leva número.
Posição de partida real (passo com `ref` para uma partida com `url` `...#<ply>`):
o número é o do lance real (ply N: o próximo lance tem o número N//2+1; brancas
se N é par). Posição montada ou de estudo: começa em 1.

    tools/.cache/venv/bin/python tools/lessons/check_numbering.py <id> [<id>...]

Lista, por chave pt/en:
- lance citado sem número que não é continuação de um par numerado, com o número
  sugerido quando ele sai da posição do passo (FEN, linha do demo ou do exercício);
- lance numerado que não é legal na posição daquele número (número ou lado errado).
`history` e `key.*` ficam de fora (são para leigo, sem notação). Sai com 1 se achar
algo.

Lance de peão sem captura nem sinal ("e4") só conta como lance se tem número, abre a
fala do lance do demo ou continua um par; solto, é casa. Também não contam: a peça
que já está na casa ("defendida por Rf3", "o peão de a6"), a casa no fim de uma
pergunta ("Quem vigia c6?"), lance numerado longe de toda posição da fala (o
"55...Rf7 de So" citado noutra posição) e o prelúdio do enunciado ("linha de
Silman, depois de 1.Tc1 Re7."), de onde a numeração do exercício continua. A
sugestão é um palpite pela posição: confira cada número contra a linha.
"""
import argparse
import json
import pathlib
import re
import sys
import urllib.parse

import chess

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / 'tools' / 'lessons' / 'endgames'
TEXTS = ROOT / 'assets' / 'lessons'
LANGS = ('pt', 'en')
# Letra da peça na fala -> letra do SAN do python-chess.
PIECES = {
    'pt': {'R': 'K', 'D': 'Q', 'T': 'R', 'B': 'B', 'C': 'N'},
    'en': {'K': 'K', 'Q': 'Q', 'R': 'R', 'B': 'B', 'N': 'N'},
}
OWNER = re.compile(r'(?:\b(?:peão|peões|rei|dama|torre|bispo|cavalo) (?:de|em|na|no)'
                   r'|\b(?:pawn|king|queen|rook|bishop|knight)s? (?:on|at)) $')
SKIP_KEY = re.compile(r'^(history|key\..*|title)$')


def token_re(lang):
    letters = ''.join(PIECES[lang])
    san = (rf'(?:O-O-O|O-O|[{letters}][a-h]?[1-8]?x?[a-h][1-8]'
           rf'|[a-h]x[a-h][1-8](?:=[{letters}])?|[a-h][1-8](?:=[{letters}])?)')
    # número: "12." (brancas) ou "12..." / "12…" (pretas); "..." sem número também conta.
    return re.compile(
        rf'(?<![\w.…])(?P<num>(?P<n>\d+)(?P<dots>\.\.\.|…|\.)|\.\.\.|…)?'
        rf'(?P<san>{san})(?P<suf>[+#]?(?:[!?]{{1,2}})?)(?![\w-])')


def to_chess_san(san, lang):
    if san[0] in PIECES[lang] and len(san) > 2 and not san.startswith('O-O'):
        san = PIECES[lang][san[0]] + san[1:]
    if '=' in san:
        head, promo = san.split('=')
        san = f'{head}={PIECES[lang].get(promo, promo)}'
    return san


class State:
    """Uma posição com o número do lance de quem joga."""

    def __init__(self, board, number):
        self.board = board
        self.number = number

    @property
    def side(self):
        return 'w' if self.board.turn == chess.WHITE else 'b'

    def label(self, san):
        return f'{self.number}.{san}' if self.side == 'w' else f'{self.number}...{san}'

    def push(self, move):
        board = self.board.copy(stack=False)
        number = self.number + (0 if board.turn == chess.WHITE else 1)
        board.push(move)
        return State(board, number)


def parse_move(state, san, lang, suf=''):
    """O lance, se é legal na posição (e, com "+" ou "#", se dá xeque ou mate)."""
    try:
        move = state.board.parse_san(to_chess_san(san, lang))
    except ValueError:
        return None
    if suf.startswith(('+', '#')):
        board = state.board.copy(stack=False)
        board.push(move)
        if not board.is_check() or (suf.startswith('#') and not board.is_checkmate()):
            return None
    return move


# ---------------------------------------------------------------- partidas

def game_plies(url):
    """FENs (só peças e vez) de cada ply da partida da url do Lichess."""
    m = re.match(r'https://lichess\.org/analysis/pgn/([^#]+)', url or '')
    if not m:
        return None
    board = chess.Board()
    out = [board.fen().split(' ')[:2]]
    for san in urllib.parse.unquote(m.group(1)).split('_'):
        if not san:
            continue
        try:
            board.push_san(san)
        except ValueError:
            break
        out.append(board.fen().split(' ')[:2])
    return out


def url_ply(url):
    m = re.search(r'#(\d+)$', url or '')
    return int(m.group(1)) if m else None


def start_number(fen, ref, refs, warnings, where):
    """Número do primeiro lance a partir do FEN: o da partida, se o passo aponta uma."""
    board = chess.Board(fen)
    if not ref:
        return State(board, 1)
    rid, _, ply = ref.partition('#')
    r = refs.get(rid)
    if not r or r.get('kind') != 'game':
        return State(board, 1)
    plies = game_plies(r.get('url'))
    ply = int(ply) if ply else url_ply(r.get('url'))
    key = fen.split(' ')[:2]
    if plies is None:
        if ply is not None:
            return State(board, ply // 2 + 1)
        warnings.append(f'{where}: partida `{rid}` sem url de PGN; numerando a partir de 1')
        return State(board, 1)
    if ply is not None and ply < len(plies) and plies[ply] == key:
        return State(board, ply // 2 + 1)
    found = [i for i, p in enumerate(plies) if p == key]
    if found:
        warnings.append(f'{where}: FEN é o ply {found[0]} de `{rid}`, não o {ply}')
        return State(board, found[0] // 2 + 1)
    if ply is not None:
        warnings.append(f'{where}: FEN não aparece em `{rid}`; usando o ply {ply}')
        return State(board, ply // 2 + 1)
    return State(board, 1)


def origin_number(fen, origin, refs):
    r = refs.get(origin or '')
    board = chess.Board(fen)
    if r and r.get('kind') == 'game':
        plies = game_plies(r.get('url')) or []
        key = fen.split(' ')[:2]
        found = [i for i, p in enumerate(plies) if p == key]
        if found:
            return State(board, found[0] // 2 + 1)
    return State(board, 1)


# ---------------------------------------------------------------- contexto

def line_states(state, ucis):
    """Posições ao longo da linha; `None` na lista é a resposta `auto` da tabela, que
    aqui vira uma resposta qualquer que deixe legal o lance seguinte (o número é o mesmo)."""
    out = [state]
    for i, uci in enumerate(ucis):
        if uci is None:
            nxt = ucis[i + 1] if i + 1 < len(ucis) else None
            if nxt is None:
                break
            want = chess.Move.from_uci(nxt)
            reply = next((r for r in state.board.legal_moves
                          if want in state.push(r).board.legal_moves), None)
            if reply is None:
                break
            state = state.push(reply)
            out.append(state)
            continue
        move = chess.Move.from_uci(uci)
        if move not in state.board.legal_moves:
            break
        state = state.push(move)
        out.append(state)
    return out


def turn_ucis(turns):
    ucis = []
    for turn in turns:
        ucis.append(turn['teach'])
        if turn.get('reply'):
            ucis.append(None if turn['reply'] == 'auto' else turn['reply'])
    return ucis


PRELUDE = re.compile(r'(?:depois de|after) (\d+)(\.\.\.|\.)([^\s,;:]+?)[!?]*(?: ([^\s,;:]+?)[!?]*)?[.,;:]')


def prelude(state, text):
    """"Linha de Silman, depois de 1.Tc1 Re7": a posição vem depois de lances numerados
    citados na própria fala (em pt) do passo ou do enunciado; a numeração continua deles."""
    m = PRELUDE.search(text or '')
    if not m:
        return state
    number, dots, first, second = int(m[1]), m[2], m[3], m[4]
    last_black = bool(second) or dots != '.'
    last = second or first
    sq = re.search(r'([a-h][1-8])(=.)?[+#]?$', last)
    mover = chess.BLACK if last_black else chess.WHITE
    if not sq or state.board.turn == mover:
        return state
    piece = state.board.piece_at(chess.parse_square(sq[1]))
    letter = PIECES['pt'].get(last[0], 'P') if last[0].isupper() else 'P'
    kind = chess.Piece.from_symbol(letter).piece_type
    if not piece or piece.color != mover or piece.piece_type != kind:
        return state
    return State(state.board, number + 1 if last_black else number)


def contexts(source, warnings, texts=None):
    """Chave da fala (sem o idioma) -> (posições conhecidas, posição do lance K ou None).
    `texts` (as falas em pt) servem para achar o prelúdio de cada posição."""
    texts = texts or {}
    refs = {r['id']: r for r in source.get('references', [])}
    ctx = {}
    steps = [s for p in source.get('parts', []) for s in p['steps']] + source.get('steps', [])
    for step in steps:
        if 'fen' not in step:
            continue
        sid = step['id']
        start = start_number(step['fen'], step.get('ref'), refs, warnings, f'step.{sid}')
        start = prelude(start, texts.get(f'step.{sid}'))
        if step['type'] == 'demo':
            states = line_states(start, [m['uci'] for m in step['line']])
            ctx[f'step.{sid}'] = (states, None)
            for k in range(1, len(step['line']) + 1):
                ctx[f'step.{sid}.m{k}'] = (states, k - 1)
            continue
        states = line_states(start, turn_ucis(step.get('turns', [])))
        for suffix in ('', '.hint', '.done', '.hint1', '.hint2', '.hint3'):
            ctx[f'step.{sid}{suffix}'] = (states, None)
    for ex in source.get('exercises', []):
        start = prelude(origin_number(ex['fen'], ex.get('origin'), refs), texts.get(f'ex.{ex["id"]}'))
        states = line_states(start, turn_ucis(ex.get('turns', [])))
        for suffix in ('', '.hint', '.solution'):
            ctx[f'ex.{ex["id"]}{suffix}'] = (states, None)
    if source.get('practice', {}).get('fen'):
        ctx['practice'] = ([State(chess.Board(source['practice']['fen']), 1)], None)
    return ctx


# ---------------------------------------------------------------- conferência

def skip_one(st, san, lang, suf=''):
    """Posição depois de uma resposta qualquer do outro lado em que o lance é legal."""
    for reply in st.board.legal_moves:
        nxt = st.push(reply)
        if parse_move(nxt, san, lang, suf):
            return nxt
    return None


def ply_index(number, side):
    return 2 * number + (0 if side == 'w' else 1)


def reach(st, number, side, san, lang, suf, depth=3):
    """Posição com o número e o lado pedidos, a até `depth` meios-lances de `st` (lances
    quaisquer no meio), em que o lance é legal: "1...Rc7 e 2...Rd7; 2.Rg5 e 3.Rf6".
    """
    gap = ply_index(number, side) - ply_index(st.number, st.side)
    if gap <= 0 or gap > depth:
        return None
    frontier = [st]
    for _ in range(gap):
        frontier = [x.push(mv) for x in frontier for mv in x.board.legal_moves]
        if len(frontier) > 20000:
            return None
    return next((x for x in frontier if parse_move(x, san, lang, suf)), None)


def designates(san, lang, states):
    """Letra de peça e casa em que essa peça já está: nome da peça, não lance."""
    if not re.fullmatch(r'[A-Z][a-h][1-8]', san) or san.startswith('O'):
        return False
    piece = chess.Piece.from_symbol(PIECES[lang][san[0]]).piece_type
    square = chess.parse_square(san[1:])
    return any(st.board.piece_type_at(square) == piece for st in states if st)


def is_demo_move(states, current, san, lang):
    if current is None or current + 1 >= len(states):
        return False
    move = parse_move(states[current], san, lang)
    return bool(move) and states[current].push(move).board == states[current + 1].board


def check_text(key, text, lang, states, current):
    """Problemas de uma fala: lista de (posição no texto, mensagem, sugestão ou None).

    A sugestão sai da primeira posição em que o lance é legal, nesta ordem: a do lance
    do demo que a fala comenta, a depois do último lance lido, a de antes dele (uma
    alternativa ao mesmo lance), as da linha do passo; e, por último, uma resposta
    qualquer do outro lado adiante (marcada como provável)."""
    problems = []
    chain = prev = None   # posição depois do último lance lido e a de antes dele
    prev_end = None       # fim do último lance lido
    prev_white_numbered = False

    def advance(st, move):
        nonlocal chain, prev
        prev, chain = st, st.push(move)

    intro = [p.span() for p in PRELUDE.finditer(text)
             if states and int(p[1]) < states[0].number]
    for m in token_re(lang).finditer(text):
        san, suf = m['san'], m['suf']
        if any(a <= m.start() < b for a, b in intro):
            continue  # o prelúdio: lances de antes da posição
        # lance de peão sem captura nem promoção se confunde com casa ("fecha g8");
        # conta como lance com número, sinal, continuação de par ou se abre a fala do lance do demo
        pawn_push = (re.fullmatch(r'[a-h][1-8]', san) is not None
                     and not (text[:m.start()].strip() == ''
                              and is_demo_move(states, current, san, lang)))
        gap = text[prev_end:m.start()] if prev_end is not None else None
        continuation = (gap is not None and gap.strip() == '' and prev_white_numbered
                        and m['num'] is None)
        numbered = m['n'] is not None
        if pawn_push and not (numbered or suf or continuation or m['num']):
            continue  # casa solta
        if not numbered and OWNER.search(text[:m.start()]):
            continue  # "o peão de a6?", "the pawn on a6": a peça, não o lance
        if (pawn_push and not (numbered or continuation or m['num']) and suf == '?'
                and re.match(r'\s*($|[A-ZÀ-Ý])', text[m.end():])):
            continue  # "Quem vigia c6?": casa no fim de uma pergunta
        prev_end = m.end()
        if numbered:
            number = int(m['n'])
            side = 'w' if m['dots'] == '.' else 'b'
            base = [st for st in [chain, prev] if st] + states
            anchors = list(base)
            if states:  # "se fosse a vez das brancas, 1.g6!": a posição com a vez trocada
                flipped = states[0].board.copy(stack=False)
                flipped.turn = not flipped.turn
                if flipped.is_valid():
                    anchors.append(State(flipped, states[0].number))
            for st in base:
                nxt = reach(st, number, side, san, lang, suf)
                if nxt:
                    anchors.append(nxt)
            hit = next((st for st in anchors if st.number == number and st.side == side
                        and parse_move(st, san, lang, suf)), None)
            if hit is None:
                legal = [st for st in base if parse_move(st, san, lang, suf)]
                # número longe de toda posição da fala: lance de outra partida citado
                near = any(abs(st.number - number) <= 2 for st in base)
                if legal and near:
                    problems.append((m.start(), f'{m.group(0)}: número errado, '
                                     f'o certo é {legal[0].label(san)}', None))
                chain = prev = None
            else:
                advance(hit, parse_move(hit, san, lang, suf))
            prev_white_numbered = side == 'w'
            continue
        if continuation:
            move = parse_move(chain, san, lang, suf) if chain else None
            if move:
                advance(chain, move)
            else:
                chain = prev = None
            prev_white_numbered = False
            continue
        # sem número e fora de um par: sugerir o número pela posição
        order = [states[current]] if current is not None else []
        order += [st for st in [chain, prev] if st] + states
        if m['num']:  # "...Rc6": lance das pretas sem o número
            order = [st for st in order if st.side == 'b']
        st = next((st for st in order if parse_move(st, san, lang, suf)), None)
        sure = st is not None
        if st is None:
            for base in [chain] + states[-1:]:
                if base is not None:
                    st = skip_one(base, san, lang, suf)
                    if st and (not m['num'] or st.side == 'b'):
                        break
                    st = None
        if st is None and not m['num'] and designates(san, lang, [chain, prev] + states):
            continue  # "defendida por Rf3": a peça que já está na casa, não um lance
        label = f'"{m.group(0)}" sem número'
        if st:
            hint = st.label(san)
            label += f'; sugestão: {hint}' + ('' if sure else ' (provável)')
            advance(st, parse_move(st, san, lang, suf))
        else:
            hint = None
            chain = prev = None
        problems.append((m.start(), label, hint))
        prev_white_numbered = False
    return problems


def check_lesson(lesson_id):
    source = json.loads((SRC / f'{lesson_id}.json').read_text())
    warnings = []
    pt = json.loads((TEXTS / 'pt' / 'endgames' / f'{lesson_id}.json').read_text())
    ctx = contexts(source, warnings, pt)
    found = 0
    for lang in LANGS:
        texts = json.loads((TEXTS / lang / 'endgames' / f'{lesson_id}.json').read_text())
        for key, text in texts.items():
            if SKIP_KEY.match(key) or not isinstance(text, str):
                continue
            states, current = ctx.get(key, ([], None))
            for pos, msg, _ in check_text(key, text, lang, states, current):
                found += 1
                around = text[max(0, pos - 30):pos + 40].replace('\n', ' ')
                print(f'{lesson_id} [{lang}] {key}: {msg}\n    …{around}…')
    for w in warnings:
        print(f'{lesson_id} aviso: {w}')
    return found


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('ids', nargs='+')
    args = parser.parse_args()
    total = sum(check_lesson(i) for i in args.ids)
    print(f'{total} lance(s) sem número ou com número errado' if total else 'numeração ok')
    sys.exit(1 if total else 0)


if __name__ == '__main__':
    main()
