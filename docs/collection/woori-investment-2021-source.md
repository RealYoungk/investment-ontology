# 우리기술투자 FY2021 직접 원문 후보

대상은 법인코드 00231664, 접수 20220715000446의 2021.01.01–12.31 별도 원문 한 개다. 운영 읽기 전용 조회에서 CFS/OFS 모두 failed/public attempt3이며 해당 접수 FinancialReport는 0건이었다. 이 시점의 관찰이며 전체 운영 커버리지를 뜻하지 않는다.

공식 shell 법인코드·own접수, 표지와 별도 4개 표의 법인명/제26기/날짜/원 단위, URI·SHA를 고정했다. primary BS/CIS/CF의 직접 현재열 7계정만 원문 계정명과 null XBRL ID로 저장한다. 전체 원문 행을 수집했다고 표시하지 않는다. 단일 CAPEX 총계 행을 추출하지 않았으므로 unavailable을 유지한다. 이미 있는 exact CFO 분류 `영업활동으로인한순현금흐름`을 Dart/SQL 모두 그대로 재사용한다.

별도 직접 계정(원): 자산 919,280,938,907 / 부채 191,490,588,322 / 자본 727,790,350,585 / 영업수익 811,879,819,525 / 영업이익 793,507,225,421 / 당기순이익 620,087,515,295 / 영업활동 순현금흐름 2,577,554,687. BS 등식과 CE 당기초·당기말·전체 순익/기말자본을 별도 검증한다. 부모/비지배 구성요소 대체·계정 합산은 없다.

별도 CF: 직접 3활동 합계 2,577,554,687 + 8,319,080,433 − 190,277,898 = 인쇄 증감액 10,706,357,222. 기초 2,767,262,329 + 증감 = 기말 13,473,619,551이며 BS 비교/현재 현금과 각각 일치한다. FX 인쇄 셀은 `-`이고 금액을 0으로 저장하거나 추론하지 않는다. 감사 provenance는 printedFx와 fxAmountAvailable=false를 보존한다.

연결은 등록하지 않는다. 직접 4활동 합계 17,600,248,788 + 8,399,080,433 − 13,088,086,354 + 14,716,795 = 12,925,959,662지만 인쇄 증감액은 12,925,959,661로 1원 차이가 있다. 기초+인쇄증감=기말과 BS 현금은 맞지만 활동 합계 충돌을 무시하지 않는다. 원형 연결 파일은 음성 fixture로 보존하며 helper는 거부한다. 수치/FX/날짜 수정, 허용오차, CFS 등록이 없다.

기존 admin normal-job의 immutable cache replay만 활성화한다. 원문 HTTP/API 호출 0, public attempt3 또는 일반 카운터 초기화/한도 확대 0, 성공/실패 한 번 audit·scope·정정제외·취소·transaction·전체10·failure6 가드는 기존 공용 경로를 사용한다. actual source receipt는 target와 같은 원접수다.

검증: 원문 helper 순수18 PASS + immutable registry 경계15 PASS, 변경 파일 analyze 0/format 0. 격리 normal-job DB2 최종 PASS(로그 /private/tmp/io-woori-db2-final.log): API20k·일반attempt7·publicattempt3 보존, OFS7 Source 실제 URL/계정/amount/nullID·summary·SQL7 분류·CAPEX unavailable·fullStatementCollected=false·반대CFS failed 보존, 재실행 updated0/raw read0/Source·report·facts·장부 JSON 불변, SHA 변조 실패 audit1·재실행0을 확인했다. 해당 접수 운영 Report0건이었으므로 반대CFS 기존숫자 보고서 불변이라고 주장하지 않는다. 최초 환경 semaphore setUp 실패와 중간 fixture summary key 오류는 최종PASS와 구분해 로그 보존했다. 최종 실제 본인 PostgreSQL 프로세스0 확인, 설정/IPC 임의변경0/운영 DB 변경0.
