#!/usr/bin/env bash
# Dump the MySQL container's `knup` database to a gzip'd file under
# /opt/knup/backups/. Designed for a daily systemd timer or host crontab.
#
# Why this and not boot-volume snapshots? Boot snapshots include the
# Docker volume but the database is live during the snapshot — restoring
# is best-effort for MySQL. A logical dump from inside the container is
# guaranteed-consistent.
#
# Install (as ubuntu on the backend VM):
#   sudo install -m 0755 mysqldump.sh /usr/local/bin/knup-mysqldump
#   sudo crontab -l > /tmp/cron; echo '0 3 * * * /usr/local/bin/knup-mysqldump' >> /tmp/cron; sudo crontab /tmp/cron
#
# Restore:
#   gunzip < /opt/knup/backups/knup-YYYY-MM-DD.sql.gz | docker compose exec -T mysql mysql -u root -p"$DB_ROOT_PASSWORD" knup

set -euo pipefail

BACKUP_DIR=/opt/knup/backups
RETAIN_DAYS=14
ENV_FILE=/opt/knup/.env

# shellcheck source=/dev/null
. "$ENV_FILE"

mkdir -p "$BACKUP_DIR"

stamp=$(date -u +%Y-%m-%d_%H%M)
out="$BACKUP_DIR/knup-${stamp}.sql.gz"

cd /opt/knup
docker compose exec -T mysql \
  mysqldump --single-transaction --quick --routines --triggers \
    -u root -p"${DB_ROOT_PASSWORD}" knup \
  | gzip > "$out"

# Prune older than RETAIN_DAYS days
find "$BACKUP_DIR" -name 'knup-*.sql.gz' -mtime "+${RETAIN_DAYS}" -delete

echo "wrote $out ($(du -h "$out" | cut -f1))"
