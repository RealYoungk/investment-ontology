# shad 도입 기술 검토

검토일: 2026-10-03. 결론: **대표 흐름의 도입 실험을 권장한다. 전체 앱 전환 승인은 아직 아니다.** Ant 전체 재구현보다 유지보수 부담을 줄일 유력한 대안이다. 다만 shad를 Ant 재현 엔진으로 쓰는 것은 추천하지 않는다. 채택 시 디자인 기준을 shadcn 계열과 우리 서비스 토큰으로 바꾸는 별도 결정이 필요하다.

## 기준과 확보한 근거

- 패키지: `shad 0.99.4` 정확 버전, 제작/유지보수: Serverpod. 원작은 Alexandru Mariuti의 flutter-shadcn-ui.
- 검토 저장소: https://github.com/serverpod/shad
- commit: `8ea5a35bcdd350077cf5217964ede1ec4afd4d61`, 2026-08-18, `fix: Stability fixes.`
- pub.dev의 0.99.4를 실제 pub cache에 내려받아 저장소의 Dart 소스 300개와 바이트 비교: 차이 0. 단순히 main의 버전 문자열만 믿지 않았다.
- 주요 파일 SHA256: `outputs/design/shad-review/source-lock.json`.
- SDK 조건: Dart >=3.11.0 <4.0.0, Flutter >=3.41.0. 우리 앱은 Dart ^3.13.4 / Flutter ^3.47.5.
- MIT: 2023 Alexandru Mariuti 및 2026 The Serverpod authors 고지 보존 필요. 소스 복사/포크 시 LICENSE를 배포물에 포함. 번들 폰트·아이콘의 별도 라이선스 고지는 배포 전에 추가 감사한다.
- 조사 범위: app/theme 연결부, Input, DataTable/Table, Dialog/Sheet, gesture detector, 한국어 locale, 관련 테스트와 CI, 테마/표/시트/타이포그래피 가이드. 전체 57개 컴포넌트 소스 파일의 모든 API를 감사한 것은 아니다.

## 현재 프로젝트와의 연결

현재 앱은 `MaterialApp.router` + go_router, 자체 `lib/design`의 의미 토큰·브랜드·공통 컴포넌트 구조다. 기존 AppDataTable은 내용 기반 폭/자동 가로 스크롤이며, adaptive detail은 화면 폭에 따라 Dialog/BottomSheet를 쓴다. 기능 파일과 업무 데이터, Serverpod 인증/조회 경계는 UI 패키지 교체와 별개다.

권장 구조:

```
화면 / 조회 상태 / URL 필터 / 회사 선택
                  ↓
lib/design 의 AppButton / AppInput / AppCompanyTable / AppDetail / AppCompare
                  ↓
ShadThemeData + shad 0.99.4
```

화면에 ShadDataTableController 등을 광범위하게 노출하지 않는다. 스타일은 design 내부에서만 정의하고, 서비스의 의미 색·차트 색·한국어 폰트를 한 어댑터로 연결한다. AppColors와 Shad 색을 서로 독립적으로 수정해 두 테마가 어긋나지 않게 한다. 현재 Material 인증 UI와 router는 `ShadApp.custom`/builder 연결로 점진 전환을 검토한다. 중첩 Navigator를 무심코 추가하지 않는다. overlay의 root/local Navigator 선택도 명시한다.

**Ant와 shad의 위젯을 한 화면에서 혼합하거나, Ant 토큰 전체를 shad 테마에 억지로 대응시키지 않는다.** 기존 Ant 코드·원본·부분 진행표는 보존한다. 이번 검토는 기존 포팅 완료 선언이나 삭제/방향 변경 승인이 아니다.

## 기능별 평가

| 영역 | 확인한 구현 | 우리 쪽 보완 / 판단 |
|---|---|---|
| 테마 | ShadThemeData, 색·폰트·컴포넌트 override, 스타일 preset, dark/light | 한국어 폰트와 숫자·차트 의미 토큰 연결. 기본 Geist가 한글 폰트 품질을 보장하지 않는다 |
| 표 | ShadDataTableController의 로컬 정렬·필터·페이지·키 선택, TableView 기반 lazy cell 생성, 헤더 고정 | 전체 서버 데이터의 원격 정렬/페이지는 앱 조회 상태가 소유. 가상 렌더링이 로컬 필터/정렬 계산 비용까지 제거하지는 않는다 |
| 열/스크롤 | ShadTable은 고정 행/열 및 2축 스크롤 API 제공, DataTable은 기본 헤더 1행 고정 | DataTable API가 하위 Table의 모든 옵션을 노출하지 않는다. 큰 재무표는 별도 AppTable을 ShadTable로 구성할 수 있다. bounded height 필요 |
| 정렬 접근성 | 기본 DataTable 헤더는 ShadGestureDetector.onTap | Tab/Enter 정렬 안 되는 것을 재현. header가 문자열 API라 외부 정렬 버튼 또는 ShadTable 기반 헤더, 최소 수정 upstream/포크 중 선택 필요 |
| 행 상세 | onRowTap 제공 | 클릭 가능한 회사명 버튼을 셀에 제공해 키보드 진입을 보장. row 클릭과 체크박스 이벤트 중첩을 브라우저에서 검증 |
| 선택 | stable key 기반, 정렬 후 선택 유지 | corpCode 사용. 데이터 갱신으로 사라진 key와 필터 밖 선택을 비교 정책에 맞게 정리해야 함 |
| 상세 시트 | 4방향, modal route, expandable sheet | 목록 mounted/scroll 보존과 Escape 후 opener focus 복귀 테스트 통과. 기본 모달은 배경 목록 조작을 막으므로 비모달 상세 요구는 별도 설계 |
| 비교 모달 | showShadDialog + 커스텀 content | Escape 닫기 통과. 다수 기업 비교의 좁은 화면, 긴 표/스크롤 소유권은 추가 검증 |
| 입력 | EditableText, controller/focus, formatter, selection toolbar | 조합 상태의 rebuild 유지 테스트 통과. 실제 macOS/Windows 한글 IME·검색 debounce/Enter는 미검증 |
| 한국어 | ko.i18n.yaml과 생성 locale, async delegate | 일부 기본 표 문구는 영어 literal. showSelectionCount=false + 앱 문구, paginationBuilder로 보완. ko 파일 존재가 모든 UI 번역을 뜻하지 않음 |
| 접근성 | button/roving focus/ModalRoute/일부 Semantics | 스크린리더 전체 표 구조·정렬 상태·제목/장벽 label·포커스 trap은 별도 gate. 테스트 수로 접근성 인증하지 않음 |
| 사업 전용 UI | 표·폼·레이아웃 기반 제공 | 차트, treemap, 관계망, 금융 수식/근거 표시 등은 기존 독립 구현 유지 |

## Material 독립성의 실제 범위

README의 “no dependency on Material or Cupertino”는 패키지 전체에 대한 엄밀한 설명이 아니다. `lib/src/app.dart`는 material.dart와 cupertino.dart를 import하고, `theme_scope.dart`는 Material ThemeData/Theme를 사용한다. CI import 금지 검사도 이 두 파일을 예외로 둔다. 주요 컴포넌트는 widgets 기반이지만, 앱/테마/일부 플랫폼 스크롤 연결은 Material·Cupertino에 의존한다.

현재 우리 앱도 Material 기반이므로 이것 자체는 도입 차단 사유가 아니다. 다만 “완전히 디자인 라이브러리와 독립된 코어”가 필수라면 별도 어댑터/분리가 필요하다. Flutter의 material_ui 분리와 shad의 내부 legacy import 이동은 다른 일이며 자동으로 완료됐다고 간주하지 않는다.

## 의존성과 운영 부담

직접 런타임 의존성 15개(SDK 두 항목 포함): boxy, collection, flutter, flutter_animate, flutter_localizations, flutter_svg, intl, lucide_icons_flutter, slang, slang_flutter, theme_extensions_builder_annotation, two_dimensional_scrollables, universal_image, vector_graphics, web.

범위가 넓은 의존성 제약을 쓰므로 직접 버전 고정만으로 재현되지 않는다. pubspec.lock도 유지해야 한다. 테마 생성 코드를 단순 override할 때 build_runner를 앱에 추가할 필요는 없다. 포크로 생성 선언을 바꿀 때만 upstream 생성 절차를 따른다.

0.99.x이며 호환성/안정성을 장기 보장한다고 보기 어렵다. 0.99.4 changelog에는 Select auto-scroll의 event-loop 정지, toast AnimationController/타이머 누수, OTP registry, portal callback 폭증, web selection context-menu 충돌 수정이 있다. 수정 사실은 긍정적이지만 우리 플로우의 스트레스 검증을 대체하지 않는다. 처음에는 pub 패키지 정확 버전 + 얇은 App wrapper를 사용하고, 구체적으로 수정이 필요한 API만 최소 포크한다. 전부 복사하면 upstream 안정성 수정을 다시 직접 관리하게 된다.

## 실제 실행한 검증과 한계

1. upstream 대표 6개 테스트 파일군(data_table/dialog/sheet/input/select/roving_focus): **119개 통과**, Flutter VM. upstream golden은 패키지 자체 baseline이며 React 원본과 동일함을 증명하지 않는다.
2. published 0.99.4 별도 테스트 하네스: **4개 통과**, analyze 이상 없음. 한글 조합 상태 유지, 기본 헤더 키보드 정렬 부재 재현(회귀를 기록하는 characterization test), 상세 시트의 목록 scroll/focus 복원, 비교 모달 Escape.
3. 테스트 환경: 기존 설치 Flutter 3.47.5 사용. 서버 시작·운영 적용·앱 의존성 변경 없음.
   현재 Flutter 앱과 생성 client의 pubspec을 `/tmp/shad-app-solver-20261003`에 복사하고 workspace 지시문만 제거한 뒤 `shad: 0.99.4`를 추가해 의존성 resolve 성공. 기존 앱 lock을 유지한 upgrade 결과나 전체 workspace/앱 통합 빌드의 성공을 뜻하지 않는다. 로그는 `app-solver.log`, 해소된 버전은 `app-solver.lock`.
4. 실제 OS IME, 브라우저 touch/wheel/trackpad, screen reader, Flutter Web 번들 크기·로드 시간, 2,759행 데이터 처리 성능, 원본 shadcn과 픽셀/모션 대조, 전체 앱 통합 빌드는 **미검증**.

하네스: `examples/shad_review` (`shad: 0.99.4`, 독립 lock). 실행: 해당 디렉터리에서 `flutter pub get --enforce-lockfile`, `dart analyze`, `flutter test`.
로그: `outputs/design/shad-review/`. 검토 소스는 임시 `/tmp/investment-shad-review-20261003`, 재현 기준은 commit와 pub lock이다.

## 다음 도입 gate

첫 실험은 업무 API 없이 합성 데이터로 목록→오른쪽 상세 시트→선택 기업 비교 모달을 구성한다. 원본 Ant의 외형 동일성을 gate로 삼지 않고, 사용자가 원하는 깔끔한 배치와 정확한 상호작용을 gate로 삼는다. 바깥 카드와 흰 박스 중첩은 추가하지 않는다.

- 1440/1024/768/390px, light/dark, 실제 한국어 폰트/100–200% text scale에서 overflow·정렬·focus ring 확인.
- 한글 조합 중 검색·Enter·clear·drawer 열기, IME 확정 전 premature submit 방지.
- Tab/Shift+Tab/Enter/Space/Escape, 모달 내 focus 순환과 opener 복귀, 스크린리더 표 헤더/정렬 상태 확인.
- 표/페이지/시트/비교 모달 wheel·trackpad·touch의 스크롤 소유권과 edge behavior 확인.
- 2,759/10,000 합성 행의 filter/sort/build/frame/메모리 측정. 이 숫자는 금융 데이터 정답 fixture가 아니다.
- 새로고침/페이지 이동/필터 변경/실패 복구/선택 기업 삭제 때 key와 URL 상태가 일관되는지 확인.
- 실제 앱의 전체 의존성 resolve·통합 빌드, 인증 UI와 Overlay/theme 충돌 및 번들/폰트 라이선스 감사.

이 gate를 통과하면 AppButton/Input/Detail/Compare부터 적용하고 표는 단순 목록과 복합 재무표를 구분해 적용한다. 자동 upstream 추종 대신 버전 diff·changelog·위 gate 재검증으로 업그레이드한다.

## 공식 자료

- https://pub.dev/packages/shad/versions/0.99.4
- https://github.com/serverpod/shad/tree/8ea5a35bcdd350077cf5217964ede1ec4afd4d61
- https://shad.serverpod.dev/
