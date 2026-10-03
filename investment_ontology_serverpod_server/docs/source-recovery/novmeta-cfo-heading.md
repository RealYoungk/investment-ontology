# 노브메타파마 현금흐름 절 제목과 직접 합계 구분

기준 88f4caa7. 법인 01065785, 원접수 20260320000871, FY2025 OFS만 파서 구조 예외를 허용한다. 신규 공식 GET·API·운영 SQL·DB 테스트는 실행하지 않았다.

## 공식 원문 근거

fixture `test/fixtures/financial_html/novmeta-cfo-heading/proof.json`에 공식 shell/표지/OFS/CFS URI와 SHA를 보존했다. HTML은 기존 읽기 감사의 원문 바이트를 복사했다.

OFS dcm11157401/ele21/offset429403/length46142의 제16기 CF 표 첫 `영업활동 현금흐름` 행은 세 연도의 금액 TD가 모두 BR만 있다. 같은 표 뒤 `영업활동으로부터의 순현금유출`은 당기 `(3,358,353,147)`을 직접 인쇄한다. 영업에서 창출된 현금이나 이자·세금 행을 합산하지 않는다.

파서는 정확 접수·법인·basis·기간·기수·문서 좌표에 묶인 경우에만 빈 절 제목을 제외한다. 네 칸/단일 span, 당기열1, 세 금액칸 모두 진짜 빈 문자열, 뒤에 유일한 직접 whole CFO 합계 행이 필수다. 대시·0·전기 금액이 제목에 있거나 직접 합계 금액이 없으면 거부한다. 원문 표제·기수·기간·단위·전체 핵심7·BS 등식의 기존 검증은 그대로다. 원문 이름/null account_id·부호·당기열을 유지한다.

직접 핵심값(원): 자산4,362,722,562/부채770,110,124/자본3,592,612,438/매출34,838,000/영업손실-5,367,108,582/순손실-10,447,517,973/CFO-3,358,353,147. 빈 제목을 0으로 저장하지 않는다. CE 원문 기말자본과 전체손실은 동일하지만 이 후보는 새로운 CE 검증 완화나 CE로 수치 대체를 하지 않는다.

`영업활동으로부터의순현금유출` exact 이름을 FinancialAccounts의 공통 fallbackNames에 추가하여 Dart와 동적 SQL mirror가 동일 CFO 계정으로 읽는다. 다른 재무제표/segment/주석 이름/중복 whole 행은 기존 조건에서 거부한다.

## 검증 및 한계

실제 원문 양성, 빈 제목 당기/전기 값·필수 합계 빈값/대시/다중숫자·다른 합계명·회사/접수/basis/기간/단위 음성 및 계정 Dart·SQL 문자열 mirror 단위를 수행했다. 격리 정상 저장 DB와 운영 재시도는 아직 수행하지 않았으며 이 후보가 실제 저장완료라고 주장하지 않는다. CFS 원문은 기존 typed 비적용 지원 범위이며 OFS 숫자를 사용하지 않는다.

## 후속 정상 큐 후보

정확 법인01065785/접수20260320000871/FY2025 annual/CFS·OFS 두 basis를 같은 finite priority entry에 union했다. 현재3회 공개 재시도 한도와 정상 상태 조건을 변경하지 않았다. 정확 두 basis 및 회사·접수·연도·종류·한도·이미 stored 음성 단위7개를 추가했다.

격리 normalqueue DB 회귀는 각각 숫자 OFS와 pure 비적용 CFS를 원문 MockTransport로 처리하도록 작성했다. 일반 후보10개 앞에 실제 후보를 뒤에 seed하며 기존 반대 basis의 Source/report/fact JSON은 명시적으로 합성 sentinel이다. 비공개 운영 DB 원형 검증이 아니다. 숫자 신규 저장만 job.updated1, pure 없음은0이며 summary CFO 및 SQL exact 계정 매핑·API 호출0·기존 public2→3/global3 불변을 확인하는 테스트다. 실행 결과는 후속 검증 뒤 기록한다.

### 후속 검증 완료

우선순위 단위7 PASS, 정상 큐 격리 DB2 PASS. 숫자 OFS 실제 원문 Source/reference/URI/SHA/nullID/핵심7·CFO summary 및 SQL 매핑, CFS typed 비적용 별도 Source·숫자 report 미생성, 기존 합성 반대 basis JSON 불변을 확인했다. 공개 요청 MockTransport만 사용하여 외부 API0, 기존 공개attempt2→3/일반attempt3 보존을 검증했다.

처음 테스트 실패2개는 job.processed가 일반 reconcile1을 함께 포함한다는 기대 오류와 numeric audit와 typed absence audit의 서로 다른 reference 계약을 혼동한 오류였다. 생산 코드가 아니라 테스트를 수정한 뒤2 PASS다. 공개 큐 최대10은 실제 요청 고유 period 개수로 검증하며 전체 job 처리 수와 혼동하지 않는다. 운영 저장완료 주장은 하지 않는다.
