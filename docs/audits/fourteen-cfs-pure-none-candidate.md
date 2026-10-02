# 순수 CFS14건 다음버전 후보

기준3b486ad0. 공식 raw는 이전 읽기감사 두10건에서 순수문구 각7건만 재사용했습니다. owncorp/receipt/표지 실제연간기간/동일dcm/CFS절/URI·SHA는 test/fixtures/financial_html/fourteen-cfs-none/proof.json 및 sha256.json에 보존합니다. 원문·숫자·기간을 바꾸지 않았습니다.

신규 문구4종만 추가합니다: 우양HC '당사는 작성기준일 현재 해당 사항이 없습니다.', 유화 '※ 해당사항 없음.', 태양3C '당사는 본 보고서 제출일 현재 해당사항 없습니다.', SBI '- 연결재무제표 작성대상이 아닙니다.'. 기존 pure 전체section2·표/숫자/script/style 없음·회사/접수/기간/요청basis 검증은 그대로입니다. 임의 참조/법률/외부절·빈절·TABLE 안 문구·실제숫자표는 지원하지 않습니다.

정확14 CFS에만 유한 우선순위를 추가했습니다. 기존OFS profile은 변경하지 않고, 기존OFS가 같은map에 있으면 합집합으로 유지하는 방식입니다. API attempts/public attempts 초기화와 cap3 변경은 없습니다.

단위 테스트는 실제14typedSource 및 현재지원10, 신규4의 숫자/표/문맥/법률/다른절/회사/기간/basis 음성과 priority 경계를 검증합니다. 격리DB 코드는14 기존OFS sentinel을 보존하면서 첫실행최대10+30초재개/다음4로 완료하는 정상API0·Source audit·updated0를 검증하도록 준비했습니다. 현재 root 게이트와 충돌하지 않도록 DB 실행을 보류했습니다. DB 미실행 상태이므로 배포 검증 완료를 주장하지 않습니다.

추가 운영GET/API/SQL/쓰기0, 배포·push·PR0입니다.

검증 결과: 실제 원문·부정 경계 단위 69개 PASS, 접수·마감월·상한 경계를 보강한 우선순위 14개 재검증 PASS. 정적 분석 오류0·포맷 변경0·원문 및 메타데이터 SHA58개 일치·diff check PASS. DB 실행은 0회이며 정상 10+4 재개/기존 OFS 보존 회귀 코드는 준비 상태입니다.
