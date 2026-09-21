import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';

/// 개요 탭의 업종 비교: 같은 업종 기업들의 중앙값과 이 기업의 자리.
///
/// 값은 저장하지 않는다. 스크리너와 같은 계산(최근 12개월 · 최근 시세)을 쓰므로
/// 여기 숫자와 스크리너·기업 머리의 숫자가 항상 같다.
class PeerDigest extends StatefulWidget {
  const PeerDigest({super.key, required this.corpCode});

  final String corpCode;

  @override
  State<PeerDigest> createState() => _PeerDigestState();
}

class _PeerDigestState extends State<PeerDigest> {
  PeerComparison? _peers;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PeerDigest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) {
      setState(() => (_peers = null, _loaded = false));
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final peers = await client.screen.peers(widget.corpCode);
      if (mounted) setState(() => (_peers = peers, _loaded = true));
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final peers = _peers;
    if (!_loaded || peers == null) return const SizedBox.shrink();
    final shown = [
      for (final m in peers.metrics)
        if (m.value != null && m.median != null) m,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();

    String fmt(String key, double v) => switch (key) {
      'per' || 'pbr' => '${v.toStringAsFixed(2)}배',
      _ => '${v.toStringAsFixed(1)}%',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: c.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('업종 비교', accent: true),
          const SizedBox(height: 2),
          Text(
            '${peers.label} · ${peers.peerCount}개사',
            style: t.body(12.5, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          for (final m in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 82,
                    child: Text(
                      m.label,
                      style: t.body(13, color: c.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      fmt(m.key, m.value!),
                      style: t.numeric(13.5, weight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '중앙 ${fmt(m.key, m.median!)}',
                      style: t.numeric(12.5, color: c.textMuted),
                    ),
                  ),
                  if (m.rank case final rank?)
                    Text(
                      '$rank / ${m.ranked}위',
                      style: t.numeric(
                        12.5,
                        color: rank <= (m.ranked ?? 1) / 3
                            ? c.accent
                            : c.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: '이 업종 스크리닝 →',
              variant: AppButtonVariant.link,
              tone: c.accent,
              onPressed: () => context.push('/screen'),
            ),
          ),
          Text(
            '순위는 값이 있는 기업만 셉니다. PER·PBR·부채비율은 낮을수록 앞입니다.',
            style: t.body(11.5, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
