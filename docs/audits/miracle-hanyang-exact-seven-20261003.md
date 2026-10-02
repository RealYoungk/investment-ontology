# 미라클·한양 FY2022 정확 원문 핵심7 검증

## 범위와 원문

- 한국미라클피플사 01363924, 20230323001437, OFS, 2022.01.01–2022.12.31, 제9기, 원.
- 한양증권 00162416, 20230315000894, OFS, 2022.01.01–2022.12.31, 제68기, 원.
- core50 기존 공식 shell/cover/OFS를 bytes 그대로 복사. 각 manifest에 실제 6좌표 URI와 SHA256 고정. 신규GET/API/운영SQL/DB쓰기 없음.

## 직접 검증

원문에 인쇄된 필수7계정만 반환하고 accountName 원형/accountId=null을 보존합니다. 각 BS 당기·전기 A=L+E와 부채·자본 총계, CE 당기·전기 각각 고유 기초/기말 및 독립 전체 순익/자본을 교차확인합니다. OFS 총계열만 사용하며 구성요소를 합산하지 않습니다. CF의 당기·전기 순익은 PL과 일치하고 CFO+투자+재무 흐름이 현금증감과 일치합니다. 기초현금+증감+인쇄 환율효과=기말현금, 당기 기초현금=전기 기말현금도 확인합니다. 미라클 BS 현금은 CF 기말현금과 일치합니다. 한양 BS 현금및예치금은 CF 현금과 정의가 달라 같다고 주장하지 않습니다.

미라클 CE/CF 헤더 첫셀의 별첨주석 문장은 실제 원형 전체와 일치해야 합니다. 한양 PL 순익의 닫히지 않은 대손준비금 조정주석은 고치지 않고 정확 인쇄 문자열과 실제 NI셀을 검증합니다. 해당 한 문자열만 Dart/SQL 계정 역할로 정상화하고 다른 금액·문구·부모순익 변형은 매핑되지 않습니다.

양쪽 CAPEX 단일 총행은 없습니다. 세부취득을 합산하지 않으며 optional CAPEX는 미확보/null입니다. Source 행별 proof에 fullStatementCollected=false와 uncollectedOptionalAccounts=[capex] 기록. 전체 재무제표 수집완료 주장 없음. CFS 복구/완료 상태 변경도 하지 않습니다.

## 검증 상태

- 순수 신규27 + 기존 optional CAPEX5 = 32 PASS (io-exact-seven-pure-final.log).
- 정적 분석 0 issue, format 완료.
- 정상 queue/cache DB2 테스트 작성: API0/attempt3 보존, CFS failed 보존, 실제 Source URI·핵심7/원형명칭·SQL매핑·공개summary·재생멱등. 실행은 root 슬롯 허용 대기.
