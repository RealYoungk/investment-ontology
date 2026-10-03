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
import 'bond_trends_card.dart';

/// Relative ownership reduction with unchanged holdings; no personal input needed.
double? maximumOwnershipDilution(BigInt? issued, BigInt? additional) {
  if (additional == null || additional < BigInt.zero) return null;
  if (additional == BigInt.zero) return 0;
  if (issued == null || issued <= BigInt.zero) return null;
  return additional.toDouble() / (issued + additional).toDouble() * 100;
}

/// Only a complete, verified same-class CB/BW disclosure supports a maximum.
BigInt? disclosedNewShares(Map<String, dynamic>? data, String kind) {
  if (data?['state'] != 'ready') return null;
  final states = data!['states'] as Map? ?? {};
  if (![
    'CB',
    'BW',
  ].every((type) => ['verified', 'none'].contains(states[type]))) {
    return null;
  }
  final entries = (data['entries'] as List? ?? []).cast<Map<String, dynamic>>();
  String normalize(Object? value) =>
      '$value'.replaceAll(' ', '').replaceAll('주식', '주');
  var total = BigInt.zero;
  for (final row in entries.where((r) => ['CB', 'BW'].contains(r['type']))) {
    if (row['validation'] != 'verified') return null;
    if (!['보통주', '우선주'].contains(normalize(row['stockKind']))) return null;
    final shares = BigInt.tryParse('${row['shares']}');
    if (shares == null || shares < BigInt.zero) return null;
    if (normalize(row['stockKind']) == normalize(kind)) total += shares;
  }
  for (final type in ['CB', 'BW']) {
    if (states[type] == 'verified' && !entries.any((r) => r['type'] == type)) {
      return null;
    }
    if (states[type] == 'none' && entries.any((r) => r['type'] == type)) {
      return null;
    }
  }
  return total;
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

  Widget _evidence(BuildContext context) {
    final entries = ((_capital?['entries'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    if (entries.isEmpty) return const SizedBox.shrink();
    return ShadAccordion<int>(
      maintainState: false,
      children: [
        ShadAccordionItem<int>(
          value: 0,
          title: const Text('회차별 물량과 과거 추이'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDataTable(
                columns: const [
                  AppColumn('유형·회차'),
                  AppColumn('대상'),
                  AppColumn('가능 주식 수', numeric: true),
                  AppColumn('전환·행사가', numeric: true),
                ],
                rows: [
                  for (final row in entries)
                    AppRow([
                      AppDataTable.text(
                        context,
                        "${row['type']} ${row['series']}",
                      ),
                      AppDataTable.text(context, '${row['stockKind']}'),
                      AppDataTable.text(
                        context,
                        "${row['shares'] ?? '미확보'}${row['validation'] == 'verified' ? '' : ' · 검산 미완료'}",
                        numeric: true,
                      ),
                      AppDataTable.text(
                        context,
                        "${row['price'] ?? '미확보'} 원",
                        numeric: true,
                      ),
                    ]),
                ],
              ),
              BondTrendsCard(corpCode: widget.corpCode),
            ],
          ),
        ),
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
      _load();
    }
  }

  @override
  void dispose() {
    _request++;
    IngestMonitor.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo, c = context.colors;
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
    final snapshotStocks = ((_capital?['stocks'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final states = _capital?['states'] as Map? ?? {};
    final allMissing = ![
      'CB',
      'BW',
      'EB',
    ].any((type) => ['verified', 'none', 'partial'].contains(states[type]));
    return CompanyDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CompanySectionHeading('앞으로 주식이 얼마나 늘어날 수 있나?'),
          const SizedBox(height: AppSpace.sm),
          if (_failed)
            ReadFailureNotice(subject: '주식 수', retry: _load)
          else if (!_loaded)
            const Text('공시 자료를 확인 중입니다.')
          else ...[
            Text(
              '공시 기준 · ${_capital?['periodEnd'] ?? 'FY${_data?.stockTotalYear ?? '미확보'}'}',
              style: t.body(12, color: c.textSecondary),
            ),
            const SizedBox(height: AppSpace.md),
            if (allMissing) ...[
              Text(
                '추가 발행 가능 물량 미확보',
                style: t.body(18, weight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'CB·BW 공시가 아직 확보되지 않아 최대 희석률을 계산할 수 없습니다.',
                style: t.body(13, color: c.textSecondary),
              ),
            ] else
              for (final stock in rows) ...[
                Builder(
                  builder: (context) {
                    final additional = disclosedNewShares(_capital, stock.kind);
                    final snapshot = snapshotStocks
                        .where((r) => r['kind'] == stock.kind)
                        .firstOrNull;
                    final issued = BigInt.tryParse('${snapshot?['issued']}');
                    final dilution = maximumOwnershipDilution(
                      issued,
                      additional,
                    );
                    return Wrap(
                      spacing: AppSpace.xl,
                      runSpacing: AppSpace.md,
                      children: [
                        _metric(
                          context,
                          '${stock.kind} 추가 발행 가능',
                          additional == null
                              ? '미확정'
                              : '${formatCount(additional.toInt())}주',
                        ),
                        _metric(
                          context,
                          '기존 주주의 최대 희석',
                          dilution == null
                              ? '계산 불가'
                              : '${dilution.toStringAsFixed(2)}%',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpace.md),
              ],
            if (!allMissing)
              Text(
                '공시된 CB·BW가 모두 전환·행사되는 경우입니다. 실제 발행이 확정된 수량은 아닙니다.',
                style: t.body(12, color: c.textSecondary),
              ),
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.xs,
              children: [
                for (final type in ['CB', 'BW', 'EB'])
                  Text(
                    '$type · ${_typeQuantity(type, states)}',
                    style: t.body(13, color: c.textSecondary),
                  ),
              ],
            ),
            if (!allMissing)
              Text(
                'EB는 기존 주식을 교환하므로 신주 희석에서 제외합니다.',
                style: t.body(12, color: c.textSecondary),
              ),
            const SizedBox(height: AppSpace.lg),
            const CompanySectionHeading('현재 주식 수와 정관 한도'),
            if (rows.isEmpty)
              const Text('주식 수 미확보')
            else
              AppDataTable(
                columns: const [
                  AppColumn('종류'),
                  AppColumn('발행주식', numeric: true),
                  AppColumn('정관상 발행 한도', numeric: true),
                ],
                rows: [
                  for (final row in rows)
                    AppRow([
                      AppDataTable.text(context, row.kind),
                      AppDataTable.text(
                        context,
                        formatCount(row.issued!.toInt()),
                        numeric: true,
                      ),
                      AppDataTable.text(
                        context,
                        row.authorized == null
                            ? '미확보'
                            : formatCount(row.authorized!.toInt()),
                        numeric: true,
                      ),
                    ]),
                ],
              ),
            Text(
              '정관 한도는 발행 계획이 아닙니다.${snapshotStocks.isEmpty ? ' · 주식 수 FY${_data?.stockTotalYear ?? '미확보'} 기준' : ''}',
              style: t.body(12, color: c.textSecondary),
            ),
            _evidence(context),
            if (_capital?['receipt'] != null)
              ShadButton.raw(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${_capital!['receipt']}',
                  ),
                ),
                variant: ShadButtonVariant.link,
                child: Text('공시 원문'),
              ),
            if (context.isAdmin)
              ShadButton.raw(
                onPressed: _collecting ? null : _collect,
                enabled: (_collecting ? null : _collect) != null,
                variant: ShadButtonVariant.outline,
                child: Text(_collecting ? '공시 확인 중…' : '최신 공시 물량 수집'),
              ),
            if (_collectionError != null) Text('수집 실패 · $_collectionError'),
          ],
        ],
      ),
    );
  }

  String _typeQuantity(String type, Map states) {
    if (states[type] == 'none') return '없음';
    if (states[type] != 'verified') {
      return states[type] == 'partial' ? '일부 미확인' : '미확보';
    }
    final entries = ((_capital?['entries'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .where((r) => r['type'] == type)
        .toList();
    if (entries.isEmpty) return '미확정';
    var total = BigInt.zero;
    for (final entry in entries) {
      final shares = BigInt.tryParse('${entry['shares']}');
      if (entry['validation'] != 'verified' ||
          shares == null ||
          shares < BigInt.zero) {
        return '미확정';
      }
      total += shares;
    }
    return '${formatCount(total.toInt())}주';
  }

  Widget _metric(BuildContext context, String label, String value) => SizedBox(
    width: 250,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typo.body(13, color: context.colors.textSecondary),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(value, style: context.typo.numeric(24, weight: FontWeight.w600)),
      ],
    ),
  );
}
