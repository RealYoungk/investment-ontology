#!/usr/bin/env python3
"""Copy public-source trial data to the new, empty Cloud database only.

Does not copy accounts, authentication, jobs, API credentials, or session logs.
Local PostgreSQL is read-only. --apply is required for the Cloud transaction.
"""
import argparse
import atexit
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SERVER = ROOT / 'investment_ontology_serverpod_server'
parser = argparse.ArgumentParser()
parser.add_argument('--apply', action='store_true')
parser.add_argument('--filings-only', action='store_true',
                    help='Fill an empty filing ledger for reports already imported.')
args = parser.parse_args()
credential_file = Path.home() / '.config/alfinder/serverpod-trial-db.json'
if not credential_file.exists():
    parser.error('Create a temporary Cloud import user and its private credential file first.')
credentials = json.loads(credential_file.read_text())
assert credentials['database'] == 'default'
assert credentials['host'].endswith('.eu-central-1.aws.neon.tech')
snapshot_id = None


def psql(env, sql, output=None):
    command = ['psql', '-X', '-q', '-v', 'ON_ERROR_STOP=1', '-t', '-A']
    if snapshot_id and env.get('PGDATABASE') == 'investment_ontology_serverpod':
        command += ['-c', 'BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY',
                    '-c', f"SET TRANSACTION SNAPSHOT '{snapshot_id}'"]
    result = subprocess.run(command + ['-c', sql],
                            env=env, stdout=output or subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise RuntimeError(result.stderr.decode())
    return '' if output else result.stdout.decode().strip()


with tempfile.TemporaryDirectory(prefix='alfinder-trial-') as temp:
    temp = Path(temp)
    socket = temp / 's'
    local_root = SERVER / '.serverpod/development'
    socket.symlink_to(local_root / 'run', target_is_directory=True)
    local = os.environ.copy()
    local.update(PGHOST=str(socket), PGUSER='postgres', PGDATABASE='investment_ontology_serverpod',
                 PGPORT='5432', PGPASSWORD=(local_root / 'postgres.password').read_text().strip(),
                 PGOPTIONS='-c default_transaction_read_only=on')
    # Ingestion continues locally. All exports must see one database snapshot
    # so newly inserted reports cannot reference a Source absent from the export.
    snapshot_owner = subprocess.Popen(
        ['psql', '-X', '-q', '-v', 'ON_ERROR_STOP=1', '-t', '-A',
         '-c', 'BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY',
         '-c', 'SELECT pg_export_snapshot()', '-c', 'SELECT pg_sleep(300)'],
        env=local, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    atexit.register(snapshot_owner.terminate)
    snapshot_id = snapshot_owner.stdout.readline().strip()
    if not snapshot_id or any(c not in '0123456789ABCDEF-' for c in snapshot_id):
        raise RuntimeError('Could not establish a consistent export snapshot.')
    remote = os.environ.copy()
    remote.update(PGHOST=credentials['host'], PGPORT=str(credentials['port']),
                  PGUSER=credentials['user'], PGDATABASE=credentials['database'],
                  PGPASSWORD=credentials['password'], PGSSLMODE='require')
    companies = psql(local, '''SELECT DISTINCT c.id FROM company c WHERE c.id IN (
        SELECT s."companyId" FROM market_snapshot m JOIN security s ON s.id=m."securityId"
        WHERE m."baseDate"=(SELECT max("baseDate") FROM market_snapshot)
        AND s."companyId" IS NOT NULL GROUP BY s."companyId"
        ORDER BY sum(m."marketCap"::numeric) DESC NULLS LAST LIMIT 10)
        OR c."stockCode"='420770' ORDER BY c.id''')
    ids = ','.join(str(int(value)) for value in companies.splitlines())
    assert ids
    print('Trial companies:', psql(local, f'SELECT string_agg(name, \' / \' ORDER BY name) FROM company WHERE id IN ({ids})'))
    document_ids = f'SELECT id FROM business_document WHERE "companyId" IN ({ids})'
    tables = [
        ('source', 'true'), ('industry', 'true'), ('company', 'true'), ('security', 'true'),
        ('financial_report', f'"companyId" IN ({ids})'),
        ('financial_fact', f'"companyId" IN ({ids})'),
        ('disclosure_report', f'id IN (SELECT "reportId" FROM business_document WHERE "companyId" IN ({ids}))'),
        ('business_document', f'"companyId" IN ({ids})'),
        ('document_fact', f'"documentId" IN ({document_ids}) AND status=\'verified\''),
        ('business_profile', f'"documentId" IN ({document_ids})'),
        ('market_snapshot', '"baseDate"=(SELECT max("baseDate") FROM market_snapshot)'),
    ]
    if args.filings_only:
        filings = psql(remote, 'SELECT DISTINCT "rceptNo" FROM financial_report ORDER BY "rceptNo"').splitlines()
        if not filings or not all(value.isdigit() for value in filings):
            raise RuntimeError('Cloud trial has no valid imported reports.')
        recepts = ','.join("'" + value + "'" for value in filings)
        tables = [('dart_filing', f'"rceptNo" IN ({recepts})')]
    statements = ['BEGIN;']
    size = 0
    for table, where in tables:
        local_columns = psql(local, f"SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema='public' AND table_name='{table}'")
        quoted_columns = ','.join('"' + name + '"' for name in local_columns.split(','))
        path = temp / f'{table}.csv'
        with path.open('wb') as output:
            psql(local, f'COPY (SELECT * FROM "{table}" WHERE {where} ORDER BY id) TO STDOUT WITH (FORMAT CSV)', output)
        size += path.stat().st_size
        count = psql(local, f'SELECT count(*) FROM "{table}" WHERE {where}')
        print(f'{table}: {count} rows, {path.stat().st_size:,} CSV bytes')
        if args.apply:
            existing = int(psql(remote, f'SELECT count(*) FROM "{table}"'))
            if existing:
                raise RuntimeError(f'Refusing import: Cloud {table} already has {existing} rows.')
            remote_columns = psql(remote, f"SELECT string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema='public' AND table_name='{table}'")
            if set(local_columns.split(',')) != set(remote_columns.split(',')):
                raise RuntimeError(f'Column mismatch: {table}')
        statements.append(f"\\copy \"{table}\" ({quoted_columns}) FROM '{path}' WITH (FORMAT CSV)")
        statements.append(f"SELECT setval(pg_get_serial_sequence('{table}', 'id'), COALESCE(max(id),1), max(id) IS NOT NULL) FROM \"{table}\";")
    print(f'Total CSV bytes: {size:,}')
    snapshot_owner.terminate()
    snapshot_owner.wait(timeout=5)
    if size > 300_000_000:
        raise RuntimeError('Trial export exceeds conservative 300 MB data budget.')
    statements.append('COMMIT;')
    if args.apply:
        script = temp / 'import.sql'
        script.write_text('\n'.join(statements))
        result = subprocess.run(['psql', '-X', '-v', 'ON_ERROR_STOP=1', '-f', str(script)],
                                env=remote, capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError(result.stderr)
        print('Cloud transaction committed.')
        print(psql(remote, 'SELECT pg_size_pretty(pg_database_size(current_database()))'))
    else:
        print('Dry run only. No Cloud data written.')
