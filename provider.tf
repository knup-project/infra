terraform {
  required_version = ">= 1.5"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }

  # OCI Object Storage exposes an S3-compatible API, so we use the standard
  # `s3` backend pointed at the regional compat endpoint. Auth uses OCI
  # "Customer Secret Keys" (access/secret) passed at init via -backend-config
  # or AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY env vars (never committed).
  # NOTE: `backend "oci"` does not exist in Terraform/OpenTofu — this replaces it.
  backend "s3" {
    bucket = "knup-terraform-state"
    key    = "infra/terraform.tfstate"
    region = "ap-chuncheon-1"

    endpoints = {
      s3 = "https://ax59rukgiass.compat.objectstorage.ap-chuncheon-1.oraclecloud.com"
    }

    use_path_style              = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
