# GitHub 기준 배포와 복구

## 현재 운영 방식

프런트는 **Cloudflare Pages `alfinder-web`**, Serverpod·DB·정기 작업은 **iwinv**에서 운영한다.
프런트 이전은 완료했으며 현재 배포 설정은 `deploy/release-project.json`과 [Cloudflare 운영 문서](cloudflare-pages.md)를 따른다.
`main`에 push하면 **Release** 워크플로가 분석·포맷·서버/Flutter 테스트·웹 빌드를 수행하고
커밋별 `web-release-<SHA>` 결과물을 30일간 보관한다. PR도 검증하지만 PR 결과물은 운영 배포할 수 없다.

운영 반영은 아래 배포 명령으로 실행한다. **push가 곧바로 운영을 바꾸지는 않는다.**
아직 개발 중인 기능을 자동 공개하지 않으면서 GitHub 검증과 배포 결과물을 일치시키기 위한 구성이다.
GitHub에 Cloudflare 토큰이나 서버 SSH 개인키를 저장하지 않는다. 기존 로컬 gh·Wrangler·SSH 인증과 설치된 Node/Wrangler를 사용한다. 인증 토큰은 공식 API 요청에만 전달하고 출력·배포 기록에 저장하지 않는다.

## 배포

2026-10-01 확인: 이전 main 실행은 결제 실패 또는 지출 한도 문제로 job 시작 전에 차단된 기록이 있었다.
새 PR 실행은 정상 시작했다. 결제 설정을 변경하지 않았다. 향후 CI를 실행할 수 없을 때에는
아래 **로컬 검증 경로**를 사용할 수 있으며 이를 GitHub Actions 통과로 표시하지 않는다.
기존 Analyze/Format/Tests를 Release 하나로 통합해 같은 테스트와 빌드를 중복 실행하지 않는다.

1. 완료한 변경을 커밋하고 `main`에 반영한다. 해당 커밋의 iwinv 백엔드를 먼저 배포한다. 실행 중 이미지의 `org.opencontainers.image.revision`은 프런트 산출물의 전체 40자리 커밋 SHA와 정확히 일치해야 한다.
2. GitHub Actions의 **Release**가 성공한 실행 ID를 확인한다.
3. 저장소 루트에서 실행한다 (Python 3.12 이상, gh, 기존 Node/Wrangler와 SSH 인증 필요). 동일 커밋의 깨끗한 main 체크아웃에서 실행한다.

   ```bash
   python3 scripts/release.py status
   gh run list --workflow release.yml --branch main
   python3 scripts/release.py deploy --run <성공한-실행-ID>
   ```

배포 도구는 현재 main의 성공한 Release만 허용한다. 산출물 커밋·파일 체크섬과 깨끗한 main을 확인하고,
`prepare_cloudflare_web.py`로 같은 커밋의 Worker·라우트·헤더를 포함해 패키징한다.
`.vercel/output/static`은 기존 산출물 디렉터리 이름이며 Vercel 배포를 뜻하지 않는다.

운영 백엔드의 정확한 revision을 확인한 뒤 별도 Pages 미리보기 브랜치에 업로드한다.
SHA4(`main.dart.js`, `index.html`, `release.json`, `flutter_bootstrap.js`), 공개 기업 API,
비로그인 개인 API 401을 검사한다. 검증 요청의 Origin·Cache-Control·User-Agent도 유지한다.
main·운영 배포·백엔드 이미지/revision·검증 패키지가 바뀌면 운영 업로드를 중단한다.
Pages 미리보기는 promote 대상이 아니므로 검증한 동일 패키지를 production에 다시 업로드한다.
업로드 직전에도 backend revision==artifact commit을 재확인하고,
업로드 후 immutable 주소와 `alfinder.kr` 모두에서 같은 검사를 수행한다.
이 검사는 HTTP/파일/API smoke 검사이며 새 화면의 실제 브라우저 조작 검증을 대신하지 않는다.

- `https://alfinder.kr/release.json`: 실제 배포한 Git 커밋, 트리, GitHub 실행 ID, 앱 SHA256
- GitHub Deployments의 `production-web`: 배포 커밋·이전 배포·실행 링크
- `output/releases/<미리보기-deployment-ID>.json`: 운영 변경 전에 저장하는 production ID·URL·SHA4·백엔드, 미리보기와 패키지 해시 및 복구 기록 (gitignore 대상)

운영 반영 후 기능 변경에 맞는 데스크톱/모바일 흐름을 브라우저로 확인한다.
직접 `flutter build` 후 기존 `prepare_public_web.py`만 실행한 결과는 검증된 릴리스로 간주하지 않는다.
`release_bundle.py`는 Release CI에서 빌드 직후 호출한다. 더러운 작업 트리는 봉인할 수 없다.

### GitHub Actions를 실행할 수 없을 때

```bash
python3 scripts/release.py build-local
python3 scripts/release.py deploy --local output/releases/local-<전체-main-SHA>
```

`build-local`은 GitHub의 main을 임시 폴더에 새로 clone하고 정확한 SHA를 확인한다.
개발 폴더의 미커밋 파일을 가져오지 않는다. CI와 같은 `verify_release.sh`를 실행하고,
성공 시에만 결과물·검증 로그 해시를 보존하고 GitHub 커밋 상태 `release/local`을 성공으로 기록한다.
로그는 `output/releases/local-<SHA>.log`이며 공개 `release.json`에는 `verification: local`이 표시된다.
로컬 검증은 GitHub Actions 실행 성공과 다르다. 운영 배포 전 main이 바뀌면 새 커밋을 다시 검증한다.
Flutter 3.47.5와 Python 3.12 이상이 설치된 릴리스 맥에서 실행한다.

## 프런트 복구

```bash
python3 scripts/release.py rollback --record output/releases/<배포-ID>.json
```

현재 Cloudflare 계정·프로젝트의 배포 기록만 허용한다. 기록한 production ID가 지금 운영 중인지,
백엔드 이미지·revision이 기록과 같은지 확인한 후 이전 production의 SHA4·공개 API·비로그인 API 401을 검사한다.
검사 도중 운영이나 백엔드가 바뀌지 않았는지 다시 확인하고 공식 Pages rollback API로 이전 production을 복원한다.
새로 빌드하지 않으며 DB와 백엔드는 변경하지 않는다. 복원 후 실제 도메인의 파일/API를 다시 검사한다.

백엔드가 바뀌었으면 자동 복구를 막고 API 호환성을 먼저 확인한다.
이전 production 배포를 삭제하면 복구할 수 없으므로 보존한다. Vercel 기록과 Pages 미리보기는 복구 대상으로 허용하지 않는다.
운영 업로드 결과가 불명확하면 자동 재업로드·롤백하지 않고 실제 현재 deployment ID부터 확인한다.

로컬 기록이 없으면 GitHub Deployments payload에서 이전 production ID·주소·체크섬·백엔드를 조사한다.
이는 바로 롤백할 권한이나 검증된 복구 기록의 대체가 아니다. 실제 현재 상태와 이전 패키지·API 호환성을 확인하고
복구 근거를 보존한 뒤 현재 Cloudflare의 정식 복구 경로를 사용한다.

## 서버 배포와 DB

서버는 프런트와 별개다. Docker 이미지를 GitHub에 올라간 **정확한 커밋의 깨끗한 소스**로 만들고
이미지 태그와 `org.opencontainers.image.revision` 라벨에 전체 커밋 SHA를 넣는다.
예: `--label org.opencontainers.image.revision=<SHA>`.
서버 배포 기록에는 소스 SHA, 이미지 ID, 이전 이미지 ID, 적용한 마이그레이션을 함께 남긴다.
기존 이미지는 새 버전의 정상 동작 확인 전 삭제하지 않는다.

DB 변경은 이미지 복구와 구분한다. 이전 이미지가 새 스키마와 호환되는지 확인해야 하며,
데이터 손실을 일으킬 수 있는 자동 다운 마이그레이션/백업 덮어쓰기는 이 도구에서 수행하지 않는다.
서버 자동 교체나 SSH 방화벽 개방을 이 워크플로가 추가하지 않는다.

## 최초 도입 시 주의

도입 전 배포들은 미커밋 변경을 포함하므로 과거 커밋과 운영 소스의 완전 일치를 소급해서 주장할 수 없다.
현재 운영 기능의 소스를 커밋·검증한 첫 Release 배포부터 정확한 대응이 성립한다.
초기 기준 정리는 업종 기능 개발 작업과 조율해 진행한다.


### 서버 소스가 동일한 UI 전용 배포

기본 배포의 정확한 서버 revision 검사는 유지한다. UI 전용 릴리스는
`deploy --run <ID> --backend-source <운영 서버의 전체 SHA>` (또는 `--local`)로
운영 서버를 유지할 수 있다. 이 옵션은 운영 이미지의 revision이 지정 SHA인지,
그 커밋이 프런트 커밋의 조상인지, 서버·생성 클라이언트·deploy/iwinv 소스가 동일한지,
기존 잠금 의존성 항목이 모두 동일한지 확인한다. 새 Flutter 전용 의존성 추가만 허용한다.
배포 기록의 backendSource에 차이를 명시하며, 프런트 커밋과 서버 커밋이 같다고 주장하지 않는다.
업로드 직전 소스 검사와 운영 이미지 불변 검사를 반복한다.
