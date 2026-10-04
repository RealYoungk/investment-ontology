# 기업찾기 shad 이관 — 2026-10-04

대상은 `/screen` 조건으로 찾기와 `/industries` 업종으로 찾기의 공통 탐색이다. 일반 기업 목록 `/companies`는 이번 변경에 포함하지 않는다.

- 공통 SegmentedButton을 직접 ShadToggle로 교체한다. 필수 단일 선택과 방식별 URL 필터 복원은 유지한다.
- 스크리너 시장·정렬 방향은 직접 ShadToggle, 정렬 지표는 직접 ShadSelect/Option이다. 시가총액은 실제 선택 옵션이며 기존 서버 정렬 방향을 유지한다.
- 결과는 ShadTable/Cell, 기업 이동은 ShadButton.link, 빈 결과는 ShadEmpty이다. 단일 숫자 행에 56px 높이를 사용한다. 긴 공시 원문 표의 가변 높이 계약에는 적용하지 않는다. 기업명 열을 고정하며 가로 스크롤을 허용하고 세로 스크롤은 PageFrame이 담당한다.
- 적용 조건·현재 정렬 지표의 열, 숫자 단위·연결/별도·결측 사유 tooltip·10개 조회·상세 push 탐색을 보존한다. 조건 입력과 프리셋은 기존 ShadInput/Button을 유지한다. 아이콘은 Lucide로 통일한다.
- 320px에서 페이지 이동 Row가 넘치는 문제를 Wrap으로 수정했다.

검증: 앱 전체 dart analyze 이상 없음, format 완료, 관련 29개 Flutter 테스트 통과. 320/390/768/1440px 조건 입력·프리셋·URL 유지, 연속 배당 기준연도의 가로 스크롤 접근, 10개 페이지 이동, 업종 필터/비교·디자인 경계를 검사했다. 실제 localhost:8100에서 KOSDAQ 필터와 URL, PER 정렬 및 asc=1, 실제 조회 행과 390px 표/페이지 버튼, 업종 탭 전환을 확인했다. 모바일 화면은 outputs/design/company-finder-shad-2026-10-04/mobile.png.

Serverpod MCP hot_restart 성공. 로그의 이전 reassemble timeout 뒤 마지막 restart 성공을 확인했다. 서버 쿼리 지연 기록이 있어 최초 스크리너 결과는 기다려야 했다. 마지막 재시작 뒤 전체시장 조회에서 연결 실패 안내가 나타났고 재시도 버튼 동작을 확인했다. 앞선 KOSDAQ/PER 조회는 실제 행까지 성공했다. 서버/DB/인증/vendor 변경과 운영 배포는 수행하지 않았다. 금융 값 정확성·OS IME·VoiceOver·모든 업종 결과 상호작용 완료를 의미하지 않는다.

웹 빌드 검증 한계: 표/필터 이관 후 첫 web build는 성공했다. 최종 320px 페이지 이동 줄바꿈 보정 뒤 재빌드는 동시에 변경된 graph_page의 AppLayout.maxWidth 참조로 실패했다(다른 작업에서 contentWidth로 수정됨). 재시도에서는 같은 flutter_build 산출물을 쓰는 여러 빌드가 동시에 컴파일 중이었으며 5분 이상 완료되지 않아 이번 실행만 중단했다. 최종 소스의 웹 빌드는 미확인으로 남긴다. 분석/29개 회귀 검증과 앞선 실제 화면 결과를 빌드 완료로 대신 해석하지 않는다.

## 하단 페이지네이션 후속 수정

남겨 둔 이전/다음 버튼 조합을 직접 ShadPagination으로 교체했다. 현재 페이지와 전체 페이지 수, 번호 직접 이동, 이전/다음, 로딩 중 비활성을 연결한다. 600px 미만은 siblingCount/boundaryCount를 0으로 줄이며 페이지당 10개 조회와 조건 변경 시 첫 페이지 복귀를 유지한다. 관련 21개 테스트 및 수정 화면 analyzer 통과. 번호 선택으로 offset=20 요청도 회귀 검사한다.
실제 localhost:8100에서도 ShadPagination의 번호/이전/다음을 확인하고 다음 클릭 후 11–20번째 결과와 Page 3 노출을 확인했다. 증거: outputs/design/company-finder-shad-2026-10-04/pagination.png. 번호 직접 이동 회귀 검사 추가 실행도 통과했다.
