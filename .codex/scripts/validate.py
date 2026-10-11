#!/usr/bin/env python3
"""Validação local sem modelo, rede ou leitura de credenciais."""
import json
from pathlib import Path
import subprocess
import tomllib

root = Path(__file__).resolve().parents[2]
home = Path.home() / '.codex'
snapshot = root / '.codex/local/probe.json'
if snapshot.exists():
    report = json.loads(snapshot.read_text())
    assert not report.get('errors') and not report.get('pending'), 'Probe incompleto ou com erro'
    assert report.get('models'), 'Catálogo vazio'
    assert not report.get('models_next_cursor'), 'Catálogo paginado: consulta incompleta'
    models = {m['id']: set(m['efforts']) for m in report['models']}
    source = 'snapshot autenticado ' + report['checked_at']
else:
    cache = json.loads((home / 'models_cache.json').read_text())
    models = {m['slug']: {e['effort'] for e in m['supported_reasoning_levels']} for m in cache['models']}
    source = 'cache local; acesso atual não verificado'
expected = {'triagem', 'implementador', 'revisor', 'especialista', 'critico',
            'implementador_ux', 'capturador_telas', 'revisor_licoes', 'editor_falas', 'especialista_xadrez'}
found = set()
for base in (home, root / '.codex'):
    config = tomllib.loads((base / 'config.toml').read_text())
    agents = config['agents']
    assert agents['max_concurrent_threads_per_session'] == 3, base
    assert agents['enabled'] is True, base
    assert agents['default_subagent_model'] == 'gpt-6-luna', base
    assert agents['default_subagent_reasoning_effort'] == 'low', base
    for path in (base / 'agents').glob('*.toml'):
        role = tomllib.loads(path.read_text())
        if role.get('name') not in expected:
            continue
        assert role['name'] not in found, f'Papel duplicado: {path}'
        found.add(role['name'])
        assert role['description'] and role['developer_instructions'], path
        assert role['model'] in models, path
        assert role['model_reasoning_effort'] in models[role['model']], path
        assert role['agents']['enabled'] is False, f'Recursão habilitada: {path}'
        assert role['sandbox_mode'] in ('read-only', 'workspace-write'), path
assert found == expected, (found, expected)
for name in ('economico', 'equilibrado', 'complexo', 'critico'):
    profile = tomllib.loads((home / (name + '.config.toml')).read_text())
    assert profile['model_reasoning_effort'] in models[profile['model']], name
for name in ('AGENTS.md', '.codex/config.toml', '.codex/agents/implementador_ux.toml',
             '.codex/scripts/probe.py', '.codex/scripts/validate.py', '.codex/README.md',
             '.agents/skills/example/SKILL.md'):
    result = subprocess.run(['git', 'check-ignore', '-q', '--', name], cwd=root)
    assert result.returncode == 1, f'Estrutura compartilhável indevidamente ignorada: {name}'
for name in ('.codex/local/result.json', '.codex/sessions/session.jsonl', '.codex/auth.json',
             '.codex/cache/item', '.codex/config.local.toml', '.codex/backups/item',
             '.codex/rules/project.rules', '.codex/rules/chess.rules'):
    result = subprocess.run(['git', 'check-ignore', '-q', '--', name], cwd=root)
    assert result.returncode == 0, f'Arquivo pessoal não ignorado: {name}'
subprocess.run(['git', 'diff', '--check', '--', '.gitignore', 'AGENTS.md', '.codex'], cwd=root, check=True)
print('OK: dez papéis, modelos/esforços, quatro perfis, limite=3, filhos sem recursão e regras Git.')
print('Catálogo: ' + source + '. TOML local não prova execução remota dos modelos.')
