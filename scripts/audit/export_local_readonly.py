"""Run a read-only local SQL audit without exposing credentials or changing data."""
import os,pathlib,subprocess,tempfile,sys,re
root=pathlib.Path(__file__).resolve().parents[2]
local=root/'investment_ontology_serverpod_server/.serverpod/development'
binary=pathlib.Path.home()/'Library/Caches/serverpod/pg-binaries/16.13.0-r1/macos-arm64/bin/psql'
config=(root/'investment_ontology_serverpod_server/config/development.yaml').read_text()
block=re.search(r'^database:\s*\n((?:[ \t]+[^\n]*\n|\n)*)',config,re.M)
if block is None: raise RuntimeError('development database configuration missing')
match=re.search(r'^  name:\s*([^#\n]+)',block.group(1),re.M)
if match is None: raise RuntimeError('development database name missing')
database_name=match.group(1).strip().strip("\"'")
print(f'Read-only audit database: {database_name}',file=sys.stderr)
with tempfile.TemporaryDirectory(prefix='ontology-audit-') as d:
 socket=pathlib.Path(d)/'s';socket.symlink_to(local/'run',target_is_directory=True)
 env=dict(os.environ,PGHOST=str(socket),PGPORT='5432',PGDATABASE=database_name,PGUSER='postgres',PGPASSWORD=(local/'postgres.password').read_text().strip(),PGOPTIONS='-c default_transaction_read_only=on -c statement_timeout=180000')
 with open(sys.argv[2],'w') as out:
  subprocess.run([str(binary),'-X','-q','-At','-v','ON_ERROR_STOP=1','-f',sys.argv[1]],env=env,stdout=out,check=True)
