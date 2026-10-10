#!/usr/bin/env python3
"""Bind a web bundle to a clean Git tree; used by the Release workflow."""
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent.parent


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inventory(directory):
    result = {}
    for path in sorted(directory.rglob('*')):
        if path.is_symlink():
            raise ValueError(f'Symlinks are not allowed in releases: {path}')
        if path.is_file():
            result[path.relative_to(directory).as_posix()] = sha256(path)
    return result


def verify_bundle(directory, expected_sha):
    manifest = json.loads((directory / 'manifest.json').read_text())
    if manifest['commit'] != expected_sha:
        raise ValueError('Artifact commit differs from the successful workflow run')
    if inventory(directory / '.vercel/output') != manifest['files']:
        raise ValueError('Release files differ from their checksum manifest')
    public = json.loads((directory / '.vercel/output/static/release.json').read_text())
    if public['commit'] != expected_sha or public['tree'] != manifest['tree']:
        raise ValueError('Public release metadata differs from the manifest')
    return manifest


def seal(directory):
    if git('status', '--porcelain', '--untracked-files=all'):
        raise SystemExit('Refusing to seal a dirty source tree. Commit all build inputs first.')
    commit = git('rev-parse', 'HEAD')
    if os.environ.get('ALFINDER_BUILD_COMMIT') != commit:
        raise SystemExit('Run verify_release.sh: commit must stay unchanged throughout validation/build.')
    if os.environ.get('GITHUB_SHA', commit) != commit:
        raise SystemExit('Checkout does not match GITHUB_SHA')
    output = directory / '.vercel/output'
    static = output / 'static'
    public = {
        'schemaVersion': 1,
        'commit': commit,
        'tree': git('rev-parse', 'HEAD^{tree}'),
        'workflowRun': os.environ.get('GITHUB_RUN_ID'),
        'verification': 'github-actions' if os.environ.get('GITHUB_RUN_ID') else 'local',
        'mainJsSha256': sha256(static / 'main.dart.js'),
        'component': 'web',
    }
    validation = ROOT / 'output/validation-results.json'
    if validation.exists():
        records = json.loads(validation.read_text())
        public['validationCache'] = {
            'executed': sum(row['origin'] == 'executed' for row in records),
            'reused': sum(row['origin'] == 'reused' for row in records),
        }
    (static / 'release.json').write_text(json.dumps(public, indent=2) + '\n')
    manifest = dict(public, files=inventory(output))
    (directory / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    verify_bundle(directory, commit)
    print(f'Sealed web release {commit}')


if __name__ == '__main__':
    seal(ROOT / 'output/public-deploy')
