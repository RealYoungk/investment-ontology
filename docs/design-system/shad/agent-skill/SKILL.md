---
name: shad-adoption
description: Investment Ontology Flutter UI를 shad 0.99.4 기반으로 구현하거나 변경할 때 사용한다.
---

# 서비스 UI 구현 규칙

먼저 AGENTS.md, README.md, docs/handoff.md와 docs/design-system/shad/adoption-2026-10-03.md를 읽는다. Ant 포팅은 폐기되었다.

- shad 정확 버전을 유지하고 installed package의 공개 API를 확인한다. 비슷한 이름의 shadcn_ui API를 추측해 쓰지 않는다.
- 기본 ShadButton/Input/Select/Dialog/Sheet/Badge를 직접 사용한다. 1:1 App 래퍼, 기본 위젯의 자체 재구현을 추가하지 않는다.
- 서비스 색·글꼴은 design/shad_theme.dart, 숫자·근거·재무 차트는 서비스 디자인 토큰을 사용한다.
- nullable callback이 비활성이면 `enabled`도 명시한다. 버튼 라벨은 좁은 화면의 주어진 폭을 넘지 않도록 배치한다.
- ShadInput을 직접 사용한다. third_party/shad 0.99.4 입력 한 파일에만 접근성 패치를 유지한다. SOURCE.json과 input-accessibility.patch를 확인하고 패치를 임의로 넓히지 않는다. 첫 semantic focus에서 invalid selection을 정상화하고, top Text 라벨을 editor에 연결한다. VM composing/단축키와 Chrome 첫 한글 fill을 확인했지만 OS IME/VoiceOver를 완료라고 쓰지 않는다. 자동화 Meta+A 실패는 동일 엔진의 Material TextField에서도 재현된다.
- 아이콘 버튼에는 이름과 실제 semantic tap 동작을 제공한다. 0.99.4의 semanticLabel은 내부 동작을 ExcludeSemantics로 지우므로 call-site Semantics(container: true, label: ..., button: true, enabled: ..., onTap: enabled ? action : null) + ExcludeSemantics + 직접 ShadIconButton으로 구성한다. 복합 배지의 열기/삭제는 별도 semantics 노드로 유지한다. ShadDialog/Sheet closeIcon에도 이름과 동작을 제공한다. 입력 오류·비밀번호 표시·한글 composing·clear·autofill을 보존한다.
- Shad overlay 안에서 서비스 ThemeExtensions가 필요한 경우 call-site InheritedTheme를 전달한다. API 자체를 래핑하는 새 UI 레이어를 만들지 않는다.
- URL 필터·필수 선택·금융 데이터/원문/결측 표현만 서비스 조합으로 만든다. 데이터 의미를 UI 교체 과정에서 바꾸지 않는다.
- 서버를 시작하지 않는다. main/dependency 변경 뒤 Serverpod MCP hot_restart와 로그 확인 규칙을 따른다.
- 검증은 analyzer/format/기존 Flutter tests/web build와 실제 상호작용. 특정 widget 타입보다 사용자 label/state/navigation을 검증한다. 실패를 숨기거나 기존 계약을 이유 없이 삭제하지 않는다.
- 갤러리: examples/shad_review. 한글 IME·스크린리더·대규모 표의 미검증을 완료로 표현하지 않는다.

- AppToggleGroup의 ShadToggle은 IntrinsicWidth로 감싸 Wrap 안에서 전체 폭으로 늘어나지 않게 한다. 선택 해제 시 필수 값을 비우지 않는다.
- 중첩 Navigator 앞에 페인트한 헤더/메뉴는 BlockSemantics에 가려질 수 있다. AppShell은 route 뒤에 헤더/사이드 메뉴를 페인트하고 OrderedTraversalPolicy를 사용한다.
- 재무표 이전 조건은 financial-table-contract.md를 따른다. 임의의 원문 높이를 48px로 고정하지 않는다.

- 서비스 modal Sheet는 useRootNavigator:true를 명시해 배경 헤더/메뉴까지 제외한다. 인증은 실제 앱에서 우회하지 않는다. 실제 QA 범위는 phase2-2026-10-03.md를 확인한다.

- showAdaptiveDetail의 기존 서비스 헤더는 닫기 버튼을 직접 가진다. 기본 Sheet closeIcon은 숨겨 닫기 제어를 중복하지 않는다. 새 builder도 이름과 tap semantics가 있는 닫기 버튼을 제공한다.

## 서비스 시스템과 전면 화면 변경

- 공통 계약은 `../system.md`, 현재 개편/검증 범위는 `../reform-2026-10-03.md`를 읽는다. 색/한글·숫자 글꼴의 canonical source는 `design/shad_theme.dart`이며 brands/research_desk_brand.dart는 호환 이름만 제공한다.
- 일반 연구 블록은 DataPanel, 특수 상태/플랜은 직접 ShadCard를 조합한다. DataPanel 안에 새 카드 테두리를 수작업으로 추가하지 않는다. 행/차트 도형/상태 강조를 기계적으로 카드로 변환하지 않는다.
- AppLayout/AppSpace로 화면·패널·표 밀도를 정한다. 정보를 검색/기간/핵심 변화/비교/근거 순서로 정리하되 원본 단위와 결측 이유를 숨기지 않는다.
- 서버 DTO 없는 ResearchGraph/RelationshipDiagram 표시 모델을 사용한다. 금융 포맷·확인/추정 판정·URL은 feature 어댑터에 둔다. 기존 force_layout import는 호환 export다.
- 차트는 slider가 아니다. 기간 custom semantics actions, 좌우/Home/End/Escape와 null 단절을 유지한다. 같은 tooltip을 value와 중복 낭독하지 않는다. 실제 Chrome과 VM 검사를 구분한다.
- 서버 없는 합성 프리뷰는 lib/design_preview.dart. 모든 값은 예시이며 운영 금융 데이터 검증의 fixture로 쓰지 않는다.
- 전체 소스 참조 목록과 실제 화면 QA는 다르다. browser-coverage.json의 readiness 실패/guard redirect/실제 빈 결과를 별도로 판정한다. DTD driver가 끝없는 프레임 때문에 timeout이면 필요한 동작에서 set_frame_sync:false 후 true로 복원해 확인한다. 인증을 우회하거나 text entry emulation을 계속 켜지 않는다.
