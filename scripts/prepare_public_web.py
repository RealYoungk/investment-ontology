#!/usr/bin/env python3
"""Prepare Flutter and its transport proxy; never upload Serverpod code or secrets."""
import json
import shutil
from pathlib import Path

root = Path(__file__).resolve().parent.parent
source = root / 'investment_ontology_serverpod_flutter/build/web'
if not (source / 'main.dart.js').is_file():
    raise SystemExit('Run flutter build web --release in the Flutter package first.')
output = root / 'output/public-deploy/.vercel/output'
output.mkdir(parents=True, exist_ok=True)
static = output / 'static'
if static.exists():
    shutil.rmtree(static)
shutil.copytree(source, static)
proxy = output / 'functions/api-proxy.func'
proxy.mkdir(parents=True, exist_ok=True)
shutil.copyfile(root / 'deploy/api-proxy.cjs', proxy / 'index.cjs')
(proxy / '.vc-config.json').write_text(json.dumps({
    'runtime': 'nodejs24.x', 'handler': 'index.cjs', 'launcherType': 'Nodejs',
    'regions': ['icn1'], 'maxDuration': 30,
}))
config = {
    'version': 3,
    'routes': [
        {'src': '/api/(.*)',
         'dest': '/api-proxy?endpoint=$1',
         'headers': {'Cache-Control': 'no-store'}},
        {'src': '/(.*)', 'continue': True, 'headers': {
            'X-Content-Type-Options': 'nosniff',
            'Referrer-Policy': 'strict-origin-when-cross-origin',
            'X-Frame-Options': 'DENY',
        }},
        {'handle': 'filesystem'},
        {'src': '/.*', 'dest': '/index.html'},
    ],
}
(output / 'config.json').write_text(json.dumps(config, indent=2) + '\n')
print(f'Prepared {output}. Deploy with --prebuilt --prod --skip-domain.')
