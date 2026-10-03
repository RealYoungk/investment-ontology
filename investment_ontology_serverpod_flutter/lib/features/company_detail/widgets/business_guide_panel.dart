import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import 'revenue_composition.dart';
import '../business/overview_catalog.dart';
import 'business_model_guide.dart';
import 'substrate_guide.dart';
import '../business/power_product_lesson.dart';
import 'power_components_guide.dart';
import '../business/company_development.dart';
import 'company_development_section.dart';
import 'company_research_guide.dart';

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
  String? _issuerSummary;
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
    if (oldWidget.corpCode != widget.corpCode) _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _data = null;
      _lesson = null;
      _lessonLoading = true;
      _powerLesson = null;
      _issuerSummary = null;
      _failed = false;
      _selected = 0;
    });
    _loadLesson(seq);
    _loadSummary(seq);
    try {
      final data = await client.disclosure.understanding(widget.corpCode);
      if (mounted && seq == _seq) setState(() => _data = data);
      if (data.status == 'ready' &&
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

  Future<void> _loadSummary(int seq) async {
    try {
      final sections = await client.disclosure.digest(widget.corpCode);
      final overview = sections
          .where((s) => s.kind == BusinessDigestKind.overview)
          .firstOrNull;
      if (mounted && seq == _seq) {
        setState(
          () => _issuerSummary = overview?.summary.split('\n').first.trim(),
        );
      }
    } catch (_) {
      // Confirmed product names remain usable if the optional digest is absent.
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
        _lesson = lesson;
        _lessonLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final data = _data;
    final research = _lesson?.research;
    final development =
        CompanyDevelopment.forCompany(widget.corpCode) ??
        (research != null && research.covers(widget.latestReport)
            ? research.development
            : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompanyDataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CompanySectionHeading('사업의 내용'),
              const SizedBox(height: AppSpace.md),
              if (research != null || development != null) ...[
                Text(
                  research?.summary ?? _issuerSummary ?? _lesson?.summary ?? '',
                  style: t
                      .body(16, weight: FontWeight.w600)
                      .copyWith(height: 1.6),
                ),
                const SizedBox(height: AppSpace.xl),
              ],
              if (development != null) ...[
                CompanyDevelopmentSection(development: development),
                const SizedBox(height: AppSpace.xl),
              ],
              if (research != null)
                CompanyResearchGuide(profile: research)
              else if (_lesson != null && development == null)
                BusinessModelGuide(
                  lesson: _lesson!,
                  summary: _issuerSummary,
                  compact: true,
                  framed: false,
                  showGrowth: false,
                )
              else if (_lessonLoading && development == null)
                const ShadProgress(minHeight: 2)
              else if (_failed) ...[
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
                  'no_document' => '제품을 확인할 사업보고서가 아직 수집되지 않았습니다.',
                  'pending' => '수집한 공시에서 제품 정보를 정리하고 있습니다.',
                  'stale' => '최근 사업보고서가 없어 제품 설명을 갱신하지 못했습니다.',
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
                        child: ShadToggle.outline(
                          value: i == _selected,
                          onChanged: (_) => setState(() => _selected = i),
                          child: Text(product.name),
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
                  '회사 제품 확인: FY${data.bsnsYear} 사업보고서 · 공정 설명은 제품 원리이며 회사별 성능 보증은 아닙니다.',
                  style: t.body(11, color: c.textMuted),
                ),
              ],
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
              '제품은 공시에서 확인했습니다. 쓰이는 공정과 고객의 사용 목적은 아직 연결되지 않았습니다.',
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
                          'DART 사업보고서 ↗',
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
