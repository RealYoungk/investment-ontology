import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'statement_conflict_evidence.dart';

/// Bound original-source contradictions, never numerical or noData facts.
class StatementConflictNotice extends StatelessWidget {
  const StatementConflictNotice({
    super.key,
    required this.corpCode,
    required this.sources,
    this.onOpen,
  });
  final String corpCode;
  final List<Source> sources;
  final void Function(Uri)? onOpen;
  static Map? evidence(Source s, String corp) {
    if (s.id == null || s.kind != SourceKind.dartReport) {
      return null;
    }
    try {
      final j = jsonDecode(s.title);
      if (j is! Map ||
          j['action'] != 'verified-primary-source-conflict' ||
          j['corpCode'] != corp ||
          j['status'] != 'failed' ||
          j['financialFactsStored'] != false ||
          j['evidence'] is! Map) {
        return null;
      }
      final key = '${j['targetReceipt']}:${j['fsDiv']}';
      final p = StatementConflictProof.expected[key];
      if (p is! Map ||
          p['corpCode'] != corp ||
          s.reference != 'financial-source-conflict:$key' ||
          s.url != p['statementSource'] ||
          j['reportName'] != '사업보고서 (${p['year']}.12)') {
        return null;
      }
      final e = j['evidence'] as Map;
      if (e.containsKey('negativeCacheManifestSha256') &&
          (e['negativeCacheManifestSha256'] !=
                  '1c1258d005c9be24980a12b10ef7bf1506d053327366f8598b0ebfa821eb41d5' ||
              e['networkRequests'] != 0 ||
              e['apiCalls'] != 0 ||
              e['readFromPinnedCache'] != true ||
              e['collectionComplete'] != false ||
              e['noData'] != false)) {
        return null;
      }
      return StatementConflictProof.matches(key, e) ? e : null;
    } on FormatException {
      return null;
    }
  }

  void open(Uri uri) {
    if (onOpen != null) {
      onOpen!(uri);
    } else {
      launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = [
      for (final s in sources)
        if (evidence(s, corpCode) != null) s,
    ];
    if (valid.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in valid) ...[
          ShadAlert(
            description: Text(
              '${evidence(s, corpCode)!['year']}년 ${evidence(s, corpCode)!['consolidated'] == true ? '연결' : '별도'} 원문 수치·기간 표기에 충돌이 있어 수집 실패로 남아 있습니다. 숫자를 임의로 고치거나 비교기간 값·0으로 대체하지 않습니다.',
            ),
          ),
          ShadAccordion<int>(
            maintainState: false,
            children: [
              ShadAccordionItem<int>(
                value: 0,
                title: Text(
                  '원문 충돌 근거 · 출처 #${s.id}',
                  style: context.typo.body(12.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evidence(s, corpCode)!['reason'] as String,
                        style: context.typo.body(12.5),
                      ),
                      Wrap(
                        spacing: AppSpace.sm,
                        children: [
                          ShadButton.raw(
                            onPressed: () => open(Uri.parse(s.url!)),
                            variant: ShadButtonVariant.link,
                            child: Text('공식 재무제표 원문'),
                          ),
                          ShadButton.raw(
                            onPressed: () => open(
                              Uri.parse(
                                evidence(s, corpCode)!['coverSource'] as String,
                              ),
                            ),
                            variant: ShadButtonVariant.link,
                            child: Text('공식 보고기간 표지'),
                          ),
                        ],
                      ),
                      Text(
                        '해당 원문의 확인된 충돌 기록입니다. 전체 재무제표·주석 수집 완료 또는 자료 없음 확정을 뜻하지 않습니다.',
                        style: context.typo.body(
                          12,
                          color: context.colors.textMuted,
                        ),
                      ),
                      SelectableText(
                        const JsonEncoder.withIndent('  ')
                            .convert(jsonDecode(s.title)),
                        style: context.typo.body(12),
                      ),
                    ],
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
