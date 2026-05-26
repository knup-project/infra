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

variable "atp_db_name" {
  type    = string
  default = "knupdb"
}

variable "atp_display_name" {
  type    = string
  default = "KNUP-ATP"
}

variable "atp_admin_password" {
  type      = string
  sensitive = true
}
