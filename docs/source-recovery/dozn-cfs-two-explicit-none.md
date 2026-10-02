# DOZN 연결 원문과 두 명시적 CFS 비적용 후보

## 범위와 실제 근거

5503d53f 기반 독립 후보입니다. 공식 원접수 GET4만 이전 읽기 단계에서 사용했고 구현 중 추가 GET/API/운영SQL/DB실행은 0입니다. 원문 근거는 `outputs/filing-collection-priority/four-identity-sources-cfs-readonly-20261002/`에 있으며 최신 live 잔여 목록이나 완료 수를 주장하지 않습니다. ITcen OFS828f 별도 후보·Protia OFS·Redwoods OFS는 보존합니다. Redwoods CFS는 다른 담당자 범위라 변경하지 않습니다.

## DOZN 20250328001780 CFS / FY2024

법인01563667, dcm10474522 / ele19 / offset202829 / length70331의 실제 CFS만 지원합니다. 원문 SHA39948296402bc3478a4388387ba6482d6beecfe0cb7510aed5453ee29a42e7c9 및 기존 연간 표지 SHA를 검증합니다. OFS와 다르게 지배주주 순익10,028,364,955원이 아닌 전체순익9,917,308,588원을 사용합니다. 전체자본41,367,841,817원도 지배지분41,081,204,501원과 구분합니다.

직접8행은 자산115,669,842,342 / 부채74,302,000,525 / 전체자본41,367,841,817 / 영업수익62,657,767,124 / 영업이익10,022,797,774 / 전체순익9,917,308,588 / 영업CF20,891,307,095 / 유형자산취득-1,467,710,372원입니다. 모든 인쇄 계정명·원 단위·CFS·null XBRL ID를 보존합니다.

각 흐름표 제목은 끝날짜 '현재'만 인쇄합니다. 시작을 제목에서 읽었다고 주장하지 않고 실제 fullFY 표지 + CE 2024.01.01 기초/2024.12.31 기말 + 전체순익/BS전체자본 + 현금 기초62,036,528,499→기말80,683,745,769/활동증가18,544,830,439/환율102,386,831원의 독립 롤포워드로 검증합니다. 정상 body/span 상한은 바꾸지 않습니다. 정확 SHA로 고정하고 독립 검증된 CE index7의 9열은 core-row grid 전에만 제외합니다. 일반 CE를 생략하는 규칙이 아닙니다.

## 정확 CFS 비적용 2건

- Protia 법인01267958 / 20230320000571 / FY2022: “당사는 연결대상 종속회사가 존재하지 않으므로, 한국채택국제회계기준의 주된 재무제표인 연결기준의 재무정보를 기재하지 않습니다.”
- ITcen PNS 법인01113499 / 20230317000589 / FY2022: “당사는 사업보고서 제출기준일 현재 해당사항 없습니다.”

원문 단일 BODY의 정확 2.연결재무제표 제목과 단일 문장만 허용합니다. 추가 조건문·숫자표·script/style·다른 절·참조는 기존 strict 가드로 거부합니다. 새 문구는 두 정확 원접수/법인/annual FY2022/full2022-01-01~12-31에만 추가하며 일반 같은 문구로 확장하지 않습니다. 직접 legalname issuerProof를 보존합니다. 실제 비적용을 API 자료 없음이나 원문 부재로 설명하지 않습니다. 정상 typed-none audit로 CFS nonpreparer를 기록하고 숫자 저장 수는 0입니다.

## 캐시와 검증 제약

DOZN CFS는 공식3raw, 두 비적용은 shell/cover/CFS/회사개요4raw URI·byte SHA 불변manifest를 추가합니다. 기존 once-cache 성공/실패 감사, 최종 scope, 취소, 전체10/실패6, publicattempt3 상한과 일반 카운터를 바꾸지 않습니다. 신규 정확 CFS map union만 추가합니다. 기존 OFS Source/facts는 유지해야 합니다.

순수 단위48 PASS(DOZN CFS+기존OFS+두 실제typed-none·표/조건문/script/style 거부), 신규3패키지와 기존DOZN OFS focused registry74 PASS, 변경파일 analyze0/format0/diffcheck PASS입니다. 정상 public2→3와 cap3 once-cache DOZN DB2 및 두 none DB4를 작성했지만 아직 실행하지 않았습니다. rootfullgate/공유메모리 환경 확인 때문에 DB미검증 후보이며 운영 완료로 세지 않습니다.
