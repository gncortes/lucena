#!/usr/bin/env python3
"""Um brief por sessão, com papel explícito e resultados ignorados pelo Git."""
import argparse
import fcntl
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import tomllib

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('role')
parser.add_argument('brief', type=Path)
parser.add_argument('--timeout', type=int, default=600, help='Limite de duração em segundos')
args = parser.parse_args()
if args.timeout <= 0:
    parser.error('Timeout deve ser positivo')
root = Path(__file__).resolve().parents[2]
assert args.role.replace('_', '').isalnum(), 'Nome de papel inválido'
paths = [root / '.codex/agents' / (args.role + '.toml'), Path.home() / '.codex/agents' / (args.role + '.toml')]
role_path = next((p for p in paths if p.is_file()), None)
if role_path is None:
    parser.error('Papel não encontrado')
a = tomllib.loads(role_path.read_text())
brief = args.brief.read_text()
if not brief.strip():
    parser.error('Brief vazio')
out = root / '.codex/local/briefs' / (datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ') + '-' + args.role)
out.mkdir(parents=True)
command = ['codex', 'exec', '--strict-config', '--ephemeral', '-C', str(root), '-s', a.get('sandbox_mode', 'read-only'), '-m', a['model'], '-c', 'model_reasoning_effort=' + json.dumps(a['model_reasoning_effort']), '-c', 'developer_instructions=' + json.dumps(a['developer_instructions'], ensure_ascii=False), '-c', 'agents.enabled=false', '--json', '-o', str(out / 'result.md'), '-']
(out / 'metadata.json').write_text(json.dumps({'role': a['name'], 'model': a['model'], 'effort': a['model_reasoning_effort'], 'brief': str(args.brief.resolve())}, indent=2))
# Processos CLI independentes não compartilham o limite nativo da sessão.
# Este runner é sequencial por projeto; não criar uma fila paralela oculta.
with (root / '.codex/local/briefs.lock').open('a') as lock:
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        parser.error('Já existe um brief deste projeto em execução')
    with (out / 'events.jsonl').open('w') as events, (out / 'stderr.log').open('w') as errors:
        try:
            result = subprocess.run(command, input=brief, text=True, cwd=root,
                                    stdout=events, stderr=errors, timeout=args.timeout)
        except subprocess.TimeoutExpired:
            print(f'Tempo excedido ({args.timeout}s); resultados parciais: {out}')
            raise SystemExit(124)
print(f'Exit={result.returncode}; resultados: {out}')
raise SystemExit(result.returncode)
