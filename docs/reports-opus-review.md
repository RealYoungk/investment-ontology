# 리포트 워크스페이스 점검 (Claude Opus 5.5) · 2026-09-24

기준: PR #80 초안 커밋 01fec33. 변경은 워크트리 `.claude/worktrees/reports-hardening`
(브랜치 worktree-reports-hardening, 01fec33에서 fast-forward)에 **커밋하지 않은 상태**로 있다.
메인 체크아웃은 백그라운드 격리 가드가 쓰기를 거부해 건드리지 않았다(아래 "차단").

## 당시 반영 방법 (현재 통합 완료)

```sh
# 메인 체크아웃(codex/reports-workspace, serverpod start는 멈추지 않아도 됨)에서
git -C .claude/worktrees/reports-hardening diff 01fec33 | git apply
cp .claude/worktrees/reports-hardening/investment_ontology_serverpod_flutter/lib/features/research/leave_guard*.dart \
   investment_ontology_serverpod_flutter/lib/features/research/
cp .claude/worktrees/reports-hardening/investment_ontology_serverpod_flutter/test/features/research_pages_test.dart \
   investment_ontology_serverpod_flutter/test/features/
cp .claude/worktrees/reports-hardening/docs/reports-opus-review.md docs/
```

(`git diff`는 새 파일을 담지 않아서 새 파일 5개는 복사한다.)

스키마·엔드포인트 시그니처·생성 코드는 바꾸지 않았다. 마이그레이션도 필요 없다.
엔드포인트 본문만 바뀌므로 감시 생성기는 클라이언트를 다시 만들 일이 없다.

## 발견 사항 (우선순위 순)

| # | 심각도 | 내용 | 조치 |
|---|---|---|---|
| 1 | 높음 (무결성) | **재이관이 관리자 수정본을 덮어쓴다.** 편집기 `save`는 새 판에 `legacy`를 물려주고, 관리자가 가져온 note를 그대로 두면 `importLegacy`의 조건(최신=공개, legacy, note 일치, 내용 다름)이 모두 참이 되어 원문을 새 판으로 **발행**한다. 수정 전 코드로 새 회귀 테스트를 돌리면 `Expected: <0> Actual: <1>`로 실패했다. | 이관기가 만든 판만 고치도록 `_importedEdition`: `legacy && publishedAt == dataAsOf && publishedAt < createdAt`. 이관기만 발행 시각을 원문 기준일(행 생성 이전)로 되돌려 적고, 편집기는 저장 뒤 현재 시각으로 발행하므로 두 경로가 겹치지 않는다. 스키마 변경 없음. 렌더링 보정 경로가 계속 동작함도 테스트로 확인. |
| 2 | 높음 (확장성) | `research.list`가 모든 글과 **모든 판의 본문**을 읽은 뒤 메모리에서 거르고 정렬했다. 같은 기준일 글끼리 순서가 정해지지 않아(`List.sort`는 안정 정렬 보장 없음) 30개 단위 페이지 사이에서 글이 중복·누락될 수 있었다. | 하나의 SQL로 읽는다: 글 ⨝ (공개판 또는 관리자면 최신판) ⟕ 내 저장. 조건은 시장·종목·저장·검색어(`strpos(lower(title‖ticker‖summary‖searchText))`, `%`·`_`가 문자 그대로)이고 `ORDER BY dataAsOf DESC, id DESC LIMIT 30 OFFSET`. 본문과 searchText는 DB 밖으로 나가지 않는다. 사용자 입력은 모두 named parameter이고, SQL 조각은 코드 상수뿐이다. |
| 3 | 중간 | `save`에서 알 수 없는 형식·400,000자 초과는 `ArgumentError`로 500 → 앱은 "연결을 확인" 문구를 보였다. 또한 Serverpod `maxRequestSize` 512KiB를 넘는 본문(한글 약 17만 자)은 엔드포인트에 닿기 전에 413으로 거절되어 같은 오해를 낳는다. | 서버: `IngestException` 메시지로 바꿈. 앱: 저장 전 UTF-8 480KiB 초과를 막고, 401/403/413을 각각 알맞은 문구로 표시(`researchError`). |
| 4 | 중간 | 편집기에서 **시장만 바꾸면** `_dirty`만 켜지고 `hasUnsavedChanges`는 꺼진 채라 메뉴 이동(`onExit`) 때 묻지 않고 변경을 버렸다. 탭 닫기·새로고침·주소 직접 입력도 보호하지 않았다. | 모든 편집을 `_markDirty()` 하나로 모았다(수정 전 코드로 테스트가 실패하는 것 확인). 웹에서는 `LeaveGuard`가 `beforeunload`로 묻는다(`leave_guard_web.dart`, 조건부 import). |
| 5 | 중간 | 목록에서 글을 열었다 돌아오면 첫 30개만 다시 불러와 "더 보기"로 불러온 글과 스크롤 위치가 사라졌다. | `_load(keep: true)`: 보이던 개수만큼 페이지를 다시 읽어 한 번에 바꾼다. 새 리포트 작성·이관·재시도 뒤에도 같다. |
| 6 | 중간 | 목록 검색어·시장이 주소에 없어 새로고침·뒤로가기에서 사라지고, `didUpdateWidget`은 주소의 `q`가 바뀔 때 시장을 지웠다. | 기업 목록과 같은 방식(`Router.neglect` + `context.go`)으로 `q`·`market`(·`ticker`)을 주소에 둔다. 입력 중에는 검색창을 주소로 덮어쓰지 않는다(한글 조합 보호). 관리자 목록도 같다. |
| 7 | 낮음 | 리더: 판 목록(`editions`) 호출이 실패하면 이미 받은 본문까지 오류 화면으로 가렸다. 오류 화면에 재시도가 없었다. "리포트 목록"은 항상 `go('/research')`라 들어온 목록의 필터·스크롤을 버렸다. 저장 응답이 늦게 오면 그사이 연 다른 글에 저장 표시가 붙을 수 있었다. | 판 목록 실패는 무시하고 본문 표시, 오류 시 "다시 시도", 목록 버튼은 `canPop`이면 pop, 저장 결과는 요청한 그 글에만 반영. |
| 8 | 낮음 | 목록: 오류와 "조건에 맞는 리포트가 없습니다"가 함께 보였고, 오류 중에도 "더 보기"가 보였다. 빈 아카이브와 검색 결과 없음이 같은 문구였다. | 오류일 때 빈 상태·더 보기 숨김, 빈 상태 문구 구분. |
| 9 | 낮음 | 편집기: 없는 주소(`/admin/research/오타`)는 `StateError` → "연결을 확인" 문구였고, 입력해도 변경으로 잡히지 않았다. | "아직 없는 리포트입니다. 이 주소로 새로 작성할 수 있습니다." + 주소 채움 + 변경 추적. |

### 확인했고 문제 없던 것

- 비로그인/독자: `draft`·`source`·`manage`·`history`·`publish`·`save`·`importLegacy` 모두 거부(기존 테스트). 명시적 `version`은 발행된 적 있는 판이고 글이 현재 공개 중일 때만 허용되며, 공개 해제 후에는 과거 판도 막힌다.
- 초안 누출: 공개 목록 검색은 조인된 공개판만 본다. 공개판 위에 비공개 초안을 저장해도 독자 검색·목록·본문에 나오지 않고 관리자 목록만 최신 초안을 보인다(새 테스트).
- 저장: 사용자 식별자로만 조회·삭제. 다른 독자의 해제 요청이 내 저장을 지우지 않는다. 공개 해제 중에는 목록에서 숨고 새 저장이 거부되며, 다시 공개하면 돌아온다(새 테스트).
- 탈퇴: `deleteMe`가 같은 트랜잭션에서 본인 저장만 지운다. 다른 사람 저장은 남는다(계정 테스트에 추가).
- 오래된 편집·발행: 테이블 잠금 + 예상 버전 비교로 거부(기존 테스트).
- Markdown 초안은 원문 그대로 저장되고 `source:true`로 편집기에 돌아온다(기존 테스트). 공개 응답은 항상 정제한 HTML이다.
- `DropdownButtonFormField(initialValue)`의 불러온 시장 표시는 Flutter가 `didUpdateWidget`에서 맞춘다(확인 후 수정하지 않음).

## 바꾼 파일

- 서버 `lib/src/ontology/endpoints/research_endpoint.dart` — list SQL, `_entry`/`_utc` 매핑, `_importedEdition`, save 오류 변환.
- 서버 테스트 `test/integration/research_endpoint_test.dart` (+7), `test/integration/account_management_test.dart` (탈퇴 시 저장 삭제 검증 추가).
- 앱 `lib/features/research/research_pages.dart`, `research_editor.dart`, `lib/app/router.dart`(`market`, 관리자 목록 `q`), 새 `leave_guard.dart`/`_stub`/`_web`.
- 앱 테스트 `test/features/research_pages_test.dart` (11개, 생성된 `EndpointResearch`를 상속한 가짜로 호출을 대답). 페이지는 테스트용 `research:` 인자를 받고 기본값은 앱 클라이언트다.

## 검증 (워크트리에서 실제 실행)

- `dart analyze` (워크스페이스 전체): No issues found.
- `dart format` (format.yml처럼 생성 경로 제외한 손 코드): 변경 파일 정리 완료.
- `bash scripts/test-server.sh`: **314/314 통과** (기존 307 + 7). `generated_code_test` 포함.
- `bash scripts/test-server.sh test/integration/research_endpoint_test.dart`: 14/14. 수정 전 판정식으로 되돌리면 "re-import never replaces an administrator edit"가 `Expected <0> Actual <1>`로 실패.
- `flutter test`: **103/103 통과** (기존 92 + 11). 시장 변경 테스트는 수정 전 코드로 `Expected true Actual false` 실패 확인.
- `flutter build web --release`: 성공(`leave_guard_web.dart` js_interop 컴파일 확인).

## E2E 증거와 차단

- `mcp__serverpod__get_flutter_app_dtd` → "The server is not running with `serverpod start` for this project." MCP가 워크트리를 프로젝트로 인식한다. 지시대로 서버·앱을 띄우지 않았고 브라우저 자동화로 대체하지 않았다. **이번 작업에서 라이브 화면 클릭·스크린샷은 하지 않았다.**
- 메인 체크아웃 쓰기 거부: `output/claude-delegation/status.md` Write가 "This background session hasn't isolated its changes yet. Call EnterWorktree first…"로 거부됨. 가드 설정은 건드리지 않았다. status.md는 워크트리의 `output/claude-delegation/status.md`에 있다.

## Codex가 확인할 것

1. 위 반영 후 메인 체크아웃에서 `dart analyze`, 두 테스트 스위트, `hot_restart`, `tail_server_logs`(list SQL 오류 없는지).
2. 라이브(읽기 전용/비공개 초안): `/research?q=…&market=KOSDAQ` 새로고침 유지, 글 열고 "리포트 목록"으로 돌아와 불러온 개수 유지, `e2e-report-review`(비공개 유지)에서 시장만 바꾸고 메뉴 이동 시 확인창, 탭 새로고침 시 브라우저 확인창, 390px 목록·툴바.
3. 운영 DB의 이관 판이 `publishedAt == dataAsOf < createdAt`를 만족하는지 읽기 전용으로 확인(만족하지 않으면 재이관 보정이 조용히 건너뛴다 — 덮어쓰는 쪽이 아니라 안전한 쪽으로 실패). 예: `SELECT count(*) FROM research_revision WHERE legacy AND ("publishedAt" IS DISTINCT FROM "dataAsOf" OR "publishedAt" >= "createdAt")` — 관리자 수정본 수와 같아야 한다.

## 남은 제한 (이번에 고치지 않음)

- **push한 상세 화면 주소가 주소창에 반영되지 않을 가능성.** go_router 18의 `optionURLReflectsImperativeAPIs`는 기본 false이고 `RouteMatchList.push`는 기준 URI를 유지한다(소스 확인). 앱 규칙(AGENTS: 상세는 `context.push`)대로면 목록에서 연 리포트의 새로고침·주소창 복사는 목록으로 돌아갈 수 있다. 앱 전체 규칙이라 바꾸지 않았다. 라이브에서 확인 후 리포트만 `go`로 열지(스크롤 손실) 결정이 필요하다. 공유 버튼은 정식 주소를 복사하므로 공유 자체는 된다.
- 공유 버튼은 `https://alfinder.kr/research/…`를 복사한다. 운영 프런트는 PR79라 머지 전에는 이 주소가 동작하지 않는다(의도된 정식 주소로 보고 유지).
- 공개 `editions`는 판의 `note`(수정 메모)와 생성 시각도 내려준다. 화면은 쓰지 않는다. 내부 메모를 쓸 계획이면 공개 응답에서 비울 것.
- 검색은 공개판 행을 순차로 훑는 `strpos`다(현재 96편은 충분). 수천 편 이상이면 `pg_trgm` GIN 인덱스(추가 마이그레이션)나 전문 검색으로 바꿀 것.
- 이관 판 식별은 불변식에 기댄다. 장기적으로는 `ResearchRevision`에 출처 열(예: `origin: import|editor`)을 추가 마이그레이션으로 두는 편이 명시적이다(생성기가 필요해 이번 워크트리에서는 하지 않음).
- `offset`은 100,000으로 제한되고 커서 페이지는 아니다. 목록 중간에 글이 발행되면 다음 페이지에서 하나가 밀릴 수 있다(순서는 안정적).
- PR80에 없는 것: 네이티브 본문 뷰어(스텁 문구 "웹에서 리포트 원문을 열어주세요."), 개별 리포트 SSR/검색엔진 메타, 이메일 구독, 기존 React 계산기 등 상호작용(스크립트 제거, `button{display:none}`).

## Codex 독립 검수 · 2026-09-24

위 기록은 Claude의 격리 워크트리 결과다. 변경을 codex/reports-workspace에 통합하고 추가 수정했다.

- 저장 성공 뒤 선택적 history 조회 실패가 저장 실패로 표시되고 expectedVersion을 갱신하지 않던 문제를 수정. 연속 두 번 저장 회귀 테스트 추가.
- 공개 list/get/editions에서 편집용 note를 비움. 관리자 source/history에서는 유지. 서버 회귀 테스트 추가.
- go_router의 push 상세 주소 반영을 활성화. 실제 로컬 브라우저에서 검색/시장 조건 목록 → 덕산하이메탈 상세 주소 → 새로고침 후 본문 → 뒤로가기 후 조건 복원을 확인.
- 통합 체크아웃에서 서버 315개, Flutter 104개 테스트 통과. dart analyze 이상 없음. 수동 코드 248개 format 변경 없음. release 웹 빌드 성공.
- Serverpod MCP hot_restart 후 DTD 연결 앱 health ok. 로그의 과거 생성 오류 이후 재시작 완료를 확인. 오래 열어둔 다른 세션의 만료 JWT 오류는 별도로 남아 있음.
- Funnel 검토판을 최신 빌드로 갱신하고 실제 목록/상세와 390×844 모바일 본문 확인. 스크린샷 output/reports-review/hardening-desktop.png 및 hardening-mobile.png.
- 비공개 e2e-report-review에서 시장만 변경 후 왼쪽 리포트 메뉴 클릭: 미저장 확인창 표시 확인. 계속 편집도 확인. 테스트 글은 저장/발행하지 않음.
- 브라우저 새로고침의 native beforeunload 경고는 자동화 reload에서 확인되지 않음. 메뉴 이탈 경고와 달리 E2E 통과로 주장하지 않는다. 브라우저 사용자 활성화/자동화의 대화상자 처리 차이를 분리하지 못해 수동 확인 대상으로 남긴다.
- 운영 프런트는 PR79 유지. 이번 변경은 PR80 리뷰용이며 아직 머지하지 않음.
