# FY2024 동일접수 별도 감사첨부 3건 후보

대상은 에피바이오텍01281541/20250318000507, 케이씨산업00366517/20250321001749, 대주이엔티00414540/20250407004206의 OFS다. 모두 같은접수 공식 고유 감사보고서 option을 따른 별도 원문이다. 기존 사업본문의 날짜·기수·단위를 수정하지 않는다. main shell+annual cover+audit shell+전체 감사재무표 4raw의 URI/SHA를 불변 프로필 및 manifest로 보존했다.

정확 FY2024·원접수·법인·basis·좌표·rawSHA만 승인한다. 모든 현재BS/CIS/CF fullperiod·현재기수열·원단위·whole7·BS등식을 기존 parser로 재검증하고, 이3에만 별도 CE의2024기초/기말·whole순손익·기말자본 직접값을 교차검증한다. 에피 영업손실/당기순손실 양수 인쇄는 기존 pure-loss 의미규칙을 재사용하며 raw양수와 CE괄호음수 및 손실명칭을 Source row provenance에 함께 남긴다. 일반 부호·기간·단위 규칙을 확대하지 않는다.

케이씨산업 CFS: `- 당사는 사업보고서 작성기준일 현재 해당사항 없습니다.` 에피 CFS: `당사는 연결재무제표 작성대상 법인이 아니므로 해당사항이 없습니다.` 실제 같은접수 목차로 추가2GET하여 확인했고 기존 엄격 typed 비적용 검증이 통과했다. API noData만으로 CFS 부재를 가정하지 않는다. CFS 추가registry/priority는 넣지 않았다.

격리 DB회귀는 정상public2→3 및 cap3oncecache 각각3개 합계6개를 작성만 했다. 대주는 저장CFS 합성sentinel Source/report/fact 전체JSON 불변을 확인하도록 했고, KC/에피는 실제CFSnoData 상태를 유지하며 가짜숫자보고서를 seed하지 않는다. 합성sentinel은 운영 DB 전체payload 검증이 아니다. 전체큐10/실패6/APIattempt3/publiccap3 불변. DB는 부모 fullgate 독점이라 실행하지 않는다.

원문 증거: outputs/filing-collection-priority/titleperiod-common-rule-three-20261002/same-receipt-audit/ 및 packaged manifest. 정상 수집 저장성공은 DB검증 후 별도 보고해야 한다.

검증: 실제3 감사첨부/손실raw·CE교차/현재기간·법인·basis·SHA 음성/실제2 CFS typednone/mock fetch/정확priority/전체registry 합계657 단위 PASS. 신규DB6 포함 소유파일 analyze0, format8파일0변경, diff-check PASS. DB6 미실행.
