# knup-infra

Terraform-managed infrastructure for the KNUP project on Oracle Cloud Infrastructure (OCI) Always Free tier.

## Overview

- **Compute**: `VM.Standard.E2.1.Micro` Ubuntu 22.04 (Always Free)
- **Database**: Autonomous Transaction Processing (ATP) Free
- **Network**: Single VCN + public subnet + Internet Gateway
- **State backend**: OCI Object Storage bucket
- **CI/CD**: GitHub Actions (plan on PR, apply on main)

## Prerequisites

- Terraform `>= 1.5`
- An OCI tenancy with Always Free capacity in your home region
- OCI API key pair generated (`~/.oci/oci_api_key.pem`)
- An OCI Object Storage bucket for remote Terraform state
- An SSH key pair for VM access

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# fill in the values
terraform init
terraform plan
terraform apply
```

## Layout

| File | Purpose |
| --- | --- |
| `provider.tf` | OCI provider + remote state backend |
| `variables.tf` | Input variable declarations |
| `network.tf` | VCN, IGW, route table, security list, subnet |
| `compute.tf` | VM instance + Ubuntu image lookup |
| `cloud-init.yaml` | VM bootstrap (Node.js, PM2, Nginx, Certbot) |
| `db.tf` | Autonomous Database (ATP Free) |
| `outputs.tf` | Public IP, DB connection URLs, SSH helper |
| `terraform.tfvars.example` | Template for required input values |
| `.github/workflows/terraform.yml` | CI pipeline |
