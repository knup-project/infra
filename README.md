# knup-infra

Terraform/OpenTofu-managed infrastructure for the KNUP (QuizFlow) project on
Oracle Cloud Infrastructure (OCI) Always Free tier.

## Overview

- **Compute**: `VM.Standard.E2.1.Micro` Ubuntu 22.04 (Always Free), +2 GB swap
- **App stack**: Spring Boot backend + MySQL 8 as **Docker Compose** containers
  on the VM (`vm/docker-compose.yml`), fronted by nginx
- **Database**: MySQL 8 container with a persistent volume (no managed DB)
- **Network**: single VCN + public subnet + Internet Gateway (22/80/443)
- **State backend**: OCI Object Storage bucket `knup-terraform-state`, via the
  S3-compatible `backend "s3"`
- **CI/CD**: GitHub Actions with **OpenTofu** (plan on PR, apply on main)

## Tooling

Use **OpenTofu** (`tofu`) — Terraform has no `oci`/this `s3`-compat combo issue,
and OpenTofu 1.12+ is what CI runs. State auth uses an OCI **Customer Secret
Key** exported as AWS creds.

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in values
export AWS_ACCESS_KEY_ID=...  AWS_SECRET_ACCESS_KEY=...   # OCI Customer Secret Key
export AWS_REGION=ap-chuncheon-1
tofu init
tofu plan
tofu apply
```

## Prerequisites

- OpenTofu `>= 1.5` (CI uses 1.12.1)
- OCI tenancy with Always Free capacity in the home region
- OCI API key pair (`~/.oci/<key>.pem`) referenced by `private_key_path`
- OCI Object Storage bucket for remote state + a Customer Secret Key
- SSH key pair for VM access

## Runbooks

- [`docs/DEPLOY.md`](docs/DEPLOY.md) — deploy the backend+MySQL stack with Docker Compose, front with nginx
- [`docs/HTTPS.md`](docs/HTTPS.md) — attach a domain + Let's Encrypt cert
- [`docs/CI-SECRETS.md`](docs/CI-SECRETS.md) — GitHub Actions secrets for the OpenTofu workflow
- [`docs/MONITORING.md`](docs/MONITORING.md) — Grafana Cloud (Free) + Alloy metrics on the 1 GB VM

## Layout

| File | Purpose |
| --- | --- |
| `provider.tf` | OCI provider + S3-compatible remote state backend |
| `variables.tf` | Input variable declarations |
| `network.tf` | VCN, IGW, route table, security list, subnet |
| `compute.tf` | VM instance + Ubuntu image lookup |
| `cloud-init.yaml` | VM bootstrap (Docker + Compose, swap, Nginx, Certbot) |
| `outputs.tf` | Public IP + SSH helper |
| `terraform.tfvars.example` | Template for required input values |
| `vm/docker-compose.yml` | Backend (ghcr image) + MySQL stack run on the VM |
| `vm/nginx/knup-app.conf` | nginx reverse proxy (443 -> backend :8080) |
| `vm/.env.example` | Template for the VM's `/opt/knup/.env` (DB secrets) |
| `.github/workflows/terraform.yml` | OpenTofu CI pipeline |
