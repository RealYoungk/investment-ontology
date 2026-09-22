import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../financials/financial_metrics.dart';

/// 기업 비교: 두세 곳을 나란히 놓고 같은 잣대로 본다.
///
/// 주소에 기업이 남는다 (`/compare?codes=00126380,00164779`). 지표는 스크리너와 같은
/// 방식으로 서버가 계산하고, 계산에 쓴 원천 값도 함께 보여 준다.
class ComparePage extends StatefulWidget {
  const ComparePage({super.key, required this.corpCodes});

  final List<String> corpCodes;

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  /// 화면이 좁아지므로 이 이상은 받지 않는다.
  static const maxCompanies = 4;

  List<ScreenRow> _rows = const [];
  Object? _error;
  bool _loading = false;

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
    if (widget.corpCodes.isEmpty) {
      setState(() => _rows = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final page = await client.screen.list(
        corpCodes: widget.corpCodes,
        limit: maxCompanies,
      );
      // 주소에 적은 순서대로 보여 준다.
      final byCode = {for (final r in page.items) r.company.corpCode: r};
      if (mounted) {
        setState(() {
          _rows = [for (final c in widget.corpCodes) ?byCode[c]];
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
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
        const PageHeading(
          title: '기업 비교',
          subtitle: '최대 4곳을 나란히 놓고 봅니다. 지표는 최근 12개월(TTM) 연결 실적과 최근 시세로 계산합니다.',
        ),
        const SizedBox(height: AppSpace.xl),
        _AddCompany(
          disabled: widget.corpCodes.length >= maxCompanies,
          onAdd: (code) {
            if (widget.corpCodes.contains(code)) return;
            _go([...widget.corpCodes, code]);
          },
        ),
        const SizedBox(height: AppSpace.md),
        if (_error != null)
          AppNotice(message: '비교하지 못했습니다 — $_error')
        else if (widget.corpCodes.isEmpty)
          Text(
            '위에서 기업을 찾아 넣으세요. 스크리너나 기업 목록에서 넘어올 수도 있습니다.',
            style: t.body(13, color: c.textMuted),
          )
        else if (_loading && _rows.isEmpty)
          const LinearProgressIndicator(minHeight: 2)
        else ...[
          if (_rows.isNotEmpty) _ComparisonCharts(rows: _rows),
          const SizedBox(height: AppSpace.xl),
          const SectionLabel('세부 수치 · 같은 기준으로 대조'),
          const SizedBox(height: AppSpace.md),
          _CompareTable(
            rows: _rows,
            onRemove: (code) => _go([
              for (final x in widget.corpCodes)
                if (x != code) x,
            ]),
          ),
        ],
      ],
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.rows, required this.onRemove});

  final List<ScreenRow> rows;
  final ValueChanged<String> onRemove;

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
      ('지배주주 순이익(TTM)', (r) => formatKrw(r.netIncome)),
      ('지배주주 자본', (r) => formatKrw(r.equity)),
      ('잉여현금흐름(TTM)', (r) => formatKrw(r.freeCashFlow)),
      ('현금배당금총액', (r) => formatKrw(r.dividendTotal)),
      ('최근 보고서', (r) => 'FY${r.bsnsYear}'),
    ];
    return AppDataTable(
      columns: [
        const AppColumn('지표', nowrap: true),
        // 기업 열이 남는 폭을 똑같이 나눠 가진다.
        for (final r in rows)
          AppColumn(r.company.name, numeric: true, minWidth: 150, flex: true),
      ],
      rows: [
        AppRow([
          AppDataTable.text(context, ''),
          for (final r in rows)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: AppSpace.sm,
                children: [
                  AppButton(
                    label: '상세 →',
                    variant: AppButtonVariant.link,
                    tone: c.accent,
                    onPressed: () =>
                        context.push(AppRoutes.company(r.company.corpCode)),
                  ),
                  AppButton(
                    label: '빼기',
                    variant: AppButtonVariant.link,
                    onPressed: () => onRemove(r.company.corpCode),
                  ),
                ],
              ),
            ),
        ]),
        for (final (label, value) in metrics)
          AppRow([
            AppDataTable.text(context, label),
            for (final r in rows)
              AppDataTable.text(context, value(r), numeric: true),
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
              color: hovered ? c.surfaceHover : Colors.transparent,
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
        final width = (box.maxWidth - AppSpace.xl * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('가격과 수익성의 차이를 먼저 살펴보세요.', style: t.display(24)),
            const SizedBox(height: AppSpace.sm),
            Text(
              '각 차트는 독립된 축입니다. 업종·보고 기간이 다르면 수치만으로 우열을 판단하기 어렵습니다. 결측값은 막대로 표시하지 않습니다.',
              style: t.body(12, color: c.textSecondary),
            ),
            const SizedBox(height: AppSpace.xl),
            Wrap(
              spacing: AppSpace.xl,
              runSpacing: AppSpace.xl,
              children: [
                for (final (title, unit, value) in metrics)
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(title, style: t.body(15, weight: FontWeight.w600)),
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
              ],
            ),
          ],
        );
      },
    );
  }
}
