# Research Desk — 투자 온톨로지

사용자가 선택한 시안 07을 기준으로 한다. 처음 온 사람은 산업이나 조건에서 시작하고, 투자자는 공시 근거까지 따라간다. 기능보다 장식이 앞서지 않는다.

## Foundation
- Source of truth: Flutter `lib/design/tokens.dart`, `brands/research_desk_brand.dart`, `app_theme.dart`.
- Canvas #F5F7FA, surface #FFFFFF, navigation/text #202831, secondary #536171, muted #607080, border #E1E6EC, action #276A9B.
- Korean market gain #B83232, loss #2463AD. Always pair color with signed values. Missing and zero are neutral.
- IBM Plex Sans KR for headings and body, IBM Plex Mono tabular figures with Korean fallback for numbers. No serif headlines or letter-spaced Korean slogans.
- Roles: page 30, section 20/600, body 14, supporting 12, metric 28/600. Intro title 28–36. Do not reduce key facts to footnotes.
- Space 4/8/12/16/24/32/48; page gutters 16 narrow / 32 wide. Radius 10, dialogs 16, fine borders 1. Shadows only for overlays.
- Functional transitions 120–200ms. No entrance animations that delay reading.

## Navigation and responsive layout
- >=1100: 204px charcoal sidebar, 64px utility header. No duplicated top navigation.
- <1100: compact header with a 288px left drawer (matching desktop menu order, active state, close button, and close-on-navigation); content uses full width. Search and account remain available.
- Detail back action in header only when router can pop. Preserve list query/filter/scroll behavior.
- Home keeps industry entry, metric conditions and company search. No invented market recommendations.
- Market shows value, equal-period returns, chart, expandable source. Company shows identity, key metrics, detail tabs.
- Chart categories are separate from gain/loss semantics. Tables stretch text columns before horizontal scrolling.

## Interaction and states
- Every actionable element needs hover, visible keyboard focus, disabled treatment. Touch actions target >=44px.
- Loading preserves layout; empty results explain how to broaden search; errors offer retry where supported.
- Missing financial metrics keep the reason; short history never implies an IPO without listing evidence.
- Tooltip/explanation is accessible by click as well as hover. Do not hide necessary data limitations in decoration.
- Theme editing and shared mutations remain admin-only. Data management stays secondary to coverage.

## Delivery / rollback
- Baseline commit fdbc93b, preserved as branch codex/pre-research-desk.
- Implementation branch codex/research-desk-design; main remains unchanged.
- Local development.yaml modification is excluded from design commits. No database migration is needed for this redesign.
- Review `/design` component gallery in debug builds and real pages at desktop and mobile widths.
