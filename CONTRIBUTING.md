# Contributing

Quick reference for people working on this infra repo. Anything not listed
here is "use your judgement" — keep the codebase boring and reversible.

## Branch naming

```
feat/<area>-<short>     new resource or feature
fix/<area>-<short>      bug fix
chore/<short>           tooling / repo hygiene
docs/<short>            docs / runbook only
ci/<short>              workflow changes
```

`<area>` examples: `compute`, `network`, `backup`, `cost`, `monitoring`,
`tfvars`, `cloud-init`. Branch off `main`; rebase rather than merge `main`
back in.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/). One logical
change per commit — easier to revert one resource without dragging unrelated
files along.

```
feat(backup): assign bronze policy to frontend boot volume
fix(cloud-init): insert iptables rule at head of INPUT
ci(plan): cache .terraform between PR runs
docs(cost): document opt-in budget alerting
```

Never append `Co-Authored-By: Claude` (or any AI co-author). Use Claude as a
tool, not a co-author.

## Pull requests

- Open against `main`. The PR template fills in: summary, linked issues
  (`Closes #N`), expected `tofu plan` diff, risk checklist, test plan.
- The CI plan posts a sticky comment with the live plan output — re-read it
  before requesting review.
- **Hard rule**: a PR that recreates a running VM, VCN, or boot volume needs
  an explicit note in the body explaining why. The default expectation is
  that `ignore_changes` covers all drift.

## Local checks before pushing

```bash
tofu fmt -recursive
tofu validate
tofu plan          # against your own tfvars / state
```

The CI runs `tofu fmt -check -recursive` (fails on unformatted files) and
`tofu validate` on every PR.

## Secrets

- Never commit `terraform.tfvars`, `*.pem`, or any file containing OCIDs +
  fingerprints + private keys together. `.gitignore` already covers the
  common cases; if you add a new secret-bearing file type, extend it.
- VM-side secrets (DB, Gemini, Grafana Cloud) live in `/opt/knup/.env` on the
  host. The template is `vm/.env.example` — that's the only file that should
  contain placeholder values.

## Reviewing

- Re-run the sticky plan after rebase. A stale plan is worse than no plan.
- Confirm no resources are destroyed unless the PR explicitly says so.
- For VM-side changes, check whether the host needs `docker compose pull` /
  `up -d alloy` after merge — those don't run automatically.
