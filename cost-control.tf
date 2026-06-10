# Opt-in monthly budget for the knup compartment.
#
# Always Free should bill $0/month. The point of this resource is to catch a
# misconfiguration (e.g. someone resizes a VM to a paid shape, or the ATP
# Free quota is exceeded) before it racks up a bill.
#
# The resource is gated on var.budget_alert_emails — leave it empty and
# nothing is created. Once you set at least one email and re-apply, OCI
# starts evaluating spend and emails the listed addresses when the rule
# trips.
locals {
  budget_enabled = length(var.budget_alert_emails) > 0
}

resource "oci_budget_budget" "knup" {
  count = local.budget_enabled ? 1 : 0

  # Budgets are created in the tenancy root, but target a child compartment.
  compartment_id = var.tenancy_ocid
  target_type    = "COMPARTMENT"
  targets        = [var.compartment_ocid]

  amount       = var.budget_amount
  reset_period = "MONTHLY"
  display_name = "knup-monthly"
  description  = "Monthly billing watchdog for the knup compartment."
}

# Fire on any non-zero actual spend — Always Free should never produce one.
resource "oci_budget_alert_rule" "knup_any_spend" {
  count = local.budget_enabled ? 1 : 0

  budget_id      = oci_budget_budget.knup[0].id
  display_name   = "any-actual-spend"
  type           = "ACTUAL"
  threshold_type = "PERCENTAGE"
  threshold      = 1
  recipients     = join(";", var.budget_alert_emails)
  message        = "knup compartment has incurred actual cost. Investigate which resource left the Always Free envelope."
}
