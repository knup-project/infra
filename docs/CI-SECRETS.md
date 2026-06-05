# GitHub Actions secrets

## infra repo — `.github/workflows/terraform.yml` (OpenTofu)

Set in: GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**.

| Secret name | Where the value comes from | Notes |
| --- | --- | --- |
| `OCI_TENANCY_OCID` | `tenancy_ocid` in `terraform.tfvars` | OCI Console → profile → Tenancy → OCID |
| `OCI_USER_OCID` | `user_ocid` | OCI Console → My profile → OCID |
| `OCI_FINGERPRINT` | `fingerprint` | My profile → API Keys → Fingerprint |
| `OCI_REGION` | `region`, e.g. `ap-chuncheon-1` | home region |
| `OCI_COMPARTMENT_OCID` | `compartment_ocid` | here = tenancy root |
| `OCI_PRIVATE_KEY` | **Full** contents of the OCI API key PEM (`~/.oci/knup_oci_api_key.pem`), incl. BEGIN/END lines | Multiline; paste exactly |
| `SSH_PUBLIC_KEY` | `ssh_public_key` (the `knup-oci` ed25519 public key) | one line |
| `STATE_S3_ACCESS_KEY_ID` | OCI **Customer Secret Key** access key (for the S3-compat state backend) | from `~/.oci/knup_s3_state.env` |
| `STATE_S3_SECRET_ACCESS_KEY` | OCI Customer Secret Key secret | from `~/.oci/knup_s3_state.env` |

> No more `ATP_ADMIN_PASSWORD` — the database is now a MySQL container on the VM,
> not a managed Oracle ATP. Its credentials live in the VM's `/opt/knup/.env`.

Remote state lives in the OCI Object Storage bucket `knup-terraform-state`
(`backend "s3"` in `provider.tf`), authenticated by the `STATE_S3_*` keys.

## backend repo — `.github/workflows/docker-image.yml`

No custom secrets needed. It pushes to `ghcr.io` using the built-in
`GITHUB_TOKEN` (workflow has `packages: write`).

## Quick check (infra)

Open a small PR (tweak a comment in `network.tf`) and confirm the **Plan** job
posts `Plan: 0 to add, 0 to change, 0 to destroy.` with no "required variable
not set" errors.
