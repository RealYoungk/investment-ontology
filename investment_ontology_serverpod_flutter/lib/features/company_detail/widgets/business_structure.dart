import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';

class BusinessStructureItem {
  BusinessStructureItem(this.segment);
  final String segment;
  final List<({String company, String service})> providers = [];
  final List<String> services = [],
      products = [],
      uses = [],
      companies = [],
      evidence = [];
}

/// Only named source columns; continuation rows inherit the segment, not numbers.
List<BusinessStructureItem> businessStructureItems(BusinessContent content) {
  final groups = <String, BusinessStructureItem>{};
  String key(String text) =>
      text.replaceAll(RegExp(r'\([^)]*\)'), '').replaceAll(RegExp(r'\s+'), '');
  for (final section in content.sections) {
    final lines = section.text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final header = lines[i].split('|').map((s) => s.trim()).toList();
      final segmentIndex = header.indexWhere(
        (s) => {'사업부문', '사업부', '부문'}.contains(key(s)),
      );
      final companyIndex = header.indexWhere(
        (s) => RegExp(r'^(해당)?연결회사$|^해당회사$').hasMatch(key(s)),
      );
      final serviceIndex = header.indexWhere(
        (s) => key(s).contains('주요제품및제공용역'),
      );
      final productIndex = header.indexWhere(
        (s) => {'품목', '주요제품', '제품'}.contains(key(s)),
      );
      final useIndex = header.indexWhere(
        (s) => {'구체적용도', '용도'}.contains(key(s)),
      );
      if (segmentIndex < 0 ||
          !((companyIndex >= 0 && serviceIndex >= 0) ||
              (productIndex >= 0 && useIndex >= 0))) {
        continue;
      }
      String? segment;
      for (var j = i + 1; j < lines.length; j++) {
        final raw = lines[j].trim();
        if (!raw.contains('|')) break;
        var cells = raw.split('|').map((s) => s.trim()).toList();
        if (cells.length == 2 &&
            companyIndex == 1 &&
            serviceIndex == 2 &&
            segment != null) {
          cells = [segment, ...cells];
        }
        // A second header expands year columns into amount/share pairs.
        // The named descriptive columns retain their original positions.
        if (cells.length != header.length &&
            !(productIndex >= 0 &&
                useIndex >= 0 &&
                cells.length > header.length &&
                cells
                    .skip(useIndex + 1)
                    .every((c) => RegExp(r'^[\d,.%()\s-]+$').hasMatch(c)))) {
          continue;
        }
        final candidate = cells[segmentIndex];
        if (RegExp(r'^(합계|총계|계)$').hasMatch(key(candidate))) break;
        if (candidate.isNotEmpty && candidate != '-') segment = candidate;
        if (segment == null || RegExp(r'^\d|매출액|비율').hasMatch(segment)) {
          continue;
        }
        final item = groups.putIfAbsent(
          key(segment),
          () => BusinessStructureItem(segment!),
        );
        void add(List<String> target, int index) {
          if (index < 0) return;
          final value = cells[index];
          if (value.isNotEmpty && value != '-' && !target.contains(value)) {
            target.add(value);
          }
        }

        if (companyIndex >= 0 && serviceIndex >= 0) {
          final provider = (
            company: cells[companyIndex],
            service: cells[serviceIndex],
          );
          if (!item.providers.contains(provider)) item.providers.add(provider);
        }
        add(item.companies, companyIndex);
        add(item.services, serviceIndex);
        add(item.products, productIndex);
        add(item.uses, useIndex);
        item.evidence.add('${lines[i]}\n$raw');
      }
    }
  }
  return groups.values.toList();
}

class BusinessStructureOverview extends StatefulWidget {
  const BusinessStructureOverview({
    super.key,
    required this.items,
    required this.content,
  });
  final List<BusinessStructureItem> items;
  final BusinessContent content;
  @override
  State<BusinessStructureOverview> createState() =>
      _BusinessStructureOverviewState();
}

class _BusinessStructureOverviewState extends State<BusinessStructureOverview> {
  final Set<String> _open = {};
  List<BusinessStructureItem> get items => widget.items;
  BusinessContent get content => widget.content;
  Widget toggle(String key, String label) => Align(
    alignment: Alignment.centerLeft,
    child: ShadButton.ghost(
      onPressed: () => setState(() {
        if (!_open.remove(key)) _open.add(key);
      }),
      child: Text('${_open.contains(key) ? "−" : "+"} $label'),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        content.source?.title ?? '${content.bsnsYear}년 보고서',
        style: context.typo.body(12, color: context.colors.textMuted),
      ),
      const SizedBox(height: AppSpace.md),
      LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth >= 680
              ? (box.maxWidth - AppSpace.md) / 2
              : box.maxWidth;
          return Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.md,
            children: [
              for (final (index, item) in items.indexed)
                SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.chartGrid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.segment,
                          style: context.typo.body(17, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        if (item.products.isNotEmpty) ...[
                          Text(
                            '제품·서비스',
                            style: context.typo.body(
                              12,
                              color: context.colors.textMuted,
                            ),
                          ),
                          for (final product in item.products)
                            Text(product, style: context.typo.body(14)),
                          const SizedBox(height: AppSpace.sm),
                        ],
                        if (item.uses.isNotEmpty) ...[
                          Text(
                            '용도',
                            style: context.typo.body(
                              12,
                              color: context.colors.textMuted,
                            ),
                          ),
                          for (final use in item.uses)
                            Text(use, style: context.typo.body(13)),
                        ] else
                          for (final service in item.services)
                            Text(service, style: context.typo.body(14)),
                        const SizedBox(height: AppSpace.sm),
                        if (item.providers.isNotEmpty) ...[
                          toggle('$index-providers', '담당 회사·제공 사업'),
                          if (_open.contains('$index-providers'))
                            for (final provider in item.providers) ...[
                              Text(
                                provider.service,
                                style: context.typo.body(
                                  13,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                provider.company,
                                style: context.typo.body(12),
                              ),
                              const SizedBox(height: AppSpace.sm),
                            ],
                        ],
                        toggle('$index-evidence', '원문 근거'),
                        if (_open.contains('$index-evidence'))
                          SelectableText(
                            item.evidence.join('\n\n'),
                            style: context.typo.body(12),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
