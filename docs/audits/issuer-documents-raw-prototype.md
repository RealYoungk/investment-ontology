# 투자회사 공식 원문 메타데이터 프로토타입

기준9092e75b. ResearchSnapshot의 immutable payload/source/digest 계약을 재사용한다. 새 모델/DTO/마이그레이션은 없다. 기존 FinancialReport, BusinessDocument, DartFiling, 재무지표, 정기자료 coverage에 기록하지 않는다.

## 허용 범위

issuerDocuments JSON 한 배치는 검증 대상3펀드 중 회사1곳의1~100개 메타데이터 행이다. 실제표제/문서종류/명시표지기간/게시일/공식PDF URL/SHA/인쇄인용을보존하며 숫자는notExtracted/null, 공개는linkOnly다. KIND providerReceipt와providerDocumentId는독립항목이고DART접수로승격하지않는다. 현재DART provider는허용하지않는다. 원문자료사실확인과공개재배포허가는다르므로 importFeed의권리reference는 `official-links-metadata-only;no-redistribution-license-asserted` 만허용한다. 이는라이선스주장이아니다.

## 입력 증거의 한계

Dart validator는메타데이터형식/회사별공식host/date/중복/SHA형식/숫자null만검증한다. JSONSHA가실제PDF와같은지또는원문기간이메타데이터와같은지 온라인재검증하는PDF parser가아니다. 정상관리자입력이라는기존auth계약을유지하되 이메타데이터를자동검증재무자료라고표시하면안된다.

별도offline prepare_cache.py는원본PDF SHA·매직헤더·미리추출한text의issuer/period exactquotes를대조하고SHA파일명으로불변내부cache에만보존한다. 신규네트워크수집/서버자산배포/공식corp별온라인proof/검증된증거서명은아직연결하지않았다. cache-dir은공개웹assets가아닌서버내부경로로deployment시지정한다. pdftotext결과의진실성/metadataperiod-quote의의미대조는현재sourceledger의실제읽기감사범위다. 이도구출력이숫자검증완료를의미하지않는다.

## 실제기간 자료

root outputs/filing-collection-priority/unidentified-periodic-readonly-20261002/alternative-reports-and-listing-review/history/mapps-five-annual-ledger.json 에2021~2025PDF URL/SHA/실제각표지기간을보존했다. 제15~19기각Jan1..Dec31이고최신20기2026Jan1..Jun30은회계기간변경강조사항있다. 2021표지에관리자인미래에셋자산운용도별도인쇄되므로issuer는보고서제목/감사의견대상투자회사로검증해야한다.

맥쿼리 2021~2025 감사보고서 PDF 5개도 공식 검색 목록에서 확보했다. 각 표지의 투자회사명과 Jan1~Dec31을 확인했으며, 2021~2023의 추출 글꼴 문제는 표지 PNG 직접 읽기로 확인했다. `history/mkif-five-annual-ledger.json`에 URL/SHA/실제 기간을 보존한다.

KB발해는 2024·2025 감사보고서 2개를 공식 공고의 PDF 링크에서 확보하고 실제 표지를 확인했다. 공식 공고가 연결한 KIND 접수는 각각 20250207001315, 20260130001376이며 DART 접수로 간주하지 않는다. 2024 주석은 2006-01-24 설립, 2024-11-29 상장을 직접 명시하고 감사의견은 2023 비교 재무제표도 감사 대상으로 명시한다. 따라서 2021~2023 자체 연간 PDF를 아직 얻지 못한 것을 회사 설립 전 또는 원문 부재로 해석하지 않는다. 현재 공식 홈페이지 감사보고서 분류는 2건만 반환했고 이전 3개 원문은 미확보 상태다.

세 회사 5개년 연간 PDF는 현재 12/15개이며, 최신 2026 원문은 별도로 보존한다. 맵스 최신 감사보고서는 6개월이고 맥쿼리·KB 최신 운용보고서는 3개월이다. 숫자 추출·DB 저장·재무 완료는 모두 별도 단계다. `history/three-fund-five-fiscal-status.json`이 이 구분을 기록한다.

## 검증

순수Dart unit20 PASS(issuerDocuments17+기존feed3), scoped analyze0. 명시기본port443 Uri정규화경계는rawauthority검사로거부한다. wrongcompanyhost/credential/query/날짜모순/미래/임의숫자/annual가짜필드/원문재배포/IR접수추정/중복거부. DB테스트0, import/운영반영0, 금융·기존수집변경0. 아직비배포프로토타입이다.
