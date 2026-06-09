# Backup & disaster recovery

Two layers, deliberately overlapping:

1. **OCI boot-volume snapshots** — captures the whole disk weekly.
   Recovers from disk corruption, bad apt upgrades, cloud-init mistakes.
2. **MySQL logical dumps** — captures only `knup` DB, daily.
   Recovers from accidental `DELETE`, bad schema migration, application
   bug. Guaranteed-consistent (mysqldump `--single-transaction`).

## Layer 1: boot-volume snapshots (managed by Terraform)

`backup.tf` attaches Oracle's predefined **Bronze** policy to both VM
boot volumes:

- 1 weekly full snapshot
- Retained 4 weeks
- 50 GB × 4 snapshots × 2 VMs = 400 GB snapshot storage
  (snapshots are incremental, so actual usage is much smaller; still
  inside Always Free's per-volume 5-snapshot cap)

Toggle off with:

```hcl
# terraform.tfvars
enable_volume_backups = false
```

### Restore a boot volume

OCI Console → **Storage → Boot Volumes → (volume name) → Backups**:

1. Pick the snapshot date you want.
2. **Create Boot Volume** from that snapshot.
3. **Compute → Instance → Stop** the broken VM.
4. **Boot Volume → Detach** the bad volume.
5. Attach the restored volume → **Start**.

Downtime: ~5 minutes if the snapshot is from this week.

> The Terraform state still points at the original `boot_volume_id`. If
> you restore-by-replace, do `tofu apply -refresh-only` afterward so the
> state catches up; otherwise the next `tofu apply` will plan to swap
> the volume back.

## Layer 2: MySQL dumps (cron on the backend VM)

[`vm/backup/mysqldump.sh`](../vm/backup/mysqldump.sh) does
`docker compose exec mysql mysqldump --single-transaction` and writes
`/opt/knup/backups/knup-YYYY-MM-DD_HHMM.sql.gz`. Old files are pruned
after 14 days.

### Install (one-time, on the backend VM)

```bash
# from your PC
scp vm/backup/mysqldump.sh ubuntu@<backend-ip>:/tmp/

# on the VM
sudo install -m 0755 /tmp/mysqldump.sh /usr/local/bin/knup-mysqldump
echo '0 3 * * * /usr/local/bin/knup-mysqldump >> /var/log/knup-backup.log 2>&1' \
  | sudo tee /etc/cron.d/knup-mysql-backup
```

3 AM Asia/Seoul daily. First run will write the first dump immediately.

### Restore

```bash
# pick the snapshot
ls -lh /opt/knup/backups/
# restore (replace target_file)
cd /opt/knup
gunzip < /opt/knup/backups/knup-2026-06-09_0300.sql.gz \
  | docker compose exec -T mysql mysql -u root -p"$DB_ROOT_PASSWORD" knup
```

### (Optional) ship dumps off-box

Local dumps live on the same boot volume as the running DB — they don't
survive a "whole region lost" event. If you care about that, sync them
to Object Storage:

```bash
# install rclone, configure an OCI Object Storage remote, then:
rclone copy /opt/knup/backups oci:knup-backups/ --max-age 25h
```

Object Storage's 20 GB Free fits a year of compressed dumps comfortably.

## Recovery drill

Pick one and actually do it once a quarter. Untested backups are not
backups.

- Restore last night's dump into a throwaway MySQL container:
  ```bash
  docker run --rm -d --name mysql-test -e MYSQL_ROOT_PASSWORD=x mysql:8
  gunzip < /opt/knup/backups/knup-*.sql.gz \
    | docker exec -i mysql-test mysql -u root -px
  docker exec -i mysql-test mysql -u root -px -e 'SHOW TABLES' knup
  docker stop mysql-test
  ```
- Restore a boot-volume snapshot into a paused detached volume and
  attach it briefly to confirm the filesystem mounts.
