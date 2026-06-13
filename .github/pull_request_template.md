## Summary

<!-- 1-3 bullets: what changed and why -->

## Linked issues

<!-- e.g. Closes #12, Refs #8 -->

## Expected `tofu plan`

<!-- Paste the resource diff or "no infra changes — docs/CI only" -->

```
+ 0 to add, ~ 0 to change, - 0 to destroy
```

## Risk

- [ ] No running resources are recreated (lifecycle `ignore_changes` covers any drift)
- [ ] If new variables were added, defaults keep behaviour identical
- [ ] Docs / runbooks updated when behaviour changed

## Test plan

- [ ] `tofu fmt -check -recursive` passes
- [ ] `tofu validate` passes
- [ ] `tofu plan` matches the snippet above
- [ ] (if VM-side change) `docker compose config` parses on the host
