# 최신 FY2025 CFS 비적용 10건과 완료 진전 재개

공식 shell, 표지, 요청 CFS 본문을 각 3회씩 총 30회 공개 GET으로 확인했다. API/운영 SQL/데이터 쓰기 없이 확인한 원문이며 fixture의 proof.json에 정확 URI와 SHA를 보존했다. 표지는 모두 2025.01.01~12.31, shell 법인코드와 ownreceipt, 표지/CFS 동일 dcm을 확인했다.

10개 모두 CFS 본문에는 표와 숫자가 없는 한 문장 비적용 선언만 있다. 요청 영역에 BS/CIS/CF/CE가 없으므로 7계정이나 0을 만들지 않는다. OFS 저장 상태는 기존 inventory 스냅샷이며 여기서 OFS 실제 숫자를 재감사하지 않았다.

새 문구는 유비씨의 `당사는 보고서 작성기준일 현재 해당사항 없습니다.`, 유엑스엔의 `당사는 사업보고서 작성 기준일 현재 해당사항이 없습니다.`, 로지스몬의 `당사는 연결재무제표 대상 법인이 아닙니다.`만 정확 허용한다. 전체 body가 요청 CFS 제목과 해당 한 문장으로만 구성되어야 한다. 주석/참조/조건/복수 문장/표/숫자/script/style/다른 절은 거절한다. 표지 법인/기간과 URI 경계는 기존 guard를 유지한다.

이미 지원한 나머지 7개도 신규 exact receipt/corp/FY2025/CFS priority로 연결한다. priority는 실제 미완료 상태와 publicattempt<3에만 적용한다. 감사 스냅샷은 모두 attempt2이며 카운터 초기화, cap 확대, immutable cache 추가는 없다. 이후 cap3에 도달하면 이 priority만으로 재실행하지 않는다.

비적용은 정상 typed Source 감사 후 해당 CFS만 noData로 저장한다. 숫자 저장 집계 job.updated는 0이다. 실제 소스 검증으로 batch를 무실패 완료했고 잔여 후보가 있으면 예약 직전 시각 기준 30초 후 재개한다. 실패만 있는 batch는 15분을 유지한다. 이번 숫자 저장 또는 이번 처리 무실패만 실패 circuit를 초기화한다. 이전 OFS stored는 이번 CFS 실패를 성공으로 바꾸지 않는다. 최대10/연속실패6/취소/cap3/일일 API hardcap은 그대로다.

DB 회귀의 OFS 자료는 합성 preservation sentinel(자산123/이전100)이며 비공개 운영 DB 원형 반출이나 실금액 검증을 주장하지 않는다. 정상 source fetch/typed audit/CFS 상태, 기존 합성 OFS Source/report/fact 불변, job.updated0, 재개 간격과 실패6 중단을 검증한다. 공식 실제 source 바이트는 unit 및 동일 normaljob의 fetch mock에서 검증한다.

검증: 단위 409건 확인(최초 408 PASS 후 대문자 BODY의 음성 삽입 테스트를 고친 1건 focused PASS), DB 15건 확인(실제10·기존 진전/실패/취소3·비적용 batch1·기존 OFS/CFS 실패 batch1; 실패했던 환경/timeout/일반attempt 기대값 수정 후 해당 focused 재실행). production 코드의 GET 간격은 변경하지 않았다. 합성 batch 10 source 요청은 30초 이상 걸려 해당 테스트 timeout만 2분으로 설정했다. 일반 실패 attempts는 기존 정상 정책대로 한 번 증가하고 publicattempt는 별도로 cap3를 유지한다.
