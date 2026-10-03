import 'research_import.dart';

import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../app/ingest_monitor.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_viewer.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart' show formatKrwLong;

typedef ResearchLoader = Future<String> Function(String, String);
const researchLabels = {
  'insiders': '임원·주주',
  'majorHoldings': '주요주주',
  'capital': '자금조달',
  'treasury': '자사주',
  'consensus': '실적 전망·목표주가',
  'flows': '투자자 수급',
  'shorts': '공매도',
  'program': '프로그램 매매',
  'credit': '신용 잔고',
  'lending': '대차 잔고',
};

/// Missing DART snapshots are acquired and cached by the server on first read.
class ResearchSection extends StatefulWidget {
  const ResearchSection({
    super.key,
    required this.corpCode,
    required this.kinds,
    this.loader,
    this.showManagement = false,
  });
  final String corpCode;
  final List<String> kinds;
  final ResearchLoader? loader;
  final bool showManagement;
  @override
  State<ResearchSection> createState() => _ResearchSectionState();
}

class _ResearchSectionState extends State<ResearchSection> {
  final _feeds = <String, Map<String, dynamic>>{};
  int _request = 0;
  Timer? _retryTimer;
  String? _collecting, _error;
  late String _kind = widget.kinds.first;
  int _limit = 5;
  String? _series;
  bool _showUnavailable = false;
  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(covariant ResearchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode ||
        oldWidget.loader != widget.loader ||
        oldWidget.kinds.join('|') != widget.kinds.join('|')) {
      if (!widget.kinds.contains(_kind)) _kind = widget.kinds.first;
      _feeds.clear();
      _showUnavailable = false;
      _limit = 5;
      _series = null;
      _error = null;
      _load();
    }
  }

  @override
  void dispose() {
    _request++;
    _retryTimer?.cancel();
    IngestMonitor.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    _retryTimer?.cancel();
    final request = ++_request, corp = widget.corpCode;
    final values = await Future.wait(
      widget.kinds.map((kind) async {
        try {
          return MapEntry(
            kind,
            jsonDecode(
              await (widget.loader ?? client.research.data)(corp, kind),
            ) as Map<String, dynamic>,
          );
        } catch (_) {
          return MapEntry(kind, <String, dynamic>{
            'state': 'error',
            'message': '자료를 불러오지 못했습니다.',
            'rows': [],
          });
        }
      }),
    );
    if (!mounted || request != _request) return;
    setState(() {
      _feeds.addEntries(values);
    });
    final retryDelays = values
        .map((v) => v.value['retryAfterSeconds'])
        .whereType<int>()
        .where((n) => n > 0);
    if (retryDelays.isNotEmpty) {
      final seconds = retryDelays.reduce((a, b) => a < b ? a : b);
      _retryTimer = Timer(Duration(seconds: seconds), _load);
    }
  }

  Future<void> _collect() async {
    if (!context.ensureAdmin()) return;
    final corp = widget.corpCode, kind = _kind;
    setState(() {
      _collecting = kind;
      _error = null;
    });
    try {
      await client.research.collect(corp, kind);
      await _load();
    } catch (e) {
      if (mounted && corp == widget.corpCode) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _collecting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feeds[_kind];
    final rows = ((feed?['rows'] as List?) ?? []).cast<Map<String, dynamic>>();
    final ready = feed?['state'] == 'ready';
    bool available(String k) =>
        {'capital', 'treasury', 'insiders', 'majorHoldings'}.contains(k) ||
        _feeds[k]?['state'] == 'ready' ||
        _feeds[k]?['state'] == 'error';
    final visibleKinds = widget.kinds
        .where((k) => _showUnavailable || available(k))
        .toList();
    final hasUnavailable = widget.kinds.any((k) => !available(k));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (visibleKinds.length > 1 || _showUnavailable)
            LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth < 500
                    ? box.maxWidth
                    : (box.maxWidth - AppSpace.sm) / 2;
                return Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final kind in visibleKinds)
                      SizedBox(
                        width: width,
                        child: Material(
                          color: kind == _kind
                              ? context.colors.surface
                              : context.colors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: context.shape.borderRadius,
                            side: BorderSide(
                              color: kind == _kind
                                  ? context.colors.accent
                                  : context.colors.border,
                            ),
                          ),
                          child: ShadButton.ghost(
                            height: 0,
                            width: double.infinity,
                            padding: EdgeInsets.zero,
                            onPressed: () => setState(() {
                              _kind = kind;
                              _limit = 5;
                              _series = null;
                              _error = null;
                            }),
                            child: Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpace.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      researchLabels[kind]!,
                                      style: context.typo.body(
                                        14,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.xs),
                                    Text(
                                      researchOverview(kind, _feeds[kind]),
                                      style: context.typo.body(
                                        12,
                                        color: context.colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: AppSpace.md),
          if (feed == null)
            const ShadProgress(minHeight: 2)
          else if (!ready)
            Row(
              children: [
                Expanded(
                  child: Text(
                    feed['message'] as String? ?? '수집 전입니다.',
                    style: context.typo.body(
                      13,
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
                if ({
                  'error',
                  'retryLater',
                  'collecting',
                }.contains(feed['state']))
                  ShadButton.ghost(
                    onPressed: _load,
                    child: Flexible(child: const Text('다시 시도')),
                  ),
              ],
            )
          else if (rows.isEmpty)
            Text(
              '수집 범위에 해당 보고가 없습니다.',
              style: context.typo.body(13, color: context.colors.textMuted),
            )
          else ...[
            if (_kind == 'insiders' || _kind == 'majorHoldings')
              Text(
                '공시 접수일 기준 · 보유 증감은 매매뿐 아니라 증여·상속·전환 등을 포함합니다.',
                style: context.typo.body(12, color: context.colors.textMuted),
              ),
            if ({
              'flows',
              'shorts',
              'consensus',
              'program',
              'credit',
              'lending',
            }.contains(_kind))
              _feedChart(context, rows)
            else ...[
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border.all(color: context.colors.border),
                  borderRadius: context.shape.borderRadius,
                ),
                child: Column(
                  children: [
                    for (final (index, row)
                        in rows.reversed.take(_limit).indexed) ...[
                      if (index > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: context.colors.border,
                        ),
                      ResearchEventCard(row: row),
                    ],
                  ],
                ),
              ),
              if (rows.length > _limit)
                ShadButton.ghost(
                  onPressed: () => setState(() => _limit += 20),
                  child: Flexible(
                    child: Text('이전 보고 더 보기 · ${rows.length - _limit}건'),
                  ),
                ),
            ],
          ],
          if (widget.showManagement &&
              (ready || hasUnavailable || context.isAdmin))
            ShadAccordion<int>(
              maintainState: false,
              children: [
                ShadAccordionItem<int>(
                  value: 0,
                  title: Text(
                    context.isAdmin ? '출처 · 관리' : '출처 · 자료 상태',
                    style: context.typo.body(
                      12,
                      color: context.colors.textMuted,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ready)
                        Text(
                          '${feed?['provider']} · 수집 ${feed?['collectedAt'].toString().split('T').first}',
                          style: context.typo.body(
                            11,
                            color: context.colors.textMuted,
                          ),
                        ),
                      if (hasUnavailable)
                        ShadButton.ghost(
                          onPressed: () => setState(() {
                            _showUnavailable = !_showUnavailable;
                            if (!_showUnavailable && !available(_kind)) {
                              _kind = widget.kinds.firstWhere(
                                available,
                                orElse: () => widget.kinds.first,
                              );
                            }
                          }),
                          child: Flexible(
                            child: Text(
                              _showUnavailable ? '미연결 항목 접기' : '미연결 항목 보기',
                            ),
                          ),
                        ),
                      if (context.isAdmin &&
                          {
                            'insiders',
                            'majorHoldings',
                            'capital',
                            'treasury',
                            'flows',
                            'shorts',
                          }.contains(_kind))
                        Align(
                          alignment: Alignment.centerRight,
                          child: ShadButton.ghost(
                            onPressed: _collecting != null ? null : _collect,
                            enabled:
                                (_collecting != null ? null : _collect) != null,
                            child: Flexible(
                              child: Text(
                                _collecting == null ? '자료 수집·갱신' : '수집 중…',
                              ),
                            ),
                          ),
                        ),
                      if (context.isAdmin &&
                          {
                            'consensus',
                            'flows',
                            'shorts',
                            'program',
                            'credit',
                            'lending',
                          }.contains(_kind))
                        ResearchImport(
                          corpCode: widget.corpCode,
                          kind: _kind,
                          onSaved: _load,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          if (_error != null)
            Text(
              _error!,
              style: context.typo.body(12, color: context.colors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _feedChart(BuildContext context, List<Map<String, dynamic>> rows) {
    // Keep securities, periods and accounting bases separate.
    String key(Map r) => _kind == 'consensus'
        ? '${r['metric']} · ${r['periodStart']}~${r['periodEnd']} · ${r['basis']} · ${r['stockCode'] ?? ''}'
        : '${r['stockCode']}';
    final keys = rows.map(key).toSet().toList();
    final selected = keys.contains(_series) ? _series! : keys.first;
    final data = rows.where((r) => key(r) == selected).toList()
      ..sort((a, b) => '${a['date']}'.compareTo('${b['date']}'));
    final visible = data.length > 120 ? data.sublist(data.length - 120) : data;
    final colors = [
      context.colors.chartSeries1,
      context.colors.chartSeries2,
      context.colors.chartSeries3,
    ];
    final fields = _kind == 'flows'
        ? ['foreign', 'institution', 'individual']
        : [
            switch (_kind) {
              'shorts' => 'volume',
              'program' => 'netVolume',
              'credit' || 'lending' => 'balanceVolume',
              _ => 'value',
            },
          ];
    const names = {
      'foreign': '외국인 순매수',
      'institution': '기관 순매수',
      'individual': '개인 순매수',
      'volume': '공매도 수량',
      'value': '추정치',
      'netVolume': '프로그램 순매수',
      'balanceVolume': '잔고 수량',
    };
    final series = [
      for (var i = 0; i < fields.length; i++)
        ChartSeries(
          label: names[fields[i]]!,
          color: colors[i],
          values: [for (final r in visible) double.tryParse('${r[fields[i]]}')],
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelect<String>(
          options: Map.fromEntries([
            for (final k in keys) MapEntry(k, _seriesLabel(k)),
          ]),
          value: selected,
          onChanged: (v) => setState(() => _series = v),
          placeholder: '선택',
          allowClear: false,
        ),
        ChartLegend(series: series),
        AppColumnChart(
          categories: [for (final r in visible) '${r['date']}'],
          series: series,
          formatValue: (v) => _kind == 'consensus'
              ? formatKrwLong(v)
              : '${formatCount(v.round())}주',
        ),
        if (_kind == 'consensus')
          Text(
            '참여기관 ${visible.last['contributors']}곳 · 예상치는 실적과 다릅니다.',
            style: context.typo.body(12),
          ),
        if (_kind == 'shorts')
          Text(
            '최근 공매도 비중 ${_shortRatio(visible.last)}',
            style: context.typo.body(12),
          ),
        if (_kind == 'consensus' && visible.last['actual'] != null)
          Text(
            '발표 실적 ${formatKrwLong(double.parse(visible.last['actual']))} · 발표 전 추정 대비 ${_surprise(visible.last)}',
            style: context.typo.body(12),
          ),
      ],
    );
  }

  String _seriesLabel(String key) {
    const names = {
      'revenue': '매출액',
      'operatingProfit': '영업이익',
      'netIncome': '순이익',
      'eps': '주당순이익',
      'targetPrice': '목표주가',
      'consolidated': '연결',
      'separate': '별도',
    };
    var label = key;
    for (final e in names.entries) {
      label = label.replaceAll(e.key, e.value);
    }
    return label;
  }

  String _shortRatio(Map r) {
    final total = double.tryParse('${r['totalVolume']}');
    return total == null || total == 0
        ? '계산 불가'
        : '${(double.parse(r['volume']) / total * 100).toStringAsFixed(2)}%';
  }

  String _surprise(Map r) {
    final estimate = double.parse(r['value']);
    return estimate == 0
        ? '계산 불가'
        : '${((double.parse(r['actual']) - estimate) / estimate.abs() * 100).toStringAsFixed(1)}%';
  }
}

class ResearchEventCard extends StatelessWidget {
  const ResearchEventCard({super.key, required this.row});
  final Map<String, dynamic> row;
  double? n(String k) => double.tryParse('${row[k]}');
  String count(String k) =>
      n(k) == null ? '—' : '${formatCount(n(k)!.round())}주';
  @override
  Widget build(BuildContext context) {
    if (row['reporter'] == null) return _DecisionCard(row: row);
    final change = n('change'), holding = n('holdings');
    final delta = change == null
        ? '보유 증감 미확인'
        : '${change >= 0 ? '+' : ''}${formatCount(change.round())}주';
    return Material(
      color: context.colors.surface,
      child: ShadAccordion<int>(
        key: ValueKey('holding-${row['receipt']}'),
        maintainState: false,
        children: [
          ShadAccordionItem<int>(
            value: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpace.sm,
                  children: [
                    Text(
                      '${row['date']}',
                      style: context.typo.body(
                        12,
                        color: context.colors.textMuted,
                      ),
                    ),
                    Text(
                      '보고자 ${row['reporter']}',
                      style: context.typo.body(14, weight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(delta, style: context.typo.body(13)),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (row['api'] == 'majorstock')
                    Text(
                      '보고서의 합산 보유량 · 특별관계자 포함 여부는 원문 확인',
                      style: context.typo.body(12),
                    ),
                  Text(
                    '${holding != null && change != null && holding - change >= 0 ? '${formatCount((holding - change).round())} → ' : ''}${count('holdings')}${n('ratio') == null ? '' : ' · ${n('ratio')}%'}',
                    style: context.typo.body(13),
                  ),
                  if (row['reason'] != null)
                    Text('${row['reason']}', style: context.typo.body(13)),
                  ShadButton.ghost(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${row['receipt']}',
                      ),
                    ),
                    leading: const Icon(Icons.open_in_new, size: 14),
                    child: Flexible(child: const Text('공시 원문')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.row});
  final Map<String, dynamic> row;
  double? n(String k) => double.tryParse('${row[k]}');
  @override
  Widget build(BuildContext context) {
    final exchange = row['api'] == 'exbdIsDecsn';
    final equity = row['api'] == 'piicDecsn';
    final purposes = ((row['purposes'] as List?) ?? []).cast<Map>();
    final shares = n('shares'), before = n('existingShares');
    final ratio = shares != null && before != null && before > 0
        ? shares / before * 100
        : n('ratioToExisting');
    final purpose = purposes.map((p) => p['label']).join(' · ');
    final shareLabel = exchange
        ? ('${row['stockKind']}'.contains('자기주식')
              ? '기존 자기주식 교환 대상'
              : '기존 주식 교환 대상')
        : equity
        ? '신주 발행 예정'
        : '대상 주식';
    Widget line(String t) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Text(t, style: context.typo.body(13)),
    );
    final summary = equity
        ? (ratio != null
              ? '신주 발행 예정 · 기존 주식의 ${ratio.toStringAsFixed(2)}%'
              : '새 주식을 발행해 자금 마련')
        : exchange
        ? (ratio != null
              ? '기존 주식 ${ratio.toStringAsFixed(2)}%가 교환 대상'
              : '기존 주식을 교환하는 조건으로 자금 마련')
        : row['api'] == 'cvbdIsDecsn'
        ? '향후 주식으로 바꿀 수 있는 채권 발행'
        : row['api'] == 'bdwtIsDecsn'
        ? '새 주식을 살 권리가 붙은 채권 발행'
        : shares != null
        ? '예정 ${formatCount(shares.round())}주'
        : n('amount') != null
        ? '예정 ${formatKrwLong(n('amount')!)}'
        : '규모와 목적 보기';
    return Material(
      color: context.colors.surface,
      child: ShadAccordion<int>(
        key: ValueKey('conditions-${row['receipt']}'),
        maintainState: false,
        children: [
          ShadAccordionItem<int>(
            value: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final event = Text(
                      '${row['label'] ?? researchPlainTitle(row)}',
                      style: context.typo.body(15, weight: FontWeight.w600),
                    );
                    final date = Text(
                      '${row['date']}',
                      style: context.typo.body(
                        12,
                        color: context.colors.textMuted,
                      ),
                    );
                    return constraints.maxWidth < 420
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [date, event],
                          )
                        : Row(
                            children: [
                              SizedBox(width: 104, child: date),
                              Expanded(child: event),
                            ],
                          );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (row['label'] != null &&
                          researchPlainTitle(row) != row['label'])
                        Text(
                          researchPlainTitle(row),
                          style: context.typo.body(
                            12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      Text(
                        summary.isEmpty ? purpose : summary,
                        style: context.typo.body(
                          12,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (purpose.isNotEmpty) line('목적 · $purpose'),
                        if (n('amount') != null)
                          line('금액 · ${formatKrwLong(n('amount')!)}'),
                        if (shares != null)
                          line('$shareLabel ${formatCount(shares.round())}주'),
                        if (row['method'] != null)
                          line('방식 · ${row['method']}'),
                        if (row['stockKind'] != null)
                          line('대상 · ${row['stockKind']}'),
                        if (row['series'] != null) line('${row['series']}회차'),
                        if (n('otherShares') != null)
                          line(
                            '기타주식 ${formatCount(n('otherShares')!.round())}주',
                          ),
                        if (n('otherAmount') != null)
                          line('기타주식 예정금액 ${formatKrwLong(n('otherAmount')!)}'),
                        if (n('conversionPrice') != null)
                          line(
                            '${exchange ? '교환가' : '전환·행사가'} ${formatCount(n('conversionPrice')!.round())}원 / 주',
                          ),
                        for (final p in purposes)
                          line(
                            '${p['label']} · ${formatKrwLong(double.parse('${p['amount']}'))}',
                          ),
                        if (equity &&
                            n('amount') == null &&
                            purposes.isNotEmpty)
                          line(
                            '사용 목적별 금액은 DART API 응답 기준입니다. 발행 조건과 정정 사항은 원문에서 확인하세요.',
                          ),
                        if (before != null && shares != null)
                          line(
                            '비율 = 예정 주식 ${formatCount(shares.round())} ÷ 기존 주식 ${formatCount(before.round())}',
                          ),
                        if (exchange && ratio != null && before == null)
                          line('기존 주식 대비 비율은 공시 기재 값입니다.'),
                        if (row['maturityDate'] != null)
                          line(
                            '만기 ${row['maturityDate']} · 표면금리 ${row['coupon'] ?? '—'}%',
                          ),
                        if (row['periodStart'] != null ||
                            row['periodEnd'] != null)
                          line(
                            '예정 기간 ${row['periodStart'] ?? '미확인'} → ${row['periodEnd'] ?? '미확인'}',
                          ),
                        if (row['paymentDate'] != null)
                          line('납입 예정일 ${row['paymentDate']}'),
                        if (row['decisionDate'] != null)
                          line(
                            '결정일 ${row['decisionDate']} · 접수일 ${row['date']}',
                          ),
                        if (row['reason'] != null) line('${row['reason']}'),
                        line('결정 공시이며 이행 완료를 뜻하지 않습니다. 정정·철회는 원문 확인이 필요합니다.'),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ShadButton.ghost(
                      onPressed: () => launchUrl(
                        Uri.parse(
                          'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${row['receipt']}',
                        ),
                      ),
                      leading: const Icon(Icons.open_in_new, size: 14),
                      child: Flexible(child: const Text('공시 원문')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rule-based wording: a decision remains a plan, never a completed action.
String researchPlainTitle(Map<String, dynamic> row) {
  final reason = '${row['reason'] ?? ''}';
  return switch (row['api']) {
    'tsstkAqDecsn' =>
      reason.contains('소각') ? '없앨 목적으로 자기주식을 살 계획' : '회사가 자기주식을 살 계획',
    'tsstkDpDecsn' =>
      RegExp('보수|보상|성과급|스톡옵션|주식매수선택권').hasMatch(reason)
          ? '보상으로 회사 보유 주식을 지급할 계획'
          : '회사 보유 주식을 팔거나 넘길 계획',
    'tsstkAqTrctrCnsDecsn' => '금융기관에 자기주식 매입을 맡길 계획',
    'tsstkAqTrctrCcDecsn' => '자기주식 매입 위탁계약을 끝낼 계획',
    'piicDecsn' => '새 주식을 발행해 자금을 마련할 계획',
    'exbdIsDecsn' => '기존 주식을 교환 조건으로 돈을 빌릴 계획',
    'cvbdIsDecsn' => '주식으로 바꿀 수 있는 채권을 발행할 계획',
    'bdwtIsDecsn' => '주식 매입 권리가 붙은 채권을 발행할 계획',
    _ => '${row['label'] ?? '공시'}',
  };
}

String researchOverview(String kind, Map<String, dynamic>? feed) {
  if (feed == null) return '확인 중…';
  if (feed['state'] != 'ready') {
    return switch (feed['state']) {
      'error' => '불러오기 실패',
      'collecting' => '수집 대기 중…',
      'retryLater' => '수집 지연 · 재시도 예정',
      'budgetExhausted' => '오늘 수집 한도 소진 · 내일 재개',
      'notConfigured' => '수집 연결 미설정',
      'schemaPending' => '저장소 준비 중',
      _ => '아직 수집하지 않은 자료예요',
    };
  }
  final rows = ((feed['rows'] as List?) ?? []).cast<Map<String, dynamic>>();
  if (rows.isEmpty) return '수집 범위에서 해당 공시가 없어요';
  final sorted = [...rows]
    ..sort((a, b) => '${a['date']}'.compareTo('${b['date']}'));
  final r = sorted.last;
  final amount = double.tryParse('${r['amount']}');
  final change = double.tryParse('${r['change']}');
  final ratio = double.tryParse('${r['ratio']}');
  final size = amount != null
      ? '예정 ${amount >= 1000000000000
            ? '약 ${(amount / 1000000000000).toStringAsFixed(1)}조원'
            : amount >= 100000000
            ? '약 ${(amount / 100000000).toStringAsFixed(0)}억원'
            : formatKrwLong(amount)}'
      : change != null
      ? '증감 ${change >= 0 ? '+' : ''}${formatCount(change.round())}주${ratio == null ? '' : ' · 공시 지분 ${ratio.toStringAsFixed(2)}%'}'
      : double.tryParse('${r['shares']}') != null
      ? '${formatCount(double.parse('${r['shares']}').round())}주'
      : '규모는 상세 확인';
  final event = r['reporter'] != null
      ? '보고자 ${r['reporter']}'
      : '${r['label'] ?? researchPlainTitle(r)}';
  return '최근 · ${r['date']}\n$event\n$size · 수집 ${rows.length}건';
}
