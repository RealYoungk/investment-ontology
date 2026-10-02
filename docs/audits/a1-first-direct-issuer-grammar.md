# 에이원알폼 당시 직접 법인명 문법 후보

기준88f4caa7. corp00614089/접수20260316001360/FY2025/OFS의 공식 표지·회사개요·재무표 raw만 재사용했습니다. URI·SHA는 test/fixtures/financial_html/a1-first-direct/proof.json에 보존합니다. 추가 GET/API/SQL/운영쓰기0입니다.

당시 직접 첫 선언은 "당사의 명칭은 '주식회사 에이원알폼' 이라고 표기합니다. 또한 영문으로는 'A ONE ALFORM CO., LTD.'라 표기합니다."입니다. 현 master 에이원큐브텍을 변경하지 않고 당시 선언명/표지명과 현재명을 별도 evidence로 유지합니다.

기존 유일 naming heading 및 첫 직접 문장 경계 안에서 singlequote+이라고+또한 영문으로는+라 표기합니다 문법만 추가했습니다. 실제 원문은 BR로 한국어와 영문 문장을 나눕니다. 바로 다음 paragraph가 정확한 영문 continuation인 경우에만 두 문장을 함께 검사하며 intervening/history/예정/다른회사 문맥은 거부합니다. 영문명을 한국어로 변환하지 않습니다.

자기corp/receipt·문서좌표·실제365일·표지명·현재whole8(핵심7+유형취득)·원단위·BS/CE 검증은 기존대로 유지합니다. 숫자와 raw label은 직접 원문 값을 보존하고 당시 회사명을 현재 이름으로 덮지 않습니다. 큐 priority·ingest·model·DB 변경0이며 DB 검증은 이 후보 범위에서 실행하지 않았습니다.

검증: A1 직접명칭/실제8행·mock transport·부정경계 및 기존 first5/법적명칭 단위64개 PASS. 분석 오류0·format 변경0·공식 raw4개 SHA 일치·diff check PASS. DB0 대기, 운영·push·PR0.
