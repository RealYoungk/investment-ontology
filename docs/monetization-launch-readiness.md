# 광고와 광고 제거 이용권 준비 상태 — 2026-10-01

확정 결정: 공용 기업 데이터는 무료 공개, 일반 광고 우선, 광고 제거 월 2,900원. 공개 고객문의는 이메일 우선. PG 정기결제 계약과 실키는 확인되지 않았다.

## 운영과 이번 PR의 구분

운영은 PR #83 / main 3e92d3e의 광고 배치 준비 상태다. AdSense 소유 확인·심사 요청은 완료했지만 마지막 확인 상태는 준비 중이었다. 광고 요청과 자동 광고는 꺼져 있다. 시장·기업 목록의 본문 배너만 준비했고 상세 정보 열람을 가리지 않는다.

PR #85는 별도 워크트리의 준비 작업이다. 문의·이용권 소개·현재 개인정보 처리 안내와 아래 결제 구현을 포함한다. PR #85의 병합·운영 배포 완료를 뜻하지 않는다. 개인정보 현황 안내를 최종 법적 고지나 동의 취득으로 취급하지 않는다.

## 구현한 결제 흐름

- Serverpod 개인 인증 RPC: 이용권 상태, 카드 등록 시작·완료·취소, 다음 갱신 해지. 공유 데이터 변경 권한이나 관리자 권한은 주지 않는다.
- 서버 상품 금액 KRW 2900. 클라이언트 금액·계정 식별자를 받지 않는다. 토스 v2 SDK 카드 등록창을 사용하며 카드 원문은 우리 앱·서버에 저장하지 않는다.
- 계정에 묶인 10분 일회 state의 해시, 약관 버전·동의 시각을 저장하고 외부 API 호출 전에 원자적으로 사용 처리한다. 성공 URL 방문만으로 이용권을 주지 않는다.
- 구독·기간별 결제 시도 원장, 기간/주문/멱등 키/결제 키 고유 제약, DB 잠금과 트랜잭션. 공급자의 고객·주문·금액·통화·승인 상태를 검증한다.
- 빌링 참조는 소유 계정에 묶인 AES-GCM으로 암호화한다. 서버 전용 모델이며 RPC로 노출하지 않는다. 암호화 키는 서버 비밀 설정에만 둔다.
- FutureCall 갱신, 월말·윤년의 기간 경계, 해지 후 다음 청구 차단, 이미 결제한 기간의 이용권 유지. 결과 불명은 같은 주문 조회로 대사하며 새 주문으로 반복 청구하지 않는다.
- 전액 환불 확인 시 원장 이용권을 제거한다. 탈퇴 중 늦게 승인된 결제는 환불 대기 기록으로 정리한다. 탈퇴는 청구용 키를 즉시 비활성화하고 암호화된 삭제 대기 키를 유지해 공급자 삭제 성공까지 재시도한다.
- Flutter 계정 상태는 서버 원장을 조회하고 1분마다/앱 복귀 시 갱신한다. 만료 타이머는 네트워크 실패 중에도 유료 권한을 제거하고 계정 전환의 오래된 응답을 무시한다.
- 결제 화면: 동의 전 시작 차단, SDK 실패·취소 시 대기 state 해제, 서버 검증 결과로만 이용권 표시, 일회 인증 쿼리 제거, 320px 화면 검증.

## 검증의 범위

| 구분 | 현재 확인 |
| --- | --- |
| 실제 토스 테스트 | 사용자가 SDK 테스트 카드 등록을 완료. 테스트 빌링 발급 → 2,900원 승인 → 동일 주문 조회 DONE → 전액 취소 CANCELED, balance 0 확인. 개발자센터 취소 내역도 확인 |
| 서버 집중 검증 | 결제·원장·생성 등록·계정 경계 65개 통과. 모의 HTTP와 실제 격리 PostgreSQL 사용: 동시 갱신/콜백, 다른 계정·만료 state, 응답 불명 후 조회, 해지 후 늦은 대사, 탈퇴 중 승인 환불, 공급자 키 삭제 실패 재시도 |
| Flutter 집중 검증 | 광고·디자인·상태 모니터·결제 화면 19개 통과: 320~1440px, 동의/취소/완료, 만료/로그아웃/계정 전환 |
| JS 검증 | 광고 로더 9개 + 토스 로더 4개 통과. 실제 브라우저 광고 로더를 모의 Google 응답으로 실행해 채움/미채움/실패/유료 제거 확인 |
| 정적 분석 | dart analyze --fatal-infos 통과 |

실제 토스 테스트는 개발자용 SDK 화면과 공급자 실행기로 진행했다. 새 Flutter 가입·인증 → 토스 → 서버 원장 → 광고 제거까지 이어지는 통합 브라우저 E2E, 실제 운영 갱신과 실결제는 아직 확인하지 않았다. DB 통합 테스트의 모의 응답을 실제 PG 결제로 주장하지 않는다. 전체 회귀/출시 빌드 결과는 PR의 최신 검증 기록을 따른다.

## 출시 전에 남은 조건

1. AdSense 승인·지급 설정, 최종 광고/쿠키 고지 및 적용 지역의 인증 CMP·거부 동작 검증. 가입 개인정보 고지/동의는 이번 결제 동의 기록과 별개다.
2. 토스 자동결제 계약·리스크 심사와 해당 상점의 테스트/실키 확인. 이번 실제 테스트는 개발자 테스트 상점이며 운영 사업자의 계약을 증명하지 않는다.
3. 최종 판매 약관, 환불/청약철회·보존기간·국외 이전/수탁자 안내 확정과 공개 페이지 반영. 테스트 동의를 최종 판매약관 동의로 취급하지 않는다.
4. 상점 테스트 키로 새 Flutter 화면의 계정별 통합 E2E와 다음 기간 갱신 확인. 해지 뒤 재가입·카드 변경, 장기 미승인 주문·공급자 키 삭제 결과 불명의 운영 처리도 완료해야 한다. 현재 미승인 주문은 안전하게 조회 상태로 남고 자동 새 주문 청구를 하지 않는다.
5. 암호화 키 백업/회전, 결제 원장 보존·삭제, 대사 실패 모니터링과 고객 환불 처리 절차를 정한 뒤 활성화한다. 부분 환불·고객 셀프 환불은 아직 제공하지 않는다.

## 활성화와 재현

광고는 `ADSENSE_ENABLED`, `ADSENSE_SITE_APPROVED`, `ADSENSE_PRIVACY_READY`가 모두 true이고 ID가 유효해야 요청한다. 운영 기본값은 false다. 플래그 자체가 CMP나 사용자 동의 구현은 아니다.

테스트 결제는 development/test/staging에서 `ALFINDER_BILLING_SANDBOX_ENABLED=true`와 test 키만 허용한다. production은 `ALFINDER_BILLING_LIVE_ENABLED=true`, `ALFINDER_PG_BILLING_APPROVED=true`, `ALFINDER_BILLING_PRIVACY_READY=true`, 비어 있지 않은 `ALFINDER_BILLING_TERMS_VERSION`과 live 키가 모두 있어야 열린다. 현재 모두 꺼져 있다.

서버 비밀 설정: `tossTestSecretKey`/`tossTestClientKey` 또는 `TOSS_TEST_SECRET_KEY`/`TOSS_TEST_CLIENT_KEY`; 운영은 각각 Live/LIVE 이름. `billingEncryptionKey` 또는 `BILLING_ENCRYPTION_KEY`는 base64 32바이트이며 임의 교체하면 기존 키를 복호화할 수 없다. 비밀 키·authKey·빌링 키는 채팅·로그·PR에 넣지 않는다. 실제 테스트의 임시 키 파일은 실행 후 삭제했다.

```sh
# 다른 개발 DB와 분리, 9080/9081/9082/9190. 기본 결제·FutureCall 실행 OFF
bash scripts/start-billing-sandbox.sh
# 격리 테스트 DB는 Docker 없이 시작
bash scripts/test-server.sh
node --test investment_ontology_serverpod_flutter/test/web/*_test.cjs
# 깨끗한 커밋에서 전체 검증과 출시 번들 생성
bash scripts/verify_release.sh
```

Serverpod 모델 마이그레이션과 재시작은 해당 워크트리 MCP에서 수행한다. 생성 파일을 손으로 수정하지 않는다. 개발 전용 `tool/ad-sandbox`, `tool/toss-sandbox`는 출시 web 번들 밖에 있다. 실제 공급자 실행기 `server/tool/test_toss_sandbox.dart`는 test 키만 받고 lookup / approve-and-refund를 지원한다.

## 참고 원문

- https://docs.tosspayments.com/guides/v2/billing/integration
- https://support.google.com/adsense/answer/1348695?hl=ko
- https://support.google.com/adsense/answer/16918505?hl=ko
