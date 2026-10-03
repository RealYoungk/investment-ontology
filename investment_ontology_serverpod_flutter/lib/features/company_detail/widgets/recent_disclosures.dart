import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';

/// 개요 탭의 최근 공시: 이 기업이 최근에 낸 공시 목록 (종류 가리지 않음).
///
/// 계약·증자·주요사항처럼 정기보고서 사이에 일어난 일을 본다. 누르면 DART 원문.
class RecentDisclosures extends StatefulWidget {
  const RecentDisclosures({super.key, required this.corpCode});

  final String corpCode;

  @override
  State<RecentDisclosures> createState() => _RecentDisclosuresState();
}

class _RecentDisclosuresState extends State<RecentDisclosures> {
  List<DartDisclosure> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecentDisclosures oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) {
      setState(() => _items = const []);
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final items = await client.disclosure.recentOf(
        widget.corpCode,
        limit: 50,
      );
      if (mounted) setState(() => _items = items);
    } catch (_) {}
  }

  /// 같은 날 같은 이름의 공시는 한 줄로 묶는다 — 임원 소유상황처럼 사람 수만큼
  /// 따로 나오는 공시가 목록을 덮지 않게. 누르면 그중 첫 건의 원문으로 간다.
  static List<({DartDisclosure first, int count})> group(
    List<DartDisclosure> items,
  ) {
    final out = <({DartDisclosure first, int count})>[];
    for (final d in items) {
      final last = out.isEmpty ? null : out.last;
      if (last != null &&
          last.first.reportName == d.reportName &&
          last.first.receivedDate == d.receivedDate) {
        out[out.length - 1] = (first: last.first, count: last.count + 1);
      } else {
        out.add((first: d, count: 1));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (_items.isEmpty) return const SizedBox.shrink();
    // 묶고 나서 열 개까지만 — 개요는 훑어보는 자리다.
    final rows = group(_items).take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('최근 어떤 공시가 나왔나요?', accent: true),
        const SizedBox(height: AppSpace.md),
        DataPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('최근 공시', style: t.body(18, weight: FontWeight.w700)),
              const SizedBox(height: AppSpace.sm),
              for (final (index, row) in rows.indexed) ...[
                if (index > 0) Divider(height: AppSpace.lg, color: c.border),
                HoverBuilder(
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${row.first.rceptNo}',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  builder: (context, hovered) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatDate(row.first.receivedDate),
                                style: t.numeric(12, color: c.textMuted),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                row.count > 1
                                    ? '${row.first.reportName} · ${row.count}건'
                                    : row.first.reportName,
                                style: t
                                    .body(14, weight: FontWeight.w500)
                                    .copyWith(
                                      height: 1.5,
                                      decoration: hovered
                                          ? TextDecoration.underline
                                          : null,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Icon(Icons.open_in_new, size: 16, color: c.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
