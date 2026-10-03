"""Pages transport for verified release artifacts. Never logs credentials."""
import json
import os
from pathlib import Path
import re
import subprocess
from urllib.error import HTTPError
from urllib.request import Request, urlopen

PROJECT = 'alfinder-web'
ACCOUNT = '9b9f77379317355dab85693ad96be8d8'
NODE = '/opt/homebrew/bin/node'
WRANGLER = '/Users/realyoungk/.npm/_npx/62152447c589c641/node_modules/wrangler/bin/wrangler.js'


def cli(*args):
    command = [os.environ.get('ALFINDER_NODE', NODE),
               os.environ.get('ALFINDER_WRANGLER', WRANGLER), *args]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode:
        # CLI auth errors may contain credentials; do not echo output.
        raise ValueError('Cloudflare CLI failed; check the existing Wrangler login')
    return result.stdout


def api(path='', method='GET'):
    credentials = json.loads(cli('auth', 'token', '--json'))
    if credentials.get('type') not in ('oauth', 'api_token') or not credentials.get('token'):
        raise ValueError('Cloudflare release requires existing OAuth or API-token login')
    url = f'https://api.cloudflare.com/client/v4/accounts/{ACCOUNT}/pages/projects/{PROJECT}' + path
    request = Request(url, data=b'{}' if method == 'POST' else None, method=method,
                      headers={'Authorization': 'Bearer ' + credentials['token'],
                               'Content-Type': 'application/json'})
    try:
        with urlopen(request, timeout=60) as response:
            value = json.load(response)
    except HTTPError as error:
        error.close()
        raise ValueError(f'Cloudflare Pages API failed ({error.code}); no credentials logged') from None
    if value.get('success') is not True:
        raise ValueError('Cloudflare Pages API rejected the request')
    return value['result']


def deployment(value, environment=None, commit=None):
    if not re.fullmatch(r'[0-9a-f-]{36}', value.get('id', '')):
        raise ValueError('Invalid Pages deployment identifier')
    if value.get('project_name') != PROJECT:
        raise ValueError('Foreign Pages project')
    if environment and value.get('environment') != environment:
        raise ValueError('Wrong Pages deployment environment')
    if value.get('latest_stage', {}).get('status') != 'success':
        raise ValueError('Pages deployment did not succeed')
    if not re.fullmatch(r'https://[a-z0-9-]+\.alfinder-web\.pages\.dev', value.get('url', '')):
        raise ValueError('Not an immutable alfinder-web Pages deployment URL')
    metadata = value.get('deployment_trigger', {}).get('metadata', {})
    if commit and (metadata.get('commit_hash') != commit or metadata.get('commit_dirty') is not False):
        raise ValueError('Pages deployment commit does not match the clean artifact')
    # Never persist provider env_vars or other secret-bearing response fields.
    return {'id': value['id'], 'url': value['url'], 'environment': value['environment']}


def project():
    value = api()
    if value.get('name') != PROJECT or value.get('production_branch') != 'main':
        raise ValueError('Pages project/production branch differs from release configuration')
    return value


def production():
    return deployment(project()['canonical_deployment'], 'production')


def upload(directory, commit, production_environment=False):
    branch = 'main' if production_environment else 'release-preview-' + commit
    result = cli('pages', 'deploy', str(directory), '--project-name', PROJECT,
                 '--branch', branch, '--commit-hash', commit, '--commit-dirty=false')
    urls = set(re.findall(r'https://[a-z0-9-]+\.alfinder-web\.pages\.dev', result))
    if not urls:
        raise ValueError('Could not identify one immutable Pages upload URL')
    # List by explicit URL rather than assuming latest means our upload.
    values = api('/deployments?per_page=100')
    matches = [value for value in values if value.get('url') in urls]
    if len(matches) != 1:
        raise ValueError('Pages upload result is not uniquely bound to the project')
    return deployment(matches[0], 'production' if production_environment else 'preview', commit)


def rollback(old):
    # Pages preview deployments cannot be rollback targets.
    original = deployment(api('/deployments/' + old['id']), 'production')
    if original['id'] != old['id'] or original['url'] != old['url']:
        raise ValueError('Recorded rollback target URL changed')
    return deployment(api('/deployments/' + old['id'] + '/rollback', 'POST'), 'production')
