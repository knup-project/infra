# GitHub Actions secrets

`.github/workflows/terraform.yml` consumes these. Set them in:

GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**.

| Secret name | Where the value comes from | Notes |
| --- | --- | --- |
| `OCI_TENANCY_OCID` | OCI Console → top-right profile → **Tenancy** → "OCID" | Same as `tenancy_ocid` in `terraform.tfvars` |
| `OCI_USER_OCID` | OCI Console → **My profile** → "OCID" | Same as `user_ocid` |
| `OCI_FINGERPRINT` | OCI Console → **My profile → API Keys** column "Fingerprint" | Same as `fingerprint` |
| `OCI_REGION` | OCI home region key, e.g. `ap-chuncheon-1` | Same as `region` |
| `OCI_COMPARTMENT_OCID` | Identity & Security → Compartments → your compartment OCID | Same as `compartment_ocid` |
| `OCI_PRIVATE_KEY` | **Full** contents of `~/.oci/oci_api_key.pem`, including the `-----BEGIN/END PRIVATE KEY-----` lines | Multiline. Paste exactly. |
| `SSH_PUBLIC_KEY` | Contents of `~/.ssh/id_ed25519.pub` (one line) | Same as `ssh_public_key` |
| `ATP_ADMIN_PASSWORD` | The password you set when creating the ATP DB | Same as `atp_admin_password` |

## Quick check

After adding them all, open a small PR (e.g. tweak a comment in `network.tf`) and confirm:

- The **plan** job runs and posts a `#### Terraform Plan` comment with `Plan: 0 to add, 0 to change, 0 to destroy.`
- No "Error: required variable X not set" lines.

If anything is missing, the plan job will say which variable.

## After the first CI plan succeeds

You can stop applying locally. The CI flow becomes:

1. Branch + edit `.tf`
2. PR → CI plans and comments diff
3. Merge to `main` → CI applies

`terraform.tfvars` then only exists locally for one-off manual `terraform plan` / `apply` from your PC. The workflow uses `TF_VAR_*` env vars instead.
