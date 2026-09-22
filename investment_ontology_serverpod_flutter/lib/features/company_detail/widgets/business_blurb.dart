import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';

/// 개요 탭의 "무엇을 하는 회사인가" — 사업의 내용을 읽기 좋게 녹인 절 가운데 첫 절.
///
/// 저장된 요약만 읽는다 (ai.submitDigest로 미리 넣은 것). 없으면 아무것도 그리지 않는다.
class BusinessBlurb extends StatefulWidget {
  const BusinessBlurb({
    super.key,
    required this.corpCode,
    required this.onOpen,
  });

  final String corpCode;
  final VoidCallback onOpen;

  @override
  State<BusinessBlurb> createState() => _BusinessBlurbState();
}

class _BusinessBlurbState extends State<BusinessBlurb> {
  BusinessDigestSection? _overview;
  int _count = 0;
  int _seq = 0;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BusinessBlurb old) {
    super.didUpdateWidget(old);
    if (old.corpCode != widget.corpCode) _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    try {
      final sections = await client.disclosure.digest(widget.corpCode);
      if (!mounted || seq != _seq) return;
      setState(() {
        _count = sections.length;
        _overview = sections
            .where((s) => s.kind == BusinessDigestKind.overview)
            .firstOrNull;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final o = _overview;
    if (o == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '무엇을 하는 회사인가 · FY${o.bsnsYear}',
          trailing: AppButton(
            label: '사업의 내용 $_count절 →',
            variant: AppButtonVariant.link,
            tone: c.accent,
            onPressed: widget.onOpen,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (_expanded)
          SelectableText(o.summary, style: t.body(16).copyWith(height: 1.85))
        else
          Text(
            o.summary,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: t.body(16).copyWith(height: 1.85),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? '사업 설명 접기' : '사업 설명 전체 읽기'),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          '사업보고서 "사업의 내용"을 읽어 쓴 글입니다. 근거는 사업의 내용 탭에서 절마다 펼쳐 볼 수 있습니다.',
          style: t.body(12, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.section),
      ],
    );
  }
}
