#!/usr/bin/env python3
"""Consulta oficial sem turnos de modelo; imprime somente campos operacionais."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import queue
import subprocess
import threading
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, help='Snapshot local opcional (não versionar)')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    requests = {
        2: ('config/read', {'cwd': str(root), 'includeLayers': False}),
        3: ('model/list', {'includeHidden': False}),
        4: ('account/read', {'refreshToken': False}),
        5: ('account/rateLimits/read', {}),
        6: ('skills/list', {'cwds': [str(root)], 'forceReload': True}),
        7: ('account/usage/read', {}),
    }
    replies = {}
    messages = queue.Queue()
    with subprocess.Popen(['codex', 'app-server', '--strict-config', '--stdio'],
                          cwd=root, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                          stderr=subprocess.DEVNULL, text=True) as process:
        def reader():
            for line in process.stdout:
                messages.put(line)
        threading.Thread(target=reader, daemon=True).start()

        def send(value):
            process.stdin.write(json.dumps(value) + '\n')
            process.stdin.flush()

        send({'id': 1, 'method': 'initialize', 'params': {
            'clientInfo': {'name': 'lucena_orchestration_probe', 'version': '1.0'},
            'capabilities': {'experimentalApi': True}}})
        deadline = time.monotonic() + 35
        try:
            while time.monotonic() < deadline:
                try:
                    value = json.loads(messages.get(timeout=0.5))
                except queue.Empty:
                    if process.poll() is not None:
                        break
                    continue
                request_id = value.get('id')
                if request_id == 1:
                    if 'error' in value:
                        raise RuntimeError('Falha ao inicializar app-server')
                    send({'method': 'initialized'})
                    for ident, (method, params) in requests.items():
                        send({'id': ident, 'method': method, 'params': params})
                elif request_id in requests:
                    replies[request_id] = value
                    if len(replies) == len(requests):
                        break
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)

    def result(ident):
        return replies.get(ident, {}).get('result') or {}

    config = result(2).get('config', {})
    account = result(4).get('account') or {}
    limits = result(5)
    buckets = limits.get('rateLimitsByLimitId') or {'default': limits.get('rateLimits')}
    safe_limits = {}
    for name, bucket in buckets.items():
        if not bucket:
            continue
        safe_limits[name] = {key: bucket.get(key) for key in
                             ('planType', 'primary', 'secondary', 'rateLimitReachedType', 'spendControlReached')}
    skills = result(6).get('data', [])
    report = {
        'checked_at': datetime.now(timezone.utc).isoformat(),
        'account': {'type': account.get('type'), 'planType': account.get('planType')},
        'config': {key: config.get(key) for key in ('model', 'model_reasoning_effort', 'agents')},
        'models': [{'id': model['id'], 'efforts': [e['reasoningEffort'] for e in model['supportedReasoningEfforts']],
                    'multiAgentVersion': model.get('multiAgentVersion')}
                   for model in result(3).get('data', [])],
        'models_next_cursor': result(3).get('nextCursor'),
        'ordinaryUsageAllowed': limits.get('ordinaryUsageAllowed'),
        'limits': safe_limits,
        'token_activity': result(7).get('summary'),
        'skills': [{'cwd': entry.get('cwd'),
                    'names': [skill['name'] for skill in entry.get('skills', [])],
                    'error_count': len(entry.get('errors', []))} for entry in skills],
        'errors': {requests[ident][0]: value['error'].get('code') for ident, value in replies.items() if 'error' in value},
        'pending': [requests[ident][0] for ident in requests if ident not in replies],
    }
    # A configuração retornada pode incluir instruções/políticas extras: só campos permitidos.
    agents = report['config'].get('agents') or {}
    report['config']['agents'] = {key: agents.get(key) for key in
        ('enabled', 'max_concurrent_threads_per_session', 'default_subagent_model', 'default_subagent_reasoning_effort')}
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + '\n')
    print(rendered)
    return int(bool(report['errors'] or report['pending']))


if __name__ == '__main__':
    raise SystemExit(main())
