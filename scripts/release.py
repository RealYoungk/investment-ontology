#!/usr/bin/env python3
"""Deploy successful GitHub Release artifacts, or restore a recorded web release.

Uses existing gh, Wrangler Cloudflare Pages and SSH login. Never uploads local source or credentials.
Run `status`, `deploy --run ID`, or `rollback --record PATH`.
"""
import argparse
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
from urllib.request import Request, urlopen
from urllib.error import HTTPError
import cloudflare_release as pages
from prepare_cloudflare_web import prepare

from release_bundle import ROOT, sha256, verify_bundle

CONFIG = json.loads((ROOT / 'deploy/release-project.json').read_text())
REPO = CONFIG['repository']
STATE = ROOT / 'output/releases'


def run(*args, cwd=None):
    return subprocess.check_output(args, cwd=cwd or ROOT, text=True).strip()


def gh_api(path, payload=None):
    args = ['gh', 'api', f'repos/{REPO}/{path}']
    if payload is None:
        return json.loads(run(*args))
    result = subprocess.run([*args, '--input', '-'], input=json.dumps(payload),
                            capture_output=True, text=True, check=True)
    return json.loads(result.stdout)


def production():
    if (CONFIG.get('provider'), CONFIG.get('projectName'), CONFIG.get('accountId')) != ('cloudflare-pages', pages.PROJECT, pages.ACCOUNT):
        raise ValueError('Release configuration must match the current Cloudflare Pages project')
    return pages.production()


def backend():
    # Only immutable image identity and non-secret source label; never inspect Env.
    command = ("cd /opt/alfinder && docker compose --profile app ps -q server | "
               "xargs -r docker inspect --format "
               "'{{.Image}} {{index .Config.Labels \"org.opencontainers.image.revision\"}}'")
    result = run('ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
                 '-i', str(Path.home() / '.ssh/alfinder_iwinv_20261001'),
                 'root@49.247.192.41', command)
    if not re.fullmatch(r'sha256:[0-9a-f]{64}(?: [^\n]*)?', result):
        raise ValueError('Could not identify exactly one running backend image')
    return result


def require_backend_commit(identity, commit):
    """Require the running immutable image to declare this exact artifact source."""
    if not re.fullmatch(r'[0-9a-f]{40}', commit) or not re.fullmatch(
            r'sha256:[0-9a-f]{64} ' + re.escape(commit), identity):
        raise ValueError('Running backend OCI revision must match the artifact commit')


def fetch(url, data=None):
    request = Request(url, data=data, headers={
        'Cache-Control': 'no-cache', 'Origin': CONFIG['productionUrl'],
        'Content-Type': 'application/json', 'User-Agent': 'alfinder-release/1.0',
    })
    with urlopen(request, timeout=60) as response:
        return response.read()


def check_web(url, manifest=None, expected_main=None):
    main_hash = hashlib.sha256(fetch(url + '/main.dart.js')).hexdigest()
    if expected_main and main_hash != expected_main:
        raise ValueError('Served app differs from the expected release')
    if manifest:
        for name in ('index.html', 'release.json', 'flutter_bootstrap.js'):
            digest = hashlib.sha256(fetch(url + '/' + name)).hexdigest()
            if digest != manifest['files']['static/' + name]:
                raise ValueError(f'Served {name} differs from the verified artifact')
        if main_hash != manifest['mainJsSha256']:
            raise ValueError('Served main.dart.js differs from the verified artifact')
    response = json.loads(fetch(url + '/api/company/overview', b'{}'))
    if not isinstance(response, dict) or not isinstance(response.get('totalListed'), int):
        raise ValueError('Company overview smoke check returned an unexpected response')
    try:
        fetch(url + '/api/membership/status', b'{}')
    except HTTPError as error:
        error.close()
        if error.code != 401:
            raise ValueError('Unauthenticated personal endpoint did not return 401') from None
    else:
        raise ValueError('Unauthenticated personal endpoint unexpectedly succeeded')
    return main_hash


def web_hashes(url):
    return {name: hashlib.sha256(fetch(url + '/' + name)).hexdigest()
            for name in ('main.dart.js', 'index.html', 'release.json', 'flutter_bootstrap.js')}


def check_hashes(url, hashes):
    if set(hashes) != {'main.dart.js', 'index.html', 'release.json', 'flutter_bootstrap.js'} or web_hashes(url) != hashes:
        raise ValueError('Rollback files differ from the saved release')
    check_web(url, expected_main=hashes['main.dart.js'])


def check_run(candidate):
    if candidate.get('conclusion') != 'success' or candidate.get('status') != 'completed':
        raise ValueError('Release workflow has not completed successfully')
    if candidate.get('event') not in ('push', 'workflow_dispatch'):
        raise ValueError('Pull request artifacts cannot be promoted')
    if candidate.get('head_branch') != CONFIG['branch']:
        raise ValueError('Only the production branch can be deployed')
    if candidate.get('head_repository', {}).get('full_name') != REPO:
        raise ValueError('Workflow belongs to a different repository')
    if candidate.get('path') != '.github/workflows/' + CONFIG['workflow']:
        raise ValueError('Artifact was not produced by the Release workflow')
    if not re.fullmatch(r'[0-9a-f]{40}', candidate.get('head_sha', '')):
        raise ValueError('Invalid commit SHA')


def require_head(sha):
    if gh_api('commits/' + CONFIG['branch'])['sha'] != sha:
        raise ValueError('main moved. Use its successful Release run instead.')


def unpack(archive, destination):
    with tarfile.open(archive) as bundle:
        for member in bundle.getmembers():
            path = Path(member.name)
            if path.is_absolute() or '..' in path.parts or not (member.isfile() or member.isdir()):
                raise ValueError('Unsafe path or link in release archive')
            if member.name != 'manifest.json' and not (member.name == '.vercel/output'
                                                       or member.name.startswith('.vercel/output/')):
                raise ValueError('Unexpected file in release archive')
        bundle.extractall(destination, filter='data')


def save(path, record):
    temp = path.with_suffix('.partial')
    temp.write_text(json.dumps(record, indent=2) + '\n')
    temp.replace(path)


def build_local():
    """Use remote committed sources, never copy the caller's working tree."""
    commit = gh_api('commits/' + CONFIG['branch'])['sha']
    destination = STATE / ('local-' + commit)
    if destination.exists():
        raise ValueError('This commit already has a local artifact. Keep it or remove it explicitly.')
    context = 'release/local'
    gh_api(f'statuses/{commit}', {'state': 'pending', 'context': context,
                               'description': 'Validating a clean checkout on the release Mac'})
    with tempfile.TemporaryDirectory(prefix='alfinder-source-') as temporary:
        checkout = Path(temporary) / 'source'
        run('gh', 'repo', 'clone', REPO, str(checkout), '--', '--single-branch',
            '--branch', CONFIG['branch'])
        if run('git', 'rev-parse', 'HEAD', cwd=checkout) != commit:
            raise ValueError('main changed during clone; rebuild the new commit')
        env = os.environ.copy()
        for name in ('GITHUB_SHA', 'GITHUB_RUN_ID'):
            env.pop(name, None)
        log_path = STATE / ('local-' + commit + '.log')
        try:
            with log_path.open('w') as log:
                subprocess.run(['bash', 'scripts/verify_release.sh'], cwd=checkout,
                               env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
            require_head(commit)
            shutil.copytree(checkout / 'output/public-deploy', destination)
            manifest = verify_bundle(destination, commit)
            if manifest['verification'] != 'local' or manifest['workflowRun'] is not None:
                raise ValueError('Local verification is mislabeled')
            save(destination / 'verification.json', {
                'commit': commit, 'manifestSha256': sha256(destination / 'manifest.json'),
                'logSha256': sha256(log_path), 'log': str(log_path),
                'verifiedUtc': datetime.now(timezone.utc).isoformat(),
            })
            gh_api(f'statuses/{commit}', {'state': 'success', 'context': context,
                                        'description': 'Clean clone: analyze, format, tests and web build passed'})
        except Exception:
            gh_api(f'statuses/{commit}', {'state': 'failure', 'context': context,
                                        'description': 'Local release validation failed; inspect local log'})
            raise
    print(f'Verified artifact: {destination}')


def deploy(run_id=None, local=None):
    if local:
        attestation = json.loads((local / 'verification.json').read_text())
        commit = attestation['commit']
        if not re.fullmatch(r'[0-9a-f]{40}', commit):
            raise ValueError('Invalid local release commit')
        if sha256(local / 'manifest.json') != attestation['manifestSha256']:
            raise ValueError('Local manifest changed after validation')
        if sha256(Path(attestation['log'])) != attestation['logSha256']:
            raise ValueError('Local validation log changed')
        statuses = gh_api(f'commits/{commit}/status')['statuses']
        if not any(s['context'] == 'release/local' and s['state'] == 'success' for s in statuses):
            raise ValueError('Local verification has no successful GitHub status')
        candidate = {'html_url': f'https://github.com/{REPO}/commit/{commit}'}
    else:
        candidate = gh_api(f'actions/runs/{run_id}')
        check_run(candidate)
        commit = candidate['head_sha']
    require_head(commit)
    with tempfile.TemporaryDirectory(prefix='alfinder-release-') as temporary:
        work = Path(temporary) / 'artifact'
        work.mkdir()
        if local:
            shutil.copytree(local / '.vercel', work / '.vercel')
            shutil.copy2(local / 'manifest.json', work / 'manifest.json')
        else:
            run('gh', 'run', 'download', str(run_id), '--repo', REPO,
                '--name', 'web-release-' + commit, '--dir', str(work))
            unpack(work / 'web-release.tar.gz', work)
        manifest = verify_bundle(work, commit)
        expected_run = None if local else str(run_id)
        if manifest['workflowRun'] != expected_run:
            raise ValueError('Manifest workflow run does not match selected run')
        if manifest['verification'] != ('local' if local else 'github-actions'):
            raise ValueError('Verification origin does not match selected release path')
        # Worker/routes/headers must come from this same committed main checkout.
        if run('git', 'rev-parse', 'HEAD') != commit or run('git', 'status', '--porcelain', '--untracked-files=no'):
            raise ValueError('Pages preparation requires the clean artifact main checkout')
        prepared = Path(temporary) / 'pages'
        prepare(work, prepared)
        prepared_hashes = {path.relative_to(prepared).as_posix(): sha256(path)
                           for path in prepared.rglob('*') if path.is_file()}
        previous = production()
        server = backend()
        require_backend_commit(server, commit)
        previous['mainJsSha256'] = check_web(previous['url'])
        previous['fileHashes'] = web_hashes(previous['url'])
        check_hashes(CONFIG['productionUrl'], previous['fileHashes'])
        preview = pages.upload(prepared, commit)
        check_web(preview['url'], manifest)
        require_head(commit)
        if production()['id'] != previous['id'] or backend() != server:
            raise ValueError('Production changed during preview verification')
        if prepared_hashes != {path.relative_to(prepared).as_posix(): sha256(path)
                               for path in prepared.rglob('*') if path.is_file()}:
            raise ValueError('Prepared Pages upload changed after preview verification')
        record = {'schemaVersion': 2, 'provider': 'cloudflare-pages',
                  'projectName': pages.PROJECT, 'accountId': pages.ACCOUNT,
                  'commit': commit, 'runId': run_id,
                  'createdUtc': datetime.now(timezone.utc).isoformat(),
                  'backend': server, 'previous': previous, 'preview': preview,
                  'manifest': manifest, 'preparedFiles': prepared_hashes,
                  'status': 'verified-before-production-upload'}
        path = STATE / (preview['id'] + '.json')
        save(path, record)  # Durable recovery target BEFORE the production upload.
        gh_deployment = gh_api('deployments', {
            'ref': commit, 'environment': 'production-web', 'auto_merge': False,
            'required_contexts': [], 'description': 'Verified Release artifact',
            'payload': {'cloudflarePreview': preview, 'previous': previous, 'runId': run_id,
                        'backend': server, 'mainJsSha256': manifest['mainJsSha256']},
        })
        record['githubDeploymentId'] = gh_deployment['id']
        save(path, record)
        # Upload the identical verified package to production. Pages does not promote previews.
        require_head(commit)
        if production()['id'] != previous['id'] or backend() != server:
            raise ValueError('Production changed before the final Pages upload')
        require_backend_commit(backend(), commit)
        record['status'] = 'production-upload-requested'
        save(path, record)
        try:
            target = pages.upload(prepared, commit, production_environment=True)
        except Exception:
            record['status'] = 'production-upload-outcome-unknown'
            save(path, record)
            raise
        record['deployment'] = target
        record['status'] = 'production-uploaded-verification-pending'
        save(path, record)
        try:
            if production()['id'] != target['id'] or backend() != server:
                raise ValueError('Production/backend differs after upload')
            check_web(target['url'], manifest)
            check_web(CONFIG['productionUrl'], manifest)
        except Exception:
            record['status'] = 'production-verification-failed'
            save(path, record)
            print(f'Production verification failed. Recovery: python3 scripts/release.py rollback --record {path}')
            raise
        record['status'] = 'success'
        save(path, record)
        gh_api(f"deployments/{gh_deployment['id']}/statuses", {
            'state': 'success', 'environment_url': CONFIG['productionUrl'],
            'log_url': candidate['html_url'],
        })
        print(json.dumps({'commit': commit, 'url': target['url'], 'record': str(path)}))


def rollback(path):
    record = json.loads(path.read_text())
    if record.get('provider') != 'cloudflare-pages' or record.get('projectName') != pages.PROJECT or record.get('accountId') != pages.ACCOUNT:
        raise ValueError('Rollback requires a Cloudflare Pages release record for this project')
    if 'deployment' not in record:
        raise ValueError('Production upload outcome is unknown; identify the exact current deployment before rollback')
    if production()['id'] != record['deployment']['id']:
        raise ValueError('This record is not for the current deployment')
    if backend() != record['backend']:
        raise ValueError('Backend changed; compatibility must be checked before rollback')
    old = record['previous']
    check_hashes(old['url'], old['fileHashes'])
    if production()['id'] != record['deployment']['id'] or backend() != record['backend']:
        raise ValueError('Production changed during rollback verification')
    restored = pages.rollback(old)
    if restored['id'] != old['id'] or production()['id'] != old['id']:
        raise ValueError('Pages rollback did not restore the recorded production deployment')
    check_hashes(CONFIG['productionUrl'], old['fileHashes'])
    record['status'] = 'rolled-back'
    save(path, record)
    if record.get('githubDeploymentId'):
        gh_api(f"deployments/{record['githubDeploymentId']}/statuses", {'state': 'inactive'})
    print('Restored ' + old['url'] + '; database and backend were not changed.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('status')
    sub.add_parser('build-local')
    source = sub.add_parser('deploy').add_mutually_exclusive_group(required=True)
    source.add_argument('--run', type=int)
    source.add_argument('--local', type=Path)
    sub.add_parser('rollback').add_argument('--record', type=Path, required=True)
    args = parser.parse_args()
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / '.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if args.command == 'status':
            print(json.dumps({'web': production(), 'backend': backend()}, indent=2))
        elif args.command == 'deploy':
            deploy(args.run, args.local)
        elif args.command == 'build-local':
            build_local()
        else:
            rollback(args.record)


if __name__ == '__main__':
    main()
