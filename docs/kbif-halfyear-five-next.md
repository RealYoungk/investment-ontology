# KB발해인프라 실제 상반기 재무실적 일부

공식 notice 168의 실제 첨부 PDF를 UI에서 찾아 원문을 확보했다. metadata receipt는 null인 officialIR이다. notice의 KIND 연결 receipt20260731001251을 다른 DART 정기보고서 receipt로 가장하지 않는다.

현재 page13 자산1,008,537·부채167,166·자본841,371, page15 **회계상** 운용수익34,397·회계적 당기순이익26,771 (모두 백만원)을 현재 인쇄 열에서 추출한다. 지표 precision은 백만원이며 저장 정수는 원 환산이다. 회계NI는 세무상 분배가능이익39,930과 다르다. page14는 Q2이므로 제외한다. 현재 BS 총괄 identity와 PL 수익−인쇄비용−NI는0이다.

page15의 `(분기 비교)` 괄호는 상반기 설명·열과 불일치하며 원문을 수정하지 않는다. page13 자산 세부합은 총계보다1백만원 높다. 해당 잔차를 수치로 보정하거나 반올림 허용하지 않는다. details/notes/fullstatement flags는false이며 direct5만 제공한다.

원문에 own 감사상태나 연결/별도 표시를 확인하지 못했으므로 basis=ownFund, auditStatus=notExtracted. 영업이익·자본변동표·현금흐름표·유형자산 취득은 null+미확보 사유. 정기반기보고서/전체 API완료/TTM에 포함하지 않는다.

기존 KB 자산운용보고서 latest manifest 항목만 실제 금융실적 source로 교체한다. 과거 metadata·privatecache·DBSource는 보존한다. 정상 issuerDocuments→issuerFinancials→공개 읽기 경로이며 FinancialReport/FinancialFact/DartFiling 합성은 없다.

DB4case는 작성만 했고 parent의 DB독점 때문에 미실행이다. 순수 정상경로와 원문 변조 거절·UI·모든 변경 Dart static checks 결과는 원장 로그에 보존한다. 전체 재무 데이터 완료 주장은 하지 않는다.
