# digest — 사업의 내용 요약·관계·본문 값을 세션에서 써서 넣는 도구

앱은 AI를 부르지 않는다. 요약(`BusinessDigestSection`)·관계(`OntologyRelation` 초안)·본문 값(`DocumentFact`)은
세션(사람 또는 모델)이 본문을 읽고 써서 서버 API로 넣는다. 매일 00:05에 본문이 300건씩 오므로 이 순서로 돈다.

```
python3 tool/digest/pending.py --out /tmp/dw          # 1. 요약 없는 본문을 시가총액 큰 순으로 덤프 (doc_<id>.txt, pending.tsv)
#    2. doc_<id>.txt를 읽고 digest_<id>.json (relations_<id>.json, facts_<id>.json) 을 같은 폴더에 쓴다
python3 tool/digest/submit.py --dir /tmp/dw --dry-run # 3. 근거가 원문에 글자 그대로 있는지 먼저 확인
python3 tool/digest/submit.py --dir /tmp/dw           # 4. 넣는다 (보낸 파일은 .sent 로 이름이 바뀐다)
python3 tool/digest_audit/digest_audit.py             # 5. 요약 속 매출·이익 숫자를 재무제표와 검산
```

파일 모양은 `submit.py` 머리말에 있다. 규칙:

- 근거(`evidence`)는 원문 **한 줄 그대로** — 표 줄이 가장 안전하다. 없으면 그 절은 버려진다.
- 숫자는 "234조 9,034억"처럼 쓰고, 그 보고서에 적힌 값만 쓴다 (전기 값도 그 보고서의 전기 칸). 부문·자회사 값이면 그렇다고 적는다.
- 요약은 문서당 한 번에 — 절 하나만 고쳐도 절 전부를 다시 보낸다. 본문 값도 같다.
- 관계는 초안으로 들어간다. 원문을 읽고 확실한 것은 `review.decideMany`로 승인하고 `review.recordCheck`에 몇 건 중 몇 건이 맞았는지 남긴다.
