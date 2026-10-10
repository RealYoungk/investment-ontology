import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../financials/financial_metrics.dart';
import 'peer_candidates_panel.dart';
import 'compare_metrics_table.dart';
import 'compare_company_search.dart';

/// 기업 비교: 두세 곳을 나란히 놓고 같은 잣대로 본다.
///
/// 주소에 기업이 남는다 (`/compare?codes=00126380,00164779`). 지표는 스크리너와 같은
/// 방식으로 서버가 계산하고, 계산에 쓴 원천 값도 함께 보여 준다.
class ComparePage extends StatefulWidget {
  const ComparePage({
    super.key,
    required this.corpCodes,
    this.discoveryProduct,
  });

  final List<String> corpCodes;
  final String? discoveryProduct;

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  /// 화면이 좁아지므로 이 이상은 받지 않는다.
  static const maxCompanies = 4;

  List<ScreenRow> _rows = const [];
  Object? _error;
  bool _loading = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ComparePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.corpCodes, widget.corpCodes) &&
        oldWidget.corpCodes.join(',') != widget.corpCodes.join(',')) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    if (widget.corpCodes.isEmpty) {
      setState(() {
        _rows = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _rows = _rows
          .where((r) => widget.corpCodes.contains(r.company.corpCode))
          .toList();
    });
    try {
      final page = await client.screen.list(
        corpCodes: widget.corpCodes,
        limit: maxCompanies,
      );
      // 주소에 적은 순서대로 보여 준다.
      final byCode = {for (final r in page.items) r.company.corpCode: r};
      if (mounted && request == _request) {
        setState(() {
          _rows = [for (final c in widget.corpCodes) ?byCode[c]];
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _go(List<String> codes) {
    final route = Uri.parse(
      AppRoutes.compare(codes.take(maxCompanies).toList()),
    );
    context.go(
      route
          .replace(
            queryParameters: {
              ...route.queryParameters,
              if (widget.discoveryProduct != null)
                'industryProduct': widget.discoveryProduct!,
            },
          )
          .toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return PageFrame(
      children: [
        const PageHeading(title: '기업 비교'),
        Text(
          '최대 4개 기업의 실적과 밸류에이션을 같은 기준으로 비교합니다.',
          style: t.body(13, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.lg),
        if (widget.discoveryProduct case final String product) ...[
          Text('탐색 기준: $product', style: t.body(14, weight: FontWeight.w600)),
          Text(
            '아래 재무 지표는 해당 제품 사업만의 실적이 아닌 기업 전체 기준입니다.',
            style: t.body(12, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        LayoutBuilder(
          builder: (context, box) {
            final beside = box.maxWidth >= 900 && widget.corpCodes.isNotEmpty;
            final searchWidth = beside
                ? (box.maxWidth - AppSpace.lg) * 0.58
                : box.maxWidth;
            return Wrap(
              spacing: AppSpace.lg,
              runSpacing: AppSpace.lg,
              children: [
                SizedBox(
                  width: searchWidth,
                  child: DataPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.corpCodes.isNotEmpty) ...[
                          Wrap(
                            spacing: AppSpace.sm,
                            runSpacing: AppSpace.sm,
                            children: [
                              for (final code in widget.corpCodes)
                                _SelectedCompany(
                                  code: code,
                                  name: _rows
                                      .where((r) => r.company.corpCode == code)
                                      .firstOrNull
                                      ?.company
                                      .name,
                                  onRemove: () => _go(
                                    widget.corpCodes
                                        .where((c) => c != code)
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.lg),
                        ],
                        CompareCompanySearch(
                          key: const ValueKey('compare-company-search'),
                          selectedCodes: widget.corpCodes,
                          onRemove: (code) => _go(
                            widget.corpCodes.where((c) => c != code).toList(),
                          ),
                          onAdd: (code) {
                            if (widget.corpCodes.length >= maxCompanies ||
                                widget.corpCodes.contains(code)) {
                              return;
                            }
                            _go([...widget.corpCodes, code]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.corpCodes.isNotEmpty)
                  SizedBox(
                    width: beside
                        ? box.maxWidth - searchWidth - AppSpace.lg
                        : box.maxWidth,
                    child: DataPanel(
                      child: PeerCandidatesPanel(
                        codes: widget.corpCodes,
                        onAdd: (code) {
                          if (widget.corpCodes.length >= maxCompanies ||
                              widget.corpCodes.contains(code)) {
                            return;
                          }
                          _go([...widget.corpCodes, code]);
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.xl),
        if (_loading && _rows.isNotEmpty) ...[
          const ShadProgress(minHeight: 2),
          const SizedBox(height: AppSpace.sm),
          Text('비교 데이터 갱신 중…', style: t.body(12, color: c.textSecondary)),
          const SizedBox(height: AppSpace.md),
        ],
        if (_error != null)
          ReadFailureNotice(subject: '비교 데이터', retry: _load)
        else if (widget.corpCodes.isEmpty)
          Text(
            '위에서 궁금한 회사를 검색해 보세요. 두 곳 이상 고르면 숫자를 나란히 비교할 수 있어요.',
            style: t.body(13, color: c.textMuted),
          )
        else if (_loading && _rows.isEmpty)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShadProgress(minHeight: 2),
              SizedBox(height: AppSpace.sm),
              Text('비교 데이터 불러오는 중…'),
            ],
          )
        else ...[
          if (!_loading && _rows.length < widget.corpCodes.length)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                '일부 기업은 비교에 필요한 재무·시세 자료가 없습니다. 선택 목록에서 뺄 수 있습니다.',
                style: t.body(13, color: c.textSecondary),
              ),
            ),
          if (_rows.isNotEmpty) _ComparisonCharts(rows: _rows),
          const SizedBox(height: AppSpace.lg),
          DataPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CompanySectionHeading('세부 수치'),
                const SizedBox(height: AppSpace.md),
                _CompareTable(rows: _rows),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.rows});

  final List<ScreenRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (rows.isEmpty) {
      return Text(
        '재무나 시세가 없어 비교할 수 없는 기업입니다.',
        style: t.body(13, color: c.textMuted),
      );
    }
    String? pct(double? v) => v == null ? null : '${v.toStringAsFixed(1)}%';
    final metrics = <(String, String? Function(ScreenRow))>[
      (
        '재무 기준',
        (r) => r.fsDiv == null
            ? '—'
            : '${fsDivLabel(r.fsDiv!)} · ${financialBasisReason(r.basisReason)}',
      ),
      ('시가총액', (r) => formatKrw(r.marketCap)),
      ('PER', (r) => formatTimes(r.per)),
      ('PBR', (r) => formatTimes(r.pbr)),
      ('ROE', (r) => pct(r.roe)),
      ('영업이익률', (r) => pct(r.operatingMargin)),
      ('매출 성장률', (r) => pct(r.revenueGrowth)),
      ('영업이익 성장률', (r) => pct(r.operatingIncomeGrowth)),
      ('부채비율', (r) => pct(r.debtRatio)),
      ('배당수익률', (r) => pct(r.dividendYield)),
      ('FCF 수익률', (r) => pct(r.fcfYield)),
      ('매출액(TTM)', (r) => formatKrw(r.revenue)),
      ('영업이익(TTM)', (r) => formatKrw(r.operatingIncome)),
      ('순이익(TTM)', (r) => formatKrw(r.netIncome)),
      ('자본', (r) => formatKrw(r.equity)),
      ('잉여현금흐름(TTM)', (r) => formatKrw(r.freeCashFlow)),
      ('현금배당금총액', (r) => formatKrw(r.dividendTotal)),
      (
        '최근 보고서',
        (r) =>
            '${r.bsnsYear} ${r.reportCode == null ? '' : reportCodeLabel(r.reportCode!)}',
      ),
    ];
    return CompareMetricsTable(
      companies: [for (final r in rows) r.company.name],
      corpCodes: [for (final r in rows) r.company.corpCode],
      metrics: [
        for (final (label, value) in metrics)
          CompareMetricRow(
            label: label,
            values: [for (final r in rows) value(r)],
            notes: [for (final r in rows) screenMetricNote(r, label)],
          ),
      ],
    );
  }
}

class _ComparisonCharts extends StatelessWidget {
  const _ComparisonCharts({required this.rows});
  final List<ScreenRow> rows;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final metrics = <(String, String, double? Function(ScreenRow))>[
      ('가격은 이익의 몇 배인가', 'PER · 배', (r) => r.per),
      ('매출에서 얼마나 남기는가', '영업이익률 · %', (r) => r.operatingMargin),
      ('자본 대비 얼마나 벌었는가', 'ROE · %', (r) => r.roe),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 960
            ? 3
            : box.maxWidth >= 640
            ? 2
            : 1;
        final width = (box.maxWidth - AppSpace.md * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CompanySectionHeading('밸류에이션·수익성'),
            const SizedBox(height: AppSpace.sm),
            Text(
              '최근 12개월 실적 기준 · 지표별 축은 다릅니다.',
              style: t.body(12, color: c.textSecondary),
            ),
            const SizedBox(height: AppSpace.xl),
            Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.md,
              children: [
                for (final (title, unit, value) in metrics)
                  SizedBox(
                    width: width,
                    child: DataPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CompanySectionHeading(title),
                          Text(unit, style: t.body(12, color: c.textSecondary)),
                          const SizedBox(height: AppSpace.md),
                          AppColumnChart(
                            categories: [for (final r in rows) r.company.name],
                            series: [
                              ChartSeries(
                                label: unit,
                                color: c.chartSeries1,
                                values: [for (final r in rows) value(r)],
                              ),
                            ],
                            formatValue: (v) => v.toStringAsFixed(1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SelectedCompany extends StatelessWidget {
  const _SelectedCompany({
    required this.code,
    required this.name,
    required this.onRemove,
  });
  final String code;
  final String? name;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => ShadBadge.outline(
    padding: const EdgeInsets.only(left: AppSpace.md, right: AppSpace.xs),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ShadButton.link(
            height: 32,
            padding: EdgeInsets.zero,
            onPressed: () => context.push(AppRoutes.company(code)),
            child: Flexible(
              child: Text(
                name?.replaceAll('(주)', '').replaceAll('주식회사', '').trim() ??
                    code,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Semantics(
          container: true,
          label: '${name ?? code} 비교에서 빼기',
          button: true,
          onTap: onRemove,
          child: ExcludeSemantics(
            child: ShadIconButton.ghost(
              width: 32,
              height: 32,
              padding: EdgeInsets.zero,
              onPressed: onRemove,
              icon: const Icon(LucideIcons.x, size: 14),
            ),
          ),
        ),
      ],
    ),
  );
}
