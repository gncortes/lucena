#!/usr/bin/env python3
"""Confere o mapa de habilidades do teste de nível e grava o asset.

Lê a fonte `tools/placement/skills.json` e confere:

- todo nó tem id único, grupo e faixa válidos;
- todo pré-requisito existe e não há ciclo;
- toda aula existe: `school` em `assets/lessons/course.json`, `endgame` em
  `assets/lessons/endgames/index.json`, `catalog` no catálogo da skill
  `aula-final` e ainda não feita, `new` na lista das aulas novas da T52
  (Partes 6.1 e 6.2);
- toda aula de final feita tem `skills` (os nós que ensina), e o campo bate
  com o mapa: a aula está em `lessons` de um nó se e só se o nó está nos
  `skills` dela;
- o asset `assets/placement/skills.json` está igual ao gerado pela fonte.

Uso:

    python3 tools/placement/check_skills.py           # só confere (CI)
    python3 tools/placement/check_skills.py --write   # grava o asset
"""

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tools' / 'placement' / 'skills.json'
ASSET = ROOT / 'assets' / 'placement' / 'skills.json'
COURSE = ROOT / 'assets' / 'lessons' / 'course.json'
ENDGAMES = ROOT / 'assets' / 'lessons' / 'endgames' / 'index.json'
CATALOG = ROOT / '.claude' / 'skills' / 'aula-final' / 'catalogo.md'

GROUPS = ('rules', 'mates', 'pawns', 'queenRook', 'minor', 'tactics')
# Os nomes de `RatingLevel` (lib/domain/models/rating_level.dart), em ordem.
BANDS = ('beginner', 'casual', 'intermediate', 'advanced', 'expert', 'master')
KINDS = ('school', 'endgame', 'catalog', 'new')
# Aulas novas propostas na T52: escola (6.1) e módulo de táticas de final (6.2).
NEW_LESSONS = {
    'rules.captureProtect', 'rules.outOfCheck', 'rules.castling',
    'rules.enPassant', 'rules.pieceValue', 'rules.draws',
    'tactics.matePatterns', 'tactics.saavedra', 'tactics.endgameTricks',
}
NODE_ID = re.compile(r'^[a-z][a-zA-Z]*(\.[a-z][a-zA-Z]*)+$')
CATALOG_ID = re.compile(r'^\|[^|]+\|\s*`([^`]+)`\s*\|')


def school_lessons():
    course = json.loads(COURSE.read_text())
    return {lesson['id'] for module in course['modules']
            for lesson in module['lessons']}


def endgame_lessons():
    index = json.loads(ENDGAMES.read_text())
    return {lesson for module in index['modules']
            for lesson in module['lessons']}


def catalog_lessons():
    ids = set()
    for line in CATALOG.read_text().splitlines():
        match = CATALOG_ID.match(line)
        if match:
            ids.add(match.group(1))
    return ids


def arb_key(node_id):
    """`rules.bishop` → `skillRulesBishop` (o nome do nó no `.arb`)."""
    return 'skill' + ''.join(part[0].upper() + part[1:]
                             for part in node_id.split('.'))


def find_cycle(nodes):
    """Um ciclo nos pré-requisitos, ou None."""
    requires = {node['id']: node.get('requires', []) for node in nodes}
    state = {}

    def visit(node_id, path):
        state[node_id] = 'open'
        for parent in requires.get(node_id, []):
            if state.get(parent) == 'open':
                return path + [node_id, parent]
            if parent in requires and parent not in state:
                cycle = visit(parent, path + [node_id])
                if cycle:
                    return cycle
        state[node_id] = 'done'
        return None

    for node_id in requires:
        if node_id not in state:
            cycle = visit(node_id, [])
            if cycle:
                return cycle
    return None


def check(source):
    problems = []
    nodes = source.get('nodes') or []
    if not nodes:
        return ['o mapa não tem nós']
    ids = [node.get('id') for node in nodes]
    known = set(ids)
    for node_id in sorted({i for i in ids if ids.count(i) > 1}):
        problems.append(f'{node_id}: id repetido')

    school = school_lessons()
    endgame = endgame_lessons()
    catalog = catalog_lessons()

    for node in nodes:
        node_id = node.get('id')
        where = node_id or '(sem id)'
        if not node_id or not NODE_ID.match(node_id):
            problems.append(f'{where}: id inválido')
        if node.get('group') not in GROUPS:
            problems.append(f"{where}: grupo {node.get('group')!r} inválido")
        if node.get('band') not in BANDS:
            problems.append(f"{where}: faixa {node.get('band')!r} inválida")
        if not isinstance(node.get('midgameTactic', False), bool):
            problems.append(f'{where}: midgameTactic precisa ser true ou false')
        for parent in node.get('requires', []):
            if parent not in known:
                problems.append(f'{where}: pré-requisito {parent!r} não existe')
            if parent == node_id:
                problems.append(f'{where}: é pré-requisito de si mesmo')
        lessons = node.get('lessons') or []
        if not lessons:
            problems.append(f'{where}: sem aula')
        for lesson in lessons:
            lesson_id, kind = lesson.get('id'), lesson.get('kind')
            if kind not in KINDS:
                problems.append(f'{where}: aula {lesson_id!r} com tipo '
                                f'{kind!r} inválido')
            elif kind == 'school' and lesson_id not in school:
                problems.append(f'{where}: {lesson_id!r} não é aula da escola '
                                '(assets/lessons/course.json)')
            elif kind == 'endgame' and lesson_id not in endgame:
                problems.append(f'{where}: {lesson_id!r} não é aula de final '
                                'feita (assets/lessons/endgames/index.json)')
            elif kind == 'catalog':
                if lesson_id not in catalog:
                    problems.append(f'{where}: {lesson_id!r} não está no '
                                    'catálogo (catalogo.md)')
                elif lesson_id in endgame:
                    problems.append(f'{where}: {lesson_id!r} já foi feita; '
                                    "troque o tipo para 'endgame'")
            elif kind == 'new' and lesson_id not in NEW_LESSONS:
                problems.append(f'{where}: {lesson_id!r} não é uma das aulas '
                                'novas da T52 (6.1 e 6.2)')
            elif kind == 'new' and (lesson_id in school
                                    or lesson_id in endgame):
                problems.append(f'{where}: {lesson_id!r} já existe; troque o '
                                'tipo da aula')

    taught = {}
    for node in nodes:
        for lesson in node.get('lessons') or []:
            if lesson.get('kind') == 'endgame':
                taught.setdefault(lesson['id'], set()).add(node.get('id'))
    for lesson_id in sorted(endgame):
        path = ENDGAMES.parent / f'{lesson_id}.json'
        skills = json.loads(path.read_text()).get('skills')
        if not skills:
            problems.append(f'{lesson_id}: aula de final sem o campo skills')
            continue
        for skill in sorted(set(skills) - known):
            problems.append(f'{lesson_id}: skills cita {skill!r}, que não é '
                            'nó do mapa')
        for skill in sorted(set(skills) & known - taught.get(lesson_id, set())):
            problems.append(f'{lesson_id}: skills cita {skill!r}, mas o nó '
                            'não lista a aula')
        for skill in sorted(taught.get(lesson_id, set()) - set(skills)):
            problems.append(f'{skill}: lista a aula {lesson_id!r}, mas ela '
                            'não cita o nó em skills')

    cycle = find_cycle(nodes)
    if cycle:
        problems.append('ciclo nos pré-requisitos: ' + ' → '.join(cycle))
    return problems


def render(source):
    """O asset: os nós na ordem da fonte, com `midgameTactic` explícito."""
    nodes = []
    for node in source['nodes']:
        nodes.append({
            'id': node['id'],
            'group': node['group'],
            'band': node['band'],
            'requires': node.get('requires', []),
            'lessons': node['lessons'],
            'midgameTactic': node.get('midgameTactic', False),
        })
    return json.dumps({'nodes': nodes}, ensure_ascii=False, indent=2) + '\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--write', action='store_true',
                        help='grava assets/placement/skills.json')
    args = parser.parse_args()

    source = json.loads(SOURCE.read_text())
    problems = check(source)
    if problems:
        print('Problemas no mapa de habilidades:', *problems, sep='\n- ')
        return 1
    rendered = render(source)
    if args.write:
        ASSET.parent.mkdir(parents=True, exist_ok=True)
        ASSET.write_text(rendered)
        print(f'Gerado {ASSET.relative_to(ROOT)}')
    elif not ASSET.exists() or ASSET.read_text() != rendered:
        print(f'{ASSET.relative_to(ROOT)} desatualizado: rode '
              'python3 tools/placement/check_skills.py --write')
        return 1
    count = len(source['nodes'])
    print(f'Mapa de habilidades OK: {count} nós.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
