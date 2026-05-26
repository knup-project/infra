data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu_e2" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "app" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "knup-app"
  shape               = var.instance_shape

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_e2.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "knup-vnic"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  lifecycle {
    # source_id: ignore drift from periodic Ubuntu AMI refreshes.
    # metadata: cloud-init only runs on first boot, so re-hashing user_data
    #   would force-recreate a live instance for no benefit. To re-apply
    #   cloud-init, use `terraform taint` or recreate via the console.
    # create_vnic_details: protect manual VNIC changes (e.g. swapping the
    #   ephemeral public IP for a reserved one) from being reverted by TF.
    ignore_changes = [
      source_details[0].source_id,
      metadata,
      create_vnic_details,
    ]
  }
}
