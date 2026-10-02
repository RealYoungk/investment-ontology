# 정정 공시 원접수·감사첨부 후보 패키지

이 자료는 공통 저장 경로 연결 전의 불변 원문 후보다. 운영 수집 완료, 활성 registry 등록 또는 정상 저장 검증 결과로 계산하지 않는다. HTTP/API/DB를 사용하지 않는 바이트 검증만 포함한다.

## 확인 범위

- 숫자 13 basis: 원접수 본문 11개는 기존 엄격한 기본 파서에서 직접 핵심 7~8행을 추출했고, 동일 회사·기간 감사첨부의 직접 당기값과 BS/CE를 개별 대조했다.
- 감사첨부 전용 2 basis: 유엑스엔 FY2021 OFS와 이노벡스 FY2021 OFS는 직접 감사 표의 전체 핵심 7행과 CE를 확인했으나 정상 파서 감사 경로 연결은 아직 필요하다.
- 짝인 CFS 5개는 원접수 본문의 명시 비작성 문구가 실제 확인된 자료다. 숫자 자료 부재나 API noData로 추정한 자료가 아니다.
- 다중 family 관계가 아직 단일하게 증명되지 않은 메디안 2 basis와 지엔이 1 basis는 제외했다. 법인명 증명이 추가로 필요한 별도 후보와 은행 6행도 제외했다.

## 원접수 보존

`targetReceipt`는 정정 공시, `originalReceipt`는 공식 family가 직접 명시한 사업보고서 원접수다. 숫자 출처는 `numericSourceReceipt`로 별도 기록한다. 특히 이노벡스 표지는 20220321000630이고 정정 감사 숫자는 20220328000884다. 숫자 접수번호를 표지 접수번호로 덮어쓰지 않는다.

숫자 패키지는 targetShell/originalShell/cover/primary/auditShell/audit 6개 원문을 보존한다. 명시 비작성 패키지는 첫 4개를 보존한다. URL은 공식 HTTPS DART 원문 URL이고, 각 파일 SHA256과 manifest SHA256을 보존한다. 예상 행은 원문에 인쇄된 계정명과 당기값을 유지하며 account_id는 null이다.

## 검증과 남은 연결

`python3 scripts/audit/test_header18_packages.py`는 18개 원문 바이트, 인덱스 법인·접수·basis·연도·SHA 변경 거부, 이노벡스 접수 분리를 검증한다. 이는 실제 source-proof 파서 및 normaljob 저장 회귀를 대체하지 않는다. 공통 LinkedCorrectionAuditSource/cache/sync 담당자의 exact profile 계약에 맞춰 독립 원문 증명을 연결한 뒤 정상 저장·반대 basis 보존·재실행·취소 검증이 필요하다.

근거 원장: `outputs/filing-collection-priority/header-api18-post154-readonly-20261003/basis-review-ledger.json`. 본문 검토는 표지·직접 당기 열·BS/CIS/CF·whole CE·단위·회사 범위다. 전체 감사 주석을 읽었다고 주장하지 않는다.

## 활성 연결 후보와 격리 검증

후속 구현에서 registry에 신규 18 basis를 연결했다. 11개 원접수 primary는 `header18-linked-direct-whole-v1`의 독립 원문 helper를 통해 기존 strict fetch/parser를 그대로 사용한다. 정정 감사 raw/SHA와 고정된 직접 인쇄 행을 대조하며, 숫자는 원접수의 실제 본문에서 추출한다. 감사 전용 유엑스엔·이노벡스 2개는 same-receipt audit parser의 엄격한 전체 7/8행과 독립 whole CE 검증을 사용한다. 이노벡스 표지만 원접수이고 숫자·Source receipt는 정정 접수다.

- 신규 원문 순수 검증: 28 PASS. 법인·접수·연도·각 문서 바이트/SHA 변경 거부를 포함한다.
- 활성 registry/cache 신규18 양성: 18 PASS.
- 정상 admin 수집 작업의 격리 DB: 18 PASS. API 예산 0·공개 시도 3·일반 시도 7 상태에서 불변 원문을 한 번 검증하고, 실제 숫자13/명시 비작성5를 구분했다. 네트워크/API 호출은 0이다.
- 실제 숫자 report/source/fact는 원접수 또는 정정 감사의 정확한 numericSourceReceipt와 원문 URI·combined SHA를 가진다. 직접 7/8행·당기 summary·SQL 계정 분류를 대조했다.
- 같은 target 재실행은 job.updated=0, 추가 asset 읽기 0이며 기존 opposite-basis report/Source/facts JSON은 불변이다. 공개 DTO가 없는 기존 반대 basis는 명시적으로 합성한 보존 sentinel이며 운영 DB 전체 payload를 검증했다고 주장하지 않는다.
- numeric 패키지의 읽기 수는 manifest 1 + raw 6 + 직접 기대 행 1 = 8이다. 명시 비작성은 manifest 1 + raw 4 = 5다.
- 기존 Sun/Bon 원접수·정정 비교 순수 회귀 14 PASS. 기존 3개 whole CE proof mode는 유지하고 새 감사2만 새 mode를 사용한다.

운영 배포 또는 운영 수집 완료를 의미하지 않는다. cap3·max10·실패6·일회 감사·최종 financial scope·취소·동일 transaction 저장은 기존 공통 정상 수집 경로를 유지한다. 다중 family 미증명 3 basis와 별도 법인명 미증명·숫자 충돌 자료는 등록하지 않았다.
