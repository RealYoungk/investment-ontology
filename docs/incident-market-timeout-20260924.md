# 공개 시장 타임아웃 및 스크리너 초기 조회 · 2026-09-24

## 재현과 원인 범위

사용자 휴대폰 사진은 alfinder.kr/market의 20초 타임아웃이었다. 같은 시점의 정확한 실패 요청은 식별하지 못했다. 운영 재측정에서는 시장 API 로컬 0.02~0.39초, 외부 1~3초였다. 이후 main 기반 신규 배포에서 실제 api-proxy DNS ENOTFOUND / HTTP503 재현. Cloudflare DNS-over-HTTPS는 같은 호스트의 A 레코드 두 개를 정상 반환했다. 따라서 연결 실패 문제와 DB 계산 병목을 각각 검증했으며 사진의 단일 요청 원인을 특정했다고 주장하지 않는다.

## 수정 및 검증

- 프록시: 플랫폼 DNS 전체 3초 제한 후 고정 호스트에 대한 HTTPS DNS fallback(3초). 공유 Promise·60초 캐시 유지. DNS 조회에 사용자 헤더/쿠키/본문 미전송, upstream SNI/TLS 검증 유지, 변경 요청 재전송 없음. 문서: https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/make-api-requests/
- 시장: raw minified 예외 대신 읽을 수 있는 오류와 각 구역 다시 불러오기. 지수/시총 차트의 오류도 더 이상 조용히 숨기지 않음.
- 스크리너: financial_fact 약10,898,830행 전체 스캔 확인. TTM에 필요한 현재 보고서·전년 연간·전년 동기 보고서로 조회 제한. EXPLAIN ANALYZE 기존7838ms / 개선4748ms. 동일 SQL 결과 양방향 EXCEPT ALL 차이0건(2,229개 결과 기업). 전체 결과/계산식 변경 없음.
- 초기 캐시가 없을 때 동시4요청이 계산1개를 공유. 전체 테스트가 동시에 돌던 실제 부하에서는4건 각9.67초, 시장 overview1.40초. 4.7초는 SQL 단독 측정이며 실제 모든 cold 요청의 보장 시간이 아님.
- 서버317/317, Flutter104/104, 정적분석·포맷·release빌드 통과. DNS fallback 동시성·비밀 미전송과 기존 인증전달 테스트2개 통과.
- 운영 승격 후 동시3 API: overview2.05초, industryTreemap2.75초, screen/list(캐시)2.26초 모두200. 운영390px 비로그인 실제 화면에2,756개사·지수·차트 표시 확인. 이미지 output/reports-review/market-recovery-mobile.png.

## 배포와 복구

운영 프런트: main 기반 codex/market-loading-hotfix(PR81). 리포트 PR80은 포함하지 않음.
배포 dpl_tR6TPiYKWjmsHmpMNd8SwPcu9CfE / https://alfinder-research-bok090see-realyoungks-projects.vercel.app 를 alfinder.kr로 promote 완료.
이전 운영 배포 dpl_LoUgfwDFvaUk1RwpTcqFgUjj3EXp 는 보존.
실행 서버에는 동일 성능 수정이 반영됨. DB 스키마/인덱스/데이터 변경 없음.
리포트 검토 링크: https://investment-ontology.tailb7d6da.ts.net/research
맥북 종료/절전/네트워크 단절 및 터널 장애는 여전히 운영 제약이다.
