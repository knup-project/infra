# Cost monitoring

The repo provisions only Always Free resources, so expected monthly cost is
**$0**. The pieces in this doc exist to catch the day that stops being true.

## What's already free

| Component | Always Free quota | What we use |
| --- | --- | --- |
| Compute (AMD `E2.1.Micro`) | 2 VMs / tenancy | 2 (app + frontend) — at quota |
| Boot volume | 200 GB total | 2 × 50 GB = 100 GB |
| Block volume backups | 5 backups / volume | Bronze policy (weekly) — see [BACKUP.md](BACKUP.md) |
| Object Storage | 20 GB Standard | Terraform state + (optional) MySQL dumps |
| Outbound transfer | 10 TB / month | well under |
| Grafana Cloud (3rd-party) | 50 GB logs + 10k series | Alloy ships into this — see [MONITORING.md](MONITORING.md) |

Anything outside this set will start billing.

## Verify "free tier" status

OCI Console → top-right profile → **Tenancy** → "Account Type" should read
`PayG` or `Trial`. Sidebar **Subscription** confirms the quota counts.

For ongoing visibility:

- **Governance & Administration → Cost Management → Cost Analysis**
  shows daily charges. With Always Free in steady state the chart is flat at
  $0.

## Opt-in budget alert

`cost-control.tf` ships a `oci_budget_budget` + `oci_budget_alert_rule` that
fires the moment actual cost exceeds **1% of `budget_amount`** (default
$0.01). It's gated on `budget_alert_emails`:

In your local `terraform.tfvars`:

```hcl
budget_alert_emails = ["you@example.com"]
# budget_amount    = 1   # optional, default 1 USD
```

Re-run `tofu apply`. Plan should show `+ 2 to add` (budget + alert rule),
no destroys.

After apply, the alert lives at:
**Governance & Administration → Cost Management → Budgets → knup-monthly**.

To turn it off later, delete the line (or set `budget_alert_emails = []`)
and apply again — the budget + alert get removed cleanly.

## Common ways the bill stops being $0

| Symptom | Cause | Fix |
| --- | --- | --- |
| "Compute" line item appears | A VM was resized to a non-`E2.1.Micro`/`A1.Flex` shape | Resize back, or accept the cost |
| "Block Volume" line item | Boot volume grew past 200 GB (across all volumes) or > 5 backups per volume | Shrink, or prune backups |
| "Object Storage" line item | State bucket + backups > 20 GB | Add a lifecycle rule to expire old objects |
| "Outbound Data Transfer" | > 10 TB egress in a month | Cache aggressively at nginx; rate-limit |
| "Autonomous Database" line item | The ATP we removed in the 2026-06-09 sync is still running outside the Free 2× ATP quota | Destroy it (see [POST-MERGE-CHECKLIST.md](POST-MERGE-CHECKLIST.md) §1) |

When the alert fires, **Cost Analysis** broken down by Service tells you
which line item went red.
