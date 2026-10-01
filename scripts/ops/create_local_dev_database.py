#!/usr/bin/env python3
"""Clone the frozen local database into a new writable development database.

No remote connections, overwritten databases, or printed credentials. The
source is read-only throughout. Serverpod remains responsible for PostgreSQL.
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'investment_ontology_serverpod_server/.serverpod/development'
BIN = Path.home() / 'Library/Caches/serverpod/pg-binaries/16.13.0-r1/macos-arm64/bin'
SOURCE = 'investment_ontology_serverpod'
TARGET = 'investment_ontology_dev'


def main():
    with tempfile.TemporaryDirectory(prefix='ontology-dev-') as temporary:
        socket = Path(temporary) / 's'
        socket.symlink_to(LOCAL / 'run', target_is_directory=True)
        env = dict(os.environ, PGHOST=str(socket), PGPORT='5432',
                   PGUSER='postgres', PGDATABASE=SOURCE,
                   PGPASSWORD=(LOCAL / 'postgres.password').read_text().strip(),
                   PGOPTIONS='-c default_transaction_read_only=on')

        def sql(database, statement, writable=False):
            connection = dict(env, PGDATABASE=database)
            connection.pop('PGOPTIONS', None)
            if writable:
                connection['PGOPTIONS'] = '-c default_transaction_read_only=off'
            return subprocess.check_output(
                [str(BIN / 'psql'), '-X', '-At', '-v', 'ON_ERROR_STOP=1',
                 '-c', statement], env=connection, text=True).strip()

        if sql(SOURCE, 'SHOW default_transaction_read_only') != 'on':
            raise SystemExit('Source must already be frozen read-only.')
        if sql('postgres', f"SELECT 1 FROM pg_database WHERE datname='{TARGET}'"):
            raise SystemExit('Target already exists. Refusing to overwrite it.')
        sql('postgres', f'CREATE DATABASE {TARGET}', writable=True)
        print('Development database created; copying a consistent snapshot.', flush=True)
        dump = subprocess.Popen(
            [str(BIN / 'pg_dump'), '--format=custom', '--compress=0',
             '--no-owner', '--no-privileges'], env=env, stdout=subprocess.PIPE)
        target_env = dict(env, PGDATABASE=TARGET,
                          PGOPTIONS='-c default_transaction_read_only=off')
        restore = subprocess.Popen(
            [str(BIN / 'pg_restore'), '--exit-on-error', '--no-owner',
             '--no-privileges', '--dbname', TARGET],
            env=target_env, stdin=dump.stdout)
        dump.stdout.close()
        restore_code = restore.wait()
        dump_code = dump.wait()
        if restore_code or dump_code:
            raise SystemExit('Copy failed; source preserved. Target left for diagnosis.')
        sql('postgres', f'ALTER DATABASE {TARGET} SET default_transaction_read_only=off', writable=True)
        counts = {}
        for table in ['company', 'financial_report', 'financial_fact',
                      'market_snapshot', 'business_document', 'research_snapshot']:
            statement = f'SELECT count(*) FROM {table}'
            before, after = sql(SOURCE, statement), sql(TARGET, statement)
            if before != after:
                raise SystemExit(f'Count mismatch for {table}; do not switch config.')
            counts[table] = int(after)
        # Demonstrate writes with a rolled-back TEMP table, leaving no test rows.
        sql(TARGET, 'BEGIN; CREATE TEMP TABLE dev_write_probe (id int); '
            'INSERT INTO dev_write_probe VALUES (1); ROLLBACK;')
        print(json.dumps({'source': SOURCE, 'sourceReadOnly': sql(SOURCE, 'SHOW default_transaction_read_only'),
                          'target': TARGET, 'targetReadOnly': sql(TARGET, 'SHOW default_transaction_read_only'),
                          'counts': counts}, indent=2), flush=True)


if __name__ == '__main__':
    main()
