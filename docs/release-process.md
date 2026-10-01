# GitHub 기준 배포와 복구

## 현재 운영 방식

프런트는 Vercel, Serverpod와 DB는 iwinv에서 운영한다. 호스팅 이전은 하지 않는다.
`main`에 push하면 **Release** 워크플로가 분석·포맷·서버/Flutter 테스트·웹 빌드를 수행하고
커밋별 `web-release-<SHA>` 결과물을 30일간 보관한다. PR도 검증하지만 PR 결과물은 운영 배포할 수 없다.

운영 반영은 아래 배포 명령으로 실행한다. **push가 곧바로 운영을 바꾸지는 않는다.**
아직 개발 중인 기능을 자동 공개하지 않으면서 GitHub 검증과 배포 결과물을 일치시키기 위한 구성이다.
GitHub에 Vercel 토큰이나 서버 SSH 개인키를 저장하지 않는다. 기존 로컬 gh·Vercel·SSH 인증을 사용한다.

## 배포

2026-10-01 확인: 기존 GitHub Actions는 결제 실패 또는 지출 한도 문제로 job 시작 전에 차단됐다.
결제 설정을 변경하지 않았다. 해소 전에는 아래 **로컬 검증 경로**를 사용하며 GitHub CI 통과로 표시하지 않는다.

1. 완료한 변경을 커밋하고 `main`에 반영한다. 배포되지 않은 서버 기능에 의존하는 프런트는 먼저 올리지 않는다.
2. GitHub Actions의 **Release**가 성공한 실행 ID를 확인한다.
3. 저장소 루트에서 실행한다 (Python 3.12 이상, gh, Vercel CLI 필요).

   ```bash
   python3 scripts/release.py status
   gh run list --workflow release.yml --branch main
   python3 scripts/release.py deploy --run <성공한-실행-ID>
   ```

배포 도구는 현재 main의 성공한 Release만 허용한다. GitHub 결과물의 커밋/파일 체크섬을 확인하고,
별도 Vercel 주소에 올린 뒤 HTML·release.json·앱 파일과 공개 조회 API를 검사한다.
검증 도중 main, 운영 배포, 서버 이미지가 바뀌면 운영 전환을 중단한다.
운영 전환 전 복구 기록을 먼저 저장하며, 전환 후 같은 검사를 실제 도메인에 수행한다.
이 검사는 HTTP/파일/API smoke 검사다. 새 화면의 실제 브라우저 조작 검증을 대신하지 않는다.

- `https://alfinder.kr/release.json`: 실제 배포한 Git 커밋, 트리, GitHub 실행 ID, 앱 SHA256
- GitHub Deployments의 `production-web`: 배포 커밋·이전 배포·실행 링크
- `output/releases/dpl_*.json`: 로컬 상세 기록과 복구 정보 (gitignore 대상)

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

기록한 배포가 지금 운영 중인지, 서버 이미지가 그때와 같은지 확인한 후 이전 배포를 사전 검사하고
Vercel 도메인을 이전 배포로 돌린다. 새로 빌드하지 않는다. DB와 서버는 변경하지 않는다.
서버가 바뀌었으면 자동 복구를 막고 API 호환성을 먼저 확인한다.
이전 Vercel 배포가 삭제되면 복구할 수 없으므로 복구 대상 배포를 삭제하지 않는다.

로컬 기록이 없을 때는 GitHub Deployments의 payload에서 이전 배포 ID/주소·체크섬·서버 이미지를
조회할 수 있다. 당시 서버 이미지와 API 호환성을 확인한 뒤 수동 promote한다.

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
