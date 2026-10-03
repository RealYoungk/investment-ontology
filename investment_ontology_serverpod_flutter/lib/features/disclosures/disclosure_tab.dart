import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';

/// 기업 상세의 공시 항목 탭: 정기보고서 주요정보 28종의 원문 표.
///
/// 응답 필드를 그대로 보여 주고 머리글만 한글로 바꾼다. 값·단위는 원문 그대로다.
class DisclosureTab extends StatefulWidget {
  const DisclosureTab({
    super.key,
    required this.corpCode,
    required this.sections,
    this.dataVersion = 0,
  });

  final String corpCode;
  final List<DisclosureSectionInfo> sections;

  /// 수집이 끝날 때마다 오른다. 바뀌면 다시 읽되 고른 항목은 그대로 둔다.
  final int dataVersion;

  @override
  State<DisclosureTab> createState() => _DisclosureTabState();
}

class _DisclosureTabState extends State<DisclosureTab> {
  late DartSection _section = widget.sections.first.section;
  int? _year;
  DisclosureTable? _table;
  Object? _error;
  bool _loading = false;
  int _seq = 0;
  final _tableAnchor = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DisclosureTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion) _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() => _loading = true);
    try {
      final table = await client.disclosure.table(
        widget.corpCode,
        _section,
        bsnsYear: _year,
      );
      if (mounted && seq == _seq) {
        setState(() => (_table = table, _error = null, _loading = false));
      }
    } catch (e) {
      if (mounted && seq == _seq) {
        setState(() => (_error = e, _loading = false));
      }
    }
  }

  void _select(DartSection section) {
    if (section == _section) return;
    setState(() {
      _section = section;
      _year = null;
    });
    _load().then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _tableAnchor.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(target, duration: AppMotion.fast);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final table = KeyedSubtree(
          key: _tableAnchor,
          child: CompanyDataCard(child: _buildTable(context)),
        );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AppSelect<DartSection>(
                  label: '항목',
                  placeholder: '항목',
                  allLabel: '—',
                  value: _section,
                  options: {
                    for (final s in widget.sections)
                      s.section: '${s.group} · ${s.label}',
                  },
                  onChanged: (s) {
                    if (s != null) _select(s);
                  },
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              table,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 240,
              child: _SectionList(
                sections: widget.sections,
                selected: _section,
                onSelect: _select,
              ),
            ),
            const SizedBox(width: AppSpace.xl),
            Expanded(child: table),
          ],
        );
      },
    );
  }

  Widget _buildTable(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final table = _table;
    if (_error != null) {
      return ReadFailureNotice(subject: '표', retry: _load);
    }
    if (table == null) return const ShadProgress(minHeight: 2);
    return AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: _loading ? 0.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(table.label, style: t.body(13, weight: FontWeight.w600)),
              if (table.years.length > 1 ||
                  table.years.first < DateTime.now().year)
                AppToggleGroup<int>(
                  value: table.bsnsYear,
                  // 지금 해의 사업보고서가 아직 없으면 그 칸을 지우지 않고 흐리게 둔다.
                  options: {
                    for (final y in _withThisYear(table.years)) y: 'FY$y',
                  },
                  disabled: {
                    for (final y in _withThisYear(table.years))
                      if (!table.years.contains(y)) y,
                  },
                  onChanged: (y) {
                    setState(() => _year = y);
                    _load();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'FY${table.bsnsYear} 사업보고서'
            '${table.settlementDate == null ? '' : ' · 기준일 ${formatDate(table.settlementDate)}'}'
            ' · 원문 ${table.rows.length}행'
            '${table.emptyRowCount > 0 ? ' (값이 모두 비어 있던 ${table.emptyRowCount}행 제외)' : ''}'
            ' · 값과 단위는 원문 그대로',
            style: t.body(12, color: c.textMuted),
          ),
          const SizedBox(height: AppSpace.md),
          if (!_loading && _section == DartSection.employees) ...[
            _EmployeeChart(table: table),
            const SizedBox(height: AppSpace.xl),
          ],
          AppDataTable(
            columns: [
              for (final (i, h) in table.headers.indexed)
                // 숫자는 한 줄로 — 칸이 좁으면 "508,157,14 8"처럼 접혀 읽을 수 없다.
                AppColumn(
                  h,
                  numeric: _numericColumn(table, i),
                  nowrap: _numericColumn(table, i),
                  // 가장 긴 값이 들어갈 폭을 직접 준다 (숫자 글꼴 한 글자 ≈ 7.6px).
                  minWidth: _numericColumn(table, i)
                      ? _longestCell(table, i) * 7.6 + 2 * AppSpace.sm
                      : null,
                ),
            ],
            rows: [
              for (final r in table.rows)
                AppRow(emphasized: r.isTotal, [
                  for (final (i, cell) in r.cells.indexed)
                    AppDataTable.text(
                      context,
                      cell,
                      numeric: _numericColumn(table, i),
                      nowrap: _numericColumn(table, i),
                    ),
                ]),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (table.source case final s?)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.title} · 접수 ${s.reference ?? ''} · 수집 ${formatDateTime(s.retrievedAt)}',
                    style: t.body(11.5, color: c.textMuted),
                  ),
                ),
                if (s.url != null)
                  ShadButton.raw(
                    onPressed: () => launchUrl(Uri.parse(s.url!)),
                    variant: ShadButtonVariant.link,
                    child: Flexible(child: Text('DART 공시 →')),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// 값이 있는 칸이 모두 숫자 표기면 숫자 열.
  static bool _numericColumn(DisclosureTable table, int i) {
    var any = false;
    for (final r in table.rows) {
      final v = i < r.cells.length ? r.cells[i] : null;
      if (v == null) continue;
      any = true;
      if (!RegExp(r'^-?[\d,]+(\.\d+)?%?$').hasMatch(v.trim())) return false;
    }
    return any;
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.sections,
    required this.selected,
    required this.onSelect,
  });

  final List<DisclosureSectionInfo> sections;
  final DartSection selected;
  final ValueChanged<DartSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final groups = <String, List<DisclosureSectionInfo>>{};
    for (final s in sections) {
      (groups[s.group] ??= []).add(s);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.md, bottom: 4),
            child: SectionLabel(g.key),
          ),
          for (final s in g.value)
            HoverBuilder(
              onTap: () => onSelect(s.section),
              builder: (context, hovered) {
                final active = s.section == selected;
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
                    s.label,
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
      ],
    );
  }
}

/// 표가 가진 해에 지금 해를 더한다 (없으면 "없음" 칸으로 보이게). 최신 해부터.
List<int> _withThisYear(List<int> years) {
  final thisYear = DateTime.now().year;
  final all = {...years, if (years.isNotEmpty) thisYear}.toList()
    ..sort((a, b) => b.compareTo(a));
  return all;
}

/// i번째 열에서 가장 긴 값의 글자 수 (머리글 포함).
int _longestCell(DisclosureTable table, int i) {
  var n = table.headers[i].length;
  for (final r in table.rows) {
    final len = i < r.cells.length ? (r.cells[i]?.length ?? 0) : 0;
    if (len > n) n = len;
  }
  return n;
}

/// 인원만 시각화한다. 급여·근속연수를 같은 축에 섞지 않고 합계행 중복도 피한다.
class _EmployeeChart extends StatelessWidget {
  const _EmployeeChart({required this.table});
  final DisclosureTable table;
  @override
  Widget build(BuildContext context) {
    final count = table.headers.indexOf('합계');
    final division = table.headers.indexOf('사업부문');
    final sex = table.headers.indexOf('성별');
    if (count < 0 || division < 0) return const SizedBox.shrink();
    final values = <(String, double)>[];
    for (final row in table.rows) {
      if (row.isTotal ||
          row.cells.length <= count ||
          row.cells.length <= division) {
        continue;
      }
      final label = row.cells[division] ?? '';
      if (label.contains('합계') || label.contains('소계')) continue;
      final value = double.tryParse(
        (row.cells[count] ?? '').replaceAll(',', ''),
      );
      if (value == null || !value.isFinite || value < 0) continue;
      values.add((
        '$label${sex >= 0 && row.cells.length > sex ? ' · ${row.cells[sex] ?? ''}' : ''}',
        value,
      ));
    }
    if (values.isEmpty || values.length > 12) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('사업부문별 인원 구성', style: context.typo.display(22)),
        const SizedBox(height: AppSpace.sm),
        Text(
          '공시된 인원 합계 · 명. 성별·사업부문별 행이며 합계행은 중복 표시하지 않습니다.',
          style: context.typo.body(12, color: context.colors.textSecondary),
        ),
        const SizedBox(height: AppSpace.md),
        AppColumnChart(
          categories: [for (final v in values) v.$1],
          series: [
            ChartSeries(
              label: '직원 수',
              color: context.colors.chartSeries1,
              values: [for (final v in values) v.$2],
            ),
          ],
          formatValue: (v) => '${formatCount(v.round())}명',
        ),
      ],
    );
  }
}
