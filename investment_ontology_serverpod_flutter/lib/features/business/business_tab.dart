import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart' show formatKrwShort;
import '../review/review_page.dart';

/// 글을 문단과 표(' | '로 이은 줄이 이어진 묶음)로 나눈다.
List<({bool table, List<String> lines})> businessBlocks(String text) {
  final blocks = <({bool table, List<String> lines})>[];
  for (final line in text.split('\n')) {
    final isTable = line.contains(' | ');
    if (blocks.isNotEmpty && blocks.last.table == isTable) {
      blocks.last.lines.add(line);
    } else {
      blocks.add((table: isTable, lines: [line]));
    }
  }
  return blocks;
}

/// 기업 상세의 사업의 내용 탭: 사업보고서 본문 "II. 사업의 내용" (공시 원본 그대로).
class BusinessTab extends StatefulWidget {
  const BusinessTab({super.key, required this.corpCode});

  final String corpCode;

  @override
  State<BusinessTab> createState() => _BusinessTabState();
}

class _BusinessTabState extends State<BusinessTab> {
  BusinessContent? _content;
  Object? _error;
  int? _year;
  int _section = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await client.disclosure.businessContent(
        widget.corpCode,
        bsnsYear: _year,
      );
      if (mounted) setState(() => (_content = c, _error = null, _section = 0));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final content = _content;
    if (_error != null) {
      return AppNotice(message: '사업의 내용을 불러오지 못했습니다 — $_error');
    }
    if (content == null) return const LinearProgressIndicator(minHeight: 2);
    final sections = content.sections;
    final current = sections.isEmpty
        ? null
        : sections[_section.clamp(0, sections.length - 1)];

    final toc = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in sections.indexed)
          HoverBuilder(
            onTap: () => setState(() => _section = i),
            builder: (context, hovered) {
              final active = i == _section;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? c.inverse
                      : hovered
                      ? c.surfaceHover
                      : Colors.transparent,
                  borderRadius: context.shape.borderRadius,
                ),
                child: Text(
                  s.title.isEmpty ? '(머리말)' : s.title,
                  style: t.body(
                    13,
                    color: active ? c.onInverse : c.textPrimary,
                    weight: active ? FontWeight.w600 : null,
                  ),
                ),
              );
            },
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${content.title} · FY${content.bsnsYear} 사업보고서',
              style: t.body(14, weight: FontWeight.w600),
            ),
            if (content.years.length > 1)
              AppToggleGroup<int>(
                value: content.bsnsYear,
                options: {for (final y in content.years) y: 'FY$y'},
                onChanged: (y) {
                  setState(() => _year = y);
                  _load();
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        _DocumentFacts(corpCode: widget.corpCode),
        _AiRelations(corpCode: widget.corpCode),
        const SizedBox(height: AppSpace.lg),
        Text(
          '공시 원본 파일에서 뽑은 글 (${formatCount(content.charCount)}자). 표는 칸만 옮겼고, '
          '그림·서식은 빠집니다. 정확한 원문은 DART 공시에서 확인하세요.',
          style: t.body(12, color: c.textMuted),
        ),
        const SizedBox(height: AppSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final body = current == null
                ? Text('본문이 없습니다.', style: t.body(13, color: c.textMuted))
                : _SectionBody(section: current);
            if (constraints.maxWidth < 900) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  toc,
                  const SizedBox(height: AppSpace.lg),
                  body,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 240, child: toc),
                const SizedBox(width: AppSpace.xl),
                Expanded(child: body),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.xl),
        if (content.source case final s?)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${s.title} · 접수 ${s.reference ?? ''} · 수집 ${formatDateTime(s.retrievedAt)}',
                  style: t.body(11.5, color: c.textMuted),
                ),
              ),
              if (s.url != null)
                AppButton(
                  label: 'DART 공시 →',
                  variant: AppButtonVariant.link,
                  onPressed: () => launchUrl(Uri.parse(s.url!)),
                ),
            ],
          ),
      ],
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.section});

  final BusinessSection section;

  static int _width(({bool table, List<String> lines}) b) =>
      b.lines.map((l) => l.split(' | ').length).reduce((a, b) => a > b ? a : b);

  static List<String> _padded(String line, int width) {
    final cells = line.split(' | ');
    return [...cells, for (var i = cells.length; i < width; i++) ''];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.title.isNotEmpty)
          Text(section.title, style: t.body(18, weight: FontWeight.w700)),
        const SizedBox(height: AppSpace.md),
        for (final b in businessBlocks(section.text)) ...[
          if (b.table)
            AppDataTable(
              maxCellWidth: 360,
              // 병합 칸 때문에 행마다 칸 수가 달라, 가장 긴 행에 맞춰 머리글을 늘린다.
              columns: [
                for (final (i, h) in _padded(b.lines.first, _width(b)).indexed)
                  AppColumn(i == 0 || h.isNotEmpty ? h : ''),
              ],
              rows: [
                for (final line in b.lines.skip(1))
                  AppRow([
                    for (final cell in line.split(' | '))
                      AppDataTable.text(context, cell.isEmpty ? null : cell),
                  ]),
              ],
            )
          else
            SelectableText(
              b.lines.join('\n'),
              style: t.body(14).copyWith(height: 1.7),
            ),
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }
}

/// 이 기업이 들어간 AI 관계 (거절한 것 제외)와 "이 기업 관계 추출".
class _AiRelations extends StatefulWidget {
  const _AiRelations({required this.corpCode});

  final String corpCode;

  @override
  State<_AiRelations> createState() => _AiRelationsState();
}

class _AiRelationsState extends State<_AiRelations> {
  List<ReviewItem>? _items;
  bool _extracting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await client.review.forCompany(widget.corpCode);
      if (mounted) setState(() => _items = items);
    } catch (_) {}
  }

  Future<void> _extract() async {
    setState(() => (_extracting = true, _message = null));
    try {
      final r = await client.ai.extractCompany(widget.corpCode);
      setState(
        () => _message = r.succeeded
            ? '관계 후보 ${r.relationCount}건 (근거가 원문에 없어 버린 것 ${r.droppedCount}건)'
            : '추출 실패: ${r.error}',
      );
      await _load();
    } on IngestException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final items = _items ?? const <ReviewItem>[];
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            'AI가 뽑은 관계 (공급 · 경쟁 · 제품)',
            accent: true,
            trailing: AppButton(
              label: _extracting ? '읽는 중… (수십 초)' : '이 기업 관계 추출',
              variant: AppButtonVariant.link,
              onPressed: _extracting ? null : _extract,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '근거 인용이 원문에 그대로 있는 것만 남기고, 검수에서 승인해야 확정됩니다.',
            style: t.body(12, color: c.textMuted),
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(_message!, style: t.body(12.5, color: c.textSecondary)),
          ],
          const SizedBox(height: AppSpace.sm),
          if (items.isEmpty)
            Text('아직 없습니다.', style: t.body(13, color: c.textMuted))
          else ...[
            // 확정된 것은 이름만 묶어서 (해마다 같은 공급처가 되풀이된다).
            _RelationGroups(
              items: [
                for (final i in items)
                  if (i.relation.status != RelationStatus.draft) i,
              ],
              corpCode: widget.corpCode,
              onOpenCompany: (code) => context.push(AppRoutes.company(code)),
            ),
            // 검수 대기는 근거를 봐야 하니 카드로.
            for (final item in items)
              if (item.relation.status == RelationStatus.draft)
                ReviewCard(
                  item: item,
                  onDecide: (approve) async {
                    await client.review.decide(item.relation.id!, approve);
                    await _load();
                  },
                ),
          ],
        ],
      ),
    );
  }
}

/// 본문에서 뽑아 승인한 값 (수주잔고·가동률·점유율 등). API로는 받을 수 없는 것들이다.

/// 확정된 관계를 종류별로 이름만 묶어 보여 준다. 해마다 같은 공급처가 되풀이되므로
/// 카드로 늘어놓으면 읽히지 않는다. 이름을 누르면 그 기업으로 간다.
class _RelationGroups extends StatelessWidget {
  const _RelationGroups({
    required this.items,
    required this.corpCode,
    required this.onOpenCompany,
  });

  final List<ReviewItem> items;

  /// 지금 보고 있는 기업. 상대가 누구인지는 이 기준으로 가른다
  /// (다른 기업의 보고서에서 온 관계도 섞여 있다).
  final String corpCode;
  final ValueChanged<String> onOpenCompany;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (items.isEmpty) return const SizedBox.shrink();
    // (종류, 상대) 하나로 묶고 연도 범위를 적는다.
    final groups = <RelationPredicate, Map<String, (ReviewItem, Set<int>)>>{};
    for (final i in items) {
      final r = i.relation;
      // 내가 주어면 상대는 목적어(매출처·제품), 아니면 주어(공급처).
      // 다른 기업의 보고서에서 온 관계도 섞여 있어 보고서 기업이 아니라
      // 지금 보고 있는 기업으로 가른다.
      final other = i.subjectCorpCode == corpCode
          ? r.objectName
          : r.subjectName;
      final byName = groups.putIfAbsent(r.predicate, () => {});
      final prev = byName[other];
      byName[other] = (
        prev == null || r.bsnsYear > prev.$1.relation.bsnsYear ? i : prev.$1,
        {...?prev?.$2, r.bsnsYear},
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.sm, bottom: 4),
            child: Text(
              '${predicateLabel(entry.key)} ${entry.value.length}',
              style: t.body(12.5, color: c.textSecondary),
            ),
          ),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: 6,
            children: [
              for (final e in entry.value.entries)
                Tooltip(
                  message:
                      '${e.value.$1.relation.evidence ?? ''}\n'
                      'FY${(e.value.$2.toList()..sort()).join(", FY")}',
                  child: HoverBuilder(
                    onTap: () {
                      final item = e.value.$1;
                      final code = item.subjectCorpCode == corpCode
                          ? item.objectCorpCode
                          : item.subjectCorpCode;
                      if (code != null && code != corpCode) {
                        onOpenCompany(code);
                      }
                    },
                    builder: (context, hovered) => Text(
                      e.key,
                      style: t
                          .body(
                            13.5,
                            color: c.textPrimary,
                            weight: FontWeight.w500,
                          )
                          .copyWith(
                            decoration: hovered
                                ? TextDecoration.underline
                                : null,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 본문에서 뽑은 값의 종류 이름. 개요 탭 요약과 검수 화면도 같은 이름을 쓴다.
String documentFactKindLabel(DocumentFactKind k) => switch (k) {
  DocumentFactKind.orderTotal => '수주총액',
  DocumentFactKind.orderDelivered => '기납품액',
  DocumentFactKind.orderBacklog => '수주잔고',
  DocumentFactKind.capacity => '생산능력',
  DocumentFactKind.production => '생산실적',
  DocumentFactKind.utilization => '가동률',
  DocumentFactKind.marketShare => '시장점유율',
  DocumentFactKind.investmentPlan => '투자계획',
  DocumentFactKind.investmentActual => '투자집행',
};

/// 해마다 같은 항목이 있으면 흐름으로 (수주잔고·생산능력·점유율 …).
///
/// 표만 있으면 숫자가 늘었는지 줄었는지 눈에 안 들어온다.
class _FactTrend extends StatelessWidget {
  const _FactTrend({required this.facts, required this.kindLabel});

  final List<DocumentFact> facts;
  final String Function(DocumentFactKind) kindLabel;

  /// 가로축의 해. 기준일이 있으면 그 해를 쓴다 (투자계획은 다음 해 값이다).
  static int _year(DocumentFact f) => f.asOf?.year ?? f.bsnsYear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final unit = facts.first.unit;
    // 눈금은 읽기 쉬운 단위로. 백만원은 조·억으로 바꿔 적는다 (값 자체는 공시 단위 그대로).
    String short(double v) => switch (unit) {
      '%' => '${v.toStringAsFixed(1)}%',
      '백만원' => formatKrwShort(v * 1000000),
      '억원' => formatKrwShort(v * 100000000),
      '조원' => formatKrwShort(v * 1000000000000),
      // 10만부터 "만"으로 줄인다. 그보다 작으면 반올림 때문에 눈금이 겹친다
      // (15,000과 20,000이 둘 다 "2만"이 되던 문제).
      _ =>
        v.abs() >= 100000
            ? '${formatCount((v / 10000).round())}만'
            : formatCount(v.round()),
    };
    final last = facts.last.value, first = facts.first.value;
    final change = first == 0 ? null : 100 * (last - first) / first.abs();
    final hasPlan = facts.any(
      (f) => f.kind == DocumentFactKind.investmentPlan,
    );
    // 집행과 계획을 한 차트에. 계획은 아직 안 지난 해라 색을 달리 한다.
    final series = hasPlan
        ? [
            ChartSeries(
              label: '집행',
              color: c.chartSeries1,
              values: [
                for (final f in facts)
                  f.kind == DocumentFactKind.investmentPlan ? null : f.value,
              ],
            ),
            ChartSeries(
              label: '회사가 밝힌 계획',
              color: c.chartSeries2,
              values: [
                for (final f in facts)
                  f.kind == DocumentFactKind.investmentPlan ? f.value : null,
              ],
            ),
          ]
        : [
            ChartSeries(
              label: kindLabel(facts.first.kind),
              color: c.chartSeries1,
              values: [for (final f in facts) f.value],
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '${kindLabel(facts.first.kind)} · ${facts.first.label}',
                style: t.body(13.5, weight: FontWeight.w600),
              ),
            ),
            Text(
              '${formatDecimal(last)}$unit',
              style: t.numeric(15, weight: FontWeight.w700),
            ),
            if (change != null) ...[
              const SizedBox(width: AppSpace.sm),
              Text(
                '${_year(facts.first)}→${_year(facts.last)} '
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                style: t.numeric(
                  12,
                  color: change >= 0 ? c.success : c.accent,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        if (series.length > 1) ...[
          ChartLegend(series: series),
          const SizedBox(height: AppSpace.xs),
        ],
        AppColumnChart(
          categories: [for (final f in facts) '${_year(f)}'],
          series: series,
          formatValue: short,
          height: 150,
        ),
      ],
    );
  }
}

class _DocumentFacts extends StatefulWidget {
  const _DocumentFacts({required this.corpCode});

  final String corpCode;

  @override
  State<_DocumentFacts> createState() => _DocumentFactsState();
}

class _DocumentFactsState extends State<_DocumentFacts> {
  List<DocumentFact> _facts = const [];
  List<DocumentFact> _trends = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _DocumentFacts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) _load();
  }

  Future<void> _load() async {
    try {
      final (f, trends) = await (
        client.disclosure.facts(widget.corpCode),
        client.disclosure.factTrends(widget.corpCode),
      ).wait;
      if (mounted) setState(() => (_facts = f, _trends = trends));
    } catch (_) {}
  }

  /// 같은 (항목, 구분)이 두 해 이상 있으면 흐름으로 본다. 오래된 해부터.
  Map<String, List<DocumentFact>> get _series {
    final by = <String, List<DocumentFact>>{};
    for (final f in _trends) {
      // 투자 집행과 다음 해 계획은 한 차트에 같이 놓는다 (앞을 보는 숫자다).
      final group = f.kind == DocumentFactKind.investmentPlan
          ? DocumentFactKind.investmentActual.name
          : f.kind.name;
      by.putIfAbsent('$group|${f.label}|${f.unit}', () => []).add(f);
    }
    by.removeWhere((_, v) => v.length < 2);
    // 한 보고서에 여러 해가 적히기도 하므로 기준일의 해로 줄 세운다.
    int year(DocumentFact f) => f.asOf?.year ?? f.bsnsYear;
    for (final list in by.values) {
      list.sort((a, b) => year(a).compareTo(year(b)));
    }
    // 수주 → 생산 → 점유율 순으로 (읽는 순서를 고정한다).
    const order = [
      DocumentFactKind.orderTotal,
      DocumentFactKind.orderDelivered,
      DocumentFactKind.orderBacklog,
      DocumentFactKind.capacity,
      DocumentFactKind.production,
      DocumentFactKind.utilization,
      DocumentFactKind.marketShare,
    ];
    final keys = by.keys.toList()
      ..sort((a, b) {
        final ka = order.indexOf(by[a]!.first.kind);
        final kb = order.indexOf(by[b]!.first.kind);
        return ka != kb ? ka.compareTo(kb) : a.compareTo(b);
      });
    return {for (final k in keys) k: by[k]!};
  }

  static String label(DocumentFactKind k) => documentFactKindLabel(k);

  @override
  Widget build(BuildContext context) {
    if (_facts.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            '본문에서 뽑은 값',
            accent: true,
            trailing: Text(
              '사람이 승인한 것만',
              style: t.body(12, color: c.textMuted),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          for (final entry in _series.entries) ...[
            _FactTrend(facts: entry.value, kindLabel: label),
            const SizedBox(height: AppSpace.lg),
          ],
          if (_series.isNotEmpty) ...[
            Text(
              '차트는 각 해 사업보고서에 적힌 그 해 값입니다. 회사가 나중에 기준을 바꿔 다시 적기도 합니다.',
              style: t.body(11.5, color: c.textMuted),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          Text(
            'FY${_facts.first.bsnsYear} 값과 근거',
            style: t.body(12.5, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.xs),
          AppDataTable(
            columns: const [
              AppColumn('항목', nowrap: true),
              AppColumn('구분'),
              AppColumn('값', numeric: true),
              AppColumn('기준일', nowrap: true),
              AppColumn('근거'),
            ],
            rows: [
              for (final f in _facts)
                AppRow([
                  AppDataTable.text(context, label(f.kind)),
                  AppDataTable.text(context, f.label),
                  AppDataTable.text(
                    context,
                    '${formatDecimal(f.value)}${f.unit}',
                    numeric: true,
                  ),
                  AppDataTable.text(
                    context,
                    f.asOf == null ? null : formatDate(f.asOf),
                    nowrap: true,
                  ),
                  Tooltip(
                    message: f.evidence,
                    child: Text(
                      f.evidence,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.body(12, color: c.textMuted),
                    ),
                  ),
                ]),
            ],
          ),
        ],
      ),
    );
  }
}
