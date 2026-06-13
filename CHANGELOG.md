# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [SemVer](https://semver.org/lang/ko/)를 따릅니다.

## [Unreleased]
### Added
- OCI Budget + 1% actual-spend 알림 (opt-in, `budget_alert_emails`)
- Boot volume bronze 백업 정책 자동 attach + MySQL `mysqldump` 스크립트
- Grafana Cloud Loki로 Docker 컨테이너 로그 전송 (Alloy 확장)
- `docs/POST-MERGE-CHECKLIST.md`, `docs/COST.md`, `docs/BACKUP.md`,
  `docs/LOGGING.md` 런북 4종
- CONTRIBUTING.md + PR/Issue 템플릿, README 아키텍처 다이어그램 + 배지
### Changed
- CI plan job: `.terraform` 캐시, sticky PR comment, stale run 자동 취소
- CI apply job: `.terraform` 캐시 + workflow-level concurrency 가드
- `outputs.tf`의 ssh 명령어가 `var.ssh_private_key_path` 사용
### 계획
- managed DB/백업 자동화, 무중단 배포(blue-green) 검토 — [로드맵](https://github.com/knup-project/.github/blob/main/docs/ROADMAP.md)

## [1.0.0] - 2026-06-08
### Added
- 백엔드 종합 Grafana 대시보드 JSON, Grafana Cloud Free + Alloy 원격 수집
- 프론트엔드용 두 번째 E2.1.Micro VM, 백엔드 컨테이너에 `GEMINI_API_KEY` 주입
### Changed
- Spring Boot + MySQL + Docker 스택으로 인프라 재구성(`vm/docker-compose.yml`)

## [0.1.0] - 2026-06-01
### Added
- OCI Always Free VM + VCN/네트워크(OpenTofu), cloud-init(Docker·swap·nginx·certbot)
- HTTPS + 도메인 설정, 배포 런북, OpenTofu CI(plan/apply), 원격 state(OCI Object Storage)

[Unreleased]: https://github.com/knup-project/infra/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/knup-project/infra/releases/tag/v1.0.0
[0.1.0]: https://github.com/knup-project/infra/releases/tag/v0.1.0
