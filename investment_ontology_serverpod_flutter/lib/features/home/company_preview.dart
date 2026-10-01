import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';

typedef PreviewFactsLoad = Future<List<DocumentFact>> Function();

/// Live stored filing rows, including their units and verbatim evidence.
class CompanyPreview extends StatefulWidget {
  const CompanyPreview({super.key, this.load});
  final PreviewFactsLoad? load;
  @override
  State<CompanyPreview> createState() => _CompanyPreviewState();
}

class _CompanyPreviewState extends State<CompanyPreview> {
  List<DocumentFact>? _facts;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all =
          await (widget.load?.call() ?? client.disclosure.facts('00126380'));
      final facts = all
          .where(
            (f) =>
                f.kind == DocumentFactKind.segmentRevenue &&
                f.status == RelationStatus.verified,
          )
          .toList();
      facts.sort(
        (a, b) => (b.asOf ?? DateTime(b.bsnsYear)).compareTo(
          a.asOf ?? DateTime(a.bsnsYear),
        ),
      );
      final latest = facts.firstOrNull;
      final samePeriod = latest == null
          ? <DocumentFact>[]
          : facts
                .where(
                  (f) =>
                      f.documentId == latest.documentId &&
                      f.asOf == latest.asOf &&
                      f.unit == latest.unit,
                )
                .toList();
      if (mounted) {
        setState(() {
          _facts = samePeriod;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final facts = _facts;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: context.shape.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('삼성전자', style: t.body(17, weight: FontWeight.w600)),
              ),
              Text('실제 저장 공시', style: t.body(10, color: c.accent)),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text('어떤 사업에서 매출이 나올까요?', style: t.body(12, color: c.textSecondary)),
          const SizedBox(height: AppSpace.lg),
          if (_failed)
            TextButton(
              onPressed: _load,
              child: const Text('예시 공시를 불러오지 못했어요 · 재시도'),
            )
          else if (facts == null)
            const LinearProgressIndicator(minHeight: 2)
          else if (facts.isEmpty)
            Text(
              '표시할 부문 매출 자료가 없습니다.',
              style: t.body(12, color: c.textSecondary),
            )
          else ...[
            Text(
              '공시 부문 매출 · ${formatDate(facts.first.asOf)} 기준',
              style: t.body(10, color: c.textSecondary),
            ),
            const SizedBox(height: AppSpace.sm),
            for (final f in facts.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.xs,
                      children: [
                        Text(
                          f.label,
                          style: t.body(12, weight: FontWeight.w600),
                        ),
                        Text(
                          '${formatDecimal(f.value)} ${f.unit}',
                          style: t.numeric(12),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      f.evidence.split(' | ').skip(1).firstOrNull ?? '공시 근거 확인',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.body(10, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: c.surface),
              child: ExpansionTile(
                dense: true,
                tilePadding: EdgeInsets.zero,
                title: Text('공시 근거 펼치기', style: t.body(11, color: c.accent)),
                children: [
                  Text(
                    facts.take(4).map((f) => f.evidence).join('\n\n'),
                    style: t
                        .body(11, color: c.textSecondary)
                        .copyWith(height: 1.7),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          Text(
            '부문 간 내부거래 등이 포함될 수 있어 합계를 연결 매출로 표시하지 않습니다.',
            style: t.body(10, color: c.textSecondary),
          ),
          TextButton(
            onPressed: () => context.go('/company/00126380'),
            child: const Text('실제 기업 화면 열기 →'),
          ),
        ],
      ),
    );
  }
}
