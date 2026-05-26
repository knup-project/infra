terraform {
  required_version = ">= 1.5"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }

  # TODO: replace `namespace` with your OCI Object Storage namespace
  # (Tenancy details > Object Storage Namespace in the OCI console).
  backend "oci" {
    bucket    = "knup-terraform-state"
    namespace = "REPLACE_WITH_OCI_NAMESPACE"
    key       = "infra/terraform.tfstate"
    region    = "ap-chuncheon-1"
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
