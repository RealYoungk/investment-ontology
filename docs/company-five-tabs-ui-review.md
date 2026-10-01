# 기업 5개 탭 위계 재검토 — 2026-10-01

이전 수정은 일부 제목·카드만 통일했으며 전체 위계 검토가 부족했다. 이번 검토는 로컬 SK하이닉스 기준이다.

| 검토 영역 | 문제 | 반영 |
|---|---|---|
| 공통 머리말 | 탭 전체 제목과 내부 항목명 미구분 | CompanyTabIntro 22px, 내부 섹션16px, 설명12~13px |
| 개요 | 사업 개요/매출 구성 제목 중복, 카드 내부 제목이 상위보다 큼 | 중복 제거, 상위→내용 순서 |
| 재무 | 첫 차트만 카드, TTM/현금흐름은 배경에 직접 표시 | 세 차트 동일 CompanyDataCard |
| 지배구조 | 단일 숫자36px와 회사명22px가 다른 탭보다 과도 | 핵심숫자28px, 주주명16px; 5년추이 제목도 동일 위계 |
| 주주환원 | 배당 두 카드 높이 불일치, 자기주식 카드 없음 | 높이210px 통일, 자기주식도 데이터 카드 |
| 공시 | 탭 머리말과 하위 제목 중복 | 공통 머리말→분류 미리보기→공시 목록 |
| 상세 펼치기 | 색/구분선 제각각 | 기업 페이지 범위 ExpansionTileTheme 적용 |

## 확인 범위
- 실제 IAB: 동일 기업 5개 탭 모두 상단 비교. 재무 하단 TTM/현금흐름 확인.
- 390px: 5개 탭 각각 전환·스크린샷 확인. 기본 viewport 복원.
- 관련 테스트32개 통과(재무320/1280, 공시, 주주 현황/추이, 개요 business, 디자인 경계).
- 모든 기업의 실제 데이터 화면을 전수 검토한 것은 아니다. 데이터 내용·수집 범위는 이번 UI 변경 범위 밖이다.

## 화면 증거

### 개요

![개요](../outputs/company-events/hierarchy-overview.png)

### 재무

![재무](../outputs/company-events/hierarchy-financials.png)

### 지배구조

![지배구조](../outputs/company-events/hierarchy-governance.png)

### 주주환원

![주주환원](../outputs/company-events/hierarchy-returns.png)

### 공시

![공시](../outputs/company-events/hierarchy-disclosures.png)
