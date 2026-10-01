# 광고·월 2,900원 광고 제거: 승인 전 검증

검증일: 2026-10-01 KST. PR #87 당시 웹 c1b7034는 후속 배포 7d6d236으로 대체되었다. 이번 후속 변경은 main 789fbe5와 운영 백엔드 4fd01b3의 기능을 포함하며 프런트·백엔드를 모두 변경한다. 아래 기존 수치는 당시 증거이고 후속 결과는 마지막 절에서 구분한다. 기본 체크아웃의 다른 작업과 기존 광고 워크트리는 수정하지 않았다.

## 완료 범위와 증거

| 검증 | 결과 | 실제/모의 구분 |
|---|---|---|
| 동의 전·거절·동의 bridge 누락 | Google CMP/AdSense script 0, 광고 push 0 | Node 및 실제 브라우저, Google 전송 모의 |
| 허용 + Google CMP300/목적1/vendor755 동의 | CMP script 1, AdSense script 1, push 1 | 운영 JS/브라우저 DOM, Google 응답 모의 |
| CMP 누락·지연·오류·지역 불명·타 CMP·vendor 미동의 | AdSense script 0, 광고 push 0, 늦은 콜백도 0 | Node + 브라우저 모의 |
| 철회·다른 탭 철회·동의창 재표시·승인 후 오류 | 기존 DOM 제거, 추가 push 0 | Node, 브라우저 모의 |
| 회원 복원·초기 조회 중/실패 | 광고 위젯 미생성, bridge 호출 안 함 | Flutter widget 회귀 |
| 후속 무료회원 조회 실패 | 광고 차단 상태로 전환; 성공 회복 후 허용 | MembershipMonitor 회귀, 이번 수정 |
| 유료·갱신 해지·만료·환불·카드 변경·재가입 | paid period 해지 후 유지, 만료/환불 제거 | 실제 Chrome + 인증 RPC + 격리 PostgreSQL, PG 모의 |
| 로그인/로그아웃·계정 전환·늦은 응답 | 다른 계정의 결제 state 사용 불가, 오래된 결과 폐기 | Chrome/RPC/DB 및 Flutter 회귀 |
| 중복 콜백·동시 갱신·결과 불명·전액 환불·탈퇴 | 한 주문/멱등키, 동일 주문 조회, 확인 전 성공 처리 안 함 | 서버 집중 70개, HTTP 공급자 모의 |
| 테스트/실 키 및 enable 조건 | production sandbox 플래그 차단, live 전제 모두 필수 | 단위 검증 및 코드 검토 |
| 운영 기업 목록 새로고침 | 관찰 구간 Google/Toss 외부 요청 0 | 운영 브라우저 CDP |

집중 검증: JS 27개, 서버 70개, Flutter 23개, Chrome 결제 E2E 1개 통과. 실제 브라우저 광고 harness `tool/ad-consent-check/`는 11/11 통과했다. script 수는 harness가 포착한 **삽입 시도**이며 Google 네트워크 성공 횟수가 아니다. 유료 전환 전 이미 시작한 script 요청은 되돌릴 수 없지만, 전환 후 slot push는 막는다. 실제 browser 결제 E2E의 광고는 preview 위젯이며 실제 Google 광고가 아니다. Google loader DOM/요청 시도는 별도 harness에서 검증했다.

매분 정상 상태 확인은 마지막 성공한 상태를 유지한다(정상 polling마다 광고를 새로 만들지 않음). 계정 변경/복원은 즉시 미확정, 실패는 광고 차단으로 바뀐다. 만료 타이머는 권한을 제거하고 재조회가 실패하면 광고 차단을 유지한다. 새로운 유료 상태/환불은 성공한 서버 상태 응답에 반영되며 실시간 webhook push 기능은 없다.

재현:

```sh
node --test investment_ontology_serverpod_flutter/test/web/*_test.cjs
bash scripts/test-server.sh test/unit/billing test/integration/billing_checkout_test.dart test/integration/billing_renewal_test.dart test/integration/membership_ledger_test.dart test/unit/generated_code_test.dart
(cd investment_ontology_serverpod_flutter && flutter test test/ad_monetization_test.dart test/membership_monitor_test.dart test/billing_checkout_page_test.dart test/design_boundary_test.dart)
bash scripts/test-billing-browser.sh
python3 -m http.server 9210 --bind 127.0.0.1
# /tool/ad-consent-check/ → 전체 검증 실행 (출시 번들 밖)
```

## 남은 외부 검증

실제 Toss 테스트 승인·조회·전액 취소는 기존 기록의 완료 증거이며 이번 실행에서 다시 실거래하지 않았다. 계약 대상 상점 승인/운영키 연결/실거래는 확인하지 않았다. 개발자 테스트 상점과 계약 상점을 구분한다.

Google 인증 CMP 지역별 허용/거부/철회의 실제 동작은 운영 활성화 전 필수다. 모의 __tcfapi는 Google runtime을 검증하지 않는다. 승인 상태는 이전 확인의 준비중이며 이번 문서가 준비됨을 선언하지 않는다. 운영 빌드의 광고 플래그가 false라 일반 방문 및 debug query만으로 Google CMP가 로드되지 않는다. 실제 Google 테스트 결과는 별도 항목에 기록하고, 없는 결과를 모의 통과로 채우지 않는다.

## 광고 활성화 순서 / 중단

1. AdSense Sites에서 alfinder.kr 준비됨, 수동 단위 3239020318, ads.txt 승인, 지급 설정과 Auto Ads OFF를 증거로 기록한다. Google 계정 메시지 게시와 첫 화면 거부 버튼을 확인한다. 판매자·쿠키/국외 처리 고지와 실제 지역 CMP 검증을 완료한다.
2. 모든 광고 플래그 OFF 상태를 기본으로 유지한다. 승인 후 별도 PR에서 `deploy/web-build-defines.json`의 ENABLED/SITE_APPROVED/PRIVACY_READY를 모두 true, TEST_MODE=true로 만들고 동일 clean release 검증을 통과한다. ID는 기존 공개값 유지. 외부 승인 플래그는 검증 증거 없이 true로 만들지 않는다.
3. 검증된 artifact를 Cloudflare 미리보기/운영에 배포. 한국 정상 방문과 `?fc=alwaysshow&fctype=gdpr`, 적용 지역별 새 쿠키 세션에서 자체 미선택/거절 0 script, 허용 후 CMP 거절 0 inventory, CMP 허용 1 test push, 철회 제거/추가 0, 유료/초기 조회중/실패 0 request를 브라우저 Network로 확인한다. CMP가 지역을 판정하지 못하면 광고 차단이 정상이다. 단순 배너 숨김만으로 통과시키지 않는다.
4. test inventory 확인 후 별도 검증 릴리스에서 TEST_MODE=false. 광고 클릭으로 테스트하지 않는다. 고정/overlay/자동 새로고침/Auto Ads를 추가하지 않는다.
5. 장애 시 ENABLED=false인 검증 릴리스 배포 또는 Cloudflare의 이전 비활성 deployment를 rollback. 열린 구버전 탭은 이미 로드된 JS가 남으므로 새로고침 필요. 철회 이전 요청을 네트워크에서 취소했다고 주장하지 않는다. 기존 Vercel 배포는 보존한다.

## 결제 활성화 순서 / 중단

1. PG 자동결제 계약 승인, 계약상점 test/live 키 구분, 판매자 연락처/신고 적용 여부, 개인정보 위탁/국외 처리, 최종 약관 버전, 문의 전액 환불 운영, 암호화 키 복구 사본과 거래기록 보존/파기 책임을 확정한다. 미확정 고지를 완료 처리하지 않는다.
2. 상점 test 키로 최초 승인/GET/취소, 카드 변경 추가청구0, 월말/윤년 갱신, 해지 후 재청구0, 재개, 재가입, 중복 callback/동시 갱신, timeout/동일 주문 대사, 두 계정 격리를 반복한다. 실물 카드 등록은 사람이 수행한다. 원장 모델/마이그레이션 및 FutureCall 등록 확인.
3. 서버 전용 production 환경에 LIVE_ENABLED/PG_BILLING_APPROVED/BILLING_PRIVACY_READY=true와 비어 있지 않은 TERMS_VERSION을 설정한다. live_sk_/live_ck_와 base64 32바이트 암호화 키를 서버 비밀 설정에만 둔다. sandbox flag로 production이 열리지 않는다. 암호화키를 임의 교체하지 않는다. 가격 KRW2900은 서버 상수이다.
4. 정상 인증 계정 status paymentAvailable을 확인하고 승인된 운영 검증 거래의 주문/금액/통화/고객/승인 및 취소잔액0을 확인한다. callback URL 방문만으로 권한을 발급하지 않는다. 관리자 환불은 Scope.admin 필수다. 인증/권한을 임시 우회하지 않는다.
5. webhook 수신 구현은 없다. webhook payload가 권한을 주지 않으며 중복 webhook 처리 통과라고 주장하지 않는다. 현재 유료기간의 공급자 직접 전액 취소는 5분 worker의 GET 대사로 자동 반영한다(갱신 해지 회원 포함). 만료된 과거 회차는 관리자 대사로 처리하고 5분 worker의 unknown/refund/key cleanup와 1분 계정 조회를 모니터한다. 향후 webhook은 별도 인증·재조회·멱등성 검증 없이는 추가하지 않는다.
6. 장애 시 판매 차단과 기존 주문의 조회/환불을 분리한다. `ALFINDER_BILLING_CHARGES_PAUSED=true`는 checkout/paymentAvailable 및 신규·갱신 청구를 중단하지만 동일 주문 GET/대기 환불/키 삭제는 계속한다. LIVE_ENABLED=false는 provider worker 전체를 중단하므로 기존 거래 처리용 중단 설정과 혼동하지 않는다. 무작정 플래그를 끄고 환불이 자동 완료된다고 안내하지 않는다. 배포 rollback은 호환되는 image로만, 원장 DB 삭제/reset은 하지 않는다. 암호화 키와 기존 멱등키를 보존한다.

공식 CMP 원문: https://developers.google.com/funding-choices/fc-api-docs (built-in/Exa에서 같은 원문 확인). API_READY는 API 호출 가능, DATA_READY는 동의 데이터 준비를 의미한다. 공개 사이트의 published message와 debug query를 함께 검사한다.

## 실제 Google CMP 전용 진단 (추가)

운영 /cookies.html?fc=alwaysshow&fctype=gdpr의 임시 탭에 Funding Choices 메시지 전용 tag를 로드했다(광고 태그/ins/push 없음). Google /i HTTP200, 메시지 데이터 /f HTTP200, __tcfapi callback success=true, cmpId300, cmpStatus loaded, gdprApplies=false, **eventStatus 없음**을 실제로 관찰했다. Google은 이 세션을 GDPR 비적용으로 판정했다. 이것은 EU 허용/거부/철회나 AdSense 승인 증거가 아니다. 메시지/철회 API는 표시되지 않아 EU debug UI는 이 tag만으로 검증하지 못했다. 이 결과만으로 승인이 메시지 표시의 선행 조건이라고 결론 내리지 않는다. 후속 진단은 마지막 절을 따른다.

이 실제 callback은 기존 loader의 eventStatus 필터에서 무기한 대기 후 차단될 수 있었다. 당시에는 명시적 GDPR 비적용만으로 허용했다. 후속 변경은 미국 상태까지 확인하며, GDPR 비적용 자체는 광고 허용 증거가 아니다. 지역 불명, 오류, GDPR 적용 상태는 여전히 최종 이벤트와 동의가 필요하다. 임시 진단은 탭 폐쇄로 제거하며 운영 파일/광고 플래그는 변경하지 않았다. Google event URL의 opaque 식별자는 증거/로그에 저장하지 않는다.

## AdSense 태그 자체 요청 발견과 로딩 순서 수정

Auto Ads OFF를 관리 화면에서 현재 확인한 뒤 별도 임시 진단 탭에서 AdSense tag만 로드했다. 애플리케이션의 ins 생성/push가 없어도 Google tag는 숨김 0×0 ins/iframe과 `/pagead/ads` 요청을 자체 생성했다. 노출된 배너는 없었고 탭을 즉시 닫았다. 따라서 **push=0은 Google 광고 요청=0을 증명하지 않는다**. 이 진단은 운영 플래그를 활성화하지 않았지만 실제 tag 네트워크 요청은 발생한 것으로 명확히 기록한다.

최종 구현은 자체 opt-in → Google Funding Choices **메시지 전용** `/i/pub-…?ers=1` → CMP 명시 허용 → AdSense tag → 수동 slot 순서다. CMP 거절/불명/오류/지연/누락에서는 AdSense tag 자체를 로드하지 않는다. 메시지 전용 tag의 실제 응답과 TCF API는 앞선 진단에서 확인했다. 기존 'AdSense tag가 CMP를 로드한 뒤 push만 차단' 설명은 역사적 구현이며 이 순서로 대체된다. 공급자 message-only tag의 EU/US 실제 지역별 동작이 확인되기 전 privacy-ready는 계속 false다. Auto Ads OFF라도 AdSense tag가 만드는 내부 요청을 수동 광고 slot 요청과 구분해 Network에서 측정한다. 최종 Node/browser harness는 CMP script와 AdSense script 삽입을 각각 센다.

## 실제 Flutter Web 렌더러 회원 전환 검증 (최종)

추가 harness `scripts/start-ad-membership-browser.sh`는 widget-test가 아니라 일반 Flutter Web renderer로 앱을 빌드해 localhost9211에서 연다. 운영 `AdBanner`/`AdPlatform`/`ad_loader.js`/`MembershipMonitor`, 실제 인증 RPC와 격리 PostgreSQL을 연결한다. `test/web/ad_browser_transport_fixture.js`가 Google script 전송을 가로채 모의 CMP/채움으로 처리한다. PG는 기존 fixture의 모의 응답이다. 이 fixture는 출시 web assets에 포함되지 않는다.

실제 DOM에서 9/9 통과: 무료 push1 → 조회실패 push1/DOM없음 → 조회성공복원 push2 → 유료 push2/DOM없음 → 유료기간 갱신해지 push2/DOM없음 → 만료 push3 → 갱신유료 push3/DOM없음 → 전액환불 push4 → 로그아웃 push5. AdSense script 삽입은 전체1회로, 정상 polling이나 유료 전환이 새 script 요청을 만들지 않는다. 광고 복원은 조회실패 회복/만료/환불/로그아웃 같은 상태 전환이며 자동 광고 새로고침 기능이 아니다.

처음 추가한 widget-test의 실광고 DOM 검증은 platform DOM이 연결되지 않아 실패했다. 그 실험을 성공으로 기록하지 않고 원래 preview 기반 Chrome 결제 E2E를 유지한 뒤 일반 renderer의 별도 harness로 이 경계를 검증했다. 이 두 검증과 실제 Google 공급자 진단을 구분한다. 위 preview-only 한계는 이 추가 harness가 보완하며, 실제 Google inventory 성공/운영 PG 거래를 대신하지 않는다.

재현: `bash scripts/start-ad-membership-browser.sh` 실행 → http://127.0.0.1:9211/ 열기 → `#ad-membership-result` JSON의 passed9/total9 확인 → 실행 종료. 임시 인증 파일/산출물은 종료 시 삭제된다. 다른 서버·DB·운영 키를 사용하지 않는다.

## 후속 보완과 검증 (2026-10-01)

- Google 계정에서 기존 EU 메시지 게시와 첫 화면 거절 선택을 확인했다. 없었던 미국 메시지 `Alfinder US opt-out`을 alfinder.kr에만 만들고 기존 브랜드 로고를 등록하여 **게시됨**을 확인했다. Google 화면은 전파에 최대 1시간이 걸릴 수 있다고 안내한다. Auto Ads/사이트 승인/실광고 플래그를 변경하지 않았다.
- GDPR 비적용이어도 미국 초기 상태 UNKNOWN/OPTED_OUT, GPC, GPP 누락이면 AdSense tag를 로드하지 않는다. DOES_NOT_APPLY만 직접 허용하며 NOT_OPTED_OUT은 GPP loaded/ready를 추가 확인한다. 이후 sectionChange/화면 재표시/신호·CMP 오류는 기존 slot과 진행 중 push를 무효화한다.
- JavaScript 30개 통과. 실제 브라우저 DOM/운영 loader 모의 공급자 harness는 미국 불명·거부·GPC·GPP 누락·허용·철회를 추가하여 **17/17** 통과했다. 일반 Flutter Web + 인증 RPC + 격리 DB 회원 전환은 **9/9** 통과했다. Google/Toss 전송 응답 모의라는 한계는 그대로다.
- 집중 서버 검증은 **75개** 통과했다. 공급자 직접 전액 취소를 현재 paid 기간의 동일 주문 GET으로 확인하고, 금액/통화/주문/결제 식별자/잔액0 검증 후 원장·권한·키 삭제를 반영한다. 중복 조회, 갱신 해지 상태, 조회 오류/다른 paymentKey, 만료된 기간 제외와 청구 중단 중 GET-only 복구를 검증했다. raw webhook이 권한을 주는 경로는 없다. 현재 paid 대사는 구독당 최대 월 회차 수만큼 5분마다 GET하며 가입자 증가 시 호출량을 점검한다.
- 신규 중단 설정 `ALFINDER_BILLING_CHARGES_PAUSED=true`는 과거 주문 처리와 판매 중단을 분리한다. 실판매 전 이 설정으로 paymentAvailable=false/신규 POST0/갱신 POST0/기존 GET 및 환불 가능을 상점 테스트 환경에서 확인한다. 기존 활성화 조건을 우회하지 않으며 운영 활성화 플래그는 계속 false다.

### 실제 Google 진단의 범위와 미완료

운영 origin의 임시 /cookies?fc=alwaysshow&fctype=gdpr 탭에서 debug query를 메시지 tag에도 전달했다. 실제 Google CMP300/loaded/gdprApplies=true를 받았지만 eventStatus·목적/vendor 선택과 UI가 없었다. 따라서 EU 허용·거절·철회를 완료로 기록하지 않는다. Google 공식 문서는 AdSense/Publisher tag가 메시지를 게시하고, Privacy & messaging 전용 tag는 광고 차단 회복 메시지용이라고 구분한다. 기존 `/i/…?ers=1`의 TCF API 응답만으로 EU/US 메시지 전체를 지원한다고 단정할 수 없다. 이 통합의 실제 동의창은 아직 미완료이며 외부 사이트 승인 때문이라고 입증하지 않았다.

안전한 재현: 새 임시 운영-origin 탭에서 CDP Network.setBlockedURLs로 `*googlesyndication.com/pagead/ads*`, `*doubleclick.net*`, 광고 측정 경로를 먼저 차단 → Google callbackQueue의 API_READY/DATA_READY 및 TCF/GPP 안전한 상태 필드만 관찰 → 공식 AdSense tag를 pauseAdRequests=1로 로드 → test-only 단위의 push도 중지 상태로만 진단한다. 실행 중인 운영 앱/파일/플래그는 바꾸지 않는다. 원시 Google 식별 URL/쿠키는 저장하지 않는다. 임시 탭을 닫아 주입을 제거한다. 이 진단에서 inventory를 막는 것은 성공한 실제 광고 송출 검증이 아니다. 중지된 태그로 메시지 UI가 표시되지 않으면 공급자 설치 경로 문제를 해결하고 재검증하기 전 PRIVACY_READY를 켜지 않는다.

공식 설치/진단: https://support.google.com/adsense/answer/14660912?hl=en (동일 게시자·최상위 창·cross-origin referrer; 운영 header strict-origin-when-cross-origin 확인). 요청 중지 API: https://support.google.com/adsense/answer/9042142?hl=en. 미국/GPP API: https://developers.google.com/funding-choices/fc-api-docs. webhook 종류: https://docs.tosspayments.com/reference/using-api/webhook-events.
