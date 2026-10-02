# CP·코스텍 원문 캐시 1회 재검증

선행 의존은 e0621664이다. 신규 exact receipt/FY2022/OFS 2개에만 적용하며 CP·코스텍 숫자/매출 null 파서 규칙을 확대하지 않는다.

## 패키지와 신원 증거

assets/financial_source_cache/20230315000997-ofs 및 20230308000311-ofs의 manifest 바이트 SHA를 컴파일 registry에 고정했다. shell/cover/OFS/overview 4개 원문 각각의 실제 공식 URI 및 SHA를 기록한다. 회사개요는 I.회사의개요 원문 자체이며 cover에 문자열을 덧붙이지 않는다. 정상 PublicFinancialHtmlFetcher가 own shell 법인·접수·dcm·노드, 표지 actual기간·당시 이름과 회사개요 단일 직접 명칭을 재검증한다. 모든 숫자/계정은 기존 정상 파서와 저장 경로를 사용한다.

requiresIssuerOverview의 기본값은 false이다. 기존17개 registry 항목은 3문서 검증 그대로이며 이 2개만 4문서 pinned client를 요청할 수 있다. unknown URI/추가문서/중복 label/file/잘못된 SHA/manifest/corp/year/kind/basis는 거부한다. 패키지는 Dockerfile 기존 assets COPY 경로로 함께 배포되고 임의 외부 입력이나 endpoint를 받지 않는다.

publicattempt3인 exact scope만 기존 1회 캐시 단계로 평가한다. 기존 final scope·transaction lock·취소·감사 reference(manifestdigest+receipt+basis+ruleVersion)·공통 최대10/circuit6·admin 정상 job·카운터 보존 경로를 사용한다. GET/API0이다. 성공·실패 감사가 이미 있으면 다시 raw를 읽거나 fact/source를 만들지 않는다. 최신 정정이 있으면 해당 과거 target를 복구하지 않는다.

숫자 Source에는 직접6+매출null 및 부분 핵심6 사유를 유지한다. updated=1은 실제 정상 _store 숫자6 삽입 성공만 의미한다. typed noData나 매출0으로 바꾸지 않는다. basis별 기존 반대 재무보고서/source/facts는 손대지 않는다. 감사의 historicalCompanyIdentity에는 별도 overview 실제 URI/SHA가 그대로 들어간다.

## 검증

- registry 전체 단위271 PASS: 19개 package 및 기존/추가 overview 바이트 음성, 요청 basis·신원·기간·한도·임의 manifest 객체 차단.
- 신규 normaljob DB8 PASS: 두기업 각각 성공/재실행, overview SHA 실패/재실행, 취소, 최신 정정 제외. Source실제값6/null매출+출처·SHA/회사개요audit/summary missingreason/SQL매핑·updated1→0·public3/general7/API20000 불변 확인.
- 반대 CFS는 명시 합성 sentinel Source/report/facts wholeJSON 불변이다. 생산 DB DTO 반출 검증이 아니다.
- 소유 코드/테스트 analyze0 및 format/diffcheck. 운영 SQL·쓰기/API·외부 GET·배포0, DB tearDownAll 완료.
- 기존 전체 registry 공통 cap10/circuit6 DB 테스트의 expected reads/remaining은 문서 수/registry 크기에서 계산하도록 수정했다. 새 전체 suite 실행은 루트 통합 게이트에서 수행한다.

## 통합 경계

부모의 9a3ffb linkedAudit package 2개는 auditShell이라는 별도 4번째 문서를 갖는다. 이 후보는 overview라는 다른 4번째 문서를 갖는다. 통합 시 두 공식 문서 타입을 각각 exact compiled 항목에서 허용하고, 일반17항목의 3문서 규칙을 유지해야 한다. auditShell과 overview를 같은 raw로 바꾸거나 concatenation하지 않는다. 둘 다 동시에 필요한 신규 항목을 임의 허용하지 않는다.
