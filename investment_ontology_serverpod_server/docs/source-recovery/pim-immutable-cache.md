# PIM 연결 원문 캐시 한 번 재검증 후보

Talos5ed175e8 뒤 확장이다. 필수 파서 의존은 4ca2cdb0aba600d82c5616037cbbee3ebd485f23이며 이 작업 트리의 cherry는1de44b33이다. 대상은 한국피아이엠00765897, 접수20250321001900, 2024.01.01~12.31 연간 연결뿐이다. 자본변동표의 직접 whole 총계 순손익2,777,596,031원과 기말 자본43,652,099,251원을 손익표·재무상태표와 대조한다. 지배기업 값이나 부문 합산으로 대체하지 않는다.

고정 패키지는 assets/financial_source_cache/pim-cfs-2024의 공식 shell/cover/CFS 원문과 manifest이다. 원문 바이트 SHA는 기존 실제 fixture와 같다. manifest digest는 c964aef1f97af016e1d54595c8b05c5fb5762bc80ab02cc363b504ea1c62ac80. 원문 계정 ID는 제공되지 않아 null을 보존하고 인쇄 명칭·원화 단위·직접 current 값·기간·basis·원 URL·행 provenance를 기존 normal _store에 넘긴다. 정상 financial-api-noData-source audit도 공용 함수로 기록해 기존 기간 검증·요약·SQL 계정 매핑이 같은 자료를 읽는다. 전체 재무제표 복구가 아닌 원문 부분 핵심계정이다.

_store/_insert는 기존 동작을 유지하며 선택적 Transaction을 받아 캐시 검증·숫자 저장·정상 출처 audit·한 번 cache audit·장부 상태를 같은 트랜잭션으로 묶는다. 캐시가 보유한 filing FOR UPDATE 안에서 별도 내부 transaction을 열지 않는다. 기존 연결 보고서나 이미 존재하는 기간 audit는 보수적으로 충돌 거부한다. 동일 manifest/접수/basis/rule version 성공·원문검증 실패는 다시 실행하지 않는다. 취소와 더 최신 같은 기간 접수는 새 등록을 하지 않는다. 기존 별도 공개 DTO(report115392/source/facts)의 모든 필드는 격리 foreign key/ID만 새로 부여하고 전후 불변으로 검증한다. 비공개 운영 DB 전체 자료 반출·검증이 아니다.

Talos와 PIM 캐시 처리 건수는 기존 연간 공개 큐와 합계 최대10기간이고 연속실패6·공개attempt3·일반attempt 값·기존 API meter를 보존한다. 외부 HTTP/API 호출0, 새 endpoint/model/migration0. 공개 DTO 준비를 위한 인증 없는 정상 API 읽기2회는 별도이다. runtime Docker 기존 assets 패키징을 사용하고 공개 DTO/test fixtures는 런타임에 넣지 않는다.

검증 범위: PIM 캐시24·PIM 파서15·Talos 캐시24 단위63개. 격리 DB PIM5(성공+재실행·SHA실패+재실행·취소·최신 접수 대체·기존 출처 충돌)와 Talos4. 성공 케이스는 실제 7핵심/current raw 값/null IDs/SourceSHA·정상 요약과 SQL 순손익·자본 대조, OFS 공개 DTO 원형 불변을 검증한다. 동시 두 transaction 회귀는 Serverpod 자동 rollback test proxy가 금지하여 실행 검증 범위에 포함하지 않는다; 운영 잠금 동시실행을 검증했다고 주장하지 않는다. 재실행 무중복과 global advisory lock/행 잠금은 유지한다. 운영·counter reset·배포 없음.
