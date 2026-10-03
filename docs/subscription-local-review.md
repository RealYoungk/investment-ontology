# 멤버십 로컬 리뷰 — 2026-10-02

로컬 URL: http://localhost:8100/membership

## 구현한 정책

- 하나의 월간 유료 멤버십. 출시 신규 가격 4,900원, VAT 포함. 목표 19,900원은 계획이며 자동 인상 일정 없음.
- 서버 `ALFINDER_NEW_SUBSCRIPTION_PRICE_KRW`로 신규 게시 가격 설정(4900/9900/14900/19900). 실제 청구는 구독·회차에 저장한 금액과 버전을 사용.
- 첫 승인부터 가입 가격 보호. 만료 전 해지 철회는 같은 가격, 기간 종료 후 재가입은 당시 신규 가격. 카드 교체는 가격 변경 없음.
- 월말/윤년을 고려한 UTC 월간 기준일. 거절이 확인된 갱신만 1/3/6일에 재시도하고 7일 유예 종료. 응답 유실/미확인은 조회만 하며 결제 주문을 교체하지 않음.
- 서버 청구 일시 중지 시 유예 시계를 멈춤. 장기 시스템 지연은 과거 여러 회차를 청구하지 않고 같은 가격의 새 한 달로 재개.
- 기존 2,900원 원장의 PG·금액 보존. 과거 환불은 해당 회차 금액·PG로 처리.

## 결제 연결

PortOne V2 CARD 빌링키 발급 UI와 서버 어댑터를 연결했다. 카드 정보는 PG 등록창에서 처리하며 서버에는 계정에 묶어 암호화한 빌링키를 보관한다. 서버는 상점·채널·발급 요청 ID·고객·통화·주문·금액을 조회 검증한 뒤 이용권을 부여한다. 기존 Toss 어댑터는 기존 원장 처리에 유지한다.

웹훅 수신은 현재 연결하지 않았다. 서버 FutureCall이 5분마다 GET으로 미확인 승인·환불·유료 기간을 대사한다. 공개 콜백 데이터만으로 유료 권한을 부여하지 않는다. 웹훅은 추후 지연 최적화에 추가할 수 있다.

## 운영 전에 필요한 설정

현재 로컬 화면은 출시 준비 상태이며 실결제를 열지 않았다. 실제 PG 계약, KCP 카드 정기결제 심사, 실제 업종 조건·보증보험·고정비, PortOne 상점/채널/키가 아직 확인되지 않았다. 공급업체에 연락하거나 계약·실결제를 진행하지 않았다.

테스트 모드: `ALFINDER_BILLING_SANDBOX_ENABLED=true`, `ALFINDER_BILLING_PROVIDER=portone`, `PORTONE_TEST_STORE_ID`, `PORTONE_TEST_CHANNEL_KEY`, 서버 비밀 `portoneTestApiSecret` 또는 `PORTONE_TEST_API_SECRET`, 암호화 비밀 `billingEncryptionKey` 또는 `BILLING_ENCRYPTION_KEY`(32바이트 base64). 실제 발급 가능한 **테스트** 채널을 사용해야 한다. PortOne 선택 채널 응답에는 테스트 여부 필드가 없어 키·채널의 모드 분리가 운영 책임이다.

운영 모드에는 별도 `PORTONE_LIVE_*` 설정과 `ALFINDER_BILLING_LIVE_ENABLED`, `ALFINDER_PG_BILLING_APPROVED`, `ALFINDER_BILLING_PRIVACY_READY`, `ALFINDER_BILLING_TERMS_VERSION`이 필요하다. Flutter 결제 UI 활성화는 `MEMBERSHIP_CHECKOUT_ENABLED=true` 빌드 설정도 필요하다. 청구 중지는 전체 PG 연결을 제거하지 않고 `ALFINDER_BILLING_CHARGES_PAUSED=true`를 사용한다.

## 저장 방식과 설계 문서 차이

이번 구현은 별도 가격 버전/계약 테이블 대신 BillingCheckout의 동의 시각·약관·금액·가격 버전과 BillingPaymentAttempt의 회차별 금액·버전을 이력으로 보존한다. 신규 가격 버전 문자열은 `monthly-v1-<금액>`이며 게시 변경은 서버 배포 설정으로 한다. 관리 화면에서 임의 가격을 편집하는 기능은 제공하지 않는다.

확정 실패 재시도는 새 PG 주문 ID를 사용하고 실패한 주문 ID를 원장에 보존한다. 논리적 구독 회차는 동일하며 중복 실행은 거래 잠금으로 차단한다.


## 검증 결과

서버 결제/가격/생성 등록 관련 91개, Flutter 결제/플랜/상태/디자인 경계 15개, 브라우저 SDK 로더 6개 테스트 통과. 서버와 Flutter `dart analyze` 모두 이슈 없음. 테스트 PG 응답은 격리된 MockClient이며 실제 카드 승인 증거가 아니다.

로컬에서 390px 모바일 및 1280px 데스크톱 가입 화면, 가격 유지 FAQ 펼침, 무료 이용 버튼의 로그인 이동을 확인했다. 마이그레이션 3개를 MCP로 적용하고 서버·앱 hot restart 성공. 최초 생성기 캐시 오류와 CLI 4.0.3/패키지 4.0.0의 생성 테스트 도구 호환 오류는 4.0.0 생성기로 복구했다. 후속 모델 변경 시 실행 중 CLI 버전을 패키지와 맞춰야 한다.

스크린샷: `outputs/subscription-review/desktop-plan.jpg`, `mobile-plan.jpg`, `mobile-policy.jpg`.

기존 Toss 키를 PortOne 키로 자동 변환하지 않는다. 이미 Toss 구독을 가진 계정의 PG 전환은 이전 키 삭제 확인 및 미확인 거래 대사를 먼저 해야 한다. 기존 PG 자격 증명은 과거 거래 환불·대사를 위해 유지해야 한다.

주요 공식 연동 근거: [PortOne 빌링키 발급](https://developers.portone.io/opi/ko/integration/start/v2/billing/issue?v=v2), [KCP 연동 제한](https://developers.portone.io/opi/ko/integration/pg/v2/kcp-v2?v=v2). 주문 ID와 빌링 발급 ID는 KCP 길이·문자 제한을 고려해 34자의 영숫자 ID를 사용한다. REST 본문은 공식 @portone/server-sdk 0.19.0 타입을 기준으로 확인했다.

고객 화면 보정 (2026-10-02): 사용자 요청에 따라 내부 목표 가격과 인상 계획을 고객 화면·공개 약관·MembershipView API에서 제거했다. 얼리버드 현재 요금과 구독 유지 중 가입 가격으로 새 기능을 이용하는 혜택을 강조한다. 미확정 인상 일정이나 마감, 최저가 단정은 표시하지 않는다.
