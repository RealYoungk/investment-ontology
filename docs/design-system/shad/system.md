# 알파인더 UI 시스템

기준은 shad 0.99.4 + 문서화한 input.dart 호환 패치다. Ant를 재현하는 시스템이 아니다. 기본 UI의 API와 동작은 shad에 의존하고, 금융·출처·URL·탐색의 의미만 서비스가 조합한다.

## 소유권과 파일

| 요소 | 구현 책임 / 실제 파일 |
|---|---|
| 기본 버튼·입력·선택·탭·배지·알림·메뉴·accordion·tooltip·toast·dialog·sheet | `third_party/shad/lib/src/components/`; 기본 Shad API 직접 사용 |
| 서비스 색·한글 글꼴·Shad 텍스트 역할 | `lib/design/shad_theme.dart`: serviceBrand, serviceColors, buildServiceShadTheme |
| 금융 상승/하락·계열색·숫자 글꼴·간격·모션 | `lib/design/tokens.dart`; 시세 방향색을 일반 차트 계열색으로 쓰지 않는다 |
| 화면 최대 폭·좁은 화면 여백·패널·표 밀도 | `lib/design/layout.dart`: AppLayout |
| 화면/탭/섹션 제목 | PageHeading, CompanyTabIntro, CompanySectionHeading, SectionLabel |
| 연구 블록 | DataPanel: 실제 ShadCard 사용, 같은 블록 안의 중첩 DataPanel은 박스를 만들지 않음 |
| 긴 근거와 숫자를 읽는 표 | AppDataTable: 가변 높이·숫자 우측 정렬·필요한 경우에만 가로 스크롤. `financial-table-contract.md` |
| 범주/시계열/혼합 차트 | `design/components/charts/app_charts.dart`: 축, 범례, 음수, 결측 단절, 두 축, 값 보기 |
| 면적 차트 | AppTreemap: 면적 비례, 긴 이름, 값·이름 semantics, hover/선택 |
| 자유 관계망 | ResearchGraphCanvas + ResearchGraph/Node/Edge + forceLayout: 서버 DTO 없는 표시 모델 |
| 방향성 관계 도식 | RelationshipDiagram<T>: 원본 단위·표시 문자열·확인/추정·탐색 대상은 호출자가 제공 |
| 조회 실패/수집 상태 | ReadFailureNotice, StatusDot: 실패를 빈 데이터로 표현하지 않음. 반복 상태 모션은 동작 줄이기 설정 존중 |
| URL 필터·필수 선택·탭 계약 | AppSelect/AppToggleGroup/AppTabBar: 서비스 값 연결. 기본 위젯 재구현 금지 |
| 목록 유지 → 상세 | showAdaptiveDetail: root modal, 600px 이상 오른쪽/그 이하 하단, 중복 닫기 버튼 없음 |

`brands/research_desk_brand.dart`는 이전 import용 호환 이름만 제공한다. 실제 서비스 테마는 shad_theme.dart 한 곳에서 관리한다. Material ThemeExtensions는 기존 선택 가능한 원문과 구조용 Material/Scaffold에 사용하는 interop다. 이를 이유로 별도 Material 입력·버튼을 추가하지 않는다.

## 정보 계층

화면의 목적과 첫 행동 → 기업/기간/기준을 식별하는 정보 → 핵심 값/변화 → 비교·상세 → 산식·원문 순서로 읽는다. 홈에서는 기업 검색/산업 탐색을 시장 요약과 공시보다 먼저 둔다. 정보 블록마다 제목 하나를 두고 보조 설명은 13px 역할로 읽는다. 일반 정보는 DataPanel로 묶되, 행·차트 도형·선택/오류 상태색·사업 설명 그림을 기계적으로 카드로 바꾸지 않는다.

AppLayout은 할당된 폭을 기준으로 사용한다. 기본 최대 폭은 1280, 720 미만 gutter 16/그 이상 32, 연구 패널 padding 16/24, 표 셀 세로 padding 10이다. 글이 긴 단독 문서는 readingWidth 760을 선택할 수 있다. 이 값이 모든 사업 화면에 이미 적용됐다는 뜻은 아니다. 데스크톱/모바일 기기명을 기준으로 분기하지 않는다.

## 값과 상태 계약

- 값 옆에서 연결/별도·기간·원/백만원/%/%p·관측 기준일을 확인할 수 있어야 한다. UI 코드는 금융 계산식/기준 선택을 새로 구현하지 않는다.
- 자료 없음은 `—` 및 필요한 항목·기간·사유. 0, 조회 실패, 수집 대기, 공개하지 않는 데이터와 구분한다.
- 추정은 점선/문구, 확정 관계는 원래의 근거. 신뢰도를 측정 정확성으로 바꾸지 않는다.
- 새 조회 중 이전 콘텐츠가 남으면 갱신 표시를 주고, 빈 결과로 잠깐 바꾸지 않는다. 서버 오류 원문을 고객에게 출력하지 않는다.
- 출처는 필요할 때 펼칠 수 있지만 기준일·단위·결측 사유는 핵심 정보를 읽는 위치에 둔다. 출처를 제거하거나 데이터 범위를 넓히지 않는다.
- 개인정보·변경·결제 접근 규칙은 서버와 기존 URL 정책을 따른다. UI 검증 때문에 인증을 우회하지 않는다.

## 시각화 상호작용

범주 차트는 Tab으로 focus, 좌우 방향키로 기간 이동, Home/End로 첫/마지막, Escape로 상세를 닫는다. hover와 터치 상세도 유지한다. 선택한 기간의 단위별 값과 결측 사유를 semantics value로 제공한다. 차트는 숫자 slider가 아니므로 `다음 기간`/`이전 기간` custom semantics action을 제공한다. 표로 보기와 원문은 서비스의 기존 데이터/산식 경로를 유지한다.

차트는 세로 휠을 가로 기간 이동으로 가로채지 않는다. AppDataTable은 내용 폭이 넘을 때 가로로 움직이고, 화면은 세로로 움직인다. 자유 관계망의 pan/zoom은 InteractiveViewer, 작은 화면의 관계는 서비스 목록으로 읽는다. 자유 관계망은 보통 600px 이상에서 사용한다. 관계망의 휠·핀치 경계 전체와 실제 OS 보조 기술 지원은 별도 검증 항목이며, 구현과 브라우저 부분 검증을 완료 인증으로 혼동하지 않는다.

그래프의 DTO→표시 모델 변환, tooltip 금융 포맷, 어떤 노드를 어떤 URL로 여는지는 `features/graph/graph_page.dart`, `features/governance/governance_graph.dart`가 담당한다. 디자인 영역은 서버·사업 화면을 import하지 않는다. 해당 경계는 design_boundary_test.dart로 검사한다.

## 서버 없이 검토

`investment_ontology_serverpod_flutter/lib/design_preview.dart`는 서버 client/auth 없이 동일 서비스 테마·DesignGallery를 렌더링한다. 모든 값은 합성 예시다.

```sh
cd investment_ontology_serverpod_flutter
flutter build web -t lib/design_preview.dart --output build/design-preview
```

빌드 결과는 정적 파일로 열 수 있다. 이 명령은 Serverpod 서버를 시작하지 않는다. 실행 중 실제 앱의 debug `/design`도 같은 갤러리를 사용한다. 기본 upstream 상호작용 비교 예시는 기존 `examples/shad_review`를 유지한다.

## 변경 검증

색·글꼴은 테마, 밀도·간격은 AppLayout/AppSpace, 기본 동작은 upstream에 고친다. 서비스 금융 규칙은 feature에 고친다. 새 기본 App 위젯 래퍼와 vendor fork 확장은 금지한다. 업그레이드는 adoption-2026-10-03.md의 정확 버전/패치/라이선스/회귀 비교 절차를 따른다.

변경한 계약에 맞춰 widget tests → 전체 analyzer/format/회귀 → web build → 320/390/768/1440 실제 화면과 관련 상호작용 → MCP 재시작/로그를 확인한다. 비동기 화면은 메뉴나 탭 이름의 존재만으로 로딩 완료라고 쓰지 않는다. 실제 데이터, 빈 상태, 실패 상태를 분리해서 기록한다. 검증 범위는 reform-2026-10-03.md와 outputs/design/reform의 원본 로그를 따른다.
