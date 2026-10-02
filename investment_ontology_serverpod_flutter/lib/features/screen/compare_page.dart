import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../financials/financial_metrics.dart';
import 'peer_candidates_panel.dart';

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

  void _go(List<String> codes) =>
      context.go(AppRoutes.compare(codes.take(maxCompanies).toList()));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return PageFrame(
      children: [
        const PageHeading(title: '기업 비교'),
        const SizedBox(height: AppSpace.lg),
        if (widget.discoveryProduct case final String product) ...[
          Text('탐색 기준: $product', style: t.body(14, weight: FontWeight.w600)),
          Text(
            '아래 재무 지표는 해당 제품 사업만의 실적이 아닌 기업 전체 기준입니다.',
            style: t.body(12, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        if (_rows.isNotEmpty) ...[
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final row in _rows)
                InputChip(
                  label: Text(
                    row.company.name
                        .replaceAll('(주)', '')
                        .replaceAll('주식회사', '')
                        .trim(),
                  ),
                  tooltip: '기업 상세 보기',
                  onPressed: () =>
                      context.push(AppRoutes.company(row.company.corpCode)),
                  onDeleted: () => _go([
                    for (final code in widget.corpCodes)
                      if (code != row.company.corpCode) code,
                  ]),
                  deleteButtonTooltipMessage: '비교에서 빼기',
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
        ],
        Theme(
          data: Theme.of(context)
              .copyWith(dividerColor: c.border.withValues(alpha: 0)),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            expandedAlignment: Alignment.centerLeft,
            backgroundColor: c.surface.withValues(alpha: 0),
            collapsedBackgroundColor: c.surface.withValues(alpha: 0),
            key: ValueKey(widget.corpCodes.length < 2),
            initiallyExpanded: widget.corpCodes.length < 2,
            leading: const Icon(Icons.add_circle_outline, size: 20),
            title: Text('비교 기업 찾기', style: t.body(15, weight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.only(
              top: AppSpace.sm,
              bottom: AppSpace.md,
            ),
            children: [
              _AddCompany(
                disabled: widget.corpCodes.length >= maxCompanies,
                onAdd: (code) {
                  if (widget.corpCodes.contains(code)) return;
                  _go([...widget.corpCodes, code]);
                },
              ),
              const SizedBox(height: AppSpace.lg),
              PeerCandidatesPanel(
                codes: widget.corpCodes,
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
        const SizedBox(height: AppSpace.xl),
        if (_error != null)
          ReadFailureNotice(subject: '비교 데이터', retry: _load)
        else if (widget.corpCodes.isEmpty)
          Text(
            '위에서 궁금한 회사를 검색해 보세요. 두 곳 이상 고르면 숫자를 나란히 비교할 수 있어요.',
            style: t.body(13, color: c.textMuted),
          )
        else if (_loading && _rows.isEmpty)
          const LinearProgressIndicator(minHeight: 2)
        else ...[
          if (_rows.isNotEmpty) _ComparisonCharts(rows: _rows),
          const SizedBox(height: AppSpace.lg),
          CompanyDataCard(
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
    return AppDataTable(
      columns: [
        const AppColumn('지표', nowrap: true),
        // 기업 열이 남는 폭을 똑같이 나눠 가진다.
        for (final r in rows)
          AppColumn(r.company.name, numeric: true, minWidth: 150, flex: true),
      ],
      rows: [
        for (final (label, value) in metrics)
          AppRow([
            AppDataTable.text(context, label),
            for (final r in rows)
              Tooltip(
                message: screenMetricNote(r, label) ?? '',
                child: AppDataTable.text(context, value(r), numeric: true),
              ),
          ]),
      ],
    );
  }
}

/// 기업을 찾아 비교에 넣는다.
class _AddCompany extends StatefulWidget {
  const _AddCompany({required this.onAdd, required this.disabled});

  final ValueChanged<String> onAdd;
  final bool disabled;

  @override
  State<_AddCompany> createState() => _AddCompanyState();
}

class _AddCompanyState extends State<_AddCompany> {
  final _controller = TextEditingController();
  List<CompanyListItem> _results = const [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final query = q.trim();
      if (query.isEmpty) {
        setState(() => _results = const []);
        return;
      }
      try {
        final page = await client.company.list(
          query: query,
          sort: CompanySort.marketCap,
          limit: 6,
        );
        if (mounted && _controller.text.trim() == query) {
          setState(() => _results = page.items);
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _controller,
            enabled: !widget.disabled,
            onChanged: _search,
            style: t.body(14),
            decoration: InputDecoration(
              hintText: widget.disabled ? '네 곳까지 넣을 수 있습니다' : '회사명 · 종목코드',
              prefixIcon: Icon(Icons.search, size: 20, color: c.textSecondary),
            ),
          ),
        ),
        for (final item in _results)
          HoverBuilder(
            onTap: () {
              widget.onAdd(item.corpCode);
              _controller.clear();
              setState(() => _results = const []);
            },
            builder: (context, hovered) => Container(
              width: 320,
              color: hovered ? c.surfaceHover : c.surface.withValues(alpha: 0),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm,
                vertical: 7,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      item.stockCode ?? '',
                      style: t.numeric(12, color: c.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.body(13.5),
                    ),
                  ),
                ],
              ),
            ),
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
                    child: CompanyDataCard(
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
