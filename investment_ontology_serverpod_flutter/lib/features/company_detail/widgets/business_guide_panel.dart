import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import 'revenue_composition.dart';
import '../../financials/financial_metrics.dart' show reportCodeLabel;
import '../business/overview_catalog.dart';
import 'business_model_guide.dart';
import 'substrate_guide.dart';
import '../business/power_product_lesson.dart';
import 'power_components_guide.dart';

/// Every issuer uses the same stored profile contract and explicit coverage states.
class BusinessGuidePanel extends StatefulWidget {
  const BusinessGuidePanel({
    super.key,
    required this.corpCode,
    this.latestReport,
  });
  final String corpCode;
  final FinancialPeriod? latestReport;
  @override
  State<BusinessGuidePanel> createState() => _BusinessGuidePanelState();
}

class _BusinessGuidePanelState extends State<BusinessGuidePanel> {
  BusinessUnderstanding? _data;
  CompanyOverviewLesson? _lesson;
  bool _lessonLoading = true;
  PowerProductLesson? _powerLesson;
  bool _failed = false;
  int _seq = 0, _selected = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BusinessGuidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode ||
        oldWidget.latestReport?.rceptNo != widget.latestReport?.rceptNo) {
      _load();
    }
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _data = null;
      _lesson = null;
      _lessonLoading = true;
      _powerLesson = null;
      _failed = false;
      _selected = 0;
    });
    _loadLesson(seq);
    try {
      final data = await client.disclosure.understanding(widget.corpCode);
      if (mounted && seq == _seq) {
        // Frontend/backend may be deployed separately. The retired pipeline
        // rule must never be revived by a legacy response during rollout.
        setState(
          () => _data = data.ruleVersion < 40000
              ? data.copyWith(status: 'pending', products: [])
              : data,
        );
      }
      if (data.status == 'ready' &&
          data.ruleVersion >= 40000 &&
          data.products.any((p) => p.name.toUpperCase().contains('SMPS'))) {
        // Optional local lesson: a failed source fetch must not hide the profile.
        try {
          final content = await client.disclosure.businessContent(
            widget.corpCode,
          );
          if (mounted && seq == _seq) {
            setState(
              () => _powerLesson = PowerProductLesson.resolve(data, content),
            );
          }
        } catch (_) {
          // Keep the original product cards and revenue fetch available.
        }
      }
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  Future<void> _loadLesson(int seq) async {
    CompanyOverviewLesson? lesson;
    try {
      lesson = (await OverviewCatalog.load()).forCompany(widget.corpCode);
    } catch (_) {
      // The API-backed product display remains available if an asset fails.
    }
    if (mounted && seq == _seq) {
      setState(() {
        _lesson = lesson == null
            ? null
            : CompanyOverviewLesson(
                summary: '',
                products: const [],
                models: lesson.models,
                hasDocument: lesson.hasDocument,
                year: null,
              );
        _lessonLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final data = _data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompanyDataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CompanySectionHeading('사업의 내용'),
              const SizedBox(height: AppSpace.md),
              if (_failed) ...[
                Text('제품 설명을 불러오지 못했습니다.', style: t.body(14)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ShadButton.ghost(
                    onPressed: _load,
                    child: Flexible(child: const Text('다시 불러오기')),
                  ),
                ),
              ] else if (data == null)
                const ShadProgress(minHeight: 2)
              else if (data.products.isEmpty)
                Text(switch (data.status) {
                  'no_document' => '제품을 확인할 정기보고서가 아직 수집되지 않았습니다.',
                  'pending' => '최신 정기보고서 본문 수집·제품 정보 갱신 대기 중입니다.',
                  'stale' => '최근 정기보고서가 없어 제품 설명을 갱신하지 못했습니다.',
                  _ => '공시는 있지만 제품과 용도를 자동으로 연결하지 못했습니다. 사업 원문에서 확인할 수 있습니다.',
                }, style: t.body(14, color: c.textSecondary))
              else if (_powerLesson != null) ...[
                PowerComponentsGuide(
                  includeOptical: widget.corpCode == '00317210',
                ),
              ] else if (data.products.any(
                (p) => p.key == 'substrate_aoi',
              )) ...[
                const SubstrateGuide(),
              ] else ...[
                Text('공시에서 확인한 제품', style: t.body(20, weight: FontWeight.w700)),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final (i, product) in data.products.indexed)
                      IntrinsicWidth(
                        child: ShadButton.ghost(
                          onPressed: () => setState(() => _selected = i),
                          child: Text(
                            product.name,
                            style: t.body(
                              14,
                              weight: i == _selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: i == _selected
                                  ? c.accent
                                  : c.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                BusinessProductCard(
                  product: data.products[_selected],
                  rceptNo: data.rceptNo,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '${data.reportName ?? '${data.bsnsYear} ${data.reportCode == null ? '정기보고서' : reportCodeLabel(data.reportCode!)}'} · 규칙 추출',
                  style: t.body(11, color: c.textMuted),
                ),
              ],
              if (data != null && data.rceptNo != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ShadButton.ghost(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${data.rceptNo}',
                      ),
                    ),
                    child: Text(
                      '${data.reportName ?? '${data.bsnsYear} 정기보고서'} 원문',
                    ),
                  ),
                ),
              if (_lesson != null) ...[
                const SizedBox(height: AppSpace.lg),
                BusinessModelGuide(
                  lesson: _lesson!,
                  compact: true,
                  framed: false,
                  showGrowth: false,
                ),
              ] else if (_lessonLoading)
                const ShadProgress(minHeight: 2),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        if (_lesson?.models.first.label != '기업인수목적회사')
          RevenueComposition(
            corpCode: widget.corpCode,
            products: data?.products ?? const [],
            printedMix: _powerLesson,
          ),
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }
}

class BusinessProductCard extends StatelessWidget {
  const BusinessProductCard({super.key, required this.product, this.rceptNo});
  final BusinessProduct product;
  final String? rceptNo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final explained = product.explanationKind != 'source_only';
    final circuit = product.key.startsWith('substrate_');
    return DataPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (explained) ...[
            Text(
              product.process,
              style: t.body(13, color: c.accent, weight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              product.role,
              style: t.body(19, weight: FontWeight.w700).copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              product.benefit.isEmpty ? '' : '고객이 쓰는 이유 · ${product.benefit}',
              style: t.body(14).copyWith(height: 1.7),
            ),
          ] else ...[
            Text(product.name, style: t.body(19, weight: FontWeight.w700)),
            const SizedBox(height: AppSpace.sm),
            Text(
              product.role.isNotEmpty ? product.role : '제품명은 공시 표에서 확인했습니다.',
              style: t.body(14, color: c.textSecondary).copyWith(height: 1.7),
            ),
          ],
          Material(
            color: c.surface,
            child: ShadAccordion<int>(
              key: ValueKey(product.key),
              maintainState: false,
              children: [
                ShadAccordionItem<int>(
                  value: 0,
                  title: Text('이 회사의 제품인 근거', style: t.body(13)),
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        product.evidence,
                        style: t.body(13).copyWith(height: 1.7),
                      ),
                      if (rceptNo != null)
                        _link(
                          'DART 정기보고서 ↗',
                          'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$rceptNo',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (product.referenceUrl != null)
            _link('제품 원리·사진 참고 ↗', product.referenceUrl!),
          if (circuit)
            _link(
              '패키지 기판의 역할 · 삼성전기 ↗',
              'https://www.samsungsem.com/kr/product/substrate/package-substrate.do',
            ),
        ],
      ),
    );
  }

  Widget _link(String label, String url) => Align(
    alignment: Alignment.centerLeft,
    child: ShadButton.raw(
      onPressed: () => launchUrl(Uri.parse(url)),
      variant: ShadButtonVariant.link,
      child: Flexible(child: Text(label)),
    ),
  );
}
