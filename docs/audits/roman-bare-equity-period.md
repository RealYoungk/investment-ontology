# CE 행 번호·명시 기말 날짜 검증

별도 자본변동표의 `V.2021년01월01일(당기초)`, `VI.2021년12월31일(당기말)`처럼 인쇄된 유효 Roman 번호만 날짜 앞 장식으로 인식한다. 순익 `2.당기순이익`은 유효 정수 순번과 정확한 whole 순익 계정명을 분리하며 실제 인쇄명은 증거에 보존한다. bare 기말 날짜는 CE 표제의 완전 당기 시작·종료일과 유일 기초·기말 행이 모두 일치할 때만 허용한다.

명칭·접수·연간기간·각 primary 날짜·단위·직접 전체계정·BS회계식·CE whole순익/자본 검산은 유지한다. 기존 BS-duration 증거는 `primary-bs-duration-equity-corroboration` mode를 보존하고, 새 독립 CE 검증 규칙은 `equityValidationRule`로 기록한다. 검증된 기간을 직접 인쇄하지 않았다고 바꾸어 기록하지 않는다.

실제 태양기계2022(20230322000366) 및 BioTen2022(20231018000215) OFS만 whole7~8 양성으로 immutable cache에 추가했다. 삼성화재2021/2022는 CE 날짜/순익행을 식별하더라도 primary 순익의 두 조정 주석이 현행 지원 범위 밖이어서 전체 핵심계정 거부 유지하며 캐시에 추가하지 않았다. 조정이익을 당기 순익으로 대체하지 않는다.

검증: 공식4원문 및 날짜/whole총계/통화/숫자순번 음성, 기존 BioTen2024 mode 회귀, compiled registry 경계, 정상 큐·cache DB2 PASS. API·attempt·기존 반대basis/Source/숫자 불변, 테스트 PostgreSQL 종료. 운영 변경 없음.
