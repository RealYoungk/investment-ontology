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
