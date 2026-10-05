# 서버 전체 테스트 성능 점검 — 2026-10-05

> 2026-10-06 후속 추적에서 원인을 정정했다. `FinancialFactsSync.callInterval=Duration.zero`와 별개로, 로컬 원문을 전달받는 `PublicFinancialHtmlFetcher`가 요청마다 실제 DART용 1초 간격을 적용하고 있었다. 아래의 “제한 대기가 원인이 아니다”는 초기 판단은 잘못되었다. 후속 구현과 실측은 `server-test-performance-2026-10-06.md`를 따른다.

## 확인 범위

배포 로그 `output/releases/local-1f998d414ab50fed8002cafa2f6372f2f732f29d.log`, 로컬 검사 캐시, `scripts/test-server.sh`, 원문 캐시 단위/통합 테스트 및 연결된 원문 파서를 조사했다. 전체 테스트를 다시 실행한 결과가 아니며, 기존 dirty 변경과 생성 파일은 수정하지 않았다.

## 측정 근거

- 전체 서버 검사 캐시의 durationSeconds: 3079.13초(51분 19초). 당시 471개 파일을 25개씩 19회 실행.
- 4번 묶음: 12분 30초. 다른 파일은 초반에 끝나고 `test/unit/verified_annual_source_registry_test.dart`가 마지막까지 실행됨.
- 18번 묶음: 14분 19초. `test/integration/financial_verified_registry_cache_test.dart`가 마지막까지 실행됨.
- 두 묶음 합계 26분 49초, 전체 기록의 약 52%. 묶음 시간은 해당 파일 단독 측정 시간과 구분한다.
- 현재 단위 테스트 재현: `bash scripts/test-server.sh test/unit/verified_annual_source_registry_test.dart --name 'actual packaged 20250321001825:consolidated' --reporter expanded` 통과, runner 표시 약 5초(프로세스 준비 시간 제외).
- 통합 테스트 재현은 로딩 실패. 현재 generated test tools가 전달하는 ephemeralDatabase를 설치된 serverpod_test 4.0.0이 받지 못함. 테스트 본문은 실행되지 않았다. 생성 파일은 수동 수정하지 않았다.

## 왜 오래 걸리는가

1. 단위 registry 테스트는 317개 receipt/basis 패키지 전체에 대해 원문 검증, 신원/기간/상태 거절, 파일별 SHA 변조 거절을 실행한다. 테스트 개수 자체보다 성공 경로의 전체 원문 해석이 비싸다.
2. 통합 registry 테스트도 전체 registry를 순회한다. 회사/보고서/출처/사실을 DB에 넣고 동일 원문 검증 경로를 호출하며, 재실행·반대 기준 값 보존·감사 기록 등을 검사한다. SourceClient를 주입하고 외부 호출 0, callInterval=Duration.zero를 확인하므로 이 경로는 실제 DART 네트워크나 제한 대기가 원인이 아니다.
3. `public_financial_html.dart`의 여러 표 순회에서 `_compact(_text(scope.substring(0, table.start)))`를 반복한다. 각 표마다 점점 긴 문서 prefix를 다시 변환하는 구조로, 긴 표 문서에서 중복 CPU 작업 후보다. 전체 시간 기여도는 아직 profiler로 확정하지 않았다.
4. 전체 실행기는 메모리 누적을 제한하기 위해 25개 파일마다 종료하고 다시 시작한다. 19회의 실행기/컴파일 준비 비용이 있지만, 로그상 두 registry 묶음의 긴 본문 실행이 더 큰 원인이다. batching 삭제의 안전성/메모리 영향은 미검증이다.

## 불필요·중복 판단

- 즉시 삭제해도 안전하다고 확인된 테스트는 없다. SHA 변조·회사/기간/연결별도 거절·원천/기존 값 보존은 데이터 정확성의 중요한 회귀 검사다.
- 같은 원문 패키지가 전용 source 테스트, registry 단위 테스트, registry 통합 테스트에서 다시 처리되는 중복은 있다. 각 계층은 파서·registry 연결·DB 저장이라는 서로 다른 실패를 검사하므로 이름이나 입력 중복만으로 삭제하면 안 된다.
- 통합 테스트의 모든 패키지에 대해 공통 저장 흐름을 반복하는 부분은 축소 후보다. ruleVersion/기준/숫자·없음/부분자료 등 행동 분류별 대표 DB 테스트와 전체 원문 검증을 분리하려면 현재 패키지별 특수 assertion을 먼저 목록화해야 한다. 현재 assertion에는 개별 원접수·정정·부분 계정 계약도 포함되어 있다.
- opt-in billing browser fixture는 전체 서버 검사에서는 skip되며, 별도 브라우저 검증에서만 대기한다. 20분 timeout 선언을 전체 테스트의 20분 대기로 해석하면 안 된다.
- 317개 원문에 대한 특수 production source 코드를 불필요하다고 단정할 근거는 없다. 제거 전 저장 데이터의 provenance와 실제 recovery 의존성을 확인해야 한다.
- 테스트 목록용 mktemp 파일에 cleanup trap이 없는 작은 정리 누락은 있지만, 51분 병목의 원인은 아니다.

## 개선 우선순위

1. 생성 도구/Serverpod 버전 불일치를 정상 코드 생성 경로로 해결하여 통합 재현 기반을 복구한다. 다른 작업의 생성 파일을 덮어쓰지 않는다.
2. 느린 원문 1~2개에 단계별 시간을 측정한다(파일 읽기/SHA/HTML 파싱/DB). prefix 반복 변환을 먼저 검증한다.
3. 동일한 본문/오프셋의 순수 텍스트 변환만 한 번 계산하도록 개선하고 원문 전체/변조 테스트를 유지한다. 검증 성공 캐시로 신원/SHA 검사를 건너뛰지 않는다.
4. 공통 DB 흐름과 패키지별 파서 검증의 중복을 줄이되 모든 ruleVersion과 특수 저장 계약의 coverage ledger를 먼저 만든다.
5. UI 전용 배포의 서버 전체 회귀 재사용은 별도 영역 캐시 설계로 검토한다. 서버/생성 클라이언트/공유 의존성/설정/검사 도구 입력을 검증해야 하며 현재는 전체 tree 캐시 정책을 유지한다.

이번 작업은 점검이며 production 코드, 테스트 범위, 배포 게이트를 변경하지 않았다.
