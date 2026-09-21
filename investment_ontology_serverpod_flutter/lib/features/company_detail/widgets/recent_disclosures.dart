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
        SectionLabel(
          '최근 공시',
          trailing: Text(
            '모든 종류 · 누르면 DART',
            style: t.body(12, color: c.textMuted),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        for (final (:first, :count) in rows)
          HoverBuilder(
            onTap: () => launchUrl(
              Uri.parse(
                'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${first.rceptNo}',
              ),
              mode: LaunchMode.externalApplication,
            ),
            builder: (context, hovered) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(
                      formatDate(first.receivedDate),
                      softWrap: false,
                      style: t.numeric(12, color: c.textMuted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      count > 1
                          ? '${first.reportName} $count건'
                          : first.reportName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t
                          .body(13, weight: FontWeight.w500)
                          .copyWith(
                            decoration: hovered
                                ? TextDecoration.underline
                                : null,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
