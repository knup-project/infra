# Logging — Grafana Cloud Loki via Alloy

Companion to [MONITORING.md](MONITORING.md). The same Alloy container
that scrapes metrics now also tails every running container's stdout/
stderr and ships them to Grafana Cloud Loki.

```
┌─────────────────────┐    docker.sock (RO)    ┌───────┐    HTTPS basic auth    ┌──────────────────┐
│ backend / mysql /   │ ─────────────────────► │ Alloy │ ─────────────────────► │ Grafana Cloud    │
│ alloy stdout/stderr │                        └───────┘                        │ Loki (Hosted)    │
└─────────────────────┘                                                          └──────────────────┘
```

## Why this layer

`docker compose logs` is fine for live tail, but:

- Logs disappear when the container restarts (no `logging: {driver: local}` retention)
- You have to be SSH'd in to read them
- No grep across time ranges or correlation with metrics

Loki gives you both `{container="backend"} |= "ERROR"` queries and joins
with the Prometheus metrics already in Grafana Cloud (same project, same
dashboards, same alerting).

## Setup (one-time)

Prereq: [MONITORING.md](MONITORING.md) is already working, so
`GRAFANA_CLOUD_API_KEY` is set.

### 1. Get the Loki Hosted endpoint

Grafana Cloud → **Connections → Loki (Hosted)** → copy:

- **URL**: `https://logs-prod-XX-….grafana.net/loki/api/v1/push`
- **Username**: numeric instance ID (often different from Prometheus's)

### 2. Make sure the access policy token has `logs:write`

Grafana Cloud → **Administration → Cloud access policies** →
your knup policy → **scopes** → add `logs:write` (alongside the existing
`metrics:write`). Save. The existing token keeps working.

### 3. Append to `/opt/knup/.env` on the backend VM

```
GRAFANA_CLOUD_LOKI_URL=https://logs-prod-XX-….grafana.net/loki/api/v1/push
GRAFANA_CLOUD_LOKI_USER=123456
# GRAFANA_CLOUD_API_KEY already set
```

### 4. Roll Alloy with the new config

```bash
# from your PC
scp vm/alloy/config.alloy ubuntu@<backend-ip>:/opt/knup/alloy/config.alloy
scp vm/docker-compose.yml ubuntu@<backend-ip>:/opt/knup/docker-compose.yml
```

```bash
# on the VM
cd /opt/knup
docker compose --profile monitoring up -d alloy
docker compose logs --tail=30 alloy   # should see "loki.source.docker started" and no auth errors
```

## Verify

In Grafana Cloud:

- **Explore → Data source: Loki** → query `{host="knup-backend"}` →
  recent stdout lines from all containers should appear
- Filter to one container: `{container="backend"} |= "ERROR"`
- Make a dashboard panel by saving the explore query

## Resource impact

- Alloy memory cap is still `160m` (unchanged). Log scraping in Alloy
  is streaming-light — typical RSS rises ~20 MB.
- Network egress: a few MB/day for a quiet service. Free Loki tier is
  50 GB/month, way beyond our needs.

## Common gotchas

| Symptom | Cause | Fix |
| --- | --- | --- |
| Alloy logs say `permission denied /var/run/docker.sock` | Socket mount missing or wrong path | Confirm `/var/run/docker.sock:/var/run/docker.sock:ro` in docker-compose.yml; re-up with `docker compose up -d alloy` |
| Alloy starts but Loki Explore is empty | Token missing `logs:write` scope | Update the policy and either rotate the token or wait for cache miss (~1 min) |
| Lots of `mysql_data` "Note: stats_persistent" noise | MySQL info log verbosity | Normal — filter at query time: `{container="mysql"} != "[Note]"` |
| New container started but its logs don't show up | Alloy's Docker discovery cache lag | Wait up to 30 s, or `docker compose restart alloy` |

## Turn it off

Logging is opt-in via the same `monitoring` profile, so:

```bash
docker compose --profile monitoring down
```

…stops Alloy entirely (kills both metrics and logs shipping). To keep
metrics but drop logs, leave the Loki env vars empty in `.env`; the
`loki.write` target then no-ops and shipped log records are dropped at
the Alloy side.
