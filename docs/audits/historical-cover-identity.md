# Receipt-bound historical cover identity

DB증권 20230321001219 OFS만 실제 원문8계정 검증을 통과했다. 현재 명칭 DB증권(주), 2022년 표지 DB금융투자주식회사, 공식 shell corp00115694 및 dcm9083870·접수 동일. 원문 보고기간2022.01.01~12.31. 현행 회사명 입력을 유지하며 parser/fetcher 공유 helper는 exact receipt/corp/basis/end/current/printed name 및 공식 cover URL·SHA256 모두 일치할 때만 인정한다. 다른 보고서나 CFS에는 허용하지 않는다.

각 반환행 html_provenance.historicalCompanyIdentity에 현재명/인쇄옛명/접수/코드/기간/basis/표지SHA/근거가 포함된다. 기존 normal ingestion의 Source audit coreRowProvenance가 이를 그대로 보존한다. 계정명은 인쇄명, account_id는 null, 숫자·원천기간·단위·회계식 검증은 기존과 같다. 전체 재무제표가 아니라 부분 핵심8계정이다.

공식 추가 GET6회/1초 간격으로 iM·DB·LS CFS/OFS 확보. iM 및 LS는 옛 사명 호출에도 core/equality 미충족, DB CFS는 current column ambiguity이므로 지원하지 않는다. 자료없음으로 해석하지 않는다. CompanyChange 이름조회0행은 사명변경 부정근거가 아니다.

새 isolated worktree 상대 database.dataPath .serverpod/test/pgdata 사용. 원본 운영/기존 WT 변경0. 실제 DB8facts·Source감사·FinancialAccounts.summary pick 저장회귀와 negativecorp/receipt/name/date/basis/cover/source 검사. API예산·재시도·priority·기존 fullfacts 불변.
