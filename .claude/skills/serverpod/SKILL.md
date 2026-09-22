---
name: serverpod
description: Serverpod 4.0 작업의 진입점 — 주제에 맞는 serverpod-* 스킬을 고르고, 스킬에 없는 내용은 docs.serverpod.dev 공식 문서를 마크다운으로 받아 읽는다. "/serverpod 마이그레이션", "/serverpod 인증 scope", "/serverpod callRecurring" 처럼 쓴다. 서버팟 문서를 찾거나 API 사용법이 불확실할 때 사용.
argument-hint: <주제 또는 질문>
---

# /serverpod — 스킬 라우터 + 공식 문서 조회

이 프로젝트는 Serverpod **4.0.0** (`investment_ontology_serverpod_server/pubspec.yaml`)을 쓴다.
설치된 `serverpod-*` 스킬 21개는 `skills` CLI가 `user-invocable: false`로 설치하므로 `/` 메뉴에는 안 보이지만,
Skill 도구로는 언제든 불러올 수 있다. 이 스킬이 그 진입점이다.

## 1. 우선순위

1. `AGENTS.md`의 프로젝트 규칙 (MCP 우선, 생성 코드 수정 금지, 인증 우회 금지, `ingest_schedule.dart` import 금지 등)
2. 아래 표의 `serverpod-*` 스킬
3. 공식 문서 (2절)
4. 패키지 소스 (3절) — 문서와 실제 API가 다를 때 최종 판단 근거

처음 작업이면 `serverpod-overview`를 한 번 불러온다.

## 2. 주제 → 스킬

`$ARGUMENTS`의 키워드로 고른다. 여러 개면 여러 개 불러온다.

| 키워드 | 스킬 |
|---|---|
| 구조, `serverpod start`, MCP 도구, 체크리스트 | `serverpod-overview` |
| 엔드포인트, `Session`, 파라미터, 클라이언트 호출, 예외 전달 | `serverpod-endpoints` |
| `.spy.yaml`, 필드, 기본값, `table`, `relation`, enum, exception | `serverpod-models` |
| CRUD, `where`, 정렬, 페이지네이션, `include`, 트랜잭션, `unsafeQuery` | `serverpod-database` |
| 마이그레이션, repair, `definition.sql`, `migration.sql` 손편집 | `serverpod-migrations` |
| 로그인, `authenticated`, `Scope`, admin, `session.authenticated` | `serverpod-auth` |
| `development.yaml`, `passwords.yaml`, 환경변수, run mode, `generator.yaml`, TLS | `serverpod-configuration` |
| `session.caches`, Redis 캐시 | `serverpod-caching` |
| FutureCall, `callWithDelay`, `callAtTime`, `callRecurring`, cron | `serverpod-scheduling` |
| Stream 반환·수신, WebSocket | `serverpod-streams` |
| `session.messages`, `postMessage`, `addListener`, Redis pub/sub | `serverpod-server-events` |
| `InternalSession`, `createSession`, 요청 밖 세션, StateError(closed) | `serverpod-sessions` |
| `session.log`, 로그 레벨·보관 | `serverpod-logging` |
| `withServerpod`, `sessionBuilder`, 테스트 인증, DB 롤백 | `serverpod-testing` |
| 업로드, `UploadDescription`, S3/GCP/R2 | `serverpod-file-uploads` |
| Relic, REST/webhook 라우트, 정적 파일, SPA, 미들웨어 | `serverpod-webserver` (+ `relic-*`) |
| 모듈 추가, nickname, 모듈 모델 참조 | `serverpod-modules` |
| `/livez` `/readyz`, HealthIndicator | `serverpod-health-checks` |
| 버전 올리기, 3.x→4.0 | `serverpod-upgrading` |
| 배포, Serverpod Cloud, Docker | `serverpod-deployment` (배포 실행은 사용자의 결정) |
| Flutter 새 화면 디자인 | `serverpod-flutter-frontend` — **이 앱은 `lib/design/` 디자인 시스템이 있으므로 쓰지 않는다** |

## 3. 스킬에 없으면 공식 문서를 읽는다

docs.serverpod.dev의 모든 페이지는 URL 끝에 `.md`를 붙이면 마크다운으로 받아진다. 브라우저 대신 curl로 읽는다.

```bash
# 1) 색인에서 페이지 찾기 (최신본). 오프라인이면 references/docs-index.md 스냅샷을 grep 한다.
curl -sL https://docs.serverpod.dev/llms.txt | grep -i '<키워드>'

# 2) 페이지 본문 받기
curl -sL https://docs.serverpod.dev/concepts/scheduling/recurring-tasks.md
```

자주 쓰는 페이지:

- 마이그레이션: `concepts/data-and-the-database/database/migrations.md`
- 필드 타입표: `concepts/data-and-the-database/models/field-types.md`
- 필터: `concepts/data-and-the-database/database/filtering.md`, 조인: `.../relation-queries.md`
- 인증 기본: `concepts/authentication/basics.md`, 사용자: `concepts/authentication/working-with-users.md`
- 반복 작업: `concepts/scheduling/recurring-tasks.md`
- 하위 호환 규칙: `concepts/endpoints-and-apis/backward-compatibility.md`
- CLI 전체: `concepts/cli/introduction.md`, MCP 서버: `concepts/cli/commands/mcp-server.md`
- 4.0 업그레이드·에이전트 설정: `upgrading/upgrade-to-four.md`

문서를 인용할 때는 페이지 URL을 답에 남긴다.

## 4. 문서와 코드가 다르면 패키지 소스가 정답

문서는 최신 stable 기준이고 프로젝트는 4.0.0에 고정돼 있다. 시그니처가 의심되면 `dart` MCP로 실제 소스를 본다.

- `read_package_uris` — 예: `package:serverpod/src/server/future_call_manager/future_call_manager.dart`
- `rip_grep_packages` — 예: `callRecurring` 을 `serverpod` 패키지에서 검색
- 생성 코드는 `investment_ontology_serverpod_server/lib/src/generated/` (읽기만, 수정 금지)

## 5. 스킬 재설치 (새 체크아웃, 버전 업 뒤)

워크스페이스 루트에서:

```bash
dart pub global activate skills
dart pub global run skills get --agent claude --all
```

`--agent generic --all` 은 `.agents/skills/`(Codex 등)에 넣는다. 관리 대상은 `.config/dart_skills/skills_config.json`에 기록되며,
이 라우터 스킬(`.claude/skills/serverpod/`)은 CLI가 관리하지 않으므로 재설치해도 지워지지 않는다.
