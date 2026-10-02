# 질경이 FY2022 독립 날짜 제목과 현재기수 열

정확 원접수 20230321000972 / 법인01063556 / CFS / FY2022.01.01~12.31만 지원한다. 공식 shell 법인·ownreceipt·목차에서 관측한 표지와 CFS URI 좌표/dcm/dtd3.xsd는 fixture proof.json에 보존한다. 이번 구현은 기존 cached 원문만 사용했으며 추가 GET/API/운영SQL/데이터쓰기 없이 작성했다.

원문은 현재 날짜를 제목표 `당기말:2022년12월31일현재`(BS), `당기:2022년1월1일부터2022년12월31일까지`(CIS/CE/CF)에 인쇄한다. 현재기수는 별도 금액표의 `제10(당)기` 열에 인쇄한다. 표지의 제10기/실제 기간, 네 재무표별 고유 날짜·회사·원 unit, BS/CF currentcolumn2 colspan2/CIS column2 colspan1, CE whole합계열6·NCI열5·고유현재start/end·현재순손실행을 모두 검증한 뒤 기존 mandatory7/금액원형/BS등식/CE순손실·기말자본 교차검증으로 연결한다. 행합산/지배기업순손실 대체/숫자0추론은 없다.

직접 인쇄된 원 단위 whole7: 자산5,880,929,737 / 부채6,307,895,583 / 자본-426,965,846 / 매출9,091,448,170 / 영업손실-971,045,103 / 당기순손실-1,102,090,301 / 영업CF-872,183,556. CE 전체순손실과 기말자본이 CIS/BS와 각각 일치한다. 현재 지배기업소유주 손실이 우연히 같아도 CIS 전체행과 CE 전체합계열을 사용한다.

FY2023 실제 원접수20240321000985의 명시적 현재기수 충돌은 별도 actual negative fixture로 계속 거절한다. 회사/접수/연도/basis/URI좌표/unit/currentdate/currentheader/whole CE/중복현재 marker와 현재기간 모호성 가드를 넓히지 않는다. source가 달라지면 이 profile은 활성화되지 않는다. report 표지 제출일2022.03.21과 접수연도2023의 차이는 원문대로 보존하며 수정하지 않는다.

정확 CFS receipt/corp/FY2022 priority만 추가한다. cap3/공용10/실패6/일일 API 한도와 기존 OFS를 변경하지 않는다. DB 회귀 작성본의 OFS 자료는 합성 preservation sentinel이며 운영 자료 원형 보존 검증으로 주장하지 않는다. normaljob이 앞단 generic10보다 실제 CFS를 먼저 선택하고 신규 Source/원문SHA/null account_id/직접값/summary/SQL 계정과 기존 합성 OFS 불변을 검증한다. DB 실행은 root 단독 슬롯 승인 이후에만 수행한다.

후보 단위 검증: 질경이21+기존 키움16, 합계37 PASS. 전체 정적 분석/형식 확인 완료. 루트 전체 게이트가 임베디드 DB를 독점 실행하므로 이 후보의 normalqueue DB1은 작성·정적 분석만 완료했으며 아직 실행하지 않았다. Source 정상 저장·summary/SQL·기존 합성 OFS 보존의 런타임 결과는 단독 슬롯 승인 후 별도로 보고한다.
