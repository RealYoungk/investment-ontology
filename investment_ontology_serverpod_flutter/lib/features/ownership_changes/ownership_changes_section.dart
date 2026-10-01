import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';

/// Compare values within the same filing row, never across people or stock kinds.
List<ShareholderEntry> comparableHolders(List<ShareholderEntry> rows) {
  final result = rows
      .where(
        (r) =>
            !r.isTotal &&
            r.sharesBegin != null &&
            r.sharesEnd != null &&
            r.sharesBegin! >= BigInt.zero &&
            r.sharesEnd! >= BigInt.zero,
      )
      .toList();
  result.sort(
    (a, b) => (b.sharesEnd! - b.sharesBegin!).abs().compareTo(
      (a.sharesEnd! - a.sharesBegin!).abs(),
    ),
  );
  return result;
}

String ownershipKey(ShareholderEntry row) {
  final name = row.holderName.replaceAll(RegExp(r'주식회사|\(주\)|㈜|\s'), '');
  final kind = row.stockKind?.replaceAll(' ', '') ?? '미표기';
  final common = kind.contains('보통') || kind == '의결권있는주식';
  final identity = row.holderCompanyId == null
      ? name
      : 'company:${row.holderCompanyId}';
  return '$identity|${common ? '보통주' : kind}';
}

ShareholderEntry? historyRow(OwnershipSnapshot snapshot, String key) {
  final matches = snapshot.shareholders
      .where((r) => !r.isTotal && ownershipKey(r) == key)
      .toList();
  // Ambiguous same-name rows are not added together or arbitrarily chosen.
  return matches.length == 1 ? matches.single : null;
}

String ownershipLabel(OwnershipSnapshot p) =>
    '${p.bsnsYear} ${switch (p.reportCode) {
      FinancialReportCode.annual => '결산',
      FinancialReportCode.halfYear => '반기',
      FinancialReportCode.q1 => '1분기',
      FinancialReportCode.q3 => '3분기',
    }}';
String ownershipDate(DateTime? d) => d == null
    ? '날짜 미확인'
    : '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

bool isMajorHolder(List<OwnershipSnapshot> periods, String key) =>
    periods.any((p) {
      final row = historyRow(p, key);
      return [
        row?.ratioBegin,
        row?.ratioEnd,
      ].any((v) => v != null && v.isFinite && v >= 5 && v <= 100);
    });

class OwnershipChangesSection extends StatefulWidget {
  const OwnershipChangesSection({
    super.key,
    required this.corpCode,
    this.loader,
    this.compact = false,
  });
  final String corpCode;
  final bool compact;
  final Future<List<OwnershipSnapshot>> Function(String)? loader;
  @override
  State<OwnershipChangesSection> createState() =>
      _OwnershipChangesSectionState();
}

class _OwnershipChangesSectionState extends State<OwnershipChangesSection> {
  List<OwnershipSnapshot>? _data;
  bool _failed = false, _ratio = true;
  Set<String>? _included;
  int _request = 0, _selected = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant OwnershipChangesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _data = null;
      _failed = false;
      _included = null;
    });
    try {
      final data =
          await (widget.loader?.call(widget.corpCode) ??
              client.governance.ownershipHistory(widget.corpCode));
      if (mounted && request == _request) {
        setState(() {
          _data = data;
          _selected = data.isEmpty ? 0 : data.length - 1;
        });
      }
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo, data = _data;
    if (_failed) {
      return Column(
        children: [
          const AppNotice(message: '주주 추이를 불러오지 못했습니다.'),
          TextButton(onPressed: _load, child: const Text('다시 시도')),
        ],
      );
    }
    if (data == null) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (data.isEmpty) {
      return const AppNotice(message: '이 기업의 주주 보고서가 아직 수집되지 않았습니다.');
    }
    final names = <String, ShareholderEntry>{};
    for (final p in data) {
      for (final r in p.shareholders.where((r) => !r.isTotal)) {
        names[ownershipKey(r)] = r;
      }
    }
    final keys = names.keys.toList()
      ..sort(
        (a, b) => (names[b]!.sharesEnd ?? BigInt.zero).compareTo(
          names[a]!.sharesEnd ?? BigInt.zero,
        ),
      );
    final selected = data[_selected];
    final defaults = keys
        .where(
          (k) => widget.compact
              ? data.any((p) => (historyRow(p, k)?.ratioEnd ?? 0) >= 5)
              : isMajorHolder(data, k),
        )
        .take(6)
        .toSet();
    final included = _included ?? defaults;
    final visible = keys.where(included.contains).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CompanySectionHeading(
            widget.compact ? '최근 5년 지분 흐름' : '주요 주주의 보유량은 어떻게 달라졌나요?',
          ),
          const SizedBox(height: AppSpace.sm),
          if (!widget.compact)
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('지분율'),
                  selected: _ratio,
                  onSelected: (_) => setState(() => _ratio = true),
                ),
                ChoiceChip(
                  label: const Text('보유 주식 수'),
                  selected: !_ratio,
                  onSelected: (_) => setState(() => _ratio = false),
                ),
                DropdownButton<int>(
                  value: _selected,
                  items: [
                    for (var i = 0; i < data.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(ownershipLabel(data[i])),
                      ),
                  ],
                  onChanged: (i) {
                    if (i != null) setState(() => _selected = i);
                  },
                ),
              ],
            ),
          Text(
            widget.compact
                ? '${ownershipDate(data.first.periodEnd)} → ${ownershipDate(data.last.periodEnd)} · 최대주주·관계인 중 주요 보유자'
                : '${ownershipDate(selected.periodStart)} → ${ownershipDate(selected.periodEnd)}${selected.collected ? '' : ' · 미수집'}',
            style: t.body(12, color: c.textSecondary),
          ),
          if (visible.isNotEmpty)
            _OwnershipChart(
              names: [for (final key in visible) names[key]!],
              periods: data,
              selected: _selected,
              ratio: _ratio,
              compact: widget.compact,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              child: Text(
                defaults.isEmpty
                    ? '5% 이상 주주가 없습니다. 비교할 주주를 선택하세요.'
                    : '비교할 주주를 선택하세요.',
                style: t.body(13),
              ),
            ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('비교 주주 선택 · ${visible.length}개', style: t.body(13)),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _included = null),
                  child: const Text('5% 이상으로 초기화'),
                ),
              ),
              for (final key in keys)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    '${names[key]!.holderName} · ${names[key]!.stockKind ?? '종류 미표기'}',
                    style: t.body(12),
                  ),
                  value: included.contains(key),
                  onChanged: !included.contains(key) && included.length >= 6
                      ? null
                      : (value) => setState(() {
                          _included = {...included};
                          value == true
                              ? _included!.add(key)
                              : _included!.remove(key);
                        }),
                ),
              Text(
                '최대 6개 · 기본은 기간 중 지분율 5% 이상',
                style: t.body(11, color: c.textMuted),
              ),
            ],
          ),
          if (!widget.compact)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('출처·집계 기준', style: t.body(12, color: c.textMuted)),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '최근 5개년 결산과 최신 중간보고서의 최대주주·특수관계인입니다. 전체 주주 명부가 아니며 5%는 화면 표시 기준입니다. 5% 미만도 선택해 비교할 수 있습니다. 같은 공시명·주식 종류를 연결하며, 누락·동명 중복은 빈칸으로 남깁니다. 차트 위에 마우스를 올리거나 터치하면 각 시점의 수치를 볼 수 있습니다.',
                  style: t.body(12, color: c.textMuted),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '비교 시작일은 직전 사업보고서 결산 다음날로 산정합니다. 보유량 증감은 매매 외의 사유로도 발생하며, 지분율은 발행주식 수 변화의 영향도 받습니다.',
                  style: t.body(12, color: c.textMuted),
                ),
                if (selected.rceptNo.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(
                          'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${selected.rceptNo}',
                        ),
                      ),
                      child: const Text('DART 원문 ↗'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OwnershipChart extends StatelessWidget {
  const _OwnershipChart({
    required this.names,
    required this.periods,
    required this.selected,
    required this.ratio,
    this.compact = false,
  });
  final List<ShareholderEntry> names;
  final List<OwnershipSnapshot> periods;
  final int selected;
  final bool ratio;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final colors = [c.chartSeries1, c.chartSeries2, c.chartSeries3];
    final series = [
      for (var i = 0; i < names.length; i++)
        ChartSeries(
          label: '${names[i].holderName} · ${names[i].stockKind ?? '종류 미표기'}',
          color: colors[i % 3],
          isLine: true,
          isDashed: i >= 3,
          values: [
            for (final p in periods)
              (() {
                final row = historyRow(p, ownershipKey(names[i]));
                final v = ratio ? row?.ratioEnd : row?.sharesEnd?.toDouble();
                return v != null && v.isFinite && v >= 0 ? v : null;
              })(),
          ],
        ),
    ];
    return Container(
      margin: const EdgeInsets.only(top: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: context.shape.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartLegend(series: series),
          const SizedBox(height: AppSpace.md),
          AppLineChart.many(
            categories: [
              for (final p in periods)
                '${p.bsnsYear % 100} ${p.reportCode == FinancialReportCode.annual
                    ? '결산'
                    : p.reportCode == FinancialReportCode.halfYear
                    ? '반기'
                    : p.reportCode == FinancialReportCode.q1
                    ? '1Q'
                    : '3Q'}',
            ],
            series: series,
            formatValue: (v) =>
                ratio ? '${v.toStringAsFixed(1)}%' : formatCount(v.round()),
            height: 210,
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.xs,
            children: [
              for (var i = 0; i < series.length; i++)
                Text(
                  compact
                      ? ownershipAvailableSummary(
                          names[i].holderName,
                          series[i].values,
                          periods,
                        )
                      : '${names[i].holderName}  ${series[i].values[selected] == null
                            ? '—'
                            : ratio
                            ? '${series[i].values[selected]!.toStringAsFixed(2)}%'
                            : '${formatCount(series[i].values[selected]!.round())}주'}',
                  style: t.body(12, weight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String ownershipTrendSummary(List<double?> values) {
  if (values.isEmpty) return '자료 없음';
  final first = values.first, last = values.last;
  String value(double? v) => v == null ? '미확보' : '${v.toStringAsFixed(2)}%';
  if (first == null || last == null) return '${value(first)} → ${value(last)}';
  final change = last - first;
  return '${value(first)} → ${value(last)} · ${change.abs() < 0.005 ? '시작·끝 동일' : '${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%p'}';
}

String ownershipAvailableSummary(
  String name,
  List<double?> values,
  List<OwnershipSnapshot> periods,
) {
  final first = values.indexWhere((v) => v != null);
  final last = values.lastIndexWhere((v) => v != null);
  if (first < 0) return '$name · 지분율 미확보';
  final range =
      '${ownershipLabel(periods[first])} → ${ownershipLabel(periods[last])}';
  return '$name · $range\n${ownershipTrendSummary(values.sublist(first, last + 1))}${last < values.length - 1 ? '\n${ownershipLabel(periods.last)} 지분율 미확보' : ''}';
}
