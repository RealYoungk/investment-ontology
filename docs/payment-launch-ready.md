# PortOne 카드 정기결제 개통 준비

2026-10-02. 현재 실결제 OFF. 웹은 결제 UI를 미리 포함하고 서버 `paymentAvailable`을 개통 기준으로 사용한다. 운영 키·PG 승인 확인 후 프런트엔드를 다시 빌드할 필요 없다. 이 문서는 실제 PG 승인 또는 실카드 승인 증거가 아니다.

## 지원 범위

이번 출시 대상은 PortOne V2를 통한 **NHN KCP V2 CARD 월간 빌링**이다. 계약 PG는 아직 확인되지 않았다. 다른 PG가 승인되면 먼저 그 PG의 빌링 발급 방식·필수 구매자 정보·ID 제한을 대조해야 한다. NICE 카드 등 일부 PG는 동일한 웹 CARD 발급 방식을 지원하지 않으므로 채널 키만 바꾸어 개통하지 않는다.

첫 결제부터 서버가 상점·채널·고객·빌링 발급 요청·주문·금액을 조회 검증한다. 모바일 redirect와 PC promise 응답을 처리하고, 세션 만료 뒤 재로그인해도 동일 checkout 정보를 보존한다. 외부 주소 또는 중복 콜백 ID는 허용하지 않는다. 서버의 계정 소유권 검사는 그대로 적용한다.

초기 월 4,900원/VAT 포함, 가입 가격 보호, 카드 교체, 해지·철회·재가입, 7일 유예 및 1/3/6일 확정 실패 재시도, 미확인 거래 GET 대사, 전액 취소를 지원한다. 5분 FutureCall이 승인·환불을 대사하므로 웹훅 등록은 현재 필수가 아니다. 웹훅 없이 PG 외부 취소 반영은 최대 다음 대사까지 지연될 수 있다. 브라우저 결과만으로 유료 권한을 부여하지 않는다.

## PG 심사에 전달할 서비스 정보

- 서비스/상품: 알파인더 투자 리서치 도구의 월간 멤버십. 투자 자문·성과 보장 상품이 아니다.
- 상품 페이지: https://alfinder.kr/membership
- 이용약관: https://alfinder.kr/membership.html
- 개인정보 안내: https://alfinder.kr/data-notice.html
- 운영/문의: https://alfinder.kr/support.html (현재 사이트에 게시된 실제 사업자 정보)
- 가격: 초기 월 4,900원, VAT 포함, 매월 자동 갱신. 해지는 계정 화면에서 가능하며 이미 결제한 기간까지 이용.
- 혜택: 관심기업 20개, 새 공시 모아보기, 알파인더 광고 제거. 공용 기업 데이터 조회는 무료.
- 환불: 현재 이용 기간 안에 문의하면 해당 회차 전액 취소. 관리자 인증으로 해당 회차를 지정하고 PG 취소를 조회 확인한다. 고객은 카드번호/CVC를 보내지 않는다.
- 심사용 계정이 필요하면 일반 회원을 생성한다. 최초 회원 관리자 부여나 인증 우회는 사용하지 않는다.

PG 업체에 아직 제출·계약하지 않았다. 사업자/통신판매 관련 추가 서류, 업종 허용 범위, 실제 비용과 심사 요구사항은 신청할 PG의 안내로 확정한다.

## 승인 전 준비

`deploy/iwinv/billing.env.example`을 **운영 서버** `/opt/alfinder/runtime/billing.env`로 복사하고 권한을 600으로 설정한다. 내용이나 비밀 키를 채팅·Git·웹 빌드에 넣지 않는다. template의 LIVE_ENABLED/PG_APPROVED/PRIVACY_READY/CHANNEL_VERIFIED는 false이고 CHARGES_PAUSED는 true다. 초기 파일을 붙이는 것만으로 개통되지 않는다.

PortOne 상점 ID, **승인된 운영 KCP CARD 빌링 채널 키**, V2 API secret을 입력한다. 테스트 채널을 운영 채널로 오인하지 않는다. 기존 암호화 빌링키가 있으면 `BILLING_ENCRYPTION_KEY`를 재생성하지 않고 같은 32바이트 base64 키를 유지한다. `runtime/passwords.yaml`의 billingEncryptionKey / portoneLiveApiSecret이 있으면 해당 값이 환경변수보다 우선하므로 서로 다른 값을 중복 설정하지 않는다. 원장에 저장된 기존 Toss 거래는 기존 자격증명도 유지한다.

개인정보 안내에 **확정 PG의 정확한 법인명, 위탁 범위, 개인정보 안내 URL**을 게시하고, 현재 '계약 확정 후 공개' 항목을 실제 내용으로 교체한 다음 PRIVACY_READY를 확인한다. 약관 2026-10-02와 서버 TERMS_VERSION을 맞춘다. 계약 PG가 KCP가 아닌 경우 개통 검토가 먼저다.

## 심사 승인 후 마지막 개통

1. 승인된 KCP 운영 채널과 키를 확인한다. PG 승인/개인정보 준비/채널 확인을 기록한 뒤 `ALFINDER_BILLING_LIVE_ENABLED`, `ALFINDER_PG_BILLING_APPROVED`, `ALFINDER_BILLING_PRIVACY_READY`, `PORTONE_LIVE_CHANNEL_VERIFIED`를 true로 설정한다. `ALFINDER_BILLING_CHARGES_PAUSED=false`로 전환하기 전 실카드 검증 담당자와 개통 시점을 맞춘다.
2. 다음 읽기 전용 점검이 통과해야 한다. 검사는 키를 출력하거나 카드 결제를 실행하지 않는다. 통과는 **설정 형식** 증거이고 PG 계약·채널 모드·키 유효성 증거는 아니다.

   ```sh
   python3 scripts/check_billing_ready.py --env-file /opt/alfinder/runtime/billing.env
   ```

3. `deploy/iwinv/compose.billing.yaml`을 `/opt/alfinder/compose.billing.yaml`로 설치한다. 현재 운영 `compose.yaml`과 **기존 override(issuer-documents 등)**를 모두 유지한 compose 명령에 마지막 파일로 추가한다. 예:

   ```sh
   cd /opt/alfinder
   docker compose -f compose.yaml -f compose.override.yaml -f compose.billing.yaml --profile app up -d --no-deps server
   ```

   이후 서버 재생성/배포에서도 같은 파일 목록을 유지해야 한다. 실제 `compose.override.yaml`이 없으면 그 인자만 뺀다. `.env`에만 값을 넣는 것으로는 컨테이너에 전달되지 않는다. DB를 재생성하지 않는다.

4. 운영 `membershipOffer.offer`가 paymentAvailable=true / isTest=false / currentPriceKrw=4900인지 확인한다. 비로그인 개인 membership.status는 여전히 401이어야 한다. 관리자의 예약 현황 또는 읽기 전용 DB 조회로 `alfinder-billing-renewal` FutureCall이 5분 간격으로 등록되었는지 확인한다.
5. 실제 카드 정보 입력·첫 결제는 담당자가 직접 수행한다. PC와 모바일에서 동일 계정으로 복귀, 해당 회차 4,900원 1건 승인, 관심기업 20개 적용, 새로고침·콜백 재방문 중복 청구 없음, 카드 변경 추가 청구 없음, 해지·철회, PG 취소 및 이용권 종료를 확인한다. 갱신/실패/만료는 격리 테스트에서 확인하고 운영 DB 날짜를 수정해 강제 청구하지 않는다.
6. 확인한 주문 ID·금액·PG 승인/취소 상태·시간과 배포 커밋을 비공개 운영 기록에 남긴다. 카드번호·CVC·빌링키·API secret은 기록하지 않는다. 실카드 승인 확인 전 결제 개통 완료라고 보고하지 않는다.

## 중지와 복구

장애 시 `ALFINDER_BILLING_CHARGES_PAUSED=true`로 설정하고 동일 compose 파일로 서버를 다시 만든다. 새 청구를 차단하면서 기존 조회·환불 대사·가격 보호는 유지한다. 키를 지우거나 LIVE_ENABLED를 false로 바꾸는 것은 대사도 멈출 수 있으므로 단순 청구 중지 대신 사용하지 않는다. 기존 이미지·Pages 배포·원장을 삭제하거나 암호화 키를 교체하지 않는다.

## 공식 기술 근거

- [빌링키 발급](https://developers.portone.io/opi/ko/integration/start/v2/billing/issue?v=v2)
- [NHN KCP V2 빌링](https://developers.portone.io/opi/ko/integration/pg/v2/kcp-v2?v=v2)
- [SDK 발급 요청·모바일 redirect](https://developers.portone.io/sdk/ko/v2-sdk/billing-key-request)
- [SDK 응답](https://developers.portone.io/sdk/ko/v2-sdk/billing-key-response)

## 완료/남은 항목

구현: 운영 compose overlay·비공개 env template·read-only preflight, 서버 승인 채널 gate, UI 사전 탑재, 모바일 redirect 결과 처리·SDK 재시도, 재로그인 콜백 보존, 공용 약관 상태의 서버 동기화. 시험 결과는 이번 작업 기록에 기재한다.

외부 의존: PortOne/PG 계약·실제 채널/운영 키, 확정 PG 개인정보 안내, 실제 카드 승인·취소. 이 부분은 가짜 값이나 임의 승인으로 채울 수 없다.
