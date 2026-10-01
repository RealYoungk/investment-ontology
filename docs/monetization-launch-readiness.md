# 광고와 유료 이용권 출시 상태 — 2026-10-01

확정 결정: 공용 데이터 무료 유지, 일반 광고 우선, 광고 제거 월 2,900원. 고객문의는 이메일을 우선 사용한다. PG 계약은 없다.

## 완료된 운영 작업

- PR #83 병합, main 3e92d3e의 Release 36824418020 결과물 배포 및 파일/API 검증.
- AdSense 게시자 pub-4209548390738211, 광고단위 3239020318. ads.txt 소유권 인증과 사이트 심사 요청 완료. Google UI 상태는 준비 중이다. 승인이 아니다.
- 광고 요청과 자동 광고는 꺼져 있다. 시장/기업 목록 본문 배너만 준비되어 있다.
- SSH는 기존 접속 IP와 이번에 승인된 IP만 허용했다. 원본 설정은 서버 /root/ufw-backup-20261001에 보관했다. 재부팅 후 SSH, 컨테이너, 공개 overview 응답 확인.

## 이번 변경

로그인 없이 접근 가능한 정적 HTML 문의, 이용권 소개, 현재 개인정보 처리 안내를 추가했다. Flutter 소개·로그인·계정 이용권 카드에서 접근한다. 개인정보 현황 안내를 법적 고지 완료나 동의 취득으로 취급하지 않는다. 결제 버튼·카드 입력·광고 요청은 추가하지 않았다.

## 광고 송출 전 남은 일

1. AdSense 사이트 승인과 지급 계정 설정 확인. Google 심사 결과를 보지 않고 승인으로 표시하지 않는다.
2. 개인정보처리방침 확정: 운영 주체·책임자, 처리 목적/항목, 법적 근거, 보유기간, 로그/백업 삭제, 수탁자 및 국외 이전 요건을 운영 설정과 대조. 현재 코드에서 Vercel 중계, iwinv 서버/DB, Resend 메일 연동 확인. 실제 공급자 계약/지역/보존기간은 별도 확인 필요.
3. 가입 시 필요한 고지와 동의 기록의 서버 저장/버전 관리. 단순 체크박스로 이미 기록된 것처럼 주장하지 않는다.
4. 실제 광고 공급자 목록·맞춤 광고 선택 및 적용 지역의 인증 CMP 검증. Flutter 앱의 동의 전 외부 요청과 거부 후 동작을 브라우저에서 확인한다.
5. 승인만으로 ADSENSE_ENABLED를 켜지 않는다. 활성화 전 광고·쿠키 정책과 계정별 설정을 다시 확인한다.

Google 원문: https://support.google.com/adsense/answer/1348695?hl=ko
CMP: https://support.google.com/adsense/answer/16918505?hl=ko

## 유료 결제 구현 기준 — 제안, 아직 판매 조건이 아님

토스페이먼츠 v2 결제창 기반 빌링을 후보로 정했다. 카드 원문을 우리 서버로 받는 직접 API 방식은 사용하지 않는다. 토스 공식 문서상 자동결제에는 추가 리스크 검토와 계약이 필요하며, 테스트 키는 계약 전에도 제공된다. 전화번호 필수 여부는 실제 신청서에서 확인한다. 문의 이메일만으로 PG 계약이 가능하다고 단정하지 않는다.

https://docs.tosspayments.com/guides/v2/billing/integration

Serverpod 구현 시 필요한 데이터와 상태:

- 서버 소유 상품: KRW 2900. 클라이언트 금액·사용자 식별자를 신뢰하지 않는다.
- Subscription: authUserId unique, customerKey opaque/unique, encrypted billing reference, status, paidThroughUtc, nextChargeAtUtc, cancelAtPeriodEnd, termsVersion, consentAtUtc.
- PaymentAttempt: subscription/period unique, orderId unique, stable idempotencyKey, expected amount/currency, provider payment key, pending/unknown/paid/failed/refunded 상태. 타임아웃은 실패로 단정하지 않고 조회로 대사한다.
- 결제 인증 리다이렉트는 로그인 사용자와 서버 발급 일회 state를 검증한다. 성공 URL 방문만으로 권한을 주지 않는다. 서버가 승인 결과의 고객·주문·금액·통화·상태를 확인하고 트랜잭션으로 지급한다.
- Serverpod FutureCall이 갱신한다. 외부 결제 호출 중 DB 잠금을 오래 잡지 않고, 중복 실행에도 같은 주문을 재사용한다. 결제 실패 시 자동으로 새 주문을 만들지 않는다.
- 해지는 다음 청구를 중단하고 이미 결제한 기간까지 유지하는 안. 취소 요청과 갱신 작업이 충돌해도 해지 후 새 청구를 만들지 않도록 상태 전이 검증.
- 환불은 서버 원장과 PG 결과 대사를 통해 권한 만료에 반영한다. 환불 계산·청약철회 조건은 아직 확정하지 않았다.
- 광고 제거 여부는 만료 시간 있는 서버 원장으로 판단한다. 현재 영구 alfinder.adFree scope helper만으로 정기구독을 출시하지 않는다.
- 탈퇴 전 활성 구독 해지·빌링키 폐기·결제 기록 법정 보존 처리. 운영자는 다른 사용자의 결제 수단을 조회할 수 없어야 한다.

필수 검증: 금액/고객 변조, 중복 콜백, 두 갱신 작업 경쟁, PG 타임아웃 후 실제 승인, 해지/청구 경쟁, 환불 재시도, 만료된 세션의 광고 제거, 탈퇴 후 청구 방지. 실키 등록과 판매 개통은 위 검증 및 계약 완료 후 진행한다.

## 외부 절차

계약 신청 초안은 개인 운영 폴더에 보관한다. 사업자 증명서 원본, 생년월일, 계좌, 비밀키를 저장소에 넣지 않는다. 신청 정보 전송·약관 서명·정산 정보 입력은 대상과 내용을 보여주고 필요한 승인 또는 사용자 입력을 받는다.

## 승인 전 샌드박스 준비와 확인 결과

2026-10-01, PR #85의 격리 워크트리에서 확인했다. 아래 테스트는 운영 정기결제 완료를 의미하지 않는다.

| 대상 | 확인된 것 | 아직 확인되지 않은 것 |
| --- | --- | --- |
| 광고 JS 로더 | Node 9개 통과: 충전/미충전, 스크립트 실패, 좁은 폭, 시간 초과, 이탈/정리, 중복 로드 | 실제 Google 광고 채움, CMP와 동의별 네트워크 |
| Flutter 광고 | 광고/디자인 경계 11개 통과: 폭 320~1440, 유료 상태 제거, 로그아웃 복원, 승인·개인정보 준비 플래그 | 실제 결제 원장과 로그인 세션의 연결 |
| 토스 API 연결부 | HTTP 모의 테스트 17개 통과: 서버 고정 금액, 고객/주문/통화/응답 검증, 안정적인 멱등 키, 타임아웃 결과 불명, 조회, 환불 | 실제 카드 인증 후 승인·조회·전액 환불 |
| 구독 규칙 | 단위 테스트 12개 통과: 월말·윤년, 만료 경계, 중복, 해지, 환불 재생, 탈퇴 후 권한 차단 | DB 트랜잭션·갱신 작업 경쟁·다중 기기 인증 |
| 브라우저 | 실제 광고 로더를 모의 Google 응답으로 실행: 충전→유료 제거, 미충전, 스크립트 실패. 실제 토스 v2 SDK 테스트 카드 등록창 열림 | 카드 입력·약관 사용자 완료 후 공급자 API 검증 |

광고 활성화에는 `ADSENSE_ENABLED=true`, `ADSENSE_SITE_APPROVED=true`, `ADSENSE_PRIVACY_READY=true`가 모두 필요하다. 두 새 플래그는 배포 준비 확인용이며 CMP나 동의 기록 자체를 구현하지 않는다. 운영 기본값은 모두 false다.

재현:

```sh
node --test investment_ontology_serverpod_flutter/test/web/ad_loader_test.cjs
cd investment_ontology_serverpod_server
dart test test/unit/billing
```

Flutter 광고 테스트는 Flutter 패키지에서 `flutter test test/ad_monetization_test.dart test/design_boundary_test.dart`를 실행한다. 광고 JS 검증은 `scripts/verify_release.sh`에 포함했다.

개발 전용 화면은 저장소 루트를 loopback HTTP로 제공한 뒤 `/tool/ad-sandbox/index.html`, `/tool/toss-sandbox/index.html`에서 실행한다. 두 화면은 Flutter `web/` 밖에 있어 출시 번들에 포함되지 않는다. 토스 화면은 test_ck_만 허용하고, 시크릿 키·카드 원문을 우리 화면에서 수집하지 않는다. 인증 성공 URL의 일회성 authKey는 비밀 값이므로 공유·로그·스크린샷에 노출하지 않는다.

실제 공급자 검증 실행기는 서버 패키지의 `tool/test_toss_sandbox.dart`다. `lookup` 또는 `approve-and-refund` 모드를 사용한다. 필요한 환경변수명은 실행기 소스에 명시했다. test_sk_만 허용하며 비밀 값은 출력하지 않는다. 승인/조회/전액 환불 성공만으로 구독 권한을 지급하지 않는다. 결과 불명은 동일 주문 조회로 대사하고 새 주문으로 반복하지 않는다.

현재 Serverpod MCP는 이 워크트리가 아닌 다른 개발 체크아웃에 연결되어 있고 해당 DB가 읽기 전용이다. 기존 앱을 재시작하거나 DB 설정을 바꾸지 않았다. 정기구독 판매 전에는 이 워크트리의 별도 Serverpod 실행 환경에서 위에 명시한 원장 모델·마이그레이션·인증 RPC·암호화된 빌링키·FutureCall 갱신·해지/탈퇴 처리를 구현하고 DB 경쟁 테스트 및 계정별 E2E를 완료해야 한다. 현재 추가한 순수 규칙/전송 모듈을 완성된 정기결제로 취급하지 않는다.
