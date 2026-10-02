import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/ingest_monitor.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_viewer.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart' show formatKrwLong;

typedef BondLoader = Future<String> Function(String corpCode);

String bondMoney(Object? value) {
  final n = BigInt.tryParse('$value');
  return n == null ? '미확보' : formatKrwLong(n.toDouble());
}

class BondTrendsCard extends StatefulWidget {
  const BondTrendsCard({
    super.key,
    required this.corpCode,
    this.loader,
    this.collector,
  });
  final String corpCode;
  final BondLoader? loader;
  final BondLoader? collector;
  @override
  State<BondTrendsCard> createState() => _BondTrendsCardState();
}

class _BondTrendsCardState extends State<BondTrendsCard> {
  Map<String, dynamic>? _data;
  String? _error, _collectionNote;
  bool _collecting = false;
  int _request = 0;
  String _selected = 'all';
  int _limit = 12;

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(covariant BondTrendsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode ||
        oldWidget.loader != widget.loader) {
      _data = null;
      _error = null;
      _collectionNote = null;
      _selected = 'all';
      _limit = 12;
      _collecting = false;
      _load();
    }
  }

  @override
  void dispose() {
    _request++;
    IngestMonitor.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request, corp = widget.corpCode;
    try {
      final data = jsonDecode(
        await (widget.loader ?? client.bond.trends)(corp),
      ) as Map<String, dynamic>;
      if (mounted && request == _request) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = '전환사채 추이를 불러오지 못했습니다.');
      }
    }
  }

  Future<void> _collect() async {
    if (!context.ensureAdmin()) return;
    final corp = widget.corpCode;
    setState(() {
      _collecting = true;
      _collectionNote = null;
    });
    try {
      final result = jsonDecode(
        await (widget.collector ?? client.bond.collect)(corp),
      ) as Map<String, dynamic>;
      if (!mounted || widget.corpCode != corp) return;
      setState(
        () => _collectionNote =
            '${result['collected']}개 보고서 저장 · ${result['remaining']}개 미수집',
      );
      await _load();
    } catch (e) {
      if (mounted && widget.corpCode == corp) {
        setState(() => _collectionNote = '$e');
      }
    } finally {
      if (mounted && widget.corpCode == corp) {
        setState(() => _collecting = false);
      }
    }
  }

  List<Map<String, dynamic>> _maps(Object? value) =>
      (value as List? ?? []).cast<Map<String, dynamic>>();
  String _key(Map<String, dynamic> row) =>
      '${row['series']}|${row['issueDate']}|${row['stockKind']}';

  @override
  Widget build(BuildContext context) {
    final t = context.typo, c = context.colors;
    final points = _maps(_data?['points']), changes = _maps(_data?['changes']);
    final latest = points.lastOrNull;
    final choices = <String, Map<String, dynamic>>{};
    for (final p in points) {
      for (final row in _maps(p['entries'])) {
        choices[_key(row)] = row;
      }
    }
    final selected = choices.containsKey(_selected) ? _selected : 'all';
    final selectedChanges = changes
        .where((r) => selected == 'all' || _key(r) == selected)
        .toList()
        .reversed
        .toList();
    return CompanyDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CompanySectionHeading('전환사채 잔액은 얼마나 줄었나?'),
          const SizedBox(height: AppSpace.sm),
          Text(
            '보고서 기준 잔액을 회차별로 대조합니다. 잔액의 순감소는 전환·상환 원인을 확정한 해소량과 구분합니다.',
            style: t.body(13, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.md),
          if (_error != null)
            Column(
              children: [
                const Text('전환사채 추이를 불러오지 못했습니다.'),
                AppButton(label: '다시 불러오기', onPressed: _load),
              ],
            )
          else if (_data == null)
            const Text('전환사채 잔액 추이를 확인 중입니다.')
          else if (points.isEmpty)
            const Text('정기보고서 목록 미확보 · 비교할 보고서가 없습니다.')
          else ...[
            Wrap(
              spacing: AppSpace.xl,
              runSpacing: AppSpace.md,
              children: [
                _metric(
                  context,
                  '최근 보고서 잔액',
                  latest!['balanceWon'] == null
                      ? '미확보'
                      : bondMoney(latest['balanceWon']),
                  '${latest['periodEnd']} 기준',
                ),
                _metric(
                  context,
                  '같은 회차 전체의 순감소 추정',
                  latest['netDecreaseWon'] == null
                      ? '비교 불가'
                      : _change(latest['netDecreaseWon']),
                  latest['fromDate'] == null
                      ? '비교 보고서 미확보'
                      : '${latest['fromDate']} → ${latest['periodEnd']}',
                ),
                _metric(
                  context,
                  '남은 전환 가능 주식',
                  latest['potentialShares'] == null
                      ? '검산 미완료'
                      : '${formatCount(BigInt.parse('${latest['potentialShares']}').toInt())}주',
                  '원문 수량 · 전환가 검산 통과분',
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              '보고서 수집 ${_data!['collectedPeriods']} / ${_data!['expectedPeriods']} · 최근 5개 연간 회계연도 + 최신 중간 보고서',
              style: t.body(12, color: c.textSecondary),
            ),
            if (choices.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              DropdownButton<String>(
                key: const ValueKey('bond-series-selector'),
                value: selected,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('전환사채 전체 잔액'),
                  ),
                  for (final e in choices.entries)
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        '${e.value['series']} · 발행 ${e.value['issueDate'] ?? '일자 미확보'} · ${e.value['stockKind']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _selected = v ?? 'all'),
              ),
            ],
            const SizedBox(height: AppSpace.md),
            if (points.any((p) => p['balanceWon'] != null))
              AppLineChart(
                categories: points.map((p) => '${p['periodEnd']}').toList(),
                series: ChartSeries(
                  label: '권면 잔액',
                  color: c.chartSeries1,
                  values: points.map((p) => _chartValue(p, selected)).toList(),
                ),
                formatValue: (v) =>
                    '${v.toStringAsFixed(v.abs() < 10 ? 1 : 0)}억',
                height: 210,
              )
            else
              const Text('잔액 표 미수집 · 자료가 확보되면 추이가 표시됩니다.'),
            const SizedBox(height: AppSpace.sm),
            Text(
              '빠진 자료는 0으로 채우지 않습니다. 그래프는 보고서 관측값이며 기간 중 변화를 나타내지 않습니다.',
              style: t.body(12, color: c.textSecondary),
            ),
            const SizedBox(height: AppSpace.lg),
            const CompanySectionHeading('회차별 잔액 변화'),
            if (selectedChanges.isEmpty)
              const Text('같은 회차의 두 보고서가 확보되면 감소량을 비교합니다.'),
            for (final r in selectedChanges.take(_limit))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${r['series']} · ${r['fromDate']} → ${r['toDate']}',
                      style: t.body(13, weight: FontWeight.w600),
                    ),
                    Text(
                      '${bondMoney(r['beforeWon'])} → ${bondMoney(r['afterWon'])} · ${r['netDecreaseWon'] == null ? '비교 불가' : _change(r['netDecreaseWon'])}',
                      style: t.numeric(16),
                    ),
                    if (r['reason'] != null)
                      Text(
                        '${r['reason']}',
                        style: t.body(12, color: c.textSecondary),
                      ),
                    if (r['unexplainedDecreaseWon'] != null)
                      Text(
                        '원인 미확인 순감소 ${bondMoney(r['unexplainedDecreaseWon'])} · 전환·상환 실행 공시 미대조',
                        style: t.body(12, color: c.textSecondary),
                      ),
                    if (r['beforePrice'] != null &&
                        r['afterPrice'] != null &&
                        r['beforePrice'] != r['afterPrice'])
                      Text(
                        '전환가 ${bondMoney(r['beforePrice'])} → ${bondMoney(r['afterPrice'])} · 가능 주식 수 변화를 해소량으로 사용하지 않음',
                        style: t.body(12, color: c.textSecondary),
                      ),
                  ],
                ),
              ),
            if (selectedChanges.length > _limit)
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: '이전 변화 더 보기 (${selectedChanges.length - _limit}건)',
                  variant: AppButtonVariant.link,
                  onPressed: () => setState(() => _limit += 12),
                ),
              ),
            const SizedBox(height: AppSpace.md),
            Material(
              color: c.surface,
              child: ExpansionTile(
                title: const Text('보고서별 수량과 원문 근거'),
                tilePadding: EdgeInsets.zero,
                children: [
                  for (final p in points.reversed)
                    _source(context, p, selected),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Text(
            '전환·상환 확정 금액: 실행 공시 미대조. 만기 전 취득은 재매각될 수 있으며, 주식 전환은 시장에서 매도됐다는 뜻이 아닙니다.',
            style: t.body(12, color: c.textSecondary),
          ),
          if (AppViewerScope.maybeOf(context)?.isAdmin ?? false) ...[
            const SizedBox(height: AppSpace.md),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: _collecting ? '원문 수집 중…' : '전환사채 추이 원문 수집',
                onPressed: _collecting ? null : _collect,
              ),
            ),
          ],
          if (_collectionNote != null)
            Text(_collectionNote!, style: t.body(12, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    String note,
  ) => SizedBox(
    width: 230,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typo.body(12, color: context.colors.textSecondary),
        ),
        Text(value, style: context.typo.numeric(22, weight: FontWeight.w600)),
        Text(
          note,
          style: context.typo.body(11, color: context.colors.textSecondary),
        ),
      ],
    ),
  );
  String _change(Object? value) {
    final n = BigInt.parse('$value');
    return '${bondMoney(n.abs())} ${n > BigInt.zero
        ? '순감소'
        : n < BigInt.zero
        ? '증가'
        : '변동 없음'}';
  }

  double? _chartValue(Map<String, dynamic> point, String selected) {
    if (point['balanceWon'] == null) return null;
    if (selected == 'all') {
      return BigInt.parse('${point['balanceWon']}').toDouble() / 100000000;
    }
    final row = _maps(point['entries'])
        .where((r) => _key(r) == selected)
        .firstOrNull;
    final scale = switch (row?['unit']) {
      '원' => 1,
      '천원' => 1000,
      '백만원' => 1000000,
      _ => null,
    };
    final value = BigInt.tryParse('${row?['balance']}');
    return value == null || scale == null
        ? null
        : value.toDouble() * scale / 100000000;
  }

  Widget _source(
    BuildContext context,
    Map<String, dynamic> p,
    String selected,
  ) {
    final rows = _maps(p['entries'])
        .where((r) => selected == 'all' || _key(r) == selected);
    final state = switch (p['state']) {
      'verified' => '잔액 표 확인',
      'none' => '공시상 해당 없음',
      'partial' => '표·단위 확인 미완료',
      'notCollected' => '미수집',
      _ => '잔액 표 미확보',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${p['periodEnd']} · $state',
            style: context.typo.body(13, weight: FontWeight.w600),
          ),
          for (final row in rows) ...[
            Text(
              '${row['series']} · 잔액 ${row['balance']} ${row['unit'] ?? '단위 미확보'} · 전환가 ${row['price'] ?? '미확보'}원 · 가능 주식 ${row['shares']}주',
            ),
            SelectableText(
              '${row['evidence'] ?? ''}',
              style: context.typo.body(11, color: context.colors.textSecondary),
            ),
          ],
          AppButton(
            label: 'DART 원문 · ${p['receipt']}',
            variant: AppButtonVariant.link,
            onPressed: () => launchUrl(Uri.parse('${p['sourceUrl']}')),
          ),
        ],
      ),
    );
  }
}
