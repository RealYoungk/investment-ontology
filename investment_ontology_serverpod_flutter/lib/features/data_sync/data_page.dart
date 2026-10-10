import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/ingest_monitor.dart';
import '../../client.dart';
import '../common/formatters.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'widgets/data_reference.dart';
import 'widgets/issuer_documents_status.dart';
import 'widgets/schedule_board.dart';
import 'widgets/ingest_job_row.dart';

/// 데이터: 원천별 수집 상태와 실행 버튼.
class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  @override
  Widget build(BuildContext context) => const PageFrame(
    maxWidth: 1120,
    children: [
      PageHeading(title: '데이터 관리', subtitle: '원천별 확보 범위와 자동 갱신 상태를 확인합니다.'),
      SizedBox(height: AppSpace.xl),
      ScheduleBoard(child: _Coverage()),
      SizedBox(height: AppSpace.xl),
      _CharterCoverage(),
      _CharterCollection(),
    ],
  );
}

class _CharterCoverage extends StatefulWidget {
  const _CharterCoverage();
  @override
  State<_CharterCoverage> createState() => _CharterCoverageState();
}

class _CharterCoverageState extends State<_CharterCoverage> {
  Map<String, dynamic>? _data;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    IngestMonitor.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final value = jsonDecode(
        await client.charter.collectionCoverage(),
      ) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _data = value;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      if (_failed) {
        return ShadButton.raw(
          onPressed: _load,
          variant: ShadButtonVariant.outline,
          child: Text('정관 확보 현황 조회 실패 · 다시 확인'),
        );
      }
      return const ShadProgress(minHeight: 2);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '정관 원문 누적 확보 · ${formatCount(data['storedNotices'] as int)} / ${formatCount(data['expectedNotices'] as int)}건',
            style: context.typo.body(15),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '대상 ${formatCount(data['companies'] as int)}개사 · 비교표 ${formatCount(data['companiesWithComparisons'] as int)}개사 · 공고 없음 ${formatCount(data['companiesWithoutNotice'] as int)}개사 · 미확보 ${formatCount(data['missingNotices'] as int)}건 · 목록 미확인 ${(data['unindexedCompanies'] as List).length}개사',
            style: context.typo.body(13, color: context.colors.textSecondary),
          ),
          Text(
            '${data['fromDate']} ~ ${data['toDate']} 소집공고 기준 · 비교표 미추출은 정관 변경이 없다는 뜻이 아닙니다.',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CharterCollection extends StatelessWidget {
  const _CharterCollection();
  @override
  Widget build(BuildContext context) => IngestJobRow(
    kind: 'charter_notices',
    label: '전체 상장사 정관 변경 · 소집공고 원문',
    action: '전체 수집 · 실패 건 재시도',
    start: () async {
      var job = await client.charter.startCollection();
      while (job.status == IngestStatus.running) {
        final next = await client.charter.advanceCollection();
        if (next == null || next.processed == job.processed) break;
        job = next;
      }
      return job;
    },
  );
}

/// 수집 현황: 층마다 얼마나 받았는지, 오늘 DART 호출, 남은 기간 어림.
class _Coverage extends StatefulWidget {
  const _Coverage();

  @override
  State<_Coverage> createState() => _CoverageState();
}

class _CoverageState extends State<_Coverage> {
  IngestCoverage? _coverage;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    IngestMonitor.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final v = await client.ingest.coverage();
      if (mounted) {
        setState(() {
          _coverage = v;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _coverage;
    final c = context.colors;
    final t = context.typo;
    if (v == null) {
      if (_failed) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ShadAlert.destructive(
              title: Text('수집 현황 조회 실패'),
              description: Text('연결 상태를 확인한 뒤 다시 시도해 주세요.'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ShadButton.outline(
                onPressed: _load,
                child: const Text('다시 시도'),
              ),
            ),
          ],
        );
      }
      return const ShadProgress(minHeight: 2);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadCard(
          width: double.infinity,
          title: const Text('수집 요약'),
          child: LayoutBuilder(
            builder: (context, box) {
              final summaries = [
                _Summary(
                  label: '등록된 상장사',
                  value: formatCount(v.listedCompanies),
                  unit: '개사',
                ),
                _Summary(
                  label: '오늘 DART 호출',
                  value: formatCount(v.dartCallsToday),
                  unit: '/ ${formatCount(v.dartDailyLimit)}회',
                ),
              ];
              if (box.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    summaries[0],
                    const SizedBox(height: AppSpace.lg),
                    summaries[1],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: summaries[0]),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(child: summaries[1]),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        const SectionLabel('수집 데이터', accent: true),
        const SizedBox(height: AppSpace.md),
        _Dataset(
          dataset: 'company',
          title: '기업 기본정보',
          source: 'DART 기업개황',

          data: '기업명·종목코드·법인번호·업종·대표자·주소 등. 기업 검색과 업종 분류에 사용합니다.',
          scope:
              '등록된 상장사 ${formatCount(v.listedCompanies)}개사 · 원천 상장사 목록 대비 완전성은 별도 집계하지 않습니다.',
          detail: '매일 08:30에 새 기업과 DART 변경일이 바뀐 기업을 수집하고, 30일마다 전체를 다시 받습니다. 신규 상장사는 DART 목록에 반영된 뒤 자동 등록됩니다. 업종 이름은 공식 KSIC 분류 자료를 사용합니다.',
          children: [
            _Summary(
              label: 'DB에 등록된 기업',
              value: formatCount(v.listedCompanies),
              unit: '개사',
            ),
          ],
        ),
        _Dataset(
          dataset: 'financial',
          details: FinancialCollectionStatus(coverage: v),
          title: '재무제표',
          source: 'DART 재무 API · 공시 원문 보완',
          data: '사업·반기·분기보고서의 연결·별도 계정과 금액을 수집합니다. API 기간이 어긋난 보고서는 원문의 검증된 핵심 계정으로 보완하며, 부분 자료와 미확보 계정은 출처에 기록합니다.',
          scope: '기업별 최근 5개년 연간 사업보고서와 그 이후 최신 분기·반기보고서 한 건을 수집합니다. 과거 분기·반기와 10년 자동 확대는 대상에서 제외합니다.',
          detail: '매일 18:30 수집. 호출 한도에 도달하면 다음 날 00:10에 재개합니다. 보고서 처리 완료는 연결·별도에 더 이상 대기가 없다는 뜻이며, 모든 계정이나 두 재무 기준이 존재한다는 뜻은 아닙니다.',
          children: [
            _Progress(
              label: '재무 자료 보유 기업',
              done: v.companiesWithFinancials,
              total: v.listedCompanies,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Progress(
                  label: '대상 보고서 처리',
                  done: v.filingsTotal - v.filingsPending,
                  total: v.filingsTotal,
                  note:
                      '미완료(대기·실패) ${formatCount(v.filingsPending)}건 · 연간 5개년과 최신 중간보고서 대상만 집계합니다. 아직 발견하지 못한 보고서는 분모에 포함되지 않습니다.',
                ),
              ],
            ),
          ],
        ),
        _Dataset(
          dataset: 'disclosure',
          title: '공시 주요정보',
          source: 'DART 주요정보 28종',
          data: '최대주주·소액주주·임원·타법인출자·배당·자기주식·주식 총수·증자 등. 지배구조와 주주환원 화면에 사용합니다.',
          scope: '최근 5개년 사업보고서와 최신 분기·반기 핵심 항목을 처리합니다. 최신 중간보고서에는 배당·자기주식·주식 총수도 포함합니다. 처리 완료에는 API의 자료 없음 응답이 포함되며, 아래 비율은 값의 확보율이 아닙니다.',
          detail: 'API 예: hyslrSttus.json(최대주주), exctvSttus.json(임원), otrCprInvstmntSttus.json(출자), alotMatter.json(배당), tesstkAcqsDspsSttus.json(자기주식). 매일 19:00 수집, 한도 도달 시 다음 날 00:05 재개. 처리율에는 저장 완료와 API의 자료 없음 응답이 모두 포함됩니다. 이 집계는 공시 주요정보 28종 장부를 기준으로 합니다.',
          children: [
            _Progress(
              label: '최신 핵심 9종 처리',
              done: v.prioritySectionsDone,
              total: v.prioritySections,
            ),
            _Progress(
              label: '주요정보 28종 전체 처리',
              done: v.sectionsDone,
              total: v.sections,
              note:
                  '미완료 ${formatCount(v.sections - v.sectionsDone)}건 · 이 중 실패 ${formatCount(v.sectionsFailed)}건',
            ),
          ],
        ),
        _Dataset(
          dataset: 'business',
          title: '사업의 내용',
          source: 'DART 공시 원문',
          data: '원문에서 부문 매출·수주·생산능력·가동률·시장점유율·연구개발비와 매입처·매출처를 읽습니다. 수치에는 원문 단위와 근거를 보존합니다.',
          scope: '기업별 연간 사업보고서 최근 5개년과 그 이후 최신 분기·반기보고서 한 건의 본문을 수집합니다. 최신 본문을 먼저 받으며 본문 확보와 지표 추출 완료는 서로 다릅니다.',
          detail: '정해진 표 구조·산술 검산을 통과한 결과를 저장합니다. 본문이 있어도 표 형식이나 검증 조건이 맞지 않으면 지표가 없을 수 있습니다. 항목별 추출 건수와 성공률은 현재 이 화면에서 집계하지 않습니다. 수동·AI 요약 작업은 보류 중입니다.',
          children: [BusinessCollectionStatus(coverage: v)],
        ),
        const IssuerDocumentsStatus(),
        _Dataset(
          dataset: 'market',

          title: '시세·시장 지수',
          source: '금융위원회 시세 API',
          data:
              '전 종목 일별 주가·거래량·시가총액, 상장종목 정보와 시장 지수. 시장 화면·주가 차트·밸류에이션에 사용합니다.',
          scope: '최근 5년의 평일 기준일을 수집합니다. 확인 범위는 실제 시세가 저장된 최신 날짜까지이며, 휴장일 0건 응답도 처리 완료에 포함합니다. 최신 날짜 이후는 원천 게시 여부를 확인할 때까지 미확보 상태로 표시합니다.',
          detail: '주식: GetStockSecuritiesInfoService_V2/getStockPriceInfo_V2. 상장종목: GetKrxListedInfoService_V2/getItemInfo_V2. 지수: GetMarketIndexInfoService_V2/getStockMarketIndex_V2. 매일 18:00 수집합니다. 최근 상장정보의 법인번호로 종목과 기업을 연결합니다.',
          children: [MarketCollectionStatus(coverage: v)],
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          '기업 보유 수는 자료가 하나라도 있는 기업 수입니다. 재무·공시 주요정보 처리율은 API의 자료 없음 응답을 포함합니다. 이 응답은 공시 원문이 없다는 뜻이 아닙니다. 본문 확보율은 실제 본문 저장 기준이며 어느 비율도 정확도 점수가 아닙니다.',
          style: t.body(12, color: c.textSecondary),
        ),
      ],
    );
  }
}

class _Dataset extends StatelessWidget {
  const _Dataset({
    required this.title,
    required this.dataset,
    required this.source,
    required this.data,
    required this.scope,
    required this.detail,
    this.children = const [],
    this.details,
  });

  final String title;
  final String dataset;
  final String source;
  final String data;
  final String scope;
  final String detail;
  final List<Widget> children;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final panelPadding = AppLayout.panelPadding(
      MediaQuery.sizeOf(context).width,
    );
    final items = switch (dataset) {
      'company' => ['기업명', '종목코드', '업종'],
      'financial' => ['손익', '재무상태', '현금흐름'],
      'disclosure' => ['주주·임원', '출자', '배당'],
      'business' => ['매출 구성', '수주', '생산·R&D'],
      _ => ['주가', '시가총액', '지수'],
    };
    final icon = switch (dataset) {
      'company' => LucideIcons.building2,
      'financial' => LucideIcons.landmark,
      'disclosure' => LucideIcons.network,
      'business' => LucideIcons.factory,
      _ => LucideIcons.chartLine,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: ShadCard(
        padding: EdgeInsets.zero,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(panelPadding),
              child: LayoutBuilder(
                builder: (context, box) {
                  final identity = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: c.accent, size: 22),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: t.body(18, weight: FontWeight.w600),
                                ),
                                Text(
                                  source,
                                  style: t.body(11, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      Wrap(
                        spacing: AppSpace.xs,
                        runSpacing: AppSpace.xs,
                        children: [
                          for (final item in items)
                            ShadBadge.outline(child: Text(item)),
                        ],
                      ),
                    ],
                  );
                  final metrics = LayoutBuilder(
                    builder: (context, size) {
                      if (children.length < 2 || size.maxWidth < 640) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < children.length; i++) ...[
                              if (i > 0) const SizedBox(height: AppSpace.md),
                              children[i],
                            ],
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < children.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpace.xl),
                            Expanded(child: children[i]),
                          ],
                        ],
                      );
                    },
                  );
                  if (dataset == 'company' && box.maxWidth >= 600) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: identity),
                        const SizedBox(width: AppSpace.xl),
                        SizedBox(width: 260, child: metrics),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      identity,
                      const SizedBox(height: AppSpace.lg),
                      metrics,
                      if (details != null) ...[
                        const SizedBox(height: AppSpace.md),
                        details!,
                      ],
                    ],
                  );
                },
              ),
            ),
            const ShadSeparator.horizontal(margin: EdgeInsets.zero),
            Padding(
              padding: EdgeInsets.fromLTRB(
                panelPadding,
                AppSpace.md,
                panelPadding,
                0,
              ),
              child: DatasetCollectionControls(dataset: dataset),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                panelPadding,
                0,
                panelPadding,
                AppSpace.sm,
              ),
              child: DataReference(
                dataset: dataset,
                collectionDetail: '$data\n\n$scope\n\n$detail',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.label,
    required this.value,
    required this.unit,
  });
  final String label;
  final String value;
  final String unit;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.typo.body(12, color: context.colors.textSecondary),
      ),
      const SizedBox(height: AppSpace.xs),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: AppSpace.sm,
        children: [
          Text(value, style: context.typo.numeric(26, weight: FontWeight.w600)),
          Text(
            unit,
            style: context.typo.body(12, color: context.colors.textSecondary),
          ),
        ],
      ),
    ],
  );
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.label,
    required this.done,
    required this.total,
    this.note,
  });

  final String label;
  final int done;
  final int total;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: t.body(12, color: c.textSecondary)),
              ),
              if (note != null)
                ShadTooltip(
                  builder: (_) => Text(note!),
                  child: Semantics(
                    tooltip: note!,
                    child: Icon(
                      LucideIcons.info,
                      size: 14,
                      color: c.textMuted,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpace.xs),
              Text(
                total == 0 ? '미집계' : '${(ratio * 100).toStringAsFixed(1)}%',
                style: t.numeric(13, weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpace.sm,
            children: [
              Text(
                formatCount(done),
                style: t.numeric(22, weight: FontWeight.w600),
              ),
              Text(
                '/ ${formatCount(total)}',
                style: t.numeric(13, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          ShadProgress(
            value: ratio,
            minHeight: 4,
            color: c.accent,
            backgroundColor: c.border,
          ),
        ],
      ),
    );
  }
}

/// Market source dates and confirmed historical coverage; nullable old-server
/// fields never fall back to invented zero counts or publication assertions.
class MarketCollectionStatus extends StatelessWidget {
  const MarketCollectionStatus({super.key, required this.coverage});
  final IngestCoverage coverage;

  @override
  Widget build(BuildContext context) {
    final v = coverage;
    final t = context.typo;
    final c = context.colors;
    final confirmed = v.marketScopeThrough;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Summary(
          label: '최신 시세 기준일',
          value: v.marketLatestPriceDate == null
              ? '집계 대기'
              : formatDate(v.marketLatestPriceDate),
          unit: '',
        ),
        Text(
          v.marketLatestPriceSecurities == null
              ? '가격 종목 수 · 집계 대기'
              : '가격 종목 ${formatCount(v.marketLatestPriceSecurities!)}개',
          style: t.body(13, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.md),
        _Summary(
          label: '최신 지수 기준일',
          value: v.marketLatestIndexDate == null
              ? '집계 대기'
              : formatDate(v.marketLatestIndexDate),
          unit: '',
        ),
        Text(
          v.marketLatestIndexCount == null
              ? '지수 수 · 집계 대기'
              : '지수 ${formatCount(v.marketLatestIndexCount!)}개',
          style: t.body(13, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.md),
        if (confirmed == null ||
            v.marketScopeStart == null ||
            v.marketExpectedWeekdays == null)
          const _Summary(label: '과거 5년 확인 범위', value: '집계 대기', unit: '')
        else ...[
          Text(
            '확인 범위 ${formatDate(v.marketScopeStart)} ~ ${formatDate(confirmed)}',
            style: t.body(12, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          if (v.marketPriceDaysStored case final done?)
            _Progress(
              label: '시세 기준일 처리',
              done: done,
              total: v.marketExpectedWeekdays!,
              note: '실제 최신 시세 기준일까지 평일 수입니다. 휴장일 0건 응답을 포함합니다.',
            ),
          if (v.marketIndexDaysStored case final done?)
            _Progress(
              label: '지수 기준일 처리',
              done: done,
              total: v.marketExpectedWeekdays!,
              note: '시세 확인 범위의 평일 수입니다. 휴장일 0건 응답을 포함합니다.',
            ),
        ],
        Text(
          v.marketHistoricalPendingDates == null
              ? '확인 범위 미완료 · 집계 대기'
              : '확인 범위 미완료 ${formatCount(v.marketHistoricalPendingDates!)}일',
          style: t.body(13, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          v.marketRecentUnconfirmedDates == null
              ? '최신 이후 미확보 · 집계 대기'
              : '최신 이후 미확보 ${formatCount(v.marketRecentUnconfirmedDates!)}일 · 원천 게시 확인 대기',
          style: t.body(13, color: c.textSecondary),
        ),
        Text(
          '최근 미확보 날짜는 원천 미게시나 휴장일로 확정한 값이 아닙니다.',
          style: t.body(12, color: c.textMuted),
        ),
      ],
    );
  }
}

class FinancialCollectionStatus extends StatelessWidget {
  const FinancialCollectionStatus({super.key, required this.coverage});
  final IngestCoverage coverage;
  @override
  Widget build(BuildContext context) {
    final v = coverage;
    final counts = [
      ('기간 일치 저장 보고서', v.financialStoredFilings),
      ('재무 API 응답 자료 없음', v.financialNoDataFilings),
      ('대기 보고서', v.financialPendingFilings),
      ('실패 보고서', v.financialFailedFilings),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.xs,
          children: [
            for (final (label, count) in counts)
              Text(
                count == null
                    ? '$label · 집계 대기'
                    : '$label ${formatCount(count)}건',
                style: context.typo.body(
                  12,
                  color: context.colors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          '실제 결산월·원접수 출처와 연결된 금액 계정이 하나 이상 있는 보고서 수입니다. 연결·별도 중 한 기준의 자료만 있어도 포함하며, 전체 계정이나 핵심7개 확보율이 아닙니다.',
          style: context.typo.body(11, color: context.colors.textMuted),
        ),
        Text(
          'API 자료 없음은 공시 원문에 재무 숫자가 없다는 뜻이 아닙니다.',
          style: context.typo.body(11, color: context.colors.textMuted),
        ),
        Text(
          '대기와 실패는 기준별 상태라 한 보고서가 두 항목에 포함될 수 있습니다.',
          style: context.typo.body(11, color: context.colors.textMuted),
        ),
      ],
    );
  }
}

class BusinessCollectionStatus extends StatelessWidget {
  const BusinessCollectionStatus({super.key, required this.coverage});
  final IngestCoverage coverage;
  @override
  Widget build(BuildContext context) {
    final v = coverage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (v.bodyScopeTotal != null && v.bodyScopeStored != null)
          _Progress(
            label: '연간 5개년·최신 중간 본문 확보',
            done: v.bodyScopeStored!,
            total: v.bodyScopeTotal!,
            note: '실제 본문을 저장한 대상 보고서입니다. 첨부 정정에 명시 연결한 같은 기간 원본은 포함하고 데이터 없음은 포함하지 않습니다.',
          )
        else
          const _Summary(label: '연간 5개년·최신 중간 본문 확보', value: '집계 대기', unit: ''),
        Text(
          v.bodyScopePending == null
              ? '대기 본문 · 집계 대기'
              : '대기 본문 ${formatCount(v.bodyScopePending!)}건',
          style: context.typo.body(12, color: context.colors.textSecondary),
        ),
        Text(
          v.bodyScopeFailed == null
              ? '실패 본문 · 집계 대기'
              : '실패 본문 ${formatCount(v.bodyScopeFailed!)}건',
          style: context.typo.body(12, color: context.colors.textSecondary),
        ),
        const SizedBox(height: AppSpace.md),
        if (v.companiesWithLatestBusinessText case final latest?)
          _Progress(
            label: '최신 접수 본문 확보',
            done: latest,
            total: v.listedCompanies,
            note: '기업별 최신 정기보고서 본문 또는 첨부 정정에 공식 연결된 같은 기간의 원본문입니다. 연결 근거가 없는 이전 접수와 다른 기간 본문은 포함하지 않습니다.',
          )
        else
          const _Summary(label: '최신 접수 본문 확보', value: '집계 대기', unit: ''),
        _Summary(
          label: '본문 보유 기업 · 어느 기간이든',
          value: formatCount(v.companiesWithBusinessText),
          unit: '개사',
        ),
      ],
    );
  }
}
