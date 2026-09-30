# 알파인더 공개 배포

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
