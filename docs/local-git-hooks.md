# 로컬 Git 훅

설치: `python3 scripts/install_git_hooks.py`

pre-commit은 `git diff --cached --check`와 스테이징된 수동 작성 Dart 파일의 포맷을 검사한다. 임시 폴더에서 인덱스 내용을 읽어 검사하므로 부분 스테이징과 작업 중인 미커밋 파일을 섞지 않고, 파일을 자동 수정하거나 추가로 스테이징하지 않는다. 생성 코드는 기존 릴리스 포맷 검사와 동일하게 제외한다. Dart와 Python 3가 PATH에 있어야 한다.

설치는 이 저장소의 로컬 core.hooksPath에 절대 경로를 설정하므로 연결된 worktree에서도 같은 훅을 사용한다. 기존 훅 설정을 발견하면 덮어쓰지 않는다. 새 clone에서는 설치 명령을 다시 실행한다.

pre-push는 실제 푸시할 커밋을 임시 clone으로 체크아웃하고 정적 분석·변경 영역 테스트를 실행한다. Flutter 변경은 Flutter 전체 테스트, 기업 검색은 검색·생성 코드·기업 엔드포인트·시가총액 목록 테스트를 실행한다. 그 밖의 서버 변경은 안전한 범위를 추정하지 않고 서버 패키지 전체 테스트를 실행한다. 결제 변경에는 브라우저 결제 검사도 추가한다. 삭제만 하는 푸시는 건너뛰며 실패한 검사는 푸시를 막는다. 검사 결과는 `output/local-checks/<SHA>.json`에 저장한다. 새 브랜치의 비교 기준은 로컬 `origin/main`과의 공통 조상이고, 기존 원격 커밋을 로컬에서 찾을 수 없으면 전체 소스로 검증한다. 전체 테스트·브라우저 검사·웹 빌드는 `python3 scripts/release.py build-local`로 커밋된 main의 깨끗한 복사본에서 실행한다. 커밋 훅의 성공은 전체 릴리스 검증 성공을 의미하지 않는다. 전체 검증을 수동으로 강제하려면 Git pre-push 형식의 ref 입력을 `python3 scripts/check_push.py --full`에 전달한다. 검사 대상 커밋을 임시 clone에서 실행하므로 미커밋 작업을 가져오지 않는다.

해제: `git config --local --unset core.hooksPath`
