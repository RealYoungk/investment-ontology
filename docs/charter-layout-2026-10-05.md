# 정관 변경 카드 레이아웃 정리 (2026-10-05)

- 각 변경 항목의 별도 Divider와 ShadAccordion 기본 separator를 제거했다. 변경 목록과 추가 원문은 여백으로 구분한다.
- 변경 전·개정안의 배경 박스를 없애고 동일한 비교 열에 작은 레이블과 본문을 배치했다. 600px 미만에서는 세로로 표시한다.
- 원문 펼침, 회사 설명, 소집공고 개정안과 변경 이력의 구분, 출처 링크는 유지했다.
- 좁은 화면의 긴 출처 링크는 가용 폭 안에서 줄바꿈한다.

검증: 관련 위젯 및 디자인 경계 테스트 7개 통과. 320/1045px에서 원문 펼침·접기 및 overflow를 확인했다. 정적 분석 통과, release 웹 빌드 33.3초 완료. 로컬 아크릴 지배구조에서 비교 원문을 펼친 화면을 브라우저로 확인했다. 스크린샷: outputs/design/charter-layout-2026-10-05/charter.jpg.

개발 Flutter의 기존 app_auth.dart incremental compiler summary 오류가 MCP 재시작 후에도 남아 있어 새 release 산출물을 승인된 로컬 origin 8110에서 확인한다. 운영 배포는 하지 않았다.

## 가독성 재조정

사용자 피드백: 구분을 모두 없애니 항목 경계가 흐려졌다. 항목 사이에 얇은 border 한 개를 적용하고, 주제 ShadBadge.secondary, 18px 제목, 개정안 요약 강조를 사용했다. 펼친 긴 비교 원문만 하나의 공통 배경에 넣어 요약과 구분한다. 아코디언 자체 separator는 계속 제거한다.

정적 분석 및 동일 테스트 7개 통과, release 웹 빌드 52.5초 완료. 실제 아크릴 원문 펼침 화면 확인: outputs/design/charter-layout-2026-10-05/balanced.jpg. MCP hot_restart는 연결 종료 오류를 반환했으므로 개발 앱 재시작 성공은 확인되지 않았다. 운영 배포는 하지 않았다.

## 간격 재조정

항목 상하 24px, 제목-비교 16px, 비교 열 사이 24px, 원문 내부 padding 16px. 의미와 비교 본문 14px/행간1.6. 펼침 header 상하8px, 변경 이력 section 앞24px 및 각 이력 header 상하8px. 출처 링크 왼쪽 정렬. 320/1045 테스트 포함7개, 분석, release 빌드46.5초 통과. MCP hot_reload 성공 및 최근 로그 정상. 브라우저에서 실제 원문 펼침/접기 확인. spacing.jpg 및 spacing-expanded.jpg 참조. 운영 배포 전.
