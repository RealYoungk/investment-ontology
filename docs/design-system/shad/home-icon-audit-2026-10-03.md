# 홈 아이콘 전수 점검 — 2026-10-03

사용자 지정 별 아이콘은 Material Icons.star_outline이었다. 홈 본문과 홈에서 열리는 AppShell 드로어·검색·알림 경로를 점검해 직접 지정한 Material 아이콘 47개 참조를 LucideIcons로 교체했다. shad가 export하는 lucide_icons_flutter를 사용하며 vendor 수정은 없다.

| 영역 | 교체 |
| --- | --- |
| HomeDashboard | star, arrowUpRight, slidersHorizontal, arrowRight |
| HomePage | search, x, refreshCw, arrowRight |
| AppShell | house, chartColumn, building2, listFilter, arrowLeftRight, network, star, x, info, database, usersRound, arrowLeft, menu, circleUserRound, search |
| NotificationBell 및 알림 패널 | x, arrowLeft, settings, fileText, mail, arrowUpRight, slidersHorizontal, bell |
| 공유 경로 | JourneyButton/소개/공시 피드의 arrowRight, store, chartLine, arrowLeftRight; NavigationMenu chevronDown; ReadFailureNotice refreshCw |

브랜드 로고는 기존 이미지 자산이다. 차트 범례는 시리즈 색을 나타내는 도형이며 아이콘 교체 대상이 아니다. 크기는 기존 역할별 14–36px를 보존했다. 모든 아이콘을 한 크기로 강제하지 않는다.

점검한 home 디렉터리 전체 및 위 공통 경로에서 Material Icons 직접 참조는 0개다. 다른 페이지 전체의 아이콘 통일을 완료했다는 뜻은 아니다. shad 내부 기본 아이콘은 패키지에 맡긴다.

검증: 대상 analyzer 문제 없음, format, MCP hot restart 성공. 실제 로그아웃 홈에서 별·화살표·상단 검색·알림 렌더링 확인. 로그인 후 알림/계정 분기는 소스 확인이며 이번 브라우저에서 실계정 검증하지 않았다. 스크린샷 outputs/design/live-home-2026-10-03/lucide-icons.png.

홈·소개·내비게이션·디자인 경계 관련 테스트 25개 통과.
