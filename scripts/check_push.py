#!/usr/bin/env python3
"""Validate the exact pushed commits in clean, isolated checkouts."""
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

SERVER = 'investment_ontology_serverpod_server/'
FLUTTER = 'investment_ontology_serverpod_flutter/'
CLIENT = 'investment_ontology_serverpod_client/'


def git(*args):
    return subprocess.check_output(['git', *args], text=True).strip()


def checks(changed, checkout, full=False):
    server = any(p.startswith((SERVER, CLIENT)) for p in changed)
    flutter = any(p.startswith((FLUTTER, CLIENT)) for p in changed)
    dependencies = any(p in ('pubspec.yaml', 'pubspec.lock') for p in changed)
    dart = server or flutter or dependencies or full
    commands = []
    if dart:
        commands += [('flutter', 'pub', 'get', '--enforce-lockfile'),
                     ('dart', 'analyze', '--fatal-infos')]
    selected = sorted({p[len(SERVER):] for p in changed
                       if p.startswith(SERVER + 'test/') and p.endswith('_test.dart')
                       and (checkout / p).exists()})
    source = [p for p in changed if p.startswith(SERVER) and not p.startswith(SERVER + 'test/')]
    search = SERVER + 'lib/src/ontology/endpoints/company_endpoint.dart'
    if source and all(p == search for p in source):
        selected += ['test/unit/company_search_test.dart',
                     'test/unit/generated_code_test.dart',
                     'test/integration/company_endpoint_test.dart',
                     'test/integration/company_list_market_cap_test.dart']
    elif source or any(p.startswith(CLIENT) for p in changed) or dependencies or full:
        selected = []  # Unknown source scope: run the complete server package.
    if server or dependencies or full:
        commands.append(('bash', 'scripts/test-server.sh', *sorted(set(selected))))
    if flutter or dependencies or full:
        commands.append(('flutter', 'test', '--directory-placeholder'))
    billing = any(any(token in p for token in ('billing', 'membership', 'monetization', 'portone'))
                  for p in changed)
    if billing or dependencies or full:
        commands.append(('bash', 'scripts/test-billing-browser.sh'))
    if full or any(p.startswith('scripts/') for p in changed):
        commands.append(('python3', '-m', 'unittest', 'discover', '-s', 'scripts/tests', '-v'))
    if full or any(p.startswith((FLUTTER + 'web/', FLUTTER + 'test/web/')) for p in changed):
        commands.append(('node', '--test', *[str(p.relative_to(checkout)) for p in
                         (checkout / FLUTTER / 'test/web').glob('*_test.cjs')]))
    if full or any(p.startswith('deploy/cloudflare/') for p in changed):
        commands.append(('node', '--test', 'deploy/cloudflare/worker.test.mjs'))
    return commands


def main():
    root = Path(git('rev-parse', '--show-toplevel'))
    local_vars = git('rev-parse', '--local-env-vars').splitlines()
    clean_env = {k: v for k, v in os.environ.items() if k not in local_vars}
    full = '--full' in sys.argv
    refs = [line.split() for line in sys.stdin if line.strip()]
    seen = set()
    for fields in refs:
        if len(fields) != 4:
            raise SystemExit('Invalid pre-push ref input.')
        _, tip, _, remote = fields
        if set(tip) == {'0'} or tip in seen:
            continue
        seen.add(tip)
        if set(remote) == {'0'}:
            try:
                base = git('merge-base', tip, 'refs/remotes/origin/main')
            except subprocess.CalledProcessError:
                base = git('hash-object', '-t', 'tree', '--stdin')
        else:
            try:
                git('cat-file', '-e', remote + '^{commit}')
                base = remote
            except subprocess.CalledProcessError:
                # Remote history unavailable: inspect the complete pushed tree.
                base = git('hash-object', '-t', 'tree', '--stdin')
        changed = git('diff', '--name-only', base, tip).splitlines()
        subprocess.run(['git', 'diff', '--check', base, tip], check=True)
        output = root / 'output/local-checks'
        output.mkdir(parents=True, exist_ok=True)
        record = output / (tip + '.json')
        record.write_text(json.dumps({'commit': tip, 'status': 'running'}) + '\n')
        with tempfile.TemporaryDirectory(prefix='alfinder-push-') as temporary:
            checkout = Path(temporary) / 'source'
            subprocess.run(['git', 'clone', '--quiet', '--shared', '--no-checkout', str(root), str(checkout)],
                           check=True, env=clean_env)
            subprocess.run(['git', 'checkout', '--quiet', '--detach', tip], cwd=checkout,
                           check=True, env=clean_env)
            plan = checks(changed, checkout, full)
            try:
                for command in plan:
                    directory = checkout
                    if command == ('flutter', 'test', '--directory-placeholder'):
                        command = ('flutter', 'test')
                        directory = checkout / FLUTTER
                    print('Pre-push:', ' '.join(command), flush=True)
                    subprocess.run(command, cwd=directory, check=True, env=clean_env)
            except (subprocess.CalledProcessError, FileNotFoundError):
                record.write_text(json.dumps({'commit': tip, 'status': 'failed', 'commands': plan}) + '\n')
                raise
            record.write_text(json.dumps({'commit': tip, 'status': 'passed', 'commands': plan}, indent=2) + '\n')
        print('Pre-push checks passed for ' + tip, flush=True)


if __name__ == '__main__':
    try:
        main()
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode)
