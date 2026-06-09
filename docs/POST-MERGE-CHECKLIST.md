# Post-merge checklist (2026-06-09 sync)

Snapshot of what changed when `main` was pulled on **2026-06-09**
(`be28ceb..c1cad23`), what this branch (`fix/post-pull-tidy`) fixes
automatically, and what still needs a human.

## What changed in `main`

| Area | Before | After |
| --- | --- | --- |
| Compute | 1 VM (`app`) | **2 VMs** — `app` (backend) + `frontend` (`compute-frontend.tf`) |
| Database | Managed Oracle ATP (Free) | **MySQL 8 container** on the backend VM, persistent volume (`vm/docker-compose.yml`) |
| Process manager | PM2 + `ecosystem.config.cjs` | **Docker Compose** (`vm/docker-compose.yml`) |
| State backend | `backend "oci"` (never actually supported) | **`backend "s3"`** pointed at OCI's S3-compat endpoint |
| Tooling | `terraform` | **OpenTofu (`tofu`)** in CI; `terraform` 1.12+ still works locally |
| Monitoring | — | **Grafana Cloud Free + Alloy** profile in compose, dashboards in `grafana/` |
| cloud-init | Node 20 + PM2 + nginx + certbot | **Docker + compose plugin + 2 GB swap** + nginx + certbot |
| Variables | included `atp_*` | `atp_*` removed; DB creds moved to VM `/opt/knup/.env` |

## Fixed in this branch

- `outputs.tf` — `ssh_command` and `frontend_ssh_command` were hardcoded to
  `-i ~/.ssh/knup_oci`. Now driven by the new
  `var.ssh_private_key_path` (default `~/.ssh/id_ed25519`), so the printed
  commands are copy-paste runnable.
- `variables.tf` — added `ssh_private_key_path`.
- `terraform.tfvars.example` — documents the override.
- Local `terraform.tfvars` (gitignored) — removed the dangling
  `atp_admin_password` line so `tofu plan` no longer warns about an
  undeclared variable.

## Still needs a human

### 1. Decide what happens to the existing ATP (free, but: data loss if destroyed)

`db.tf` was deleted upstream. If your existing state still has
`oci_database_autonomous_database.knup`, the next `tofu plan` will
propose **destroying** it.

- If you don't need the data → let the destroy happen
- If you do → export anything important first (OCI Console → ATP →
  Backup, or `expdp` via the cloud shell)

This is a one-way action. **Do not run `tofu apply` until you've
decided.**

### 2. Create an OCI Customer Secret Key (for the new state backend)

`backend "s3"` authenticates with an OCI "Customer Secret Key", not
your API key. One-time setup:

1. OCI Console → top-right profile → **My profile** →
   **Customer Secret Keys** → **Generate Secret Key**
2. Name it (e.g. `knup-tofu-state`) → copy the **secret** **once**
   (it's never shown again). The **access key** is shown in the table.
3. Save both somewhere only you can read, e.g. `~/.oci/knup_s3_state.env`:
   ```bash
   AWS_ACCESS_KEY_ID=…access key…
   AWS_SECRET_ACCESS_KEY=…secret…
   AWS_REGION=ap-chuncheon-1
   ```
4. Before running `tofu`/`terraform`, source it:
   ```powershell
   Get-Content $HOME\.oci\knup_s3_state.env | ForEach-Object {
     $name,$val = $_ -split '=',2; [Environment]::SetEnvironmentVariable($name,$val)
   }
   ```
   (Bash: `set -a; . ~/.oci/knup_s3_state.env; set +a`.)

### 3. Pick a CLI: OpenTofu or Terraform

The repo's README is opinionated about OpenTofu (CI uses `tofu` 1.12.1).
Terraform 1.12+ also understands `backend "s3"` with the OCI compat
endpoint, so either works locally.

- OpenTofu: `winget install --id=OpenTofu.OpenTofu`
- Terraform: keep using `terraform` as before — just be aware that
  CI runs `tofu`, so any provider/version drift will surface there.

### 4. Re-initialize the backend

Because the backend type changed (`oci` → `s3`):

```powershell
cd C:\Users\82108\Desktop\knup-infra
# env vars from step 2 already set
tofu init -migrate-state    # or `terraform init -migrate-state`
```

`-migrate-state` copies your existing local/OCI state into the
S3-compat bucket. Confirm the move when prompted. If the bucket is
empty and you have only local state, `tofu init` (no flag) is fine.

### 5. Plan and review

```powershell
tofu plan
```

Sanity check the diff before applying:

- `oci_core_instance.frontend` should be **created** (the new 2nd VM)
- `oci_database_autonomous_database.knup` may be **destroyed** (see #1)
- everything else should be **no change** — if `oci_core_instance.app`
  shows pending changes, double-check the lifecycle `ignore_changes`
  block in `compute.tf` still covers them

Apply only when the plan matches your intent.

### 6. After apply

- Update GitHub repo secrets per
  [`docs/CI-SECRETS.md`](CI-SECRETS.md) — most notably the new
  `STATE_S3_ACCESS_KEY_ID` / `STATE_S3_SECRET_ACCESS_KEY` from step 2
- Pull the new `frontend_public_ip` from `tofu output` and SSH in to
  bootstrap the Next.js side (no runbook yet; follows the same
  Docker pattern as backend)
- Follow [`docs/DEPLOY.md`](DEPLOY.md) to bring up the backend
  Compose stack
- Optional: enable monitoring per
  [`docs/MONITORING.md`](MONITORING.md)
