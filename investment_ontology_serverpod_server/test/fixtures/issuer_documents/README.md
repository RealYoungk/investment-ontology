# 실제 공식 원문 fixture

공식 PDF 3개를 비공개 서버 테스트에서만 사용한다. 웹 배포 assets나 공개 다운로드 경로에 넣지 않는다. provider 접수와 문서 ID는 독립적이다. 숫자는 추출하지 않는다. 원문 URL/SHA/명시 기간/다운로드 시각은 assets/issuer_documents/verified_fund_documents.json의 해당 행에 있다.

- mkif-2024.pdf: 맥쿼리 2024.01.01~12.31 감사보고서
- kbif-2024.pdf: 케이비발해 2024.01.01~12.31 감사보고서, 공식 IR 연결 KIND20250207001315
- mapps-2026-half.pdf: 맵스 2026.01.01~06.30 감사보고서. 원문 결산기간 변경을 보존하며 연간 TTM으로 전환하지 않는다.
