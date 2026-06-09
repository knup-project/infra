# Boot-volume snapshot policy attachment.
#
# Oracle ships predefined backup policies (bronze, silver, gold) per region.
# Bronze = 1 weekly full backup, kept 4 weeks — well within Always Free's
# "5 backups per volume" envelope, and enough to recover from a bad
# cloud-init / disk corruption inside the last month.
#
# The policy itself is data-only; we only need to assign it to each VM's
# boot volume.
data "oci_core_volume_backup_policies" "bronze" {
  filter {
    name   = "display_name"
    values = ["bronze"]
  }
}

resource "oci_core_volume_backup_policy_assignment" "app_boot" {
  count = var.enable_volume_backups ? 1 : 0

  asset_id  = oci_core_instance.app.boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.bronze.volume_backup_policies[0].id
}

resource "oci_core_volume_backup_policy_assignment" "frontend_boot" {
  count = var.enable_volume_backups ? 1 : 0

  asset_id  = oci_core_instance.frontend.boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.bronze.volume_backup_policies[0].id
}
