# Talos 연결 비적용 원문 캐시의 한 번 재검증

대상은 법인01020269, 접수20260323001652, 2025.01.01~12.31 연간 연결재무제표뿐이다. 공식 원문 전체 연결 절에는 제목과 `해당사항 없음`만 있다. 별도 숫자를 연결 숫자로 사용하지 않는다.

서버 assets/financial_source_cache/talos-cfs-2025에 공식 shell/cover/CFS 원문 바이트와 URL/SHA를 고정해 Docker의 기존 assets 복사로 패키징한다. 컴파일된 manifest SHA 및 각각 원문 SHA를 검증한 후 기존 공개 HTML fetcher를 네트워크 없는 고정 응답 어댑터로 실행한다. 회사코드/접수/공식 노드/표지 날짜/요청 basis/순수 비적용 문구 검증을 재사용한다. 임의 payload, 파일 경로, HTTP 요청을 허용하지 않는다.

기존 admin 정상 재무 job에서만 실행한다. 최신 최종접수와 5개년 financial_scope를 트랜잭션 안에서 다시 확인하며 global advisory lock과 행 잠금으로 성공/실패 모두 manifest digest+접수+basis+rule version별 Source audit 한 개를 기록한다. 공개 재시도3과 일반 attempts는 그대로이며 한도를 늘리거나 초기화하지 않는다. 성공은 기존 typed absence 저장 경로로 연결 noData 및 검증 원문 Source를 기록하고, 실패는 숫자/완료를 만들지 않는다. 취소 시 새 audit를 기록하지 않는다. 기존 연결 보고서나 충돌하는 비적용 Source는 거부한다. 연간 최대10기간과 연속실패6에 포함된다.

검증: 단위24개와 기존 Elivision 비적용 회귀10개 통과. 격리 DB4개(성공 후 재실행, SHA 실패 후 재실행, 읽기 중 취소, 더 최신 접수로 대체) 통과. API meter20000, 일일예산0에서 네트워크/API 요청0을 확인했다. 기존 별도 보고서115386의 인증 없는 공개 DTO(report/source/facts)를 2026-10-02 조회해 격리 ID만 새로 부여했으며 모든 필드를 전후 비교했다. 비공개 운영 DB 전체 payload 검증이라는 주장은 하지 않는다. 공개 DTO fixture는 테스트에만 포함되고 런타임 자산에는 포함하지 않는다.

이번 지원은 Talos 한 연결 자료만이며 PIM 숫자 복구와 다른 과거 접수는 포함하지 않는다. 운영 변경·배포·카운터 초기화는 수행하지 않았다.
