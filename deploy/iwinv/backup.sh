#!/usr/bin/env bash
set -euo pipefail
umask 077
cd /opt/alfinder
mkdir -p backups
exec 9>backups/.lock
flock -n 9 || exit 0
target="backups/alfinder-$(date -u +%Y%m%dT%H%M%SZ).dump.gz"
trap 'rm -f "${target}.partial"' EXIT
docker compose exec -T postgres pg_dump -U postgres --role=alfinder -d alfinder \
  --format=custom --compress=0 --no-owner --no-privileges | gzip -1 > "${target}.partial"
# External gzip keeps the custom archive itself uncompressed, compatible with
# Serverpod's Mac pg_restore build, which lacks built-in gzip support.
gzip -t "${target}.partial"
docker compose exec -T postgres sh -c 'gzip -dc | pg_restore --list' \
  < "${target}.partial" >/dev/null
mv "${target}.partial" "$target"
sha256sum "$target" > "${target}.sha256"
# Keep three completed daily snapshots. An off-server copy is still required.
find backups -maxdepth 1 \( -name 'alfinder-*.dump' -o -name 'alfinder-*.dump.gz' \) -printf '%f\n' | sort -r | \
  tail -n +4 | while IFS= read -r old; do rm -f "backups/$old" "backups/$old.sha256"; done
printf 'Backup completed: %s\n' "$target"
