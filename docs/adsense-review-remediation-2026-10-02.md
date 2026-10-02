# AdSense 재심사 대응 — 2026-10-02

## 실제 계정 상태와 문제

Google 발신 이메일과 최신 Sites 화면에서 alfinder.kr은 **주의 필요 / 게시자 콘텐츠가 없는 화면에 Google 게재 광고**다. 사이트 최종 업데이트는 2026-10-02 12:11 KST, ads.txt는 승인됨이다. ads.txt 승인과 광고 게재 승인은 다르다.

운영 첫 진입 HTML은 로딩 안내이고, 앱 로딩 후 기본 접근성 문서는 `Enable accessibility` 버튼만 표시했다. robots.txt가 없어 그 주소에도 SPA HTML이 반환되었다. 광고 lead는 시장·기업 경로만 확인해 데이터 로딩·실패·빈 목록에서도 생성될 수 있었다. 이는 직접 확인한 구현 문제다. Google이 본 URL이나 판단 과정은 제공되지 않았으므로 거절의 유일한 원인이라고 단정하지 않는다.

## 공식 근거와 조치

- [게시자 콘텐츠 없는 화면 정책](https://support.google.com/publisherpolicies/answer/11112688?hl=en): 빈 화면, 준비 중, 오류·행동 목적 화면에 광고를 두지 않는다.
- [사이트 준비 불가 대응](https://support.google.com/adsense/answer/12176698?hl=en): 공개 접근, 크롤러 접근, 콘텐츠 가치와 탐색 경험을 점검하고 수정 후 재검토한다.
- [Google JavaScript 처리](https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics): 초기 HTML과 렌더링 DOM을 구분한다. Search 문서가 AdSense 심사 알고리즘을 입증하는 것은 아니다.
- [Flutter 3.47 웹 접근성](https://docs.flutter.dev/ui/accessibility/web-accessibility): `SemanticsBinding.instance.ensureSemantics()`로 실제 화면 텍스트·의미를 HTML DOM에 노출한다.

Cloudflare `/`와 `/index.html`은 JavaScript·로그인·API 없이 읽는 실제 HTML 리서치 안내를 제공한다. 모든 방문자에게 같은 본문을 제공하며 기존 `/home`·`/market`·`/companies`·상세 앱 경로는 유지한다. 공시 기준 맞추기, TTM·PER·PBR 입력, 사업 지표 근거 읽기 자료를 제공하고 실제 앱·DART 원문으로 연결한다. 설명용 숫자는 가상 예시이며 앱 계산식과 대조했다. 특정 기업의 AI 요약·수동 데이터 입력을 재개하지 않는다.

웹 접근성을 기본 활성화한다. 시장은 조회 완료·오류 없음·상장사 수 양수, 기업 목록은 조회 완료·오류 없음·현재 목록 비어 있지 않음일 때만 광고 lead를 마운트한다. 갱신·후속 오류는 lead를 제거해 플랫폼을 dispose한다. 기존 동의·회원·승인 게이트도 유지한다. 실제 robots.txt·sitemap.xml을 제공하고 앱 서비스 링크에 읽기 자료를 연결한다. 읽기 자료·로그인·결제·오류·소개에 광고를 추가하지 않는다.

## 검증·재심사 구분

집중 테스트: 로딩(이전 데이터 유무), 오류(이전 데이터 유무), 빈 목록에서 AdBanner 자체가 마운트되지 않음, 성공 후 후속 차단 시 제거. Worker는 공개 진입과 기존 상세 경로 분리를 확인한다. HTML 테스트는 article 본문, 내부 링크, JS·광고 없음과 robots/sitemap을 검사한다. 전체 릴리스·실제 브라우저·운영 체크섬·재심사 제출은 완료 후 별도 증거로 기록한다.

모의 테스트는 실제 Google 광고 송출 검증이 아니며 재심사 요청 완료도 승인이 아니다. 실제 EU CMP와 승인된 광고 송출은 미검증이다. ADSENSE_ENABLED·SITE_APPROVED·PRIVACY_READY 및 운영 결제 플래그는 이번 수정으로 켜지 않는다.

## 승인 이후·롤백

실제 Sites가 준비됨인지 확인한 후 공식 태그로 지역별 허용·거부·철회를 검증한다. 유료·회원 조회 중·오류·빈 본문에서 불필요한 광고 요청이 없어야 한다. 실제 Google 요청과 모의 fixture 결과를 구분한다. 검증 후 `monetization-operations.md`와 `monetization-preapproval-verification.md`의 활성화 절차를 따른다. PG 승인·운영 키·고지 확인 전 결제를 켜지 않는다.

콘텐츠·동의 장애 시 광고 플래그 false로 빌드·배포한다. 이번 Worker/웹 변경은 이전 Pages 배포로 롤백 가능하다. DB 스키마·결제 원장·운영 키 변경이 없다. 공개 진입 롤백은 기존 Flutter 홈 진입으로 복귀한다. 과거 Vercel 배포는 보존하며 이번 공개 진입 변경은 Cloudflare를 대상으로 한다.
