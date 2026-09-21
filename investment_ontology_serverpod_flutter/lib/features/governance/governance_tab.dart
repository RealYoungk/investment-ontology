import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart';
import 'governance_graph.dart';
import 'governance_view.dart';

/// 기업 상세의 지배구조 탭: 주주 → 이 회사 → 출자 그래프, 다른 기업 보고서의 역방향 관계,
/// 최대주주 · 임원 · 타법인출자 원문 표.
class GovernanceTab extends StatefulWidget {
  const GovernanceTab({
    super.key,
    required this.corpCode,
    required this.companyName,
  });

  final String corpCode;
  final String companyName;

  @override
  State<GovernanceTab> createState() => _GovernanceTabState();
}

class _GovernanceTabState extends State<GovernanceTab> {
  CompanyGovernance? _data;
  Object? _error;
  int? _year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await client.governance.summary(
        widget.corpCode,
        bsnsYear: _year,
      );
      if (mounted) setState(() => (_data = d, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _open(GovernanceNode n) {
    if (n.corpCode != null) {
      context.push(AppRoutes.company(n.corpCode!, tab: 'governance'));
    } else if (n.personId != null) {
      context.push(AppRoutes.person(n.personId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final d = _data;
    if (_error != null) {
      return AppNotice(message: '지배구조를 불러오지 못했습니다 — $_error');
    }
    if (d == null) return const LinearProgressIndicator(minHeight: 2);
    if (d.bsnsYear == null) {
      return Text(
        '아직 이 기업의 사업보고서 주요정보를 받지 않았습니다.',
        style: t.body(13, color: c.textMuted),
      );
    }
    final view = GovernanceView(d);
    final holders = view.holders();
    final investments = view.investments();
    final registered = d.executives
        .where((e) => e.registration != ExecutiveRegistration.unregistered)
        .length;
    final unregistered = d.executives.length - registered;
    final management = investments
        .where((n) => n.detail?.contains('경영') ?? false)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'FY${d.bsnsYear} 사업보고서'
              '${d.settlementDate == null ? '' : ' · 기준일 ${formatDate(d.settlementDate)}'}',
              style: t.body(14, weight: FontWeight.w600),
            ),
            if (d.availableYears.length > 1)
              AppToggleGroup<int>(
                value: d.bsnsYear!,
                options: {for (final y in d.availableYears) y: 'FY$y'},
                onChanged: (y) {
                  setState(() => _year = y);
                  _load();
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.xl,
          runSpacing: AppSpace.sm,
          children: [
            _Figure(
              label: '최대주주 및 특수관계인 (보통주)',
              value: formatRatio(view.holderTotal()),
            ),
            _Figure(
              label: '임원',
              value:
                  '${d.executives.length}명'
                  '${unregistered > 0 ? ' (미등기 $unregistered)' : ''}',
            ),
            _Figure(
              label: '타법인 출자',
              value: '${investments.length}곳 (경영참여 $management)',
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: '관계망에서 더 넓게 보기 →',
            variant: AppButtonVariant.link,
            tone: c.accent,
            onPressed: () => context.push(AppRoutes.graph(widget.corpCode)),
          ),
        ),
        GovernanceGraph(
          center: widget.companyName,
          left: holders,
          right: investments,
          onTap: _open,
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          '선 굵기 = 지분율 · 파랑 = 상장사 · 주황 = 인물 · 회색 = 확인되지 않은 이름 · '
          '점선 = 추정 연결 (지분으로 이어진 기업들의 주주 명단에 같은 이름)',
          style: t.body(11.5, color: c.textMuted),
        ),
        if (d.investors.isNotEmpty || d.holdings.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xl),
          _ReverseLinks(data: d),
        ],
        const SizedBox(height: AppSpace.section),
        _HolderTable(view: view, onOpen: _open),
        const SizedBox(height: AppSpace.section),
        _ExecutiveTable(
          executives: d.executives,
          onOpenPerson: (id) => context.push(AppRoutes.person(id)),
        ),
        const SizedBox(height: AppSpace.section),
        _InvestmentTable(view: view, onOpen: _open),
        const SizedBox(height: AppSpace.xl),
        _Sources(sources: d.sources),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.body(12, color: c.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: t.numeric(18, weight: FontWeight.w600)),
      ],
    );
  }
}

/// 다른 기업 보고서에서 역으로 찾은 관계.
class _ReverseLinks extends StatelessWidget {
  const _ReverseLinks({required this.data});

  final CompanyGovernance data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    Widget chips(String title, List<GovernanceLink> links) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final l in links)
              HoverBuilder(
                onTap: l.corpCode == null
                    ? null
                    : () => context.push(
                        AppRoutes.company(l.corpCode!, tab: 'governance'),
                      ),
                builder: (context, hovered) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hovered ? c.surfaceHover : c.surface,
                    borderRadius: context.shape.borderRadius,
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    '${l.name} ${formatRatio(l.weight)} · FY${l.bsnsYear}',
                    style: t.body(12.5),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '다른 기업의 사업보고서에서 찾은 관계 (각 기업의 최근 보고서 기준)',
          style: t.body(12, color: c.textMuted),
        ),
        const SizedBox(height: AppSpace.sm),
        if (data.investors.isNotEmpty) chips('이 기업에 출자한 기업', data.investors),
        if (data.investors.isNotEmpty && data.holdings.isNotEmpty)
          const SizedBox(height: AppSpace.md),
        if (data.holdings.isNotEmpty)
          chips('이 기업이 최대주주·특수관계인인 기업', data.holdings),
      ],
    );
  }
}

Widget _link(
  BuildContext context,
  String text, {
  required VoidCallback? onTap,
  bool estimated = false,
}) {
  final c = context.colors;
  final t = context.typo;
  if (onTap == null) return AppDataTable.text(context, text);
  return HoverBuilder(
    onTap: onTap,
    builder: (context, hovered) => Text(
      estimated ? '$text (추정)' : text,
      style: t
          .body(13, color: c.accent, weight: FontWeight.w600)
          .copyWith(
            decoration: hovered ? TextDecoration.underline : null,
            decorationColor: c.accent,
          ),
    ),
  );
}

class _HolderTable extends StatelessWidget {
  const _HolderTable({required this.view, required this.onOpen});

  final GovernanceView view;
  final ValueChanged<GovernanceNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = view.data.shareholders;
    String? count(BigInt? v) => v == null ? null : formatCount(v.toInt());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('최대주주 및 특수관계인 · 최대주주 현황'),
        const SizedBox(height: AppSpace.sm),
        AppDataTable(
          columns: const [
            AppColumn('성명'),
            AppColumn('관계'),
            AppColumn('주식 종류'),
            AppColumn('기초 주식수', numeric: true),
            AppColumn('기초 지분율', numeric: true),
            AppColumn('기말 주식수', numeric: true),
            AppColumn('기말 지분율', numeric: true),
            AppColumn('연결'),
            AppColumn('비고'),
          ],
          rows: [
            for (final s in rows)
              AppRow(emphasized: s.isTotal, [
                _link(
                  context,
                  s.holderName,
                  estimated:
                      s.holderLinkBasis == DisclosureLinkBasis.ownershipCluster,
                  onTap: s.isTotal
                      ? null
                      : view.corpCodeOf(s.holderCompanyId) != null
                      ? () => onOpen(
                          GovernanceNode(
                            name: s.holderName,
                            weight: s.ratioEnd,
                            corpCode: view.corpCodeOf(s.holderCompanyId),
                          ),
                        )
                      : s.holderPersonId != null
                      ? () => onOpen(
                          GovernanceNode(
                            name: s.holderName,
                            weight: s.ratioEnd,
                            personId: s.holderPersonId,
                          ),
                        )
                      : null,
                ),
                AppDataTable.text(context, s.relationText),
                AppDataTable.text(context, s.stockKind),
                AppDataTable.text(context, count(s.sharesBegin), numeric: true),
                AppDataTable.text(
                  context,
                  formatRatio(s.ratioBegin),
                  numeric: true,
                ),
                AppDataTable.text(context, count(s.sharesEnd), numeric: true),
                AppDataTable.text(
                  context,
                  formatRatio(s.ratioEnd),
                  numeric: true,
                ),
                AppDataTable.text(context, _basisLabel(s.holderLinkBasis)),
                AppDataTable.text(context, s.remark),
              ]),
          ],
        ),
      ],
    );
  }

  static String? _basisLabel(DisclosureLinkBasis? b) => switch (b) {
    DisclosureLinkBasis.companyName => '상장사 (이름 일치)',
    DisclosureLinkBasis.executiveSameReport => '같은 보고서의 임원',
    DisclosureLinkBasis.ownershipCluster => '추정 (기업 묶음)',
    null => null,
  };
}

class _ExecutiveTable extends StatelessWidget {
  const _ExecutiveTable({required this.executives, required this.onOpenPerson});

  final List<ExecutiveEntry> executives;
  final ValueChanged<int> onOpenPerson;

  static String registrationLabel(ExecutiveRegistration r, String? raw) =>
      switch (r) {
        ExecutiveRegistration.inside => '사내이사',
        ExecutiveRegistration.outside => '사외이사',
        ExecutiveRegistration.nonExecutive => '기타비상무이사',
        ExecutiveRegistration.unregistered => '미등기',
        ExecutiveRegistration.other => raw ?? '기타',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final hasUnregistered = executives.any(
      (e) => e.registration == ExecutiveRegistration.unregistered,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('임원 · 임원 현황'),
        if (!hasUnregistered && executives.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            '이 기업은 등기임원만 공시했습니다. 미등기 임원까지 공시하는 기업도 있어 임원 수를 기업끼리 비교하면 안 됩니다.',
            style: t.body(12, color: c.textMuted),
          ),
        ],
        const SizedBox(height: AppSpace.sm),
        AppDataTable(
          columns: const [
            AppColumn('성명'),
            AppColumn('직위'),
            AppColumn('등기'),
            AppColumn('상근'),
            AppColumn('출생'),
            AppColumn('담당업무'),
            AppColumn('재직', numeric: true),
            AppColumn('임기만료'),
          ],
          rows: [
            for (final e in executives)
              AppRow([
                _link(
                  context,
                  e.name,
                  onTap: e.personId == null
                      ? null
                      : () => onOpenPerson(e.personId!),
                ),
                AppDataTable.text(context, e.position),
                AppDataTable.text(
                  context,
                  registrationLabel(e.registration, e.registrationRaw),
                ),
                AppDataTable.text(
                  context,
                  e.fullTime == null ? null : (e.fullTime! ? '상근' : '비상근'),
                ),
                AppDataTable.text(
                  context,
                  e.birthYear == null
                      ? null
                      : '${e.birthYear}.${e.birthMonth.toString().padLeft(2, '0')}',
                ),
                AppDataTable.text(context, e.duties),
                AppDataTable.text(
                  context,
                  e.tenureMonths == null ? null : '${e.tenureMonths}개월',
                  numeric: true,
                ),
                AppDataTable.text(
                  context,
                  e.termEndDate == null ? null : formatDate(e.termEndDate),
                ),
              ]),
          ],
        ),
      ],
    );
  }
}

class _InvestmentTable extends StatelessWidget {
  const _InvestmentTable({required this.view, required this.onOpen});

  final GovernanceView view;
  final ValueChanged<GovernanceNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final rows = view.data.investments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('타법인 출자 · 타법인 출자현황'),
        const SizedBox(height: AppSpace.xs),
        Text(
          '금액은 원 단위 (DART가 보고서의 백만원 값을 원으로 바꿔 준다). 대상의 총자산·순손익은 그 법인의 최근 사업연도.',
          style: t.body(12, color: c.textMuted),
        ),
        const SizedBox(height: AppSpace.sm),
        AppDataTable(
          columns: const [
            AppColumn('법인명'),
            AppColumn('출자 목적'),
            AppColumn('최초 취득일'),
            AppColumn('기말 수량', numeric: true),
            AppColumn('기말 지분율', numeric: true),
            AppColumn('기말 장부가', numeric: true),
            AppColumn('대상 총자산', numeric: true),
            AppColumn('대상 순손익', numeric: true),
          ],
          rows: [
            for (final i in rows)
              AppRow(emphasized: i.isTotal, [
                _link(
                  context,
                  i.investeeName,
                  onTap: view.corpCodeOf(i.investeeCompanyId) == null
                      ? null
                      : () => onOpen(
                          GovernanceNode(
                            name: i.investeeName,
                            weight: i.ratioEnd,
                            corpCode: view.corpCodeOf(i.investeeCompanyId),
                          ),
                        ),
                ),
                AppDataTable.text(context, i.purpose),
                AppDataTable.text(
                  context,
                  i.firstAcquiredOn == null
                      ? null
                      : formatDate(i.firstAcquiredOn),
                ),
                AppDataTable.text(
                  context,
                  i.sharesEnd == null
                      ? null
                      : formatCount(i.sharesEnd!.toInt()),
                  numeric: true,
                ),
                AppDataTable.text(
                  context,
                  i.ratioEnd == null ? null : formatRatio(i.ratioEnd),
                  numeric: true,
                ),
                AppDataTable.text(
                  context,
                  i.bookValueEnd == null ? null : formatKrw(i.bookValueEnd),
                  numeric: true,
                ),
                AppDataTable.text(
                  context,
                  i.investeeTotalAssets == null
                      ? null
                      : formatKrw(i.investeeTotalAssets),
                  numeric: true,
                ),
                AppDataTable.text(
                  context,
                  i.investeeNetIncome == null
                      ? null
                      : formatKrw(i.investeeNetIncome),
                  numeric: true,
                ),
              ]),
          ],
        ),
      ],
    );
  }
}

class _Sources extends StatelessWidget {
  const _Sources({required this.sources});

  final List<Source> sources;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('출처'),
          for (final s in sources) ...[
            const SizedBox(height: AppSpace.sm),
            Text(s.title, style: t.body(12.5, weight: FontWeight.w600)),
            Row(
              children: [
                Text(
                  'DART 접수 ${s.reference ?? ''} · 수집 ${formatDateTime(s.retrievedAt)}',
                  style: t.numeric(11, color: c.textSecondary),
                ),
                const SizedBox(width: AppSpace.md),
                if (s.url != null)
                  AppButton(
                    label: 'DART 공시 →',
                    variant: AppButtonVariant.link,
                    onPressed: () => launchUrl(Uri.parse(s.url!)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
