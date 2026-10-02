# 공통 부분6 파서의 명시 검증 옵션

기본 `parseStandardAnnual`과 일반 `fetchAnnual`은 필수 매출이 없는 원문을 거부한다. 매출 대시 변형이 공통 6행으로 반환되어 기본 계약을 바꾸던 회귀를 복구했다. 공통 fallback의 `requireWhole`은 명시 옵션이 없으면 true다. 별도 whole7/8 CE 경로의 requireWhole:true는 그대로다.

`allowSourceVerifiedPartialCore` 기본값은 false. 정확 compiled registry의 source-six rule 패키지는 기존 receipt/corp/period/URI/SHA 검증 후에만 true를 전달해 원문 검증 결과를 읽는다. 이 옵션은 저장 승인이 아니며 정상 Sync 저장 거부는 유지된다. BNK/Pureun/IMGT 기존 승인 부분 경로는 수정하지 않았다.

optional-capex 필수 매출 대시 거부, 공통6 명시 양성/기본 거부, 정확 캐시 검증, BNK/Pureun/IMGT 및 whole7/8·CE·기간 회귀 10개 suite 242 PASS. 일반 공개 fetch가 3개 실제 원문을 기본 거부하는 직접 검증도 추가했다. 운영 및 DB 변경 없음. 정상 큐 DB 슬롯은 별도 순서 대기 중이다.
