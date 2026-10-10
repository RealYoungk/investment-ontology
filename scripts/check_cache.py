#!/usr/bin/env python3
"""Reuse successful, identical local checks; never cache builds or browser tests."""
import argparse
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import time

VERSION = 1
MAX_AGE = 7 * 24 * 60 * 60
# Checkout/run labels do not change a check's inputs. CI itself is retained.
METADATA = {'PWD', 'OLDPWD', 'SHLVL', '_', 'ALFINDER_BUILD_COMMIT',
            'GITHUB_SHA', 'GITHUB_RUN_ID', 'ALFINDER_CHECK_CACHE',
            'ALFINDER_CHECK_CACHE_DIR', 'MANPATH', 'GIT_EXEC_PATH'}


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True,
                                    separators=(',', ':')).encode()).hexdigest()


def git(root, *args):
    return subprocess.check_output(['git', *args], cwd=root, text=True).strip()


def environment_key(env):
    # Hash values, including secrets, without persisting or logging them.
    return digest({key: value for key, value in env.items() if key not in METADATA})


def execute(command, cwd, env):
    subprocess.run(command, cwd=cwd, env=env, check=True)


def check_environment(root, env):
    """Match macOS xcrun's Git-hook defaults without discarding overrides."""
    env = dict(env)
    if sys.platform == 'darwin':
        helper = subprocess.check_output(['git', '--exec-path'], cwd=root,
                                         env=env, text=True).strip()
        paths = env.get('PATH', '').split(os.pathsep)
        env['PATH'] = os.pathsep.join([helper, *[p for p in paths if p != helper]])
        if 'SDKROOT' not in env:
            env['SDKROOT'] = subprocess.check_output(
                ['xcrun', '--show-sdk-path'], cwd=root, env=env, text=True).strip()
        env.setdefault('CPATH', '/usr/local/include')
        env.setdefault('LIBRARY_PATH', '/usr/local/lib')
    return env


def cacheable(command, directory):
    command = tuple(command)
    if directory == '.':
        return (command == ('dart', 'analyze', '--fatal-infos')
                or command[:2] == ('bash', 'scripts/test-server.sh')
                or command == ('python3', '-m', 'unittest', 'discover',
                               '-s', 'scripts/tests', '-v')
                or (command[:2] == ('node', '--test') and len(command) > 2
                    and all(path == 'deploy/cloudflare/worker.test.mjs'
                            or (path.startswith('investment_ontology_serverpod_flutter/test/web/')
                                and path.endswith('_test.cjs')) for path in command[2:])))
    return (directory == 'investment_ontology_serverpod_flutter'
            and command == ('flutter', 'test'))


class CheckCache:
    def __init__(self, root, env=None, cache_dir=None):
        self.root = Path(root).resolve()
        self.env = check_environment(self.root, os.environ if env is None else env)
        self.directory = Path(cache_dir or self.env.get('ALFINDER_CHECK_CACHE_DIR')
                              or Path.home() / '.cache/alfinder/checks-v1').expanduser()
        self.runtime = None

    def runtime_key(self):
        if self.runtime is None:
            versions = {'python': sys.version, 'platform': platform.platform(),
                        'machine': platform.machine()}
            for name, command in [('flutter', ['flutter', '--version', '--machine']),
                                  ('dart', ['dart', '--version']),
                                  ('node', ['node', '--version']),
                                  ('bash', ['bash', '--version']),
                                  ('git', ['git', '--version'])]:
                versions[name] = subprocess.check_output(
                    command, cwd=self.root, env=self.env, text=True,
                    stderr=subprocess.STDOUT).strip()
            if sys.platform == 'darwin':
                for name, command in [('sdk', ['xcrun', '--show-sdk-version']),
                                      ('clang', ['xcrun', 'clang', '--version'])]:
                    versions[name] = subprocess.check_output(
                        command, cwd=self.root, env=self.env, text=True).strip()
            self.runtime = digest(versions)
        return self.runtime

    def inputs(self, command, directory):
        return {'schemaVersion': VERSION, 'tree': git(self.root, 'rev-parse', 'HEAD^{tree}'),
                'command': list(command), 'directory': directory,
                'runtime': self.runtime_key(), 'environment': environment_key(self.env)}

    def clean(self):
        return not git(self.root, 'status', '--porcelain', '--untracked-files=all')

    def run(self, command, cwd=None):
        command = tuple(command)
        cwd = Path(cwd or self.root).resolve()
        directory = cwd.relative_to(self.root).as_posix()
        eligible = (self.env.get('ALFINDER_CHECK_CACHE') != 'off'
                    and cacheable(command, directory) and self.clean())
        if not eligible:
            execute(command, cwd, self.env)
            return {'command': list(command), 'directory': directory, 'origin': 'executed'}
        inputs = self.inputs(command, directory)
        key = digest(inputs)
        self.directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        if self.directory.is_symlink() or self.directory.stat().st_uid != os.getuid():
            raise ValueError('Check cache must be a local directory owned by this user')
        self.directory.chmod(0o700)
        record = self.directory / (key + '.json')
        lock = self.directory / (key + '.lock')
        if record.is_symlink() or lock.is_symlink():
            raise ValueError('Check cache entries must not be symlinks')
        with lock.open('a') as handle:
            fcntl.flock(handle, fcntl.LOCK_EX)
            if not self.clean() or self.inputs(command, directory) != inputs:
                execute(command, cwd, self.env)
                return {'command': list(command), 'directory': directory, 'origin': 'executed'}
            try:
                saved = json.loads(record.read_text())
                age = time.time() - saved['completedAt']
                hit = (saved['status'] == 'passed' and saved['inputs'] == inputs
                       and saved['key'] == key and 0 <= age < MAX_AGE)
            except (OSError, ValueError, KeyError, TypeError):
                hit = False
            if hit:
                print('Check cache hit:', ' '.join(command), flush=True)
                return {'command': list(command), 'directory': directory, 'origin': 'reused',
                        'key': key, 'validatedCommit': saved['commit']}
            print('Check cache miss:', ' '.join(command), flush=True)
            started = time.monotonic()
            execute(command, cwd, self.env)
            # A task which changed source must not validate the original tree.
            if not self.clean() or self.inputs(command, directory) != inputs:
                raise ValueError('Check inputs changed during execution; refusing to cache success')
            saved = {'status': 'passed', 'key': key, 'inputs': inputs,
                     'commit': git(self.root, 'rev-parse', 'HEAD'),
                     'completedAt': time.time(), 'durationSeconds': time.monotonic() - started}
            temporary = record.with_suffix('.partial')
            temporary.write_text(json.dumps(saved, indent=2) + '\n')
            temporary.chmod(0o600)
            temporary.replace(record)
            return {'command': list(command), 'directory': directory, 'origin': 'executed', 'key': key}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cwd', default='.')
    parser.add_argument('--report', type=Path)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    if not command:
        parser.error('A check command is required')
    root = Path(__file__).resolve().parent.parent
    result = CheckCache(root).run(command, root / args.cwd)
    if args.report:
        path = root / args.report
        path.parent.mkdir(parents=True, exist_ok=True)
        records = json.loads(path.read_text()) if path.exists() else []
        records.append(dict(result, recordedUtc=datetime.now(timezone.utc).isoformat()))
        path.write_text(json.dumps(records, indent=2) + '\n')


if __name__ == '__main__':
    try:
        main()
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode)
