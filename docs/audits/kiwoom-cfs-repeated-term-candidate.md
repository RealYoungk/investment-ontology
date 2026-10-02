# 키움증권 FY2022 CFS 정확 원문 후보

후속 후보이며 운영반영·실제큐·DB검증은 수행하지 않았다. 기준36d214d3, 공식GET/API/운영쓰기/DB테스트0. 기존 공식cell-span-review 원문을 재사용한다.

원인: 실제 BS/CIS/CE/CF 표제 `제24기 (당)기`가 기존 `제24(당)기` 정규식에 맞지 않는다. CF 당기열도 `제24기(당)기`라 별도 current-header guard에서 거부된다. 표지 사업연도는2022.01.01~12.31/기수24이고, primary BS현재일/CIS·CE·CF전체기간은 실제 해당연도와 일치한다.

변경은 corp00296290/receipt20230320001037/CFS/기수24/표지 dcm9077489 ele1 offset796 length4038/연결statement같은dcm ele17 offset905295 length107240/정확FY2022에서만 중복기 표기와 CF currentheader를 지원한다. 기존 일반 표제/date/company/basis/unit/whole7/BS등식 규칙은 그대로다. 다른 접수·basis·URI·기간·회사에서는 후보 grammar가 활성화되지 않는다.

해당 범위는 CE 직접whole-total 교차검증도 필수다. 2행9열 header의 지배주주6열/비지배1열/전체총계1열을 확인하고 당기초2022.01.01·당기말2022.12.31·그사이당기순이익이 각각유일할 때 마지막 전체총계열을 직접 읽는다. CE 전체순익508,170,326,221=wholeCIS, CE마감자본4,593,093,934,930=BS자본. 지배주주순익507,326,120,051 또는 비지배844,206,170원을 더하거나 대체하지 않는다. CE단위는 실제원만허용. 본 source CE 내부의 숫자없는 명시 caption 세종(총포괄이익/기타포괄손익/자본에인식된주주거래)만 grid 이전제외하므로 genericcellspan상한은확대하지 않는다.

직접계정: 자산48,037,301,112,929/부채43,444,207,177,999/자본4,593,093,934,930/영업수익8,942,353,665,382/영업이익656,424,566,711/whole순익508,170,326,221/영업CF-2,011,805,579,287원. 모두raw인쇄이름/account_id null/단위원/원접수와URI/CFsign 그대로8행(유형자산취득포함). 전체계정복구라고표시하지 않는다.

단위16개(실제positive+기간·기수·회사·원URI·unit·parent/NCI대체·whole행부재·CE열/기간negatives) 및 기존날짜괄호/BSduration/법적명칭회귀 합계53 PASS. 전체서버 analyze0, format/diffcheck PASS. 공시교정·attemptreset·priority·시간예약·할당량 변경0. 다음 실제queue/normalDB 검증은 별도승인 후 수행해야 한다.
