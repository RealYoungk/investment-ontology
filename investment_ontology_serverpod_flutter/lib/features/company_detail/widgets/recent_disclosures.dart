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
      final items = await client.disclosure.recentOf(widget.corpCode);
      if (mounted) setState(() => _items = items);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (_items.isEmpty) return const SizedBox.shrink();
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
        for (final d in _items)
          HoverBuilder(
            onTap: () => launchUrl(
              Uri.parse(
                'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${d.rceptNo}',
              ),
              mode: LaunchMode.externalApplication,
            ),
            builder: (context, hovered) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(
                      formatDate(d.receivedDate),
                      style: t.numeric(12, color: c.textMuted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      d.reportName,
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
