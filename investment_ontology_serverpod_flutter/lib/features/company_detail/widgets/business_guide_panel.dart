import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import 'revenue_composition.dart';
import 'business_table_insights_panel.dart';
import 'business_structure.dart';
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
    this.summary = false,
    this.afterRevenue,
  });
  final bool summary;
  final Widget? afterRevenue;
  final String corpCode;
  final FinancialPeriod? latestReport;
  @override
  State<BusinessGuidePanel> createState() => _BusinessGuidePanelState();
}

class _BusinessGuidePanelState extends State<BusinessGuidePanel> {
  BusinessUnderstanding? _data;
  BusinessContent? _content;
  bool _contentLoading = true;
  bool _contentFailed = false;
  CompanyOverviewLesson? _lesson;
  bool _lessonLoading = true;
  PowerProductLesson? _powerLesson;
  bool _failed = false;
  int _seq = 0;
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
      _content = null;
      _contentLoading = true;
      _contentFailed = false;
      _lesson = null;
      _lessonLoading = true;
      _powerLesson = null;
      _failed = false;
    });
    _loadLesson(seq);
    _loadContent(seq);
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
      if (mounted && seq == _seq && _content != null) {
        setState(
          () => _powerLesson = PowerProductLesson.resolve(data, _content),
        );
      }
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  Future<void> _loadContent(int seq) async {
    try {
      final content = await client.disclosure.businessContent(widget.corpCode);
      if (!mounted || seq != _seq) return;
      setState(() {
        _content = content;
        if (_data != null && content != null) {
          _powerLesson = PowerProductLesson.resolve(_data!, content);
        }
        _contentLoading = false;
      });
    } catch (_) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _contentFailed = true;
        _contentLoading = false;
      });
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
    final structure = _content == null
        ? <BusinessStructureItem>[]
        : businessStructureItems(_content!);
    final receipt = _content?.rceptNo ?? data?.rceptNo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompanyDataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompanySectionHeading(
                '사업 구조',
                trailing: receipt == null
                    ? null
                    : ShadButton.ghost(
                        onPressed: () => launchUrl(
                          Uri.parse(
                            'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
                          ),
                        ),
                        child: const Text('DART ↗'),
                      ),
                help: '원문의 사업부문·제품·용도·연결회사 표를 연결합니다. 금액은 아래 매출 구성과 사업 지표에서 확인할 수 있습니다. 사업 구분과 실제 매출 발생 여부는 다를 수 있습니다.',
              ),
              const SizedBox(height: AppSpace.md),
              if (_contentLoading)
                const ShadProgress(minHeight: 2)
              else if (_contentFailed) ...[
                Text('사업 본문을 불러오지 못했습니다.', style: t.body(14)),
                ShadButton.ghost(
                  onPressed: _load,
                  child: const Text('본문 다시 불러오기'),
                ),
              ],
              if (structure.isNotEmpty)
                widget.summary
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in structure)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpace.sm,
                              ),
                              child: Text(
                                '${item.segment} · ${(item.products.isNotEmpty ? item.products : item.services).join(" · ")}',
                                style: t.body(14),
                              ),
                            ),
                        ],
                      )
                    : BusinessStructureOverview(
                        items: structure,
                        content: _content!,
                      )
              else ...[
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
                    'pending' =>
                      _content != null
                          ? '본문은 수집됐으며 제품 표 추출 결과는 갱신 대기 중입니다.'
                          : '최신 정기보고서 본문 수집·제품 정보 갱신 대기 중입니다.',
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
                  LayoutBuilder(
                    builder: (context, box) {
                      final columns = box.maxWidth >= 600 ? 2 : 1;
                      return Wrap(
                        spacing: AppSpace.md,
                        runSpacing: AppSpace.md,
                        children: [
                          for (final product in data.products)
                            SizedBox(
                              width:
                                  (box.maxWidth - AppSpace.md * (columns - 1)) /
                                  columns,
                              child: BusinessProductCard(
                                product: product,
                                rceptNo: data.rceptNo,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '${data.reportName ?? '${data.bsnsYear} ${data.reportCode == null ? '정기보고서' : reportCodeLabel(data.reportCode!)}'} · 규칙 추출',
                    style: t.body(11, color: c.textMuted),
                  ),
                ],
              ],
              if (structure.isEmpty) ...[
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
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        if (_lesson?.models.first.label != '기업인수목적회사')
          RevenueComposition(
            latestReport: widget.latestReport,
            corpCode: widget.corpCode,
            products: data?.products ?? const [],
            printedMix: _powerLesson,
            showTrends: !widget.summary,
          ),
        if (widget.afterRevenue != null) ...[
          const SizedBox(height: AppSpace.xl),
          widget.afterRevenue!,
        ],
        const SizedBox(height: AppSpace.xl),
        if (_content?.title.startsWith('이전 저장 보고서 ·') == true) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Text(
              '${_content!.title} · 아래 표는 ${_content!.source?.title ?? '${_content!.bsnsYear} 저장 보고서'} 기준입니다.',
              style: t.body(13, color: c.textSecondary),
            ),
          ),
        ],
        if (!widget.summary && _content != null)
          BusinessTableInsightsPanel(
            insights: _content!.tableInsights ?? [],
            rceptNo: _content!.rceptNo,
            corpCode: widget.corpCode,
            latest: _content!,
            latestReport: widget.latestReport,
          ),
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
            if (product.role.isNotEmpty)
              Text(
                product.role,
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
