# Frontend host: a second Always Free E2.1.Micro (AMD, 1 OCPU / 1 GB), kept
# separate from the backend VM so Next.js has its own box. Reuses the same VCN /
# public subnet / security list and the Ubuntu image + arch-agnostic cloud-init
# from compute.tf.
#
# (Ampere A1 was the first choice for more headroom, but free A1 capacity is
# unavailable in ap-chuncheon-1 — "Out of host capacity" — and the frontend is
# light, so the reliable 2nd micro is the better fit.)
resource "oci_core_instance" "frontend" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "knup-frontend"
  shape               = "VM.Standard.E2.1.Micro"

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_e2.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "knup-frontend-vnic"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  lifecycle {
    ignore_changes = [
      source_details[0].source_id,
      metadata,
      create_vnic_details,
    ]
  }
}
