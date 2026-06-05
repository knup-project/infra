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
}

# NOTE: The database is no longer a managed Oracle ATP. MySQL 8 runs as a
# Docker container on the VM (see vm/docker-compose.yml), so DB credentials are
# VM-side secrets in /opt/knup/.env — NOT Terraform variables.
