# BNK 정확 원문 별도 6계정 부분 수집

대상은 BNK금융지주 corp00858364, 접수20230309000759, 문서9045525,
2022.01.01~12.31 별도 원문 한 건뿐이다. cover/statement URI와 SHA256 및
합친 원문 SHA256이 모두 일치해야 한다. 일반 은행군, 다른 접수, 연결 기준,
다른 인쇄명·단위·기간 또는 일반7계정 필수 정책을 넓히지 않는다.

원문 재무상태표3계정, 전체 손익표 영업이익·당기순이익, 전체 현금흐름표
영업현금흐름을 직접 인쇄 현재열로 수집한다. 자산=부채+자본과 자본변동표
현재 기초+모든 인쇄 변동=기말, 당기순이익=손익표, 기말자본=BS를 확인한다.
자본변동표의 7열은 이 immutable profile 안에서만 해석한다.

전체 손익표에는 aggregate 매출/영업수익 행이 없어 missingRequiredAccounts
=['revenue']를 감사에 남긴다. 이자·수수료·배당 수익을 합산하거나 0을 만들지
않는다. 유형자산취득은 원문에 있지만 이 부분6 프로필에서 수집하지 않아
uncollectedOptionalAccounts=['capex']를 별도로 기록한다. 매출·마진·매출성장률·
FCF는 null이다. 순이익 원값 사용은 정상 TTM기간·basis 조건을 그대로 따른다.

원 인쇄명, null XBRL ID, 원단위/현재셀/표 번호, CE검증 값과 원문 SHA를
Source 감사에 보존하며 Source 제목은 부분6·전체재무제표 아님을 명시한다.
독립 source-duration validator도6행의 고정 계정/금액/identity/period/SHA/CE
증거를 재검증한다. 임의 외부 partial flag나 다른6행으로 기간을 인정하지 않는다.
재시도 우선순위는 exact receipt+corp+OFS, 기존 publicattempt<3 조건을 따르고
attempt/status를 초기화하지 않는다. API0 정규 ingest 회귀에서 OFS만 저장하며
CFS 실패를 보존하고 공용 summary/SQLscreen에 누락항목이 생성되지 않음을 확인한다.
