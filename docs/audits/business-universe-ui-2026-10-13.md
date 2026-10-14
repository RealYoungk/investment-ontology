# 전체 기업 사업 화면 브라우저 점검

`node scripts/audit/business_universe_ui.cjs`는 기존 `universe.json`에서 `inventory.json`의 원문 미보유 14사를 제외한 2,745사를 실제 Flutter 브라우저로 방문한다. Serverpod 서버를 시작하거나 원문 API를 별도로 수집하지 않는다. 화면을 열면서 Flutter 앱이 호출하는 공개 읽기 API 응답을 기록한다.

독립 headless Chromium 브라우저의 context 2개를 사용한다. 메모리 누적을 제한하기 위해 `business_universe_ui_dispatch.py`가 20사씩 같은 ledger를 이어 실행하고 각 묶음 종료 뒤 owned browser를 닫는다. 다른 작업자의 브라우저와 최소 anchor는 건드리지 않는다. 각 context 첫 진입만 전체 로드하고 이후 `history.pushState` + `popstate`로 실제 Flutter router를 전환한다. 다른 작업의 브라우저 탭과 충돌하지 않는다. 1440×1600 viewport, 700px 스크롤로 사업 표를 아래까지 방문하며 위험관리 펼치기가 보이면 실제로 펼친다.

완료 게이트: 현재 회사 이름 또는 종목코드와 사업 구조 heading 렌더, businessContent·understanding·factTrends·factPeriods 응답 body 로드 및 200, Flutter exception/overflow 없음, 명시적 읽기 오류 없음, tableInsights의 모든 원문 제목 렌더(`sourceTableTitlesUnseen` 0), 두 번의 실제 하단 도달(semantics geometry 정체 후 양쪽 바깥 영역의 wheel 검사와 실제 viewport screenshot SHA 전후 일치). 표 제목별 seen/unseen과 native 원문 accordion별 전개·내용 mount trace를 기록한다. 원문 API tableCount는 semantic dedup 때문에 native 카드 수와 직접 비교하지 않는다. 사업 원문 점검 후 존재하는 재무·지배구조·주주환원·소식·공시 탭을 실제 클릭하여 URL, 읽기 응답, heading 및 오류를 확인하고 소식·공시의 원문 표 보기까지 연다. 정상적인 자료 없음 상태는 허용한다. 이는 화면 로딩·구조·표 렌더 점검이며 숫자의 의미 정확성은 별도 원문/파서 전수 검증에 의존한다.

`BUSINESS_UI_RUN=ui-final node scripts/audit/business_universe_ui.cjs`로 최종 revision의 독립 ledger를 만들 수 있다. 같은 run 재실행은 pass와 primary·verification 두 physical paint proof를 모두 가진 회사만 건너뛴다. 이전 방식의 pass도 강해진 하단 확인 근거를 갖출 때까지 재방문한다. `BUSINESS_UI_LIMIT`, `BUSINESS_UI_WORKERS`, `BUSINESS_UI_BASE`, `BUSINESS_UI_ROOT`도 지원한다.

회사별 URL, 시각, API 상태, 예외, body snapshot 경로, 표 제목 확인 결과, 상단·하단 screenshot을 `tmp/business-universe-audit-2026-10-13/<run>/`에 남긴다. run manifest는 git HEAD, 주요 소스 파일 SHA256, Flutter/server/client lib 전체 Dart 파일 fingerprint로 점검 시점의 dirty workspace도 구분한다. 종료 시 fingerprint를 다시 비교하며 코드가 바뀌었다면 동일 revision 전수 증거로 인정하지 않는다.

초기 pilot은 8사 중 첫 4사 렌더 확인 후 서버/앱 상태 변화로 나머지 4사의 상세 정보 읽기가 실패했다. 그 기록은 `ui/ledger.jsonl`에 보존했다. 최종 run은 앱이 안정된 동일 revision에서 2,745사를 모두 다시 점검해야 한다.

ui-final 첫 4사는 상세 정보 읽기 deadline으로 실패했다. 3S 독립 70초 CDP probe에서 company/detail·financial/summary 정상 JSON이 뒤늦게 도착했고 caught exception 24건은 Serverpod network timeout 21건과 resilient read timeout 3건이었다. 타입 디코딩 예외 증거는 없었다. 상세 근거는 `ui-final/probe-exceptions.json`, `probe-detail.json`, `probe-summary.json`, `probe-3s.png`. 이 실패를 전수 완료로 세지 않고 읽기 지연 해결 후 같은 전수 gate로 재실행한다.

중단 시 이전 harness가 닫힌 context 오류를 다음 queue에도 반복 기록하는 문제가 있었다. ui-final ledger 2,745행 중 실제 DOM deadline 실패 8사, 중단 중 취소 4사, 미방문 닫힌 context 항목 2,733사다. 미방문 항목을 실제 UI 점검으로 세면 안 된다. 이 분류는 `ui-final/interruption-summary.json`에 저장했다. SIGTERM/닫힌 context에서 전역 queue를 즉시 중단하도록 수정했고 다음 안정 run은 새 디렉터리에서 수행한다.

새 앱 launch 직전 listener 거부 750행은 `ui-final-stable-startup-aborted/startup-interruption-summary.json`에 실제 렌더 방문 0으로 분리했다. 이후 stable run은 46사의 실제 화면과 최신 tableInsight 제목 전체를 확인했지만 금융 자금조달 병합 숫자 파서 수정으로 revision이 바뀌어 전수 인증 대상에서 제외했다(`ui-final-stable/revision-superseded.json`). 다음 canonical run은 2,745사를 처음부터 방문하며, 표 제목뿐 아니라 ‘항목별 정보 N개’도 펼쳐 실제 원문 표 행 렌더를 확인한다.

최종 후보 `ui-fourth-final`은 Serverpod MCP가 서버 미실행을 명시하여 AGENTS 규칙에 따라 중단했다. 13회 시도 / 9개 회사의 최신 상태 중 실제 pass 5사(3S, AJ네트웍스, AP시스템, APS이노베이션, AP위성), 미해결 게이트 2사(APS, AK홀딩스의 동적 history accordion label/order key), 중단 인프라 2사(BGF, BGF리테일)이다. 나머지 2,736사는 이 run에서 미방문이다. 시작·종료 소스 fingerprint `915b93f77684c6a4ee28c9befb551c128b2ee19f36ac117b10b09c0a31c40e5c`는 동일했다. `ui-fourth-final/server-stopped-summary.json`에 분류를 보존했다. 전체 UI 검증은 완료되지 않았다.

자동 점검 보정 근거: 초기 앱 HTML이 반환되어도 main.dart.js가 아직 HTML인 준비 단계가 있어 JS MIME와 실제 flutter-view를 회사 배정 전에 확인한다. 표 전개로 semantics node id가 재생성되므로 클릭마다 live DOM을 다시 조회한다. Flutter 접근성 텍스트는 화면 범위에 따라 길이가 줄어들 수 있어 전체 글자 수를 전개 증거로 쓰지 않고, native mouse 클릭 전후 button 직후의 표 내용 변화와 실제 screenshot으로 확인한다. 지배구조 탭에 정관 변경 내용이 상단을 채우는 정상 형태도 heading으로 허용한다. 두 미해결 history key는 실제 클릭된 표의 mount 실패가 아닌 동적 키 중복/이동 문제이며, 재개 전에 카드 기준의 안정된 식별자로 보완해야 한다.

현재 canonical run은 `ui-all-final`이며 2026-10-13 19:11 KST에 전체 검증을 완료했다. 아래의 초기 pilot 및 중단 시점 수치는 당시 이력이며 최종 상태는 문서 말미와 final-ui-manifest.json을 따른다. 기존 다른 namespace의 pass는 합산하지 않는다. 최신 실제 방문 및 모든 게이트, 출처 receipt/year/source ID, snapshot 존재 여부를 `business_universe_ui_aggregate.py`가 독립 집계한다. `independent-aggregate.json`의 `complete`는 2,745사 모두 실제 pass와 모든 게이트, 두 physical paint proof, 마지막 방문 이후의 안정된 소스 fingerprint를 갖출 때만 true다. 현재 수치는 이 JSON을 확인해야 하며 부분 점검을 전체 완료로 읽으면 안 된다.

current run 보정 근거: 장시간 같은 Flutter realm을 재사용한 뒤 renderer가 `Target crashed`로 중단됐다. 잘못 분류된 미방문 2,532개 행은 원 ledger를 보존하고 `infrastructure-corrections.json`으로 visited=false 인프라 오류로 정정했다. 새 renderer에서 LG·POSCO홀딩스가 모든 표와 탭을 통과했으며 이후 20사 묶음으로 메모리 누적을 제한한다. crash가 발생하면 다음 회사를 배정하지 않는다.

iM금융지주는 첫 금융 차트 이후 원문 Text 중간에서 scroll geometry가 반복되어 source 제목 누락 게이트가 실패했다. 왼쪽 바깥 영역으로 wheel을 회복한 재시도는 7→166 steps로 늘어 모든 source 제목과 탭을 통과했다. 완전한 하단 보증을 위해 이후 geometry 정체에 실제 viewport paint 비교도 요구한다. 초기 geometry pass에 새 범위를 소급하지 않으며 해당 회사들을 다시 방문한다. 고스트스튜디오·글로벌에스엠의 재무 탭은 여러 통화가 함께 있어 추이를 합산하지 않는 정상 안내였다. live financial/summary의 통화 집합과 정확한 안내 문구가 일치할 때만 정상 unavailable heading으로 인정한다.

각 새 기록과 run manifest는 harness SHA도 남긴다. `tmp/business-ui-scroll-ab/comparison.json`의 BNK·HB솔루션 A/B는 동일 source에서 표 제목과 opened control 집합이 일치했지만 보수적인 giant plain Text jump 조건의 실행은 0건이었다. 이 제안에 속도 향상이나 전체 검증 완료를 주장하지 않는다.

2026-10-13 09:21 KST에 Serverpod MCP가 서버 미실행을 명시하여 AGENTS 규칙대로 owned UI dispatcher와 worker browser를 중단했다. 최종 강화 범위의 실제 pass는 582/2,745사이며 나머지 2,163사는 미완료다. 582사 모두 current source receipt/year/id, 모든 API source 제목, 현재 원문 control의 내용 mount, 모든 존재 탭 및 primary·verification 실제 paint end proof를 통과했다. 584사의 사업 화면 paint proof 중 2사는 서버 종료로 지배구조 탭 읽기를 마치지 못하여 전체 pass가 아니다. 이 연결 거부는 `infrastructure-corrections.json`에 인프라 오류로 정정했고 회사 데이터 오류로 세지 않는다. `server-stopped-summary.json`과 `independent-aggregate.json`에 전체 미완료 상태를 보존했다. 당시 Flutter/server/client Dart 전체 fingerprint는 `d98dbfed48e0527af58f968a429f803a066f7e3eec2fdc2335398e2e4c1e6947`이다. 재개는 서버를 다시 실행한 뒤 같은 source 버전에서 `python3 scripts/audit/business_universe_ui_dispatch.py`로 이어가며, 이전 source가 바뀌면 전수 동일 revision 인증에 사용하지 않는다.


### 2026-10-13 12:59 재개 체크포인트

기존 사용자 실행 승인 범위에서 root가 Serverpod를 재시작한 뒤 MCP 로그로 서버와 Flutter 앱의 준비 완료를 확인했다. 동일한 소스 지문 `d98dbfed48e0527af58f968a429f803a066f7e3eec2fdc2335398e2e4c1e6947`에서 582개 완료 기록을 보존하고 2 workers / 20개 회사 배치로 전수 검증을 재개했다. 재개한 7개 배치가 각 20/20 통과하여 누적 722/2,745개 완료, 2,023개 미완료 상태다. 전수 완료를 의미하지 않는다.

중단 당시 남은 2,163개는 이전 renderer crash 뒤 실제 방문하지 못한 2,159개, 사업 화면과 재무 화면 이후 지배구조 읽기가 연결 거부로 중단된 덴티움·도부 2개, owned-worker 중단으로 남은 infrastructure 기록 2개로 분류된다. raw ledger의 기존 fail 2,161개를 회사 결함으로 해석하지 않는다. 연결 거부 2개는 재개 후 전체 범위 검증에 통과했다. append-only 원본과 infrastructure-corrections.json을 유지한다.


### 2026-10-13 15:20 진행 체크포인트

동일 소스 지문에서 누적 1,512/2,745개 전체 범위 검증이 통과했다. 남은 1,233개는 계속 검증 중이며 전체 완료가 아니다. 2 workers / 20개 배치를 유지했다. 아이로보틱스 등 일부 방문에 `Cannot read properties of null (reading 'removeChild')`가 발생해 원래 실패 기록을 보존하고 재검사했다. 추가 스택 기록으로 served `main.dart.js:71`의 DWDS `dart-app-ready` 중복 로더 제거임을 확인했다. 다른 1개 방문은 body 읽기 대기 timeout이었다. 모든 해당 회사가 fresh context에서 pageErrors가 없는 전체 범위 통과를 기록하여 해결됐으며 오류 예외나 통과 gate 완화는 적용하지 않았다. 하네스에는 pageErrorStacks 기록만 추가하고 각 기록의 harnessFingerprint를 보존했다. 15:04 독립 집계에서 actualFailureCount=0, 1,420개 pass와 1,420개 두 번의 동일 paint 종료 증거가 일치했다.


### 최종 완료 — 2026-10-13 19:11 KST

실제 브라우저에서 대상 **2,745/2,745개 회사**의 사업 표 전체 펼침과 존재하는 모든 회사 탭 검증을 완료했다. 이전 다른 namespace의 pass는 합산하지 않았다. 독립 집계의 최신 고유 회사·실제 방문·전체 pass·두 번의 동일 viewport paint 종료 증거는 각각 2,745개다. source 제목 미노출, 현재 accordion 본문 미표시, 페이지/Flutter/콘솔 오류, 누락 회사, 최종 인프라 실패는 모두 0개다. 최종 `complete=true`와 `FINAL_ACTUAL_UI_VERIFIED_COMPLETE`를 확인했다.

각 필수 gate가 2,745/2,745 통과했다: live source receipt/year/source.id 일치, 전체 source 제목 노출, 두 번의 끝까지 스크롤 및 실제 paint 종료 확인, 현재 source/history control 전체의 자기 본문 mount, 존재 탭 전체 실제 클릭·응답 본문·heading 확인. 재무와 소식·공시는 각 2,745개, 지배구조와 주주환원은 해당 탭이 존재한 각 2,723개 회사에서 통과했다. 탭이 없는 22개를 누락이나 실패로 합산하지 않았다. 사업 자료가 없는 상장사 14개는 기존 inventory의 별도 제외 목록을 그대로 유지한다.

Flutter/server/client lib 전체 Dart 소스 지문은 모든 최신 회사 기록에서 `d98dbfed48e0527af58f968a429f803a066f7e3eec2fdc2335398e2e4c1e6947`로 동일하다. 마지막 방문 이후 저장한 source proof와 최종 독립 재계산이 일치한다. 5개 harness 지문은 기록별로 보존한다. 초기 강한 paint proof 버전, 스택 근거 추가, 콘솔 오류 없는 pass/resume 조건 강화의 차이를 숨기지 않으며 모든 최신 회사 기록은 독립 집계의 같은 최종 gate를 만족한다.

종료 후 기존 읽기 전용 DB helper로 재조회한 기준은 활성 원문 15,261개 / 사업 원문 회사 2,745개 / 상장사 2,759개로 최종 API 기준과 일치했다. 원문을 다시 수집하거나 DB를 수정하지 않았다. 사용자 실행 승인 범위에서 runtime 종료 2회를 복구하고, 연결 거부·DWDS 중복 로더 제거·SPA 화면 준비 timeout 방문은 원래 실패 기록을 보존한 뒤 새 브라우저에서 전체 범위를 재검증했다. 최종 unresolved failure는 0개다.

근거: `tmp/business-universe-audit-2026-10-13/ui-all-final/final-ui-manifest.json`, `independent-aggregate.json`, `ledger.jsonl`, `db-after-ui.json`, `source-fingerprint-final.json`, 회사별 `snapshots/`와 raw infrastructure corrections. 최종 ledger SHA는 `cc6e3e721e291e3902284b2b1d81d5ce4fdf19a02897a07b128d59e2616ca048`이다. `business_universe_ui_finalize.py`는 현재 소스 재계산·DB 기준 일치·전체 최신 pass와 페이지/콘솔/Flutter 오류 없음·전체 paint proof를 assert한 뒤 manifest를 만든다. Node syntax와 세 Python 도구 compile 검사도 통과했다.

이 결과는 로컬 개발 앱의 해당 소스/자료 버전과 기재한 표·탭 범위에 대한 완료 근거다. 운영 배포나 모든 수치의 경제적 의미 100% 정확도를 의미하지 않는다.
