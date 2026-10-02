#!/usr/bin/env python3
"""Read-only billing preflight. Never prints credentials or submits payments."""
import argparse
import base64
import json
import re
import stat
from pathlib import Path


def read_env(path):
    if stat.S_IMODE(path.stat().st_mode) & 0o077:
        raise ValueError('Billing file must be private (chmod 600)')
    values = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        key, separator, value = line.partition('=')
        if not separator or not re.fullmatch(r'[A-Z][A-Z0-9_]*', key) or key in values:
            raise ValueError('Invalid or duplicate billing configuration key')
        if any(char in value for char in ('$', '`', '"', "'", '\\')):
            raise ValueError('Use plain literal billing values without shell expansion')
        values[key] = value
    return values


def check(values):
    errors = []
    for key in ('ALFINDER_BILLING_LIVE_ENABLED', 'ALFINDER_PG_BILLING_APPROVED',
                'ALFINDER_BILLING_PRIVACY_READY', 'PORTONE_LIVE_CHANNEL_VERIFIED'):
        if values.get(key) != 'true':
            errors.append(key + ': approval or verification pending')
    if values.get('ALFINDER_BILLING_PROVIDER') != 'portone':
        errors.append('ALFINDER_BILLING_PROVIDER: expected portone')
    if values.get('PORTONE_CONTRACT_PG') != 'kcp_v2':
        errors.append('PORTONE_CONTRACT_PG: this release is reviewed for KCP V2 CARD; another PG needs adapter review')
    if values.get('ALFINDER_BILLING_SANDBOX_ENABLED') != 'false':
        errors.append('ALFINDER_BILLING_SANDBOX_ENABLED: expected false in production')
    if values.get('ALFINDER_BILLING_CHARGES_PAUSED') != 'false':
        errors.append('ALFINDER_BILLING_CHARGES_PAUSED: charges remain paused')
    if values.get('ALFINDER_BILLING_TERMS_VERSION') != '2026-10-02':
        errors.append('ALFINDER_BILLING_TERMS_VERSION: must match reviewed public terms')
    if values.get('ALFINDER_NEW_SUBSCRIPTION_PRICE_KRW') not in {'4900', '9900', '14900', '19900'}:
        errors.append('ALFINDER_NEW_SUBSCRIPTION_PRICE_KRW: unsupported price')
    for key, pattern in (('PORTONE_LIVE_STORE_ID', r'store-[A-Za-z0-9-]+'),
                         ('PORTONE_LIVE_CHANNEL_KEY', r'channel-key-[A-Za-z0-9-]+')):
        if not re.fullmatch(pattern, values.get(key, '')):
            errors.append(key + ': missing or invalid identifier')
    if not values.get('PORTONE_LIVE_API_SECRET', '').strip():
        errors.append('PORTONE_LIVE_API_SECRET: missing server secret')
    try:
        valid_key = len(base64.b64decode(values.get('BILLING_ENCRYPTION_KEY', ''), validate=True)) == 32
    except ValueError:
        valid_key = False
    if not valid_key:
        errors.append('BILLING_ENCRYPTION_KEY: expected 32-byte base64 vault key')
    return {'ready': not errors, 'checks': errors,
            'note': 'Configuration only; does not prove PG approval, channel mode, valid credentials or a real card authorization.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--env-file', type=Path, required=True)
    args = parser.parse_args()
    try:
        result = check(read_env(args.env_file))
    except (OSError, ValueError):
        result = {'ready': False, 'checks': ['Billing file unreadable, unsafe permissions, or invalid syntax']}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result['ready'] else 2


if __name__ == '__main__':
    raise SystemExit(main())
