# 원포유 FY2021 numeric angle-note

정확 원접수20220316000721/corp00337296/dcm8465168의 공식 별도재무제표 fixture/proof에 실제 URL/SHA/owncorp/표지2021.01.01~12.31을 보존한다. 원문 `&lt;주석14&gt;`를 태그 제거 뒤 표시문자로 해독하되 HTML원본/Source SHA는 바꾸지 않는다. 실제계정명 `매출액<주석14>`·`당기순이익<주석13>`·`영업활동으로인한현금흐름<주석15>`는 저장 그대로, 계정 ID는 null이다.

역할 선택만 trailing `<주석[0-9]+>` 한 개를 제거한다. 기존 parenthetical numeric note와 단일 alternation을 공유하여 HTML/Dart/SQL에서 같은 의미를 유지한다. 중간삽입/비숫자/쉼표 angle/닫힘누락/뒤 구성요소/여러 각주를 거부한다. 기존 basis/statement/duplicate/source/actualperiod/단위/wholecore/BS identity 조건은 유지한다.

실제 원값: 자산17467583611=부채8635596196+자본8831987415, 매출8957570370/영업2573692697/whole순익2236521775/CFO3746384242. current header 제24(당)기 논리열1~2(blank+amount), CE2021당기순익2236521775/당기말총자본8831987415를 별도 읽기 감사에서 대조했다. Optional capex를 만들지 않는다. fixture는 전체재무복구가 아닌 핵심7만 검증한다.

normal API0 격리 ingest에서 OFS7 저장, CFS는 이번 fixture 미검증 실패 유지, Source actual receipt/URL/기간 audit 보존, summary 및 screen revenue/CFO 원값 검증. SQL exact suffix mapping과 malformed suffix 거부를 함께 검증한다. 운영쓰기/API/외부GET0. FY2021 NGVI00521433/20220322000487 및 나눔01117422/20220321000166 OFS는 이전 실제7PASS 증거를 근거로 exact finitepriority만 추가하며 retrycounter/maxbatch/publicmax10 변경은 없다.
