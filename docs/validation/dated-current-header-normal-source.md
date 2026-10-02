# 날짜·현재 열 증명의 정상 원문 수집 연결 후보

대상은 루켄 00886792/20260323000759 및 바이오프로테크 00669450/20260330001644의 FY2025 CFS/OFS 네 basis이다. 기존 issuer/URI/기간/basis 검증 뒤 실제 cover/body로 독립 proof를 재계산한다. proof가 확인한 tableIndex/currentColumn/header만 현재 열 선택에 보태며, 일반 빈 헤더·span·부호·기간 규칙은 확대하지 않는다. CE는 같은 basis의 전체 합계가 BS 자본 및 CIS 전체 순손익과 일치한 증명표만 제외한다. 최종 정상 parser 핵심7도 proof의 직접 금액7과 정확히 같아야 한다.

루켄 원문 `[자산총계]`/`[부채총계]`는 증명된 BS 표에서만 파싱 계정으로 읽는다. 저장하는 account_nm은 괄호를 포함한 원문 그대로이며 XBRL ID는 null이다. FinancialAccounts의 유한 두 별칭을 Dart/SQL 공용 분류에 추가했다. 부문·주석·다른 statement·임의 중첩 괄호는 수용하지 않는다. 기존 루켄2024 OFS 정상 CE proof 계약은 유지한다.

네 원문은 shell/cover/요청basis 3raw를 수정 없이 패키징하고 URI/SHA/corp/접수/year/basis manifest를 고정했다. normal public queue에서는 attempt2→3, 이미 cap3인 경우 기존 한 번 감사 cache 단계에서만 재검증한다. 기존 public/general counter 초기화·cap3 증가·전체10/실패6 변경이 없다. 성공/실패 감사 및 저장 transaction은 기존 공용 경로를 사용한다.

순수 검증: 기존 FinancialAccounts·루켄2024 및 신규 helper/cache/priority 회귀70개 PASS. 실제 네 basis 정상 fetch/parser는 각8행(whole7+직접 CAPEX)을 읽으며, 판도라2025 OFS 실제 기수 충돌은 계속 거부한다. 단독 격리 DB 회귀는 네 basis × normal public2/cap3cache=8개로 Source URI/원접수/실제8fact/nullID·summary·SQL mapping·job.updated1·반대basis JSON 불변 및 cache 재실행 updated0을 확인한다. 반대basis는 합성 sentinel이며 운영 비공개 DTO를 반출해 비교한 것이 아니다.

최초 회귀 실행의 실패는 복사된 메디쎄이 master명과 SQL placeholder fixture 오류였다. 실제 identity guard를 유지한 채 정확 registry회사명 및 @id parameter로 테스트를 수정했다. 운영 쓰기/배포/API키/추가 원문 GET은 사용하지 않았다.

40기간80basis 감사는 별도 outputs/filing-collection-priority/header-api40-source-ledger-20261003에 있다. 원문 확보·텍스트 확인·파서 재생·전체 금액 교차검증은 별도 상태이며 전체 원문의 정상 저장 완료를 뜻하지 않는다.
