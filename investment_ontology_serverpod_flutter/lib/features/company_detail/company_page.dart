import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/ingest_monitor.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../financials/financial_section.dart';
import 'widgets/company_header.dart';
import 'widgets/company_overview_tab.dart';

enum CompanyTab { overview, financials }

/// 기업 상세: 헤더(이름 · 분류 · 핵심 지표) + 탭(개요 · 재무).
///
/// 개요는 각 탭의 요약이고 자세한 내용은 탭에서 본다. 탭은 데이터가 생기는 단계마다 늘린다
/// (3단계 지배구조 등). 빈 탭은 만들지 않는다.
class CompanyPage extends StatefulWidget {
  const CompanyPage({
    super.key,
    required this.corpCode,
    this.initialTab = CompanyTab.overview,
  });

  final String corpCode;
  final CompanyTab initialTab;

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  late CompanyTab _tab = widget.initialTab;

  CompanyDetail? _detail;
  CompanyFinancials? _financials;
  Object? _error;
  bool _loaded = false;

  /// 새 데이터를 불러올 때마다 올려 재무 탭을 새 값으로 다시 만든다.
  int _version = 0;

  /// 계산식을 펼친 지표. 머리의 지표를 누르면 재무 탭에서 그 계산식을 연다.
  String? _openMetric;

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
      final (detail, financials) = await (
        client.company.detail(widget.corpCode),
        client.financial.summary(widget.corpCode),
      ).wait;
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _financials = financials;
        _error = null;
        _loaded = true;
        _version++;
      });
    } catch (e) {
      final error = e is ParallelWaitError ? e.errors : e;
      if (mounted) setState(() => (_error = error, _loaded = true));
    }
  }

  void _openFinancials({String? metric}) => setState(() {
    _tab = CompanyTab.financials;
    // 같은 지표를 다시 누르면 닫는다.
    _openMetric = metric == _openMetric ? null : metric;
  });

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/companies');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final detail = _detail;

    return PageFrame(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: '← 뒤로',
            variant: AppButtonVariant.link,
            onPressed: _back,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (!_loaded)
          const LinearProgressIndicator(minHeight: 2)
        else if (detail == null)
          Text(
            _error != null ? '불러오지 못했습니다: $_error' : '기업을 찾을 수 없습니다.',
            style: t.body(14, color: c.textSecondary),
          )
        else ...[
          CompanyHeader(
            detail: detail,
            financials: _financials,
            openMetric: _tab == CompanyTab.financials ? _openMetric : null,
            onOpenMetric: (key) => _openFinancials(metric: key),
          ),
          const SizedBox(height: AppSpace.xl),
          AppTabBar<CompanyTab>(
            tabs: const {
              CompanyTab.overview: '개요',
              CompanyTab.financials: '재무',
            },
            value: _tab,
            onChanged: (tab) => setState(() {
              _tab = tab;
              _openMetric = null;
            }),
          ),
          const SizedBox(height: AppSpace.xl),
          switch (_tab) {
            CompanyTab.overview => CompanyOverviewTab(
              detail: detail,
              financials: _financials,
              onOpenFinancials: () => _openFinancials(),
            ),
            CompanyTab.financials => FinancialSection(
              key: ValueKey('financials-$_version'),
              corpCode: widget.corpCode,
              initialData: _financials,
              openMetric: _openMetric,
              onCloseMetric: () => setState(() => _openMetric = null),
            ),
          },
        ],
      ],
    );
  }
}
