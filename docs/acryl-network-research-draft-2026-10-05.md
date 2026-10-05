# 아크릴 GPU 네트워크 기술 — 공개 전 조사 초안

2026-10-05. 사용자 최종 확인 전이며 공개 콘텐츠 또는 탑픽 선정이 아니다. 기본 웹 검색과 Exa로 후보를 찾고 원천을 읽었다.

## 사용자 관점

아크릴의 GPU 운영 소프트웨어에서 다른 운영 솔루션과 구별되는 네트워크 기술에 주목한다. 의료 AI·피지컬 AI·AX도 언급했지만 이번 조사는 네트워크 기술로 제한한다.

## 찾은 논문

### PeRF: Preemption-enabled RDMA Framework

- USENIX ATC 2024, pp.209–225.
- 저자: Sugi Lee, Mingyu Choi, Ikjun Yeom, Younghoon Kim. 학회 페이지는 염익준의 소속을 Acryl 및 성균관대로 명시한다.
- [학회·논문·발표 링크](https://www.usenix.org/conference/atc24/presentation/lee), [원문 PDF](https://www.usenix.org/system/files/atc24-lee.pdf), [공개 구현](https://github.com/acryl-aaai/perf).
- 여러 이용자가 RDMA 네트워크 카드를 공유할 때 발생하는 성능 간섭을 소프트웨어 선점과 자원 제어로 줄이는 연구다.
- 원문 §5.1: 동일 머신 5대와 100Gbps 스위치, ConnectX-5/6을 사용한다. 비교 대상에는 Justitia 및 하드웨어 격리 방식이 있다.
- 확인 범위: 초록·저자·실험 구성·관련 연구/결론·공개 구현 README. 모든 그림/실험을 재현하거나 논문 전체를 정독한 상태는 아니다.

### Efficient User-Level Multi-Path Utilization in RDMA Networks

- IEEE Access 9 (2021), pp.127619–127629, DOI 10.1109/ACCESS.2021.3110840.
- 저자: Sugi Lee, Yusung Kim, Honguk Woo, Ikjun Yeom.
- [성균관대 논문 기록 및 초록](https://pure.skku.edu/en/publications/efficient-user-level-multi-path-utilization-in-rdma-networks/), [DOI](https://doi.org/10.1109/ACCESS.2021.3110840).
- 하나의 흐름을 여러 하위 흐름으로 나눠 경로를 활용하고 혼잡·장애에 대응하는 UL-MPRDMA를 제안한다. 초록에 상용 RDMA NIC 기반 시험이 기술되어 있다.
- 확인 범위: 대학 공식 기록·초록. 이 논문의 전체 원문 실험조건은 아직 검토하지 않았다.

## 제품과 연결하는 근거

[회사 제품 페이지](https://www.acryl.ai/product)는 GPUBASE의 네트워크 기능과 두 논문을 함께 제시한다. 기본 웹 읽기는 403으로 실패했고 Exa fetch로 내용을 읽었다. 추출 페이지에 명확한 갱신일이 없어 제품의 최신 구현 상태는 별도 확인이 필요하다.

[2026-02-02 회사 게재 CTO 인터뷰](https://www.acryl.ai/insights/215)는 염익준을 CTO로 소개한다. 직함은 해당 자료 시점을 기준으로 쓴다. 과거 IR 자료의 직함과 동일하다고 가정하지 않는다.

## 투자 글에서 구분할 것

- 논문은 네트워크 기술의 실재와 특정 조건의 성능에 관한 근거다. 모든 GPU 운영 업체보다 우월하다는 증거는 아니다.
- PeRF 공개 구현은 NVIDIA Mellanox ConnectX-4/5/6과 수정된 libmlx5를 명시한다. 이 근거만으로 완전한 하드웨어 독립성이나 AMD·국산 NPU 전반의 성능을 입증하지 않는다.
- 기술 성능, 제품 통합, 유료 고객 채택, 매출·마진 기여는 각각 확인한다.
- “효율화 이익의 10%를 매출로 받는다”는 인터뷰 중 사용자가 접했던 소개 내용이다. 계약 또는 공시로 확인하기 전 수익모델 사실로 쓰지 않는다.
- 현 주가·시총·주식 수·수익 추정치를 확인하지 않았으므로 업사이드·목표가격을 계산하지 않는다.

## 다음 콘텐츠 구성 제안

무엇을 하는 회사인가 → GPU 네트워크 병목 → PeRF/멀티패스가 해결하는 문제 → 논문과 제품의 연결 → 경쟁 비교 조건 → 상용 매출 검증 → 관찰할 지표·반증 조건. 사용자 관점은 별도 표시하며, 확정 수치에는 원천과 기준일을 붙인다.
