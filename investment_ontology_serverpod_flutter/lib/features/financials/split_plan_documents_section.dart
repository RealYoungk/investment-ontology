import 'package:shad/shad.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../design/tokens.dart';
import 'split_plan_source_registry.dart';

/// Delegated raw sources stay visibly distinct from own financial history.
class SplitPlanDocumentsSection extends StatefulWidget {
  const SplitPlanDocumentsSection({
    super.key,
    required this.corpCode,
    this.dataVersion = 0,
    this.loader,
  });
  final String corpCode;
  final int dataVersion;
  final Future<String> Function(String, String)? loader;
  @override
  State<SplitPlanDocumentsSection> createState() => _State();
}

class _State extends State<SplitPlanDocumentsSection> {
  Map<String, dynamic>? row;
  Object? error;
  bool loading = true;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant SplitPlanDocumentsSection old) {
    super.didUpdateWidget(old);
    if (old.corpCode != widget.corpCode ||
        old.dataVersion != widget.dataVersion) {
      load();
    }
  }

  Future<void> load() async {
    final token = ++generation;
    if (!SplitPlanSourceRegistry.supports(widget.corpCode)) return;
    setState(() {
      loading = true;
      error = null;
      row = null;
    });
    try {
      final value = jsonDecode(
        await (widget.loader ?? client.research.data)(
          widget.corpCode,
          'splitPlanDocuments',
        ),
      );
      final result = value['state'] == 'ready'
          ? SplitPlanSourceRegistry.validate(widget.corpCode, value)
          : null;
      if (mounted && token == generation) {
        setState(() {
          row = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted && token == generation) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SplitPlanSourceRegistry.supports(widget.corpCode)) {
      return const SizedBox.shrink();
    }
    final t = context.typo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('분할 신설회사 · 대행 제출 원문', style: t.body(16)),
          const SizedBox(height: 8),
          if (loading)
            Text('원문 보존 상태를 확인하고 있습니다.', style: t.body(13))
          else if (error != null)
            Text('출처를 검증하지 못했습니다. 다시 확인해 주세요.', style: t.body(13))
          else if (row == null)
            Text('대행 제출 원문 보존 전입니다.', style: t.body(13))
          else ...[
            Text(
              '${row!['filingActorPrintedName']}가 ${row!['targetPrintedName']}를 대신해 제출한 분할 증권신고서입니다.',
              style: t.body(13),
            ),
            const SizedBox(height: 8),
            Text(
              '제출 ${row!['filingDate']} · 계획 분할 ${row!['plannedSplitDate']} · 등록 설립 ${row!['actualEstablishedDate']}',
              style: t.body(12),
            ),
            const SizedBox(height: 8),
            Text(
              '모회사·분할 사업부문의 과거 비교자료와 예정 재무정보가 포함됩니다. 신설회사의 자체 감사 실적이나 정기보고서로 집계하지 않습니다. 재무 숫자는 추출하지 않았습니다.',
              style: t.body(13, color: context.colors.textSecondary),
            ),
            Text(
              '수집 시 전체 원문 바이트를 검증하고 비공개 보존합니다. 본문 확인 범위: 제출회사와 대행 제출 절. 정기보고서 제출 의무·과거 5개년 원천 부재는 확정하지 않았습니다.',
              style: t.body(12, color: context.colors.textMuted),
            ),
            ShadButton.ghost(
              onPressed: () => launchUrl(
                Uri.parse(row!['officialUrl'] as String),
                mode: LaunchMode.externalApplication,
              ),
              child: Flexible(child: const Text('KIND 공식 원문 보기')),
            ),
          ],
        ],
      ),
    );
  }
}
