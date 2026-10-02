# CP·코스텍 FY2022 명시 매출 결측 후보

기준 9e135ca8, 격리 branch codex/cp-kostec-explicit-revenue. 현재 운영 상태를 조회하거나 생산 데이터를 수정하지 않았다. 원문은 기존 공식 raw cache이며 새 GET/API 호출은 없다.

## 정확 범위

- CP 01601222 / 20230315000997 / FY2022 / OFS: 당시 유진기업인수목적8호 주식회사, 제2기, 2022.01.01~12.31, 원.
- 코스텍 01476219 / 20230308000311 / FY2022 / OFS: 당시 교보10호기업인수목적 주식회사, 표지 제03기·표 제3기, 같은 실제 기간·원.
- CFS, 다른 접수·기간·법인·뷰어 좌표는 이 부분자료 규칙으로 수용하지 않는다. 현재 successor 이름으로 당시 재무 수치를 추론하지 않는다.

## 출처·숫자 규칙

정상 공개 fetch가 같은 exact receipt shell의 단일 법인코드와 표지/개요 노드 좌표를 검증한다. 회사개요의 유일한 법적·상업적 명칭 절 첫 직접 문장 “당사의 명칭은 '…주식회사'입니다.”를 표지에 대조한다. 역사·자회사·조건부 문장·여러 후보를 허용하지 않는다. 코스텍 점 날짜는 해당 원문에 한해 실제 Jan1-Dec31과 대조한다.

매출 current 그룹은 col2/span2에 인쇄된 ['', '-']이다. null fact와 원문 label/account_id null을 보존하고, 0·전기 대체하지 않는다. 다른 필수6 current 직접 숫자와 BS 등식은 모두 필요하다. CE가 유일한 현재 annual full date 제목·원·당시 회사명을 인쇄하고, 정확 whole 헤더·단일 당기초/당기말·그 사이 단일 whole 순익 행을 제공해야 한다. 그 순익/기말자본은 CIS/BS와 직접 일치한다. CP CE 기타불입자본 colspan2 및 코스텍 주석 열을 보존하며 합산·parent/NCI 대체하지 않는다.

CP actual6: A12,427,859,404/L1,408,433,174/E11,019,426,230/OP-55,315,450/NET57,682,077/CFO-37,153,280. 코스텍: A9,895,742,901/L903,428,428/E8,992,314,473/OP-65,684,830/NET44,097,065/CFO11,508,090.

코스텍 CFO '영업활동으로 인한 순현금흐름'은 exact whole CF alias로 분류한다. FinancialAccounts의 같은 목록에서 Dart/SQL mirror가 생성되므로 두 경로가 동일하며 주석·부문·nonCF·중복 whole 후보는 거부한다.

## 저장·표시 계약

기존 ImgtExplicitRevenueMissing helper의 명시 source profile만 두 원문으로 확장하며 IMGT 기존 규칙·CE restatement proof는 유지한다. 신규 규칙은 spac-explicit-revenue-null-v1이다. 정상 source title에 부분 핵심6·영업수익 당기 미기재(-)를 명시하고, 기존 audit의 exact receipt/corp/year/kind/basis/URI/SHA/current group/raw cells/CE proof를 보존한다. summary는 실제 null fact와 같은 source의 numeric6·audit를 대조했을 때만 기존 unavailableReason에 FY2022 사유를 넣는다. 연간·TTM 매출은 null, 이전 수치를 채우지 않는다. 처리 완료를 핵심7 또는 전체 재무제표 확보로 주장하지 않는다.

정확 OFS 두 접수만 기존 finite priority에 추가했다. attempts reset·cap3·scope5년·속도·API 예산·일반 실패 정책은 바꾸지 않는다.

## 검증 현황

- 공식 byte-exact shell/cover/overview/OFS 8 HTML과 원 URI/SHA proof fixture.
- 기존 IMGT·신규 두 SPAC 파서/명시-null 사유/priority/계정분류 단위 105 PASS.
- Flutter 연간·TTM null 사유와 전기금액 미대체 2 PASS.
- 소유 서버/Flutter 파일 analyze 및 format 확인.
- 루트 DB 슬롯 해제 승인 후 격리 normalqueue DB2 PASS. 정확 target가 generic10 뒤에 있어도 먼저 fetch, 직접6+매출null 저장·Source/audit·summary reason·SQL CFO 매핑·같은 report facts 확인. 반대 CFS는 명시 합성 sentinel Source/report/facts wholeJSON 불변이며 생산 DB 반출 검증은 아니다.
- API 호출0, ApiCallUsage20000 불변, general attempts3 불변/public2→3, 최대10period 그대로. 운영 수집 완료를 주장하지 않는다.
- cap3이면 finite priority는 거부한다. 이 두 원문은 현재 immutable source registry에 없으므로 배포 전에 publicattempt3이 되면 이 후보만으로 재검증하지 않는다. 추가 지원은 기존 1회 manifest+raw SHA 감사 경로의 별도 후보가 필요하며 이번 작업에서 counter reset·한도 확대는 하지 않았다.
