# 지앤이 own 감사문서 후보

대상은 법인 01188749 / 접수 20260429001010 / FY2025 / OFS 한 건이다. 이전 사업보고서 20260429000962를 숫자 원접수로 가정하지 않는다. target 자체 감사표지와 첨부재무표, target shell의 own 법인코드를 검증한다.

새 독립 `GneOwnAuditSource.parse`는 exact URI·3개 raw SHA·법인·접수·연간 시작/끝·OFS를 먼저 검증한다. source 변경은 같은 URI여도 거부한다. 원문 자체는 변경하지 않는다. 원문 직접 primary table 6/9/15의 현재열 2에서 whole7만 반환한다. BS/CIS/CE/CF 표마다 직접 제12기·완전한 현재기간·회사명·원단위를 확인한다. CE table12의 당기초/기말/전체순익 고유행과 총계열, BS 자산=부채+자본을 교차 확인한다. XBRL ID는 null이며 인쇄 계정명과 금액이 그대로 남는다. 연결자료 비적용을 추정하지 않는다.

실제 direct7: 자산6,973,822,992 / 부채2,274,518,676 / 자본4,699,304,316 / 매출4,896,995,158 / 영업이익371,658,968 / 순이익377,901,260 / 영업현금흐름701,750,215원. CE 당기순익377,901,260·기말자본4,699,304,316원과 일치한다. optional CAPEX 합산/0추정은 하지 않는다.

검증: 실제 양성1+출처/접수/법인/basis/기간/dcm/단위/1원/parent순익/CE 변조 음성11 = 12 순수 테스트 통과, 변경 helper/test analyze0, format 완료. DB/정상queue/cache/Source 저장은 아직 검증하지 않았다. runtime 연결·registry 등록도 아직 없다. 첫189 릴리스 뒤 후속 cohort 후보로만 준비했으며 기존 일반 annual cover 정책은 변경하지 않았다.

raw는 test/fixtures/financial_html/gne-own-audit/{shell,cover,statement}.html에 byte 그대로 보존했다. 공식 URL·SHA는 helper의 const에 기록된다. source 실제접수는 항상20260429001010이다.
