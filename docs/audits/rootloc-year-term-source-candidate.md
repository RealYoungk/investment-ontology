# 루트락 FY2025 OFS 원문 후보

접수20260323000661/법인01262023/원문dcm11163088/OFS노드21에만 적용한다. 표지의 실제365일 사업연도와 제12기, 세 재무표의 오른쪽 2025년도(제12기) 당기열, 천원 단위 whole7을 유지한다. 날짜 없는 표제를 일반 허용하지 않는다.

독립 CE 표는 구분/과목/자본금/자본잉여금/자본조정/기타포괄손익누계액/이익잉여금/총계 8열. 당기 구분셀 rowspan7을 직접 확인하고, 나머지7개 직접셀의 유일한 2025.1.1(기초), 2025.12.31(기말), 당기순손실 whole총계 및 기말자본을 읽는다. 합산하지 않으며 generic grid 상한을 변경하지 않는다. 천원 배율은 인쇄 단위로만1000을 적용한다. CE whole 순손실/기말자본이 CIS/BS와 일치해야 한다. 원문 과거2024 BS와CE자본1천원차이는 복구하지 않는다.

공식 shell/cover/OFS 원문과 URI/SHA는 fixture proof.json. 현재후보의 단위검증만 수행하며 normal storage/queue DB 테스트는 부모 승인 전 미실행이다. 운영 수정/API 요청/attempt reset 없음.

## 후속 실제 큐 검증

빈 CE rawRows는 cells(0) 전에 FormatException으로 거부한다. 정상 fetcher→sync의 격리 단일 큐 회귀에서 exact Rootloc OFS/Elivision CFS/BioTen OFS 3기준이 generic10보다 먼저 처리됨을 확인했다. Rootloc 직접8행·whole7, rawlabel/nullID/KRW·인쇄천원·currentcolumn3·CE총계column7/wholeprofit/equity 근거가 Sourceaudit에 그대로 남는다. 실제 summary 및 SQL계정 해석도 확인했다. 미검증 Rootloc/BioTen CFS에는 raw자료가 없어 fixture가 명시적 검증실패를 반환하며 failed를 유지한다(추정noData/0생성 없음). publicattempt2→3, cap3/속도/최대10/일반실패counter 증가정책 그대로.
