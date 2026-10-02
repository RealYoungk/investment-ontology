# 서버 전체 테스트의 컴파일 임시파일 보유량 제한

CI 9e135ca8의 `/private/tmp/io-source-9e135ca8-ci-failed.log`는 테스트 2,031개 통과 뒤 25개 suite load failure와 `No space left on device`를 기록했다. 개별 테스트 논리 실패와 컴파일 파일을 만들 수 없는 실패를 구분한다.

기본 `bash scripts/test-server.sh`는 모든 `test/**/*_test.dart`를 25개 파일씩 순차 `dart test` 프로세스로 실행한다. 기본 Dart 동시성/설정/태그는 바꾸지 않는다. 각 프로세스가 종료된 뒤 다음을 실행하여 해당 runner가 소유한 컴파일 임시파일의 수명을 한 묶음으로 제한한다. 임시파일 삭제 명령이나 Docker는 추가하지 않았다. 기존 Serverpod embedded PostgreSQL 설정을 그대로 사용하며 묶음 프로세스끼리 동시 실행하지 않는다.

추적 파일 목록과 실제 디스크 탐색 결과를 대조한다. 누락된 추적 파일·빈 추적 목록·git/find 실패는 실패로 끝난다. 새 untracked 테스트도 실행하며 공백 포함 경로를 NUL로 보존한다. 한 묶음 실패는 즉시 전체 실패로 반환한다. 인자가 있는 focused 실행은 기존 `exec dart test "$@"`를 그대로 사용한다. 현재 기준 추적 테스트 파일은235개로10묶음이다.

검증: `bash -n scripts/test-server.sh`, `python3 scripts/test_server_script_test.py` 5개 PASS. 모의 Dart가 호출 인자만 기록하여 전체 파일 union/중복0/25개 상한/focused전달/실패중단/파일누락/빈전체 gate를 확인했다. 실제 Dart·DB·전체 CI를 실행하지 않았으므로 peak disk 감소나 CI 완주시간을 실측했다고 주장하지 않는다.

Release workflow 제한45분을90분으로 늘리는 것을 권장한다. runner 재시작10회와 컴파일·embedded DB 초기화 비용이 늘고 기존 gate가 disk 오류로 완주하지 못했으므로 보수적인 여유가 필요하다. 90분은 측정한 소요시간이 아니며 이번 후보는 workflow를 편집하지 않았다. 배치별 시간/디스크는 다음 CI에서 확인한다. 개별 한 파일이25개 묶음보다 큰 경우까지 해결한다는 보장은 없다.
