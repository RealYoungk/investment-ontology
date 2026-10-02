import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../app/ingest_monitor.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../auth/app_viewer.dart';
import '../research/research_section.dart';
import 'bond_trends_card.dart';

/// Constant holdings, same share class, all entered new shares issued.
double? dilutedOwnership(double held, double issued, double additional) {
  if (!held.isFinite ||
      !issued.isFinite ||
      !additional.isFinite ||
      held < 0 ||
      issued <= 0 ||
      held > issued ||
      additional < 0) {
    return null;
  }
  return held / (issued + additional) * 100;
}

class CapitalStructureCard extends StatefulWidget {
  const CapitalStructureCard({super.key, required this.corpCode});
  final String corpCode;
  @override
  State<CapitalStructureCard> createState() => _CapitalStructureCardState();
}

class _CapitalStructureCardState extends State<CapitalStructureCard> {
  ShareholderReturn? _data;
  Map<String, dynamic>? _capital;
  bool _collecting = false;
  String? _collectionError;
  bool _failed = false;
  bool _loaded = false;
  int _request = 0;
  final _held = TextEditingController();
  final _additional = TextEditingController();
  String? _kind;
  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final results = await Future.wait([
        client.disclosure.shareholderReturn(widget.corpCode),
        client.capital.summary(widget.corpCode),
      ]);
      final data = results[0] as ShareholderReturn;
      final capital = jsonDecode(results[1] as String) as Map<String, dynamic>;
      if (capital['state'] == 'ready') {
        final stocks = (capital['stocks'] as List).cast<Map<String, dynamic>>();
        if (stocks.any((r) => r['issued'] != null)) {
          data.stockTotals = [
            for (final r in stocks)
              StockTotalRow(
                kind: r['kind'] as String,
                issued: BigInt.tryParse(r['issued']?.toString() ?? ''),
                authorized: BigInt.tryParse(r['authorized']?.toString() ?? ''),
                treasury: BigInt.tryParse(r['treasury']?.toString() ?? ''),
              ),
          ];
        }
      }
      if (mounted && request == _request) {
        setState(() {
          _data = data;
          _capital = capital;
          _failed = false;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  Future<void> _collect() async {
    if (!context.ensureAdmin()) return;
    setState(() {
      _collecting = true;
      _collectionError = null;
    });
    try {
      await client.capital.collect(widget.corpCode);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _collectionError = e.toString());
    } finally {
      if (mounted) setState(() => _collecting = false);
    }
  }

  Widget _overhang(BuildContext context) {
    final c = context.colors, t = context.typo;
    final data = _capital;
    final entries = ((data?['entries'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final states = (data?['states'] as Map?) ?? {};
    String stateLabel(String type) => switch (states[type]) {
      'verified' => '수량 검산 통과',
      'none' => '해당 없음 공시',
      'partial' => '일부 미확인·검산 불일치',
      _ => '미확보',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CompanySectionHeading('CB·BW·EB 잔여 물량'),
        Text(
          '기준일: ${data?['periodEnd'] ?? '미확보'} · 기준일 이후 행사·상환은 반영되지 않습니다.',
          style: t.body(12, color: c.textSecondary),
        ),
        for (final type in ['CB', 'BW', 'EB'])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Text('$type · ${stateLabel(type)}'),
          ),
        if (entries.isNotEmpty)
          AppDataTable(
            columns: const [
              AppColumn('유형·회차'),
              AppColumn('대상 주식'),
              AppColumn('미상환 잔액'),
              AppColumn('전환·행사가'),
              AppColumn('가능 주식 수'),
              AppColumn('검산·기간'),
            ],
            rows: [
              for (final r in entries)
                AppRow([
                  AppDataTable.text(context, "${r['type']} ${r['series']}"),
                  AppDataTable.text(context, r['stockKind'].toString()),
                  AppDataTable.text(
                    context,
                    "${r['balance']} ${r['unit'] ?? '단위 미확인'}",
                  ),
                  AppDataTable.text(context, "${r['price'] ?? '미확보'} 원"),
                  AppDataTable.text(context, "${r['shares']} 주"),
                  AppDataTable.text(
                    context,
                    "${r['validation'] == 'verified'
                        ? '검산 통과'
                        : r['validation'] == 'mismatch'
                        ? '수량 불일치'
                        : '검산 미확인'} · ${r['exercisePeriod'] ?? '기간 미확보'}",
                  ),
                ]),
            ],
          ),
        Text(
          'CB·BW는 대상 주식 종류별로 확인합니다. EB는 기존 주식 교환 물량으로 신주 희석에 합산하지 않습니다. 미확보는 물량이 없다는 뜻이 아닙니다.',
          style: t.body(12, color: c.textSecondary),
        ),
        if (data?['receipt'] != null)
          AppButton(
            label: '기준 보고서 원문',
            variant: AppButtonVariant.link,
            onPressed: () => launchUrl(
              Uri.parse(
                'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${data!['receipt']}',
              ),
            ),
          ),
        if (context.isAdmin)
          AppButton(
            label: _collecting ? '원문 확인 중…' : '최신 정기보고서 잔여 물량 수집',
            onPressed: _collecting ? null : _collect,
          ),
        if (_collectionError != null) Text('수집 실패 · $_collectionError'),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant CapitalStructureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) {
      _data = null;
      _capital = null;
      _loaded = false;
      _failed = false;
      _kind = null;
      _held.clear();
      _additional.clear();
      _load();
    }
  }

  @override
  void dispose() {
    _request++;
    IngestMonitor.instance.dataVersion.removeListener(_load);
    _held.dispose();
    _additional.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo, c = context.colors;
    final samePeriod = ((_capital?['stocks'] as List?) ?? []).any(
      (r) => r['issued'] != null,
    );
    final rows =
        _data?.stockTotals
            .where(
              (r) =>
                  r.kind.replaceAll(' ', '') != '합계' &&
                  r.issued != null &&
                  r.issued! > BigInt.zero,
            )
            .toList() ??
        <StockTotalRow>[];
    final selected =
        rows.where((r) => r.kind == _kind).firstOrNull ?? rows.firstOrNull;
    double? number(String s) => double.tryParse(s.replaceAll(',', '').trim());
    final held = number(_held.text), additional = number(_additional.text);
    final issued = selected?.issued?.toDouble();
    final after = held == null || issued == null || additional == null
        ? null
        : dilutedOwnership(held, issued, additional);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompanyDataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CompanySectionHeading('주식 수와 잠재 희석'),
              const SizedBox(height: AppSpace.sm),
              if (_failed)
                ReadFailureNotice(subject: '주식 수', retry: _load)
              else if (!_loaded)
                const Text('주식 총수 자료를 확인 중입니다.')
              else if (rows.isEmpty)
                const Text('발행주식 수 미확보 · 희석률을 계산할 기준 수량이 없습니다.')
              else ...[
                Text(
                  '주식 총수 · ${samePeriod ? _capital!['periodEnd'] : 'FY${_data!.stockTotalYear}'} · 수량 단위: 주',
                  style: t.body(12, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.sm),
                AppDataTable(
                  columns: const [
                    AppColumn('종류'),
                    AppColumn('발행주식', numeric: true),
                    AppColumn('발행 가능한 총수', numeric: true),
                    AppColumn('자기주식', numeric: true),
                  ],
                  rows: [
                    for (final r in rows)
                      AppRow([
                        AppDataTable.text(context, r.kind),
                        for (final v in [r.issued, r.authorized, r.treasury])
                          AppDataTable.text(
                            context,
                            v == null ? '미확보' : formatCount(v.toInt()),
                            numeric: true,
                          ),
                      ]),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '발행 가능한 총수는 정관상 한도이며 발행 계획이 아닙니다.',
                  style: t.body(12, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.lg),
                const CompanySectionHeading('내 지분 변화 계산'),
                Text(
                  '미상환 CB·BW 등에서 확인한 추가 신주 수를 입력하세요. 공시 기준 수량을 사용하는 가정 계산입니다.',
                  style: t.body(12, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.sm),
                if (_capital?['state'] == 'ready' && samePeriod) ...[
                  AppButton(
                    label: '확인된 CB·BW 물량으로 계산',
                    onPressed: () {
                      final entries = (_capital!['entries'] as List)
                          .cast<Map<String, dynamic>>();
                      final candidates = entries.where(
                        (r) =>
                            ['CB', 'BW'].contains(r['type']) &&
                            r['validation'] == 'verified' &&
                            r['stockKind']
                                .toString()
                                .replaceAll(' ', '')
                                .contains(
                                  selected!.kind
                                      .replaceAll(' ', '')
                                      .replaceAll('주식', '주'),
                                ),
                      );
                      final total = candidates.fold<BigInt>(
                        BigInt.zero,
                        (sum, r) => sum + BigInt.parse(r['shares'] as String),
                      );
                      setState(() => _additional.text = total.toString());
                    },
                  ),
                  Text(
                    '검산 통과한 같은 종류의 주식만 반영합니다. CB·BW 항목이 미확보 또는 불일치이면 전체 물량과 최대 희석률은 미확정입니다.',
                    style: t.body(12, color: c.textSecondary),
                  ),
                ],
                if (rows.length > 1)
                  DropdownButton<String>(
                    value: selected!.kind,
                    isExpanded: true,
                    items: [
                      for (final r in rows)
                        DropdownMenuItem(value: r.kind, child: Text(r.kind)),
                    ],
                    onChanged: (v) => setState(() => _kind = v),
                  ),
                Wrap(
                  spacing: AppSpace.md,
                  runSpacing: AppSpace.sm,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _held,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '내 보유 주식 수',
                          suffixText: '주',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _additional,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '추가 발행 가정 수량',
                          suffixText: '주',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                if (after != null) ...[
                  Text(
                    '${(held! / issued! * 100).toStringAsFixed(4)}% → ${after.toStringAsFixed(4)}%',
                    style: t.numeric(24, weight: FontWeight.w600),
                  ),
                  Text(
                    '기존 지분 대비 ${(additional! / (issued + additional) * 100).toStringAsFixed(2)}% 감소 · 보유 수량 유지 가정',
                    style: t.body(13),
                  ),
                ] else if (_held.text.isNotEmpty || _additional.text.isNotEmpty)
                  const Text('보유 수량은 발행주식 이하, 추가 수량은 0 이상의 숫자로 입력하세요.'),
                Text(
                  '계산: 보유 주식 ÷ (기존 발행주식 + 추가 신주). EB는 기존 주식 교환이므로 신주 수에 더하지 않습니다. 전환가 조정·행사·상환과 기준일 이후 주식 수 변동은 별도로 확인해야 합니다.',
                  style: t.body(12, color: c.textSecondary),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              for (final source in _data?.sources ?? <Source>[])
                if (source.url != null && source.title.contains('주식의 총수'))
                  AppButton(
                    label: '주식 총수 원문 · ${source.reference ?? ''}',
                    variant: AppButtonVariant.link,
                    onPressed: () => launchUrl(Uri.parse(source.url!)),
                  ),
              _overhang(context),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        BondTrendsCard(corpCode: widget.corpCode),
        const SizedBox(height: AppSpace.md),
        ResearchSection(corpCode: widget.corpCode, kinds: const ['capital']),
      ],
    );
  }
}
