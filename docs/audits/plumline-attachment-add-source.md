# 플럼라인 첨부추가 사업보고서 별도 원문 복구

공식 접수 20260323000673, corpCode 01063237, FY2025.12의 실제 표지와 별도 재무표를 검증했습니다. 원문 URI와 SHA256은 test/fixtures/financial_html/plumline-attachment-add/proof.json 및 sha256.json에 보존합니다.

exactAnnual transport 제목에 `[첨부추가]사업보고서 (YYYY.MM)`만 추가했습니다. 일반 사업보고서/기재정정의 기존 동작은 유지하며 첨부정정·예정·중복 modifier는 이 경로에서 거부합니다. 회사·접수·문서·실제 기간·단위·BS/CE·현재 whole계정 검증은 그대로입니다. 에이원큐브텍의 회사명 불일치는 이번 복구 대상이 아닙니다.

플럼라인 해당 접수/FY2025.12/OFS만 유한 큐 우선순위에 추가했습니다. public attempt 3 이상·다른 회사·기간·kind·완료 basis는 우선순위 제외이며 API attempts 초기화나 상한 변경은 없습니다.

실제 원문 핵심 7계정은 KRW이고 BS 2025-12-31, PL/CF 2025-01-01~2025-12-31입니다. 원문 인쇄 라벨과 null XBRL 계정ID를 그대로 저장합니다. 부분 핵심계정 수집이며 전체 재무표 복구 완료를 주장하지 않습니다.

검증: 실제 mocked transport/identity·modifier·연도 음성 및 유한 priority 단위 15개 PASS. 독립 작업 트리의 정상 수집 DB 1개 PASS(API 호출 0, ownreceipt/source URI/dcmNo11163121, 7개 fact 저장, FY2025 및 API attempts3 불변). 운영 DB/API 변경은 하지 않았습니다.
