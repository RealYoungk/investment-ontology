# DB금융투자 FY2022 CFS 정확 원문 후보

기준 0f6bf729(registry214)에서 7047bd85 문서단독 변경을 먼저 반영했다. 신규 접수20230321001219/법인00115694/FY2022/CFS만 registry215로 추가한다. FY2021 OFS는 보존한다. shell/cover/overview/CFS 4원문 URI와 SHA를 모두 고정하며, 현재 DB증권 이름을 역사 원문 이름으로 덮지 않는다. 동일 접수 I.회사개요 자기명칭 디비금융투자 및 자기영문명 DB Financial Investment 선언을 표지 DB금융투자·owncorp와 함께 검증한다. 전역 음역 alias는 없다.

기존 일반 파서는 제41(당)기 현재 헤더에서 거부하므로, 다른 회사의 헤더 규칙을 넓히지 않고 독립 불변 현재셀 프로필을 사용한다. 모든 주요 표에 직접 인쇄된 원 단위와 완전 연간기간, BS/CE 전체자본·CIS/CE 전체순익, CE 소유주+비지배 전체합, 당기·전기 CF 활동/인쇄증감/FX/기초말 및 BS 현금을 독립 검산한다. 조정익 주석과 소유주 순익을 전체순익 대체값으로 쓰지 않는다. raw/currentCell/단위/기간/SHA와 검산 근거를 Source audit에 보존하며 fullStatementCollected=false이다.

직접 단일 CF '유형자산의 취득' 당기셀 (3,687,283,186), 단위 원이 존재하여 선택적 8번째 계정으로 포함했다. 무형/기타 합산이나 부호 보정은 하지 않는다. 저장과 summary의 원형 값은 -3,687,283,186이며 기존 클라이언트 capex/FCF 계산의 abs 규칙을 변경하지 않는다.

순수 검증: 신규 및 기존 DB exact 두 프로필 30 PASS, 신규 registry 경계·SHA·유일성 16 PASS. 정적 분석 No issues, format 7파일0변경. 최초 DB setup은 semget 자원 부족으로 본문0회 종료했다(/private/tmp/io-db22-queue-db.log). 루트가 소유 종료 semaphore만 확인해 환경을 복구한 뒤 승인된 1회 재실행에서 정상큐 DB1 PASS/exit0/tearDownAll 종료를 확인했다(/private/tmp/io-db22-queue-db-retry.log). 전용 postmaster99201이 종료돼 PG0이며 다른DB·IPC·운영 설정을 변경하지 않았다.

DB회귀는 API사용20,000/API호출0, attempts7/public3 보존, 기존 반대basis synthetic sentinel 불변, 실제8 Source/summary/SQL, once audit 재실행 불변을 검증했다. 저장 금액은 원형이고 capex -3,687,283,186도 Source/currentCell 및 summary에서 그대로 확인했다. 운영 배포·DB 직접 수정·재시도 초기화·권한 우회는 없다.
