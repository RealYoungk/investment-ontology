# KSIC 분류표 추출

`assets/ksic/ksic_10.json`, `ksic_11.json`은 통계청(현 국가데이터처) 고시 첨부 파일에서 추출한 것이다.

| 차수 | 고시 | 첨부 파일 |
|---|---|---|
| 제10차 | [통계청 고시 제2017-13호](https://mods.go.kr/board.es?act=view&bid=107&list_no=358712&mid=a10403040000) | `(고시자료) 총설, 분류 항목표, 분류 항목 명칭 및 내용 설명(9차, 10차 분류 연계표 포함).hwp` |
| 제11차 | [통계청 고시 제2024-2호](https://mods.go.kr/board.es?mid=a10403040000&bid=107&act=view&list_no=428660) | `3.한국표준산업분류 제11차 개정 해설서(신구연계표 포함).hwpx` |

## 다시 만들기

```bash
# 1. 위 고시 페이지에서 첨부 파일을 받는다
# 2. 10차 hwp → 텍스트 (pyhwp)
pip install pyhwp
hwp5txt ksic10.hwp > ksic10.txt
# 3. 추출
python3 build_ksic.py --ksic10-txt ksic10.txt --ksic11-hwpx ksic11.hwpx --out ../../assets/ksic
```

스크립트는 항목 수가 고시 기준(10차 21/77/232/495/1196, 11차 21/77/234/501/1205)과 다르면 실패한다.
