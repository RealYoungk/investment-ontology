# 시세 저장 후 들어온 기업마스터 재연결

브릴스는 시세의 법인번호/종목코드가 먼저 저장됐고 회사마스터가 일일 DART 한도 대기 후 2026-10-03 00:10 KST에 등록됐다. 기존 시장 수집은 새 시세일을 저장하거나 모든 종목에 법인번호가 없을 때만 상장목록 연결을 실행하여, 이미 수집된 날짜만 있는 작업은 해당 회사를 연결하지 않았다.

정상 `MarketSnapshotSync.run` 말미에서 기존 미연결 Security를 현재 상장 Company의 유일 법인등록번호, 이어서 유일 종목코드로 연결한다. 법인번호/종목코드의 후보가 중복되거나 서로 다른 회사면 거부한다. 기존 연결과 폐지 회사는 건드리지 않는다. 추가 외부 요청·새 Source·시세값·기준일·출처 갱신은 없다. 기존 관리자 시작 경로/일일 API 한도/예약 정책을 변경하지 않았다.

별도 worktree의 embedded PostgreSQL 회귀는 합성 Source/시세로 실제 정상 job을 실행한다. 운영 DB 원형을 반출한 검증이 아니다. 저장 완료 날짜·지수 원장을 준비하고 외부 transport가 호출되면 즉시 실패하도록 설정했다. 신규 마스터/유일 종목코드/중복 번호/중복 코드/서로 다른 회사/폐지·취소/재실행을 검증하고 Source와 시세 JSON의 불변을 확인한다. 회사 연결은 `job.updated`의 신규 시세일 수를 증가시키지 않는다.

운영 읽기 스냅샷은 `outputs/filing-collection-priority/non-financial-backlog-readonly-20261002/post-master-*`에 별도로 보존했다. 본 후보는 운영 쓰기·수집 실행·배포를 포함하지 않는다.

검증: `market_existing_security_relink_test.dart` 신규6건 + 기존 `market_snapshot_sync_test.dart` 13건, 총19 PASS. 관련 세 파일 `dart analyze` 문제0, 변경 두 Dart 파일 format 차이0, `git diff --check` PASS. 기준 main `6cee87ed710d76e5e5c1a1eff8f79faf5cc0cbb0`.
