# 알파인더 공개 배포

현재 배포·복구 절차는 [GitHub 기준 배포](release-process.md)를 따른다. 아래 직접 빌드/업로드
명령과 과거 배포 기록은 참고용이며, 운영 신규 배포는 검증된 커밋의 결과물만 사용한다.

## 운영 구조 (2026-09-23)

사용자 결정: 당장은 추가 서버 비용 없이 맥북에서 Serverpod와 PostgreSQL을 운영한다.

- 웹 화면: Vercel의 `alfinder-research` 프로젝트에 Flutter release 정적 빌드.
- API: 같은 도메인의 `/api/`를 Node 전송 프록시 → Tailscale Funnel → 맥북 8080으로 전달. Vercel edge rewrite에서 간헐적 DNS 실패가 재현되어 명시적 A 레코드 조회로 교체했다.
- DB와 Insights 포트는 공개 라우트로 연결하지 않는다.
- 공유 데이터 조회는 비로그인도 가능하다. 계정은 본인만, 운영과 변경은 관리자만 가능하다. 이메일은 Resend.
- 맥북이 꺼지거나 잠들거나 네트워크가 끊기면 로그인·조회·수집이 중단된다.
- 서버 시작은 사용자가 `serverpod start`로 수행한다. 배포 스크립트는 서버를 시작하지 않는다.

## 이번 전환 상태

2026-09-23 alfinder.kr을 새 Flutter 배포로 전환 완료했다. 초기 DNS 전파 중 502가 있어 잠시 복구한 뒤, 세 차례 연속 API 확인을 거쳐 다시 전환했다.
실도메인 Flutter 화면/정적 파일 200. 비로그인 company/list·market·theme는 공개 조회 200, ingest/ai/review 대기열/account는 401. 잘못된 로그인 invalidCredentials 및 허용되지 않은 Origin 403 확인. 실제 회원의 로그인 성공은 이번 전환에서는 재검증하지 않았다.
www는 Vercel 별칭은 있으나 DNS 레코드가 없어 접속 미검증이다. 안내 주소는 https://alfinder.kr 이다.

- 새 배포: `alfinder-research-5065bynvo-realyoungks-projects.vercel.app`
- 이전 배포(롤백): `alfinder-research-fzc4xg05h-realyoungks-projects.vercel.app`
- 기존 Git 연결 `RealYoungk/alfinder`는 해제했다. 예전 사이트가 자동 재배포되는 것을 방지한다.
- Vercel rootDirectory는 `apps/research`에서 null, framework는 nextjs에서 null로 변경.
- 가비아의 웹·메일 DNS는 변경하지 않았다.

## 재배포

`scripts/prepare_public_web.py`로 빌드 출력물을 준비한 뒤:

```sh
vercel deploy --prebuilt --prod --skip-domain --yes --cwd output/public-deploy
```

별도 배포 URL에서 화면·API·인증·새로고침을 검증하고 나서만 `vercel promote <URL>`로 전환한다.
프록시는 DNS만 재시도하고 전송한 변경 요청은 재시도하지 않는다. API 응답은 캐시하지 않는다. Flutter의 HTTPS 기본 API 경로는 같은 origin의 `/api/`이다.

## 맥북 터널

실제 데몬은 사용자 전용 소켓을 쓴다. 기본 `/var/run/tailscaled.socket`은 존재하지 않는다.

```sh
tailscale --socket="$HOME/.tailscale-state/tailscaled.sock" funnel status
tailscale --socket="$HOME/.tailscale-state/tailscaled.sock" funnel --bg --https=443 --set-path=/api http://127.0.0.1:8080
```

공개 DNS 등록은 최대 10분 걸릴 수 있다. status 출력만으로 성공 판정하지 않고 외부 HTTP로 검증한다.

## 복구

Vercel에서 이전 배포를 promote하면 도메인 서비스가 복구된다. 과거 프로젝트 파일과 배포는 삭제하지 않는다.
예전 Git 자동 배포까지 복구하려면 rootDirectory `apps/research`, framework `nextjs`와 저장소 연결을 함께 되돌린다.

## 운영 한계

현재는 사용자 맥북의 개발 실행 환경을 공개 연결한 단계다. 독립 서버 이전, DB 최소권한 역할,
백업 복원 훈련, 재부팅 후 운영 절차, 공개 서비스 정책 정비는 별도 운영 과제다.

## 2026-09-24 연결 및 시장 긴급 수정

PR81 main 기반 배포 dpl_tR6TPiYKWjmsHmpMNd8SwPcu9CfE (alfinder-research-bok090see-realyoungks-projects.vercel.app)를 alfinder.kr에 반영. DNS ENOTFOUND 재현 후 제한 시간 있는 DoH fallback 추가. 시장 재시도 UI 및 스크리너 초기 계산 개선. 리포트 PR80은 미포함. 근거와 복구는 [장애 기록](incident-market-timeout-20260924.md) 참고.

## 2026-09-30 개요·모바일 UI 배포

- 사용자 배포 요청에 따라 작업 트리의 Flutter release를 빌드(40초), prebuilt 배포 후 alfinder.kr로 promote했다.
- 배포 ID: `dpl_BioBjhWK75xFkQPWNb2XcVYqxmDS` (READY).
- 배포 주소: `alfinder-research-kh3u6h7g0-realyoungks-projects.vercel.app`.
- 롤백 주소: `alfinder-research-4pgrggm5c-realyoungks-projects.vercel.app` (`dpl_9oNyZ3uybskfsdhTeGUcdwhsC9Pa`).
- 커밋 기준 `2596e10` 위의 미커밋 작업 트리 포함. 커밋만으로 동일 배포를 재현한다고 해석하지 않는다.
- 공개 개요 자산 HTTP 200, 2,756개사 JSON이 로컬 원본과 바이트 단위 일치. 공개 기업 API 200. 실제 alfinder.kr 알테오젠 390px 브라우저에서 회사 데이터, 새 사업 설명·세로 도식·성장 동력 렌더링 확인.
- 임시 Vercel 주소는 허용 Origin이 아니므로 브라우저 API 403이 정상이다. 운영 Origin으로 전송한 배포 API는 200이며, 보안 설정은 넓히지 않았다.
- 웹과 API 전송 프록시만 배포. 기존 맥북 Serverpod/DB 운영 구조 유지.

## 2026-09-30 모바일 검색 포커스 수정

- iOS/Android 검색 대화상자의 자동 포커스를 끄고 입력칸 직접 탭으로 키보드를 요청하도록 변경. 데스크톱 자동 포커스 유지, 검색 입력 action 지정.
- 배포: `dpl_Fv6y8hnZPSE3SJ956n8gjd7Php47`, `alfinder-research-dtyg8dvsb-realyoungks-projects.vercel.app` (alfinder.kr promote 완료).
- 롤백: `alfinder-research-kh3u6h7g0-realyoungks-projects.vercel.app`.
- dart analyze 통과, 관련 Flutter 테스트 7개 통과, release 빌드 통과. 공개 main.dart.js가 로컬 빌드와 SHA256 일치, 기업 API 200.
- 플랫폼별 첫 포커스·재탭·대화상자 재열기 테스트 완료. 실제 휴대폰 OS 키보드 표시 여부는 물리 기기에서 추가 확인 필요.

## 2026-09-30 입력 포커스 자동 확대 보정

- Flutter semantic input/textarea의 기본 글자 크기(공개 브라우저 측정 13.3333px)를 16px로 보정. 모바일 검색의 표시 글자도 16px로 조정. viewport 확대 상한은 추가하지 않았다.
- 참고: https://github.com/flutter/flutter/issues/192327 (semantic input 크기로 인한 iOS 자동 확대).
- 배포: `dpl_EsdL73RNFVws5jaNZD7Kq1fRsVkU`, `alfinder-research-2r8kmr6ns-realyoungks-projects.vercel.app`.
- 롤백: `alfinder-research-dtyg8dvsb-realyoungks-projects.vercel.app`.
- analyze, 관련 Flutter 테스트 5개, release 빌드 통과. 실제 iPhone의 자동 확대 종료 여부는 물리 기기 확인 필요.

## 2026-09-30 모바일 검색 아이콘에서 즉시 입력

- 모바일 검색 editor를 Offstage overlay에 유지하고 아이콘 클릭 안에서 focus 변경을 즉시 적용한다. 비동기 dialog 생성 후 autofocus에 기대거나 사용자의 두 번째 탭을 요구하지 않는다.
- 닫으면 focus, 검색어, debounce와 진행 중 응답을 정리한다. LocalHistoryEntry로 뒤로가기 시 검색부터 닫고, desktop 전환 시 overlay를 제거한다.
- 배포: `dpl_8rZjBRfeS9XcXHvYjur2J5kJBbrH`, `alfinder-research-vfgmfzgep-realyoungks-projects.vercel.app`.
- 롤백: `alfinder-research-2r8kmr6ns-realyoungks-projects.vercel.app`.
- analyze, 관련 Flutter 테스트 7개, release 빌드 통과. 아이콘 탭 직후 다음 프레임 전 TextInput.show, 재열기, 뒤로가기, desktop 전환, dispose 검증. 브라우저에서 검색칸 재클릭 없이 입력 및 Enter로 기업 진입 확인.
- 실제 휴대폰 OS 키보드 표시 검증은 별도 필요. 웹 공통 16px semantic input 보정은 유지.

## 2026-09-30 지표 누락 사유 상시 표시

- 헤더의 PER/ROE 등 값이 없는 지표 바로 아래에 해당 DerivedValue.missing을 표시한다. 여러 사유를 하나의 클릭 안내로 합치던 문구는 제거했다.
- 배포: `dpl_C3xXF6SpYGuyJMNfsHpHvi6FZ2Li`, `alfinder-research-qtpervwos-realyoungks-projects.vercel.app`.
- 롤백: `alfinder-research-vfgmfzgep-realyoungks-projects.vercel.app`.
- analyze, 계산/390px/1280px 위젯 테스트 19개, release 빌드 통과. HLB 실제 화면에서 PER 누락 사유 상시 표시 확인.

## 2026-09-30 업종별 지표 탐색

- 배포: `dpl_22oVMMgv2urMNmM2oioYkquFqJX7`, `alfinder-research-fsvg5k9zd-realyoungks-projects.vercel.app`, alfinder.kr promote 완료.
- 롤백: `alfinder-research-qtpervwos-realyoungks-projects.vercel.app` (프런트엔드만). 서버 raw 계정 확장은 이전 클라이언트와 호환.
- 상단 업종/실적 상태별 6개 지표와 재무 지표 탐색·계산 모달. 지원 범위는 valuation-metrics.md 참조. EV/PEG의 원천 한계가 남아 있음.
- analyze, 전체 Flutter 144개와 후속 관련 9개 테스트, 서버 관련 24개 및 확장 계정 단위 4개, release 빌드 통과.
- preview financial/summary 200 및 현금/NCI 확장 입력, 공개 HLB PSR 54.25배/그룹 탐색/계산 모달 확인. 로컬 KB금융·기가비스 업종 선택 검증. 320px 계산창 제목 넘침 수정 및 테스트, 390px 실제 화면 확인.
- 공개/로컬 main.dart.js SHA256: `c91ce98ad02ddc19420d7f956140cc14643783fac23d9b6d2471280493208f61`.

## 2026-09-30 상단 그리드에 지표 탐색 통합

- 사용자 정정 반영: 그룹 선택과 계산창을 상단 그리드로 옮기고 재무 탭의 중복 지표 탐색·계산 영역 제거.
- 배포: `dpl_CHxQMaqcRPRfKuDW7MtMrZE7vQaA`, `alfinder-research-7a4qfvggm-realyoungks-projects.vercel.app`. alfinder.kr promote 완료.
- 롤백: `alfinder-research-fsvg5k9zd-realyoungks-projects.vercel.app`.
- analyze, 관련 7개 및 설명 추가 후 5개 테스트, release 빌드 통과. 320/1280px 위젯, 실제 모바일 390px 그리드/모달 확인, 재무 탭 중복 제거 확인.
- 공개/로컬 main.dart.js SHA256: `505fd64bf41b9b468c1dc3e29e6f4a9a85da22422d2db3cb977ed684d78c17ac`.

## 2026-09-30 모바일 지표 상세 바텀시트

- 배포: `dpl_7jYaZcbpARmuBviwGiUgDUuk1SS3`, `alfinder-research-7r8fgd9x2-realyoungks-projects.vercel.app`. alfinder.kr promote 완료.
- 롤백: `alfinder-research-7a4qfvggm-realyoungks-projects.vercel.app`.
- 600px 미만 바텀시트/그 이상 중앙 팝업. 관련 6개 테스트, analyze, release 빌드 통과. 공개 390px HLB PSR 바텀시트 및 드래그 닫기 실제 확인.
- 공개/로컬 main.dart.js SHA256: `ca43855432c96d5c28b8410175b224c42d3d333ca321a9fc1cff9ec9cfda015b`.


## 2026-09-30 지분 묶음 UI 보류

사용자 요청으로 데스크톱·모바일 공통 메뉴, 검색 바로가기, 기업 상단 묶음 안내를 제거했다. 기업 페이지의 group.of 호출도 제거했다. /groups 및 하위 주소는 홈으로 리다이렉트한다. 그룹 화면 구현과 서버·DB는 재기획을 위해 보존한다. dart analyze 무오류, 라우터·모바일 검색 테스트 5개 및 웹 release 빌드 통과. 공개 기업 화면에서 묶음 안내 제거 확인.

배포: dpl_4Me23tJaoDrxUwLoZbd5ui5ty7jd (https://alfinder-research-fgs7rm2yw-realyoungks-projects.vercel.app), alfinder.kr 승격 완료. 공개 main.dart.js와 로컬 빌드 SHA256 일치: a4761e069849cf21a3a79e1af428a8286b594ccb2a3313c309e3d50cba551c8c. 롤백 대상: https://alfinder-research-7r8fgd9x2-realyoungks-projects.vercel.app.


## 2026-09-30 상단 지표 전수 검증

[검증 보고서](metric-audit-2026-09-30.md): 2,756개사 실제 자동 기준 응답, 23개 지표의 finite-or-reason 검사 및 추천 6개 계약 통과. ID 없는 엄격한 계정명 보완, TTM 누락 계정명 표시, 비양수 시총 차단, 보고서별 CAPEX 부호 정규화 및 기간 불일치 차단. 서버 공통 SQL에도 투자액 부호 정규화 적용. EV/PEG 미연결 및 724개 기업의 일부 추천 지표 누락은 남아 있으며 전체 원문 대조 완료로 해석하지 않는다.

배포 dpl_7uJdruPavWMJ65PeeoQS1kNPmWyw (https://alfinder-research-9gngws583-realyoungks-projects.vercel.app), alfinder.kr 승격 완료. 이전 프런트: https://alfinder-research-fgs7rm2yw-realyoungks-projects.vercel.app. 서버 변경은 별도 코드 복구가 필요하다.

최종 입력 계정명 표시 배포: dpl_EEXMBpex5J2yBDQS4ZSoE9ZAEh3M, https://alfinder-research-134sj1tqp-realyoungks-projects.vercel.app (alfinder.kr 승격). 추가 지표·팝업 테스트 10개 통과.


## 2026-09-30 수집분 원천 전수 대조

[원천 대조 보고서](metric-source-audit-2026-09-30.md). 2,756개사, canonical 96,897개 보고서, 선택 원천 행 990,048개 대조 불일치 0. 자동·연결·별도 7,659개 응답의 176,157개 지표 Decimal 독립 검산 불일치 0. 자동 기준 선택·시총·시장 원천 대조도 0. 외화 정보 전달, 통화 혼합 계산 차단, IFRS 대체 계정, Unicode 공백, 원천 재무상태표 합계 불일치 처리를 수정했다. DTO 추가는 자동 생성했으며 마이그레이션 없음.

배포: dpl_Bk8Ar4EcwswQ81XLpV3oy8KYDUat, https://alfinder-research-p0w4teckd-realyoungks-projects.vercel.app 를 alfinder.kr로 승격. 프런트 이전 버전은 https://alfinder-research-134sj1tqp-realyoungks-projects.vercel.app. 서버 변경은 별도 코드 복구가 필요하다. Flutter 151개·서버 관련 24개 및 별도 원천/전수 테스트 통과. 마지막 외화 표기 변경의 지표·팝업 테스트 12개 추가 통과. 원천 스냅샷은 outputs/metric-source-audit에 로컬 보존하고 대용량 데이터는 gitignore 처리했다.

### 2026-09-30 최종 웹 계산 차단 수정

생성 FinancialLine의 nullable BigInt copyWith가 release JS에서 기존 금액을 남기는 현상을 수정: 오류 입력은 명시적인 새 DTO로 구성. 사조동아원 운영 PER 상세에서 합계 불일치 사유 확인. 독립 검산 176,157건 및 원화 오류 사유 대조 0건 불일치. 최종 배포 `dpl_GSnDR96XB6aguoe67NXP29Lh4MBg` / `https://alfinder-research-hfaswjf48-realyoungks-projects.vercel.app`, alfinder.kr 승격 완료. JS SHA256 `e24f6f8942630bc19848014c192cf39750414ef64d4d837782cc08f2db568f32`.
