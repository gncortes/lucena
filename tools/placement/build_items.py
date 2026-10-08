#!/usr/bin/env python3
"""Confere e monta o banco de perguntas do teste de nível (T52, Parte 3).

Junta os itens próprios (`tools/placement/items.json`, gerados por
`make_own_items.py`) e os puzzles do Lichess (`tools/placement/
lichess_items.json`, gerados por `import_puzzles.py`) em
`assets/placement/items.json`, conferindo:

- formato: id único, nó do mapa (`assets/placement/skills.json`), tipo,
  enunciado (chave `placement*` do `app_en.arb`) com os parâmetros certos,
  opções (chaves `placementOption*`, de 2 a 4) e resposta entre elas;
- xadrez (com o python-chess): FEN válido (sem reis só nas perguntas de casas,
  como na escola), casas certas iguais às do gerador de lances, linha legal,
  todo lance aceito legal, resposta das perguntas de regra recalculada;
- com `--tablebase`: veredito e lances aceitos de novo pela tabela de finais
  do Lichess (cache em `tools/.cache/`);
- cotas (3.3): pelo menos 6 itens por nó das tabelas 2.1 a 2.3 e 4 por nó das
  tabelas 2.4 a 2.7, salvo os nós isentos (lista abaixo, com o motivo); e a
  dificuldade cobrindo de 400 a 2600 sem buracos de mais de 200 pontos.

Uso:

    python3 tools/placement/build_items.py              # confere e grava
    python3 tools/placement/build_items.py --check      # só confere (CI)
    python3 tools/placement/build_items.py --tablebase  # e a tabela
"""

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OWN = ROOT / 'tools' / 'placement' / 'items.json'
LICHESS = ROOT / 'tools' / 'placement' / 'lichess_items.json'
SKILLS = ROOT / 'assets' / 'placement' / 'skills.json'
ASSET = ROOT / 'assets' / 'placement' / 'items.json'
ARB = ROOT / 'lib' / 'l10n' / 'app_en.arb'

TYPES = ('squares', 'move', 'choice')
# Enunciados e os parâmetros que cada um pede.
PROMPTS = {
    'placementSquares': {'piece'},
    'placementCaptureSquares': {'piece'},
    'placementKingEscape': {'side'},
    'placementTapSquare': {'square'},
    'placementPlayMove': {'move', 'side'},
    'placementCheckmate': {'side'},
    'placementBestMove': {'side'},
    'placementMoveWin': {'side'},
    'placementMoveDraw': {'side'},
    'placementWinMaterial': {'side'},
    'placementCheckMateNone': {'side'},
    'placementMateStalemateNone': {'side'},
    'placementCanCastle': {'side', 'wing'},
    'placementCanEnPassant': {'side'},
    'placementInsufficient': set(),
    'placementCatchPawn': {'side', 'king'},
    'placementResult': {'side'},
}
PARAM_VALUES = {
    'piece': {'king', 'queen', 'rook', 'bishop', 'knight', 'pawn'},
    'side': {'white', 'black'},
    'king': {'white', 'black'},
    'wing': {'king', 'queen'},
}
OPTIONS = ('mate', 'stalemate', 'check', 'none', 'yes', 'no', 'whiteWins',
           'draw', 'blackWins')
SQUARE = re.compile(r'^[a-h][1-8]$')
UCI = re.compile(r'^[a-h][1-8][a-h][1-8][qrbn]?$')

# Grupos das tabelas 2.1 a 2.3 (cota 6) e 2.4 a 2.7 (cota 4).
QUOTA = {'rules': 6, 'mates': 6, 'pawns': 6, 'queenRook': 4, 'minor': 4,
         'tactics': 4}
# Nós sem itens por enquanto, com o motivo. Saem daqui quando a aula do
# catálogo for feita (as posições-chave dela viram itens).
EXEMPT = {
    'pawns.shoulder': 'catálogo, sem aula; o ombro não se reconhece por '
                      'script sem falso positivo (o lance certo é de rei, '
                      'como em toda corrida) e os puzzles do Lichess não têm '
                      'tema próprio',
    'pawns.spareTempi': 'catálogo (expert), sem aula; tempo de reserva não '
                        'tem tema no Lichess nem critério por script',
    'pawns.correspondingSquares': 'catálogo (master), sem aula; casas '
                                  'correspondentes pedem posições de estudo '
                                  'com mais de 7 peças ou análise manual',
}
# Faixas de dificuldade (RatingLevel) e o mínimo de itens em cada uma.
BANDS = [('beginner', 0, 999), ('casual', 1000, 1299),
         ('intermediate', 1300, 1599), ('advanced', 1600, 1899),
         ('expert', 1900, 2199), ('master', 2200, 9999)]
BAND_MIN = 20
COVER_LOW, COVER_HIGH, MAX_GAP = 400, 2600, 200

# Campos que vão para o asset (o resto, como a origem e o critério da
# dificuldade, fica só na fonte, para revisão).
ASSET_FIELDS = ('id', 'node', 'type', 'difficulty', 'fen', 'lastMove',
                'prompt', 'params', 'squares', 'moves', 'accept', 'options',
                'answer', 'source', 'themes')


def load_items():
    own = json.loads(OWN.read_text())['items']
    lichess_data = json.loads(LICHESS.read_text())
    return own + lichess_data['items'], lichess_data.get('sources', '')


def check_format(items, nodes, arb):
    problems = []
    ids = [item.get('id') for item in items]
    for item_id in sorted({i for i in ids if ids.count(i) > 1}):
        problems.append(f'{item_id}: id repetido')
    for item in items:
        where = item.get('id', '(sem id)')
        kind = item.get('type')
        if item.get('node') not in nodes:
            problems.append(f"{where}: nó {item.get('node')!r} não existe")
        if kind not in TYPES:
            problems.append(f'{where}: tipo {kind!r} inválido')
            continue
        if item.get('source') not in ('own', 'lichess'):
            problems.append(f"{where}: source {item.get('source')!r}")
        difficulty = item.get('difficulty')
        if not isinstance(difficulty, int) or not 300 <= difficulty <= 3000:
            problems.append(f'{where}: dificuldade {difficulty!r}')
        prompt = item.get('prompt')
        if prompt not in PROMPTS:
            problems.append(f'{where}: enunciado {prompt!r} desconhecido')
        elif prompt not in arb:
            problems.append(f'{where}: {prompt} não está no app_en.arb')
        else:
            params = item.get('params') or {}
            if set(params) != PROMPTS[prompt]:
                problems.append(f'{where}: parâmetros {sorted(params)} '
                                f'(o enunciado pede {sorted(PROMPTS[prompt])})')
            for key, value in params.items():
                if key in PARAM_VALUES and value not in PARAM_VALUES[key]:
                    problems.append(f'{where}: {key}={value!r} inválido')
            if 'square' in params and not SQUARE.match(params['square']):
                problems.append(f'{where}: casa {params["square"]!r}')
        if kind == 'squares':
            squares = item.get('squares') or []
            if not squares or not all(SQUARE.match(s) for s in squares):
                problems.append(f'{where}: casas {squares!r}')
        elif kind == 'move':
            moves, accept = item.get('moves') or [], item.get('accept') or []
            if not moves or not all(UCI.match(m) for m in moves):
                problems.append(f'{where}: linha {moves!r}')
            if len(accept) != (len(moves) + 1) // 2:
                problems.append(f'{where}: accept com {len(accept)} vezes '
                                f'para {len(moves)} lances')
            for turn, options in enumerate(accept):
                if not options or not all(UCI.match(m) for m in options):
                    problems.append(f'{where}: accept[{turn}] {options!r}')
                elif 2 * turn < len(moves) and moves[2 * turn] not in options:
                    problems.append(f'{where}: o lance da linha '
                                    f'{moves[2 * turn]} não está em '
                                    f'accept[{turn}]')
        else:
            options = item.get('options') or []
            if not 2 <= len(options) <= 4 or len(set(options)) != len(options):
                problems.append(f'{where}: opções {options!r}')
            for option in options:
                if option not in OPTIONS:
                    problems.append(f'{where}: opção {option!r} desconhecida')
                elif option_key(option) not in arb:
                    problems.append(f'{where}: {option_key(option)} não está '
                                    'no app_en.arb')
            if item.get('answer') not in options:
                problems.append(f"{where}: resposta {item.get('answer')!r} "
                                'fora das opções')
        if item.get('source') == 'lichess' and not item.get('themes'):
            problems.append(f'{where}: puzzle sem temas')
    return problems


def option_key(option):
    return 'placementOption' + option[0].upper() + option[1:]


def check_chess(items, tablebase):
    """Recalcula as respostas com o python-chess (e a tabela, se pedida)."""
    import chess
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from placement_chess import board_ok, mating_moves  # noqa: E402

    tb = None
    if tablebase:
        from placement_chess import Tablebase
        tb = Tablebase()

    problems = []
    for item in items:
        where = item['id']
        try:
            board = chess.Board(item['fen'])
        except ValueError:
            problems.append(f'{where}: FEN ilegível')
            continue
        kind, prompt = item['type'], item['prompt']
        kingless = kind == 'squares' and prompt in (
            'placementSquares', 'placementCaptureSquares',
            'placementTapSquare')
        if not board_ok(board, kingless=kingless):
            problems.append(f'{where}: FEN inválido ({board.status()!r})')
            continue
        side = item.get('params', {}).get('side')
        if side and side != ('white' if board.turn else 'black'):
            problems.append(f'{where}: side={side} mas a vez é do outro lado')
        if item.get('lastMove'):
            # O último lance tem de levar à posição: confere de trás para
            # frente só o básico (a peça está na casa de chegada).
            last = chess.Move.from_uci(item['lastMove'])
            piece = board.piece_at(last.to_square)
            if piece is None or piece.color == board.turn:
                problems.append(f'{where}: lastMove não bate com a posição')
        if kind == 'squares':
            expected = expected_squares(board, item)
            if expected != sorted(item['squares']):
                problems.append(f'{where}: casas {item["squares"]} ≠ '
                                f'{expected}')
        elif kind == 'move':
            problems += check_line(board, item, tb, mating_moves)
        else:
            problems += check_choice(board, item, tb)
    return problems


def expected_squares(board, item):
    import chess
    prompt = item['prompt']
    if prompt == 'placementTapSquare':
        return [item['params']['square']]
    if prompt == 'placementKingEscape':
        king = board.king(board.turn)
        return sorted({chess.square_name(m.to_square)
                       for m in board.legal_moves if m.from_square == king})
    pieces = [s for s, p in board.piece_map().items()
              if p.color == board.turn
              and chess.piece_name(p.piece_type) == item['params']['piece']]
    if len(pieces) != 1:
        return ['(a peça do enunciado precisa ser única)']
    moves = [m for m in board.legal_moves if m.from_square == pieces[0]]
    if prompt == 'placementCaptureSquares':
        moves = [m for m in moves if board.is_capture(m)]
    return sorted({chess.square_name(m.to_square) for m in moves})


def check_line(board, item, tb, mating_moves):
    import chess
    where, problems = item['id'], []
    board = board.copy()
    for index, uci in enumerate(item['moves']):
        if index % 2 == 0:
            accept = item['accept'][index // 2]
            last = index == len(item['moves']) - 1
            for option in accept:
                if chess.Move.from_uci(option) not in board.legal_moves:
                    problems.append(f'{where}: aceito {option} é ilegal')
            if item['prompt'] == 'placementCheckmate' and last:
                mates = mating_moves(board)
                if sorted(accept) != mates:
                    problems.append(f'{where}: mates {mates} ≠ aceitos '
                                    f'{sorted(accept)}')
            if tb and item['source'] == 'own' and chess.popcount(
                    board.occupied) <= 7 and item['prompt'] in (
                    'placementMoveWin', 'placementMoveDraw',
                    'placementBestMove'):
                goal = 'draw' if item['prompt'] == 'placementMoveDraw' \
                    else 'win'
                good = tb.good_moves(board, goal)
                for option in accept:
                    if option not in good:
                        problems.append(f'{where}: {option} não mantém '
                                        f'{goal} (tabela)')
        move = chess.Move.from_uci(uci)
        if move not in board.legal_moves:
            problems.append(f'{where}: lance {index + 1} ({uci}) ilegal')
            break
        board.push(move)
    return problems


def check_choice(board, item, tb):
    import chess
    where, prompt, answer = item['id'], item['prompt'], item['answer']
    expected = None
    if prompt == 'placementCheckMateNone':
        expected = ('mate' if board.is_checkmate() else
                    'check' if board.is_check() else
                    'none' if not board.is_stalemate() else 'stalemate')
    elif prompt == 'placementMateStalemateNone':
        expected = ('mate' if board.is_checkmate() else
                    'stalemate' if board.is_stalemate() else 'none')
    elif prompt == 'placementCanCastle':
        rank = '1' if board.turn else '8'
        target = 'g' if item['params']['wing'] == 'king' else 'c'
        move = chess.Move.from_uci(f'e{rank}{target}{rank}')
        expected = 'yes' if move in board.legal_moves else 'no'
    elif prompt == 'placementCanEnPassant':
        expected = 'yes' if any(board.is_en_passant(m)
                                for m in board.legal_moves) else 'no'
    elif prompt == 'placementInsufficient':
        expected = 'yes' if board.is_insufficient_material() else 'no'
    elif tb and prompt in ('placementResult', 'placementCatchPawn'):
        result = tb.result(board)
        expected = result if prompt == 'placementResult' else (
            'yes' if result == 'draw' else 'no')
    if expected is not None and expected != answer:
        return [f'{where}: resposta {answer!r}, mas a posição dá '
                f'{expected!r}']
    return []


def check_quotas(items, skill_nodes):
    problems, counts = [], {}
    for item in items:
        counts[item['node']] = counts.get(item['node'], 0) + 1
    for node in skill_nodes:
        need = QUOTA[node['group']]
        have = counts.get(node['id'], 0)
        if node['id'] in EXEMPT:
            continue
        if have < need:
            problems.append(f"{node['id']}: {have} de {need} itens")
    difficulties = sorted(item['difficulty'] for item in items)
    if difficulties[0] > COVER_LOW:
        problems.append(f'dificuldade mínima {difficulties[0]} > {COVER_LOW}')
    if difficulties[-1] < COVER_HIGH:
        problems.append(f'dificuldade máxima {difficulties[-1]} < '
                        f'{COVER_HIGH}')
    for low, high in zip(difficulties, difficulties[1:]):
        if high - low > MAX_GAP and low < COVER_HIGH:
            problems.append(f'buraco de dificuldade entre {low} e {high}')
    for name, low, high in BANDS:
        have = sum(1 for d in difficulties if low <= d <= high)
        if have < BAND_MIN:
            problems.append(f'faixa {name}: {have} itens (mínimo {BAND_MIN})')
    return problems, counts


def render(items, sources, order):
    items = sorted(items, key=lambda i: (order[i['node']], i['source'],
                                         i['difficulty'], i['id']))
    out = []
    for item in items:
        out.append({key: item[key] for key in ASSET_FIELDS if key in item})
    header = json.dumps({
        'own': ('Itens próprios: posições das aulas do Lucena mexidas por '
                'script e conferidas pelo python-chess e pela tabela de '
                'finais do Lichess (tools/placement/make_own_items.py).'),
        'lichess': sources,
    }, ensure_ascii=False)
    # Um item por linha: o diff do banco fica legível.
    lines = ',\n'.join(json.dumps(item, ensure_ascii=False) for item in out)
    return f'{{"sources": {header},\n"items": [\n{lines}\n]}}\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true',
                        help='só confere (o asset precisa estar em dia)')
    parser.add_argument('--tablebase', action='store_true',
                        help='confere vereditos e lances pela tabela')
    args = parser.parse_args()

    skill_nodes = json.loads(SKILLS.read_text())['nodes']
    nodes = {node['id']: node for node in skill_nodes}
    order = {node['id']: index for index, node in enumerate(skill_nodes)}
    arb = set(json.loads(ARB.read_text()))
    items, sources = load_items()

    problems = check_format(items, nodes, arb)
    try:
        import chess  # noqa: F401
        has_chess = True
    except ImportError:
        has_chess = False
    if has_chess and not problems:
        problems += check_chess(items, args.tablebase)
    elif not has_chess:
        print('Aviso: sem o python-chess; só o formato foi conferido.')
    quota_problems, counts = check_quotas(items, skill_nodes)
    problems += quota_problems

    for node in skill_nodes:
        own = sum(1 for i in items if i['node'] == node['id']
                  and i['source'] == 'own')
        lichess = counts.get(node['id'], 0) - own
        note = ''
        if node['id'] in EXEMPT:
            note = ' (isento)'
        print(f"  {node['id']}: {own} próprios + {lichess} Lichess{note}")
    total_own = sum(1 for i in items if i['source'] == 'own')
    print(f'{len(items)} itens: {total_own} próprios, '
          f'{len(items) - total_own} do Lichess')
    for name, low, high in BANDS:
        have = sum(1 for i in items if low <= i['difficulty'] <= high)
        print(f'  faixa {name}: {have}')

    if problems:
        print('\nProblemas no banco:', *problems, sep='\n- ')
        return 1
    rendered = render(items, sources, order)
    if args.check:
        if not ASSET.exists() or ASSET.read_text() != rendered:
            print(f'{ASSET.relative_to(ROOT)} desatualizado: rode '
                  'python3 tools/placement/build_items.py')
            return 1
        print('Banco OK.')
        return 0
    ASSET.parent.mkdir(parents=True, exist_ok=True)
    ASSET.write_text(rendered)
    print(f'Gerado {ASSET.relative_to(ROOT)}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
