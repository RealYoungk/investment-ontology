import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import 'financial_metrics.dart';

/// 재무 보고서 원문 표: 재무제표별 모든 계정과 금액 열, 같은 기간의 정정 이력.
class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key, required this.reportId});

  final int reportId;

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  late int _reportId = widget.reportId;
  late Future<FinancialReportDetail?> _future = _fetch();
  FinancialStatementKind? _statement;

  Future<FinancialReportDetail?> _fetch() => client.financial.report(_reportId);

  void _open(int reportId) => setState(() {
    _reportId = reportId;
    _future = _fetch();
  });

  static String statementLabel(FinancialStatementKind k) => switch (k) {
    FinancialStatementKind.balanceSheet => '재무상태표',
    FinancialStatementKind.incomeStatement => '손익계산서',
    FinancialStatementKind.comprehensiveIncome => '포괄손익계산서',
    FinancialStatementKind.cashFlow => '현금흐름표',
    FinancialStatementKind.equityChanges => '자본변동표',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: FutureBuilder<FinancialReportDetail?>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            final detail = snap.data;
            if (detail == null) {
              return Center(
                child: Text(
                  snap.hasError
                      ? '불러오지 못했습니다: ${snap.error}'
                      : '보고서를 찾을 수 없습니다.',
                  style: context.typo.body(14),
                ),
              );
            }
            return _body(context, detail);
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, FinancialReportDetail detail) {
    final c = context.colors;
    final t = context.typo;
    final report = detail.report;
    final kinds = [
      for (final k in FinancialStatementKind.values)
        if (detail.facts.any((f) => f.statement == k)) k,
    ];
    final statement = kinds.contains(_statement)
        ? _statement!
        : kinds.firstOrNull;
    final facts = [
      for (final f in detail.facts)
        if (f.statement == statement) f,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.xl,
        AppSpace.xxl,
        AppSpace.section,
      ),
      children: [
        SectionLabel(
          '재무제표 원문 · ${fsDivLabel(report.fsDiv)}',
          accent: true,
          trailing: IconButton(
            // 주소로 바로 들어왔으면 돌아갈 화면이 없어 기업 목록으로 간다.
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/companies'),
            icon: Icon(Icons.close, color: c.textPrimary),
            tooltip: '닫기',
          ),
        ),
        Text(report.reportName, style: t.display(30, color: c.textPrimary)),
        const SizedBox(height: AppSpace.sm),
        Text(
          '${report.bsnsYear} 사업연도 · ${reportCodeLabel(report.reportCode)} · '
          '접수 ${report.rceptNo} · 계정 ${formatCount(report.factCount)}개 · 금액은 조·억·만원으로 적고 원 단위는 마우스를 올리면 보입니다'
          '${report.invalidAmountCount > 0 ? ' · 정수가 아니어서 비운 금액 ${report.invalidAmountCount}개' : ''}',
          style: t.numeric(12, color: c.textSecondary),
        ),
        if (report.supersededById != null) ...[
          const SizedBox(height: AppSpace.md),
          AppNotice(
            message: '정정공시로 대체된 보고서입니다. 값은 지우지 않고 보존합니다.',
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        _History(
          history: detail.history,
          current: report.id!,
          onOpen: _open,
        ),
        const SizedBox(height: AppSpace.lg),
        if (kinds.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: AppToggleGroup<FinancialStatementKind>(
              value: statement!,
              options: {for (final k in kinds) k: statementLabel(k)},
              onChanged: (k) => setState(() => _statement = k),
            ),
          ),
        const SizedBox(height: AppSpace.md),
        _FactTable(facts: facts),
        const SizedBox(height: AppSpace.xl),
        Text(
          detail.source?.title ?? '출처 기록 없음',
          style: t.body(13, weight: FontWeight.w600),
        ),
        if (detail.source != null)
          Text(
            '수집 ${formatDateTime(detail.source!.retrievedAt)}',
            style: t.numeric(12, color: c.textSecondary),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: 'DART 공시 원문 열기 →',
            variant: AppButtonVariant.link,
            tone: c.accent,
            onPressed: () => launchUrl(
              Uri.parse(
                'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${report.rceptNo}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({
    required this.history,
    required this.current,
    required this.onOpen,
  });

  final List<FinancialReport> history;
  final int current;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('같은 기간 보고서 · 정정 이력'),
        const SizedBox(height: AppSpace.xs),
        for (final r in history)
          HoverBuilder(
            onTap: r.id == current ? null : () => onOpen(r.id!),
            builder: (context, hovered) => Container(
              color: hovered ? c.surfaceHover : null,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: AppSpace.sm),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: r.id == current ? c.accent : null,
                      border: Border.all(color: c.accent, width: 1.5),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${r.reportName} · 접수 ${r.rceptNo}',
                      style: t.body(12.5),
                    ),
                  ),
                  Text(
                    r.supersededById == null ? '현재' : '대체됨',
                    style: t.body(12, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FactTable extends StatelessWidget {
  const _FactTable({required this.facts});

  final List<FinancialFact> facts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (facts.isEmpty) {
      return Text('계정이 없습니다.', style: t.body(13, color: c.textMuted));
    }
    final first = facts.first;
    final hasDetail = facts.any((f) => f.accountDetail != null);
    final hasCumulative = facts.any((f) => f.cumulativeAmount != null);
    final hasPriorQuarter = facts.any((f) => f.priorQuarterAmount != null);
    final hasPrior = facts.any((f) => f.priorAmount != null);
    final hasBeforePrior = facts.any((f) => f.beforePriorAmount != null);

    String head(String label, String? period) =>
        period == null ? label : '$label\n$period';

    final columns = <(String, BigInt? Function(FinancialFact))>[
      (head('당기', first.periodName), (f) => f.amount),
      if (hasCumulative) ('당기 누적', (f) => f.cumulativeAmount),
      if (hasPriorQuarter)
        (head('전기 동분기', first.priorQuarterName), (f) => f.priorQuarterAmount),
      if (hasPrior) (head('전기', first.priorPeriodName), (f) => f.priorAmount),
      if (facts.any((f) => f.priorCumulativeAmount != null))
        ('전기 누적', (f) => f.priorCumulativeAmount),
      if (hasBeforePrior)
        (head('전전기', first.beforePriorPeriodName), (f) => f.beforePriorAmount),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final available =
            (constraints.maxWidth - (hasDetail ? 520 : 260)) / columns.length;
        final valueWidth = available > 200 ? available : 200.0;
        Widget cell(
          String text, {
          bool header = false,
          bool right = true,
          double? width,
        }) => Container(
          width: width ?? valueWidth,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          alignment: right ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            text,
            maxLines: header
                ? 2
                : right
                ? 1
                : null,
            softWrap: header || !right,
            textAlign: right ? TextAlign.right : TextAlign.left,
            style: header
                ? t.body(11.5, color: c.textSecondary)
                : right
                ? t.numeric(12)
                : t.body(12.5),
          ),
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.borderStrong)),
                ),
                child: Row(
                  children: [
                    cell('계정', header: true, right: false, width: 260),
                    if (hasDetail)
                      cell('자본 구성요소', header: true, right: false, width: 260),
                    for (final (label, _) in columns) cell(label, header: true),
                  ],
                ),
              ),
              for (final f in facts)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: c.border, width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Tooltip(
                        message: f.accountId ?? '표준계정코드 미사용',
                        child: cell(f.accountName, right: false, width: 260),
                      ),
                      if (hasDetail)
                        cell(f.accountDetail ?? '', right: false, width: 260),
                      for (final (_, value) in columns)
                        if (value(f) case final v?)
                          Tooltip(
                            message: '${formatCount(v.toInt())}원',
                            child: cell(formatKrwLong(v.toDouble())),
                          )
                        else
                          cell('—'),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
