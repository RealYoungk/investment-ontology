# 유니포인트·인터로이드 검증 원문 캐시 후보

046c91ee 기반 별도 후보이며 새 재무 문법은 추가하지 않았다. FY2025 별도만 지원한다.

|회사|법인코드|원접수|basis|
|---|---|---|---|
|유니포인트|00445869|20260316001455|OFS|
|인터로이드|01290132|20260326000677|OFS|

각 공식 shell/표지/OFS 원문 3개는 이전 읽기 감사에서 확보된 byte를 그대로 복사했다. manifest에 URI·SHA·원접수·법인코드·FY2025 실제 시작/끝·basis를 고정했다. 기존 공유 캐시 validator/정상 저장/성공·실패 한 번 감사와 취소·최종 정정 선택을 그대로 사용한다. 전체 registry는 기존 25개와 두 개의 합집합 27개이다. 공개 시도 3회 한도나 일반 카운터를 초기화하지 않는다. 정상 큐 우선순위는 두 exact 회사/접수/FY2025/OFS에만 추가했다.

원문 출처는 root outputs의 unipoint-bonsystems-current-core-readonly-20261002/20260316001455 및 metadata-next-eight-readonly-20261002/20260326000677이다. 유니포인트 OFS는 실제 목차로 재확인한 actual-ofs.html을 사용했다. 다른 basis나 다른 연도·정정 접수는 이번 패키지로 판정하지 않는다.

이번 검증은 단위 및 정적 분석이다. 운영 쓰기/API/외부 GET/DB 테스트는 없으며 정상 job 저장 DB 검증은 별도 슬롯 승인 후 진행한다. 원문 패키지가 존재한다는 것만으로 운영 저장 완료를 주장하지 않는다.

검증 결과: exact priority 양성/회사·접수·연도·종류·기간·다른 basis·cap 음성 16개 PASS. 두 캐시 actual8/공통 scope 거부/3원문·manifest byte변조 음성 및 audit identity 유일성 29개 PASS. owned 파일 정적 분석 0.

표지 파일 선택 주의: 유니포인트 제공 폴더의 cover.html은 대표이사 확인서였으므로 사용하지 않았다. 같은 공식 표지 URI를 증명한 financial-failures-readonly-20261002/period-three/20260316001455/cover.html(SHA 2788fca0a2c22f377fecab10c8f2c527358637502ac8da965f6c658a72fefac2)을 byte 그대로 패키징했다. 원문·URI·기간·파서 수정은 없다. 최초 잘못된 파일의 strict 거부 후 정확한 원문 재검증이 통과했다.

## 정상 저장 후속 검증

격리 DB4 통과: 두 exact OFS 각각 normal public2→3 transport + cap3 immutable cache 정상job 저장/재실행을 검증했다. normal 경로는 원문 actual8 모든금액·Source 공식 URI/원접수·current FY2025/annual/OFS·행 provenance source/period/unit·매출 summary·job.updated1을 대조한다. 일반 attempt3/공개 attempt3/일일 API 원장20000과 반대 basis Source/report/fact 전체 JSON은 불변이다. 반대 basis 보존은 명시 합성 sentinel이며 운영 비공개 DB 원형 반출 검증이 아니다. 캐시 경로는 source combined SHA·같은 정상 저장/updated1·재실행 updated0/읽기·중복audit0을 공용 회귀로 확인했다.

첫 DB 실행의 유니포인트 테스트 매출 기대값0 잔존은 실제 인쇄 매출58,346,049,641원으로 수정했고 전체8금액 직접 대조를 추가해 재실행4 PASS를 확인했다. 생산 코드 수정은 없다. API·공개 GET·운영 DB 쓰기0이며 현재 DB 프로세스0/슬롯 해제다.
