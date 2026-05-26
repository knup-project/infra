resource "oci_database_autonomous_database" "knup" {
  compartment_id           = var.compartment_ocid
  db_name                  = var.atp_db_name
  display_name             = var.atp_display_name
  admin_password           = var.atp_admin_password
  data_storage_size_in_tbs = 1
  db_workload              = "OLTP"
  is_free_tier             = true
  license_model            = "LICENSE_INCLUDED"

  lifecycle {
    ignore_changes = [cpu_core_count]
  }
}
