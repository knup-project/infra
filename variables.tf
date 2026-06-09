variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "private_key_path" {
  type    = string
  default = "~/.oci/oci_api_key.pem"
}

variable "region" {
  type    = string
  default = "ap-chuncheon-1"
  validation {
    condition     = can(regex("^[a-z]{2,3}-[a-z]+-[0-9]+$", var.region))
    error_message = "region must look like an OCI region key, e.g. ap-chuncheon-1, us-ashburn-1."
  }
}

variable "compartment_ocid" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "instance_shape" {
  type    = string
  default = "VM.Standard.E2.1.Micro"
  validation {
    condition = contains(
      ["VM.Standard.E2.1.Micro", "VM.Standard.A1.Flex"],
      var.instance_shape,
    )
    error_message = "instance_shape must be an OCI Always Free shape (VM.Standard.E2.1.Micro or VM.Standard.A1.Flex)."
  }
}

# Path to the local SSH private key used to reach the VMs. Only referenced by
# the ssh_command outputs (informational); change here if your key isn't at the
# default location.
variable "ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

# --- Budget alerting -------------------------------------------------------
# The repo is Always Free; expected monthly cost is $0. budget_alert_emails
# being empty is the opt-out: cost-control.tf creates nothing in that case.
# Set it to one or more addresses to provision the budget + 1%-actual alert.
variable "budget_amount" {
  type    = number
  default = 1
}

variable "budget_alert_emails" {
  type    = list(string)
  default = []
}

# --- Boot volume backups ---------------------------------------------------
# When true (default), the predefined Oracle "bronze" backup policy is
# attached to each VM's boot volume. Bronze = one weekly full backup, kept 4
# weeks (within Always Free: 5 backups per volume). Set false to detach.
variable "enable_volume_backups" {
  type    = bool
  default = true
}

# NOTE: The database is no longer a managed Oracle ATP. MySQL 8 runs as a
# Docker container on the VM (see vm/docker-compose.yml), so DB credentials are
# VM-side secrets in /opt/knup/.env — NOT Terraform variables.
