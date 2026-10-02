# Three exact CFS nonapplicability literals

This change adds only complete pure-body matches under the existing exact
annual shell-corp/receipt/cover/company/period/requested-CFS/dcm guards:

- `당사는 사업보고서 제출일 현재 해당사항이 없습니다.`
- `공시서류작성기준일 현재 해당사항이 없습니다.`
- `해당사항이 없습니다.`

Any table, script/style, numeric content, conditional/attachment-reference
extra text or different heading remains a normal guarded failure. Successful
matches produce a typed PublicFinancialHtmlBasisNotApplicable exception,
containing exact raw evidence, cover/statement URLs and combined SHA. Normal
ingest saves a nonapplicability Source audit and CFS noData, never money rows.
Existing OFS report/facts/Source remain unchanged.

Five primary fixtures were retrieved and individually inspected previously:
켈스01507722/20260318001370, 바스칸00533809/20260318000161,
제노텍00393618/20260313000656, SR바이오01187458/20260316001089,
코셋00965062/20260309001126. Each declares annual2025.01.01..12.31,
with unique ownCorp/exactreceipt/same document CFS+cover nodes. proof.json
preserves URLs/SHA; official body HTML is unchanged. The first three share the
first literal, the remaining two print the other two literals respectively.

Finite priority applies only these receipts, exact corp/annual FY2025.12,
requested CFS and public attempts below3. Stored/unsupported/completed public
noData gets no priority. No attempt resets. Historical24 same-company
candidates remain unread and are not marked completed by this proof.

No additional source GET, OpenDART API call or production DB write was made.
Tests use mock transport and isolated admin-authenticated embedded DB only.
