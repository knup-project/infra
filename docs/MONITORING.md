# Monitoring — Grafana Cloud (Free) + Alloy

## 왜 이 방식인가
- 앱(`app`)·프론트(`frontend`) VM이 **AMD Always Free 2개를 이미 소진** → 추가 AMD VM은 과금.
- Ampere **A1**(별도 무료 풀)은 `ap-chuncheon-1`에서 capacity가 자주 없어 **사양을 줄여도 확보가 보장되지 않음**(호스트 가용성 문제).
- → 1 GB VM 부담을 거의 주지 않는 **Grafana Cloud Free + 경량 Alloy**가 현실적.

## 구성
- 백엔드가 `/actuator/prometheus`를 **관리 포트 8081**(내부 전용, nginx 미노출)로 노출 (backend PR #20).
- 백엔드 VM의 **Grafana Alloy** 컨테이너(`grafana/alloy`, `mem_limit 160m`)가 같은 compose 네트워크의
  `backend:8081`을 30초마다 스크래핑 → **Grafana Cloud로 remote-write**.
- 대시보드·알림은 Grafana Cloud(SaaS). VM엔 시계열 저장소를 두지 않는다.

```
backend:8081/actuator/prometheus ──scrape──▶ Alloy(VM) ──remote_write──▶ Grafana Cloud
```

## 셋업 (1회)
1. Grafana Cloud 무료 가입: https://grafana.com/auth/sign-up/create-user
2. **Connections → Prometheus (Hosted)** 에서:
   - **URL**: `https://prometheus-prod-XX-….grafana.net/api/prom/push`
   - **Username**: 숫자 instance ID
   - **Password**: **Access Policy token**(`metrics:write` scope) — *Administration → Cloud access policies* 에서 발급
3. VM `/opt/knup/.env` 에 채우기:
   ```
   GRAFANA_CLOUD_PROM_URL=https://prometheus-prod-XX-….grafana.net/api/prom/push
   GRAFANA_CLOUD_PROM_USER=123456
   GRAFANA_CLOUD_API_KEY=glc_…
   ```
4. `vm/alloy/config.alloy` 를 VM `/opt/knup/alloy/config.alloy` 로 복사:
   ```bash
   scp -i ~/.ssh/knup_oci -r vm/alloy ubuntu@<backend-ip>:/opt/knup/
   ```
5. 모니터링 프로파일로 Alloy 만 기동(기존 backend/mysql 영향 없음):
   ```bash
   ssh ubuntu@<backend-ip> 'cd /opt/knup && docker compose --profile monitoring up -d alloy'
   ```
6. Grafana Cloud → **Dashboards → Import** (데이터소스 = 위 Hosted Prometheus):
   - JVM (Micrometer): dashboard ID **4701**
   - Spring Boot Statistics: dashboard ID **6756**

## 알림 (Grafana Cloud Alerting) — 제안서 §11.2 기준 예시
- API 에러율 > 5% (5분): `sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count[5m])) > 0.05`
- JVM 힙 > 90%: `jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} > 0.9`
- p95 응답 지연 > 0.5s: `histogram_quantile(0.95, sum by (le) (rate(http_server_requests_seconds_bucket[5m]))) > 0.5`

## 메모리 안전 / 운영
- Alloy `mem_limit: 160m`. backend(JVM) + MySQL + Alloy 가 1 GB + 2 GB swap 안에서 돌도록 캡.
- 부담되면 `scrape_interval`을 60s로 늘리거나 `docker compose --profile monitoring down`(Alloy만 중지).
- 메트릭 외 **헬스/업타임**만 필요하면 외부 UptimeRobot(무료)으로 `/actuator/health`(8081은 내부이므로 별도 노출 필요) 또는 메인 도메인 핑.

## 향후
- 커스텀 비즈니스 메트릭(`quiz_sessions_active`, `quiz_answers_total`)은 백엔드에 Micrometer `Gauge/Counter`로 추가하면 같은 파이프라인으로 흘러간다.
