import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';

/// Small candidate cards; provenance and caveats only expand on demand.
class PeerCandidatesPanel extends StatefulWidget {
  const PeerCandidatesPanel({
    super.key,
    required this.codes,
    required this.onAdd,
    this.loadCandidates,
  });
  final List<String> codes;
  final ValueChanged<String> onAdd;
  final Future<PeerCandidates> Function(String)? loadCandidates;
  @override
  State<PeerCandidatesPanel> createState() => _PeerCandidatesPanelState();
}

class _PeerCandidatesPanelState extends State<PeerCandidatesPanel> {
  PeerCandidates? _data;
  bool _failed = false;
  int _request = 0;
  String? _focus;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PeerCandidatesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.codes.firstOrNull != widget.codes.firstOrNull) {
      _focus = null;
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _data = null;
      _failed = false;
    });
    final anchor = widget.codes.firstOrNull;
    if (anchor == null) return;
    try {
      final data = widget.loadCandidates != null
          ? await widget.loadCandidates!(anchor)
          : await client.screen.peerCandidates(anchor, focusKey: _focus);
      if (mounted && request == _request) {
        setState(() {
          _data = data;
          _focus ??= _focuses(data).firstOrNull?.key;
        });
      }
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.codes.isEmpty) return const SizedBox.shrink();
    final t = context.typo;
    final c = context.colors;
    final data = _data;
    if (_failed) {
      return Row(
        children: [
          Expanded(
            child: Text(
              '비교 후보를 불러오지 못했습니다.',
              style: t.body(12, color: c.textMuted),
            ),
          ),
          ShadButton.raw(
            onPressed: _load,

            variant: ShadButtonVariant.link,
            child: Flexible(child: Text('다시 시도')),
          ),
        ],
      );
    }
    if (data == null) return const ShadProgress(minHeight: 2);
    final emptyMessage = switch (data.status) {
      'no_document' => '비교에 필요한 최신 공시가 없습니다.',
      'pending' => '공시를 정리하고 있습니다. 검색으로 기업을 추가할 수 있습니다.',
      'unsupported' => '아직 비교할 제품을 확인하지 못했습니다.',
      _ => '이 제품으로 비교할 기업을 아직 찾지 못했습니다.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${_shortName(data.anchorName)}와 비교',
              style: t.body(16, weight: FontWeight.w600),
            ),
            if (_focuses(data).isNotEmpty)
              SizedBox(
                width: 230,
                child: AppSelect<String>(
                  value: _focus,
                  options: {for (final s in _focuses(data)) s.key: s.label},
                  placeholder: '비교할 제품',
                  allowClear: false,
                  onChanged: (key) {
                    if (key != null && key != _focus) {
                      _focus = key;
                      _load();
                    }
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        if (data.items.isEmpty)
          Text(emptyMessage, style: t.body(14, color: c.textSecondary))
        else
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 650 ? 2 : 1;
              final width =
                  (box.maxWidth - AppSpace.md * (columns - 1)) / columns;
              return Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.md,
                children: [
                  for (final candidate in data.items)
                    SizedBox(
                      width: width,
                      child: CompanyDataCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _shortName(candidate.name),
                                    style: t.body(15, weight: FontWeight.w600),
                                  ),
                                ),
                                ShadTooltip(
                                  builder: (_) => Text('비교 이유 보기'),
                                  child: Semantics(
                                    container: true,
                                    label: '비교 이유 보기',
                                    button: true,
                                    enabled: true,
                                    onTap: () => _showReason(
                                      context,
                                      data,
                                      candidate,
                                    ),
                                    child: ExcludeSemantics(
                                      child: ShadIconButton.outline(
                                        semanticLabel: '비교 이유 보기',
                                        onPressed: () => _showReason(
                                          context,
                                          data,
                                          candidate,
                                        ),
                                        icon: Icon(
                                          Icons.info_outline,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                ShadButton.raw(
                                  onPressed:
                                      widget.codes.length >= 4 ||
                                          widget.codes.contains(
                                            candidate.corpCode,
                                          )
                                      ? null
                                      : () => widget.onAdd(candidate.corpCode),
                                  enabled:
                                      (widget.codes.length >= 4 ||
                                              widget.codes.contains(
                                                candidate.corpCode,
                                              )
                                          ? null
                                          : () => widget.onAdd(
                                              candidate.corpCode,
                                            )) !=
                                      null,
                                  variant: ShadButtonVariant.outline,
                                  leading: Icon(
                                    widget.codes.contains(candidate.corpCode)
                                        ? Icons.check
                                        : Icons.add,
                                    size: 16,
                                  ),
                                  child: Flexible(
                                    child: Text(
                                      widget.codes.contains(candidate.corpCode)
                                          ? '추가됨'
                                          : '추가',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.sm),
                            Text(
                              '두 회사 모두 ${candidate.reasons.take(2).join(' · ')} 제품군을 다룹니다.',
                              style: t
                                  .body(14, color: c.textPrimary)
                                  .copyWith(height: 1.6),
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
}

List<PeerSignal> _focuses(PeerCandidates data) => [
  ...data.signals.where(
    (s) => const {
      'substrate',
      'wafer',
      'smt',
      'display',
      'battery',
    }.contains(s.key),
  ),
  ...data.signals.where(
    (s) => s.key.startsWith('product/') && !s.key.startsWith('product/exact/'),
  ),
  ...data.signals.where((s) => s.key.startsWith('product/exact/')),
];

String _shortName(String name) =>
    name.replaceAll('(주)', '').replaceAll('주식회사', '').trim();

void _showReason(
  BuildContext context,
  PeerCandidates data,
  PeerCandidate candidate,
) {
  final ownKeys = data.signals.map((s) => s.key).toSet();
  final otherKeys = candidate.signals.map((s) => s.key).toSet();
  final ownExtra = data.signals
      .where((s) => !otherKeys.contains(s.key))
      .map((s) => s.label)
      .toList();
  final otherExtra = candidate.signals
      .where((s) => !ownKeys.contains(s.key))
      .map((s) => s.label)
      .toList();
  showShadDialog<void>(
    context: context,
    builder: (overlayContext) => InheritedTheme.captureAll(
      context,
      Builder(
        builder: (context) {
          final t = context.typo;
          final c = context.colors;
          Widget scope(String name, List<String> labels) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _shortName(name),
                  style: t.body(14, weight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  labels.isEmpty
                      ? '추가로 구분할 제품은 확인되지 않았습니다.'
                      : labels.join(' · '),
                  style: t
                      .body(15, color: c.textSecondary)
                      .copyWith(height: 1.6),
                ),
              ],
            ),
          );
          return ShadDialog(
            closeIcon: Builder(
              builder: (context) => Semantics(
                container: true,
                label: '닫기',
                button: true,
                onTap: () => Navigator.of(context).pop(),
                child: ExcludeSemantics(
                  child: ShadIconButton.ghost(
                    width: 20,
                    height: 20,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('왜 비교하나요?', style: t.display(24)),
                          ),
                          Semantics(
                            container: true,
                            label: '닫기',
                            button: true,
                            enabled: true,
                            onTap: () => Navigator.pop(context),
                            child: ExcludeSemantics(
                              child: ShadIconButton.ghost(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                semanticLabel: '닫기',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${_shortName(data.anchorName)} · ${_shortName(candidate.name)}',
                                style: t.body(14, color: c.textSecondary),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              Text(
                                '공통으로 ${candidate.reasons.join(' · ')} 제품군을 다룹니다.',
                                style: t
                                    .body(18, weight: FontWeight.w600)
                                    .copyWith(height: 1.6),
                              ),
                              const SizedBox(height: AppSpace.xl),
                              Text(
                                '함께 살펴볼 차이',
                                style: t.body(16, weight: FontWeight.w600),
                              ),
                              scope(data.anchorName, ownExtra),
                              Divider(color: c.border),
                              scope(candidate.name, otherExtra),
                              Text(
                                '제품이 겹쳐도 주력 사업과 고객, 수익 구조는 다를 수 있습니다. 매출 구성까지 확인한 뒤 밸류에이션을 비교하세요.',
                                style: t
                                    .body(14, color: c.textSecondary)
                                    .copyWith(height: 1.7),
                              ),
                              const SizedBox(height: AppSpace.lg),
                              ShadAccordion<int>(
                                maintainState: false,
                                children: [
                                  ShadAccordionItem<int>(
                                    value: 0,
                                    title: Text(
                                      '공시 근거 보기',
                                      style: t.body(
                                        14,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _Evidence(
                                          name: data.anchorName,
                                          year: data.bsnsYear!,
                                          receipt: data.rceptNo!,
                                          signals: data.signals,
                                        ),
                                        const SizedBox(height: AppSpace.xl),
                                        _Evidence(
                                          name: candidate.name,
                                          year: candidate.bsnsYear,
                                          receipt: candidate.rceptNo,
                                          signals: candidate.signals,
                                        ),
                                        const SizedBox(height: AppSpace.md),
                                        Text(
                                          '공시에서 확인한 제품만 표시합니다. 표시되지 않은 제품이 없다는 뜻은 아닙니다.',
                                          style: t.body(13, color: c.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
    barrierLabel: '닫기',
  );
}

class _Evidence extends StatelessWidget {
  const _Evidence({
    required this.name,
    required this.year,
    required this.receipt,
    required this.signals,
  });
  final String name;
  final int year;
  final String receipt;
  final List<PeerSignal> signals;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '$name · $year 사업보고서',
        style: context.typo.body(12, weight: FontWeight.w600),
      ),
      for (final quote in signals.map((s) => s.evidence).toSet())
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.sm),
          child: SelectableText(
            '${signals.where((s) => s.evidence == quote).map((s) => s.label).join(' · ')}\n“$quote”',
            style: context.typo
                .body(14, color: context.colors.textSecondary)
                .copyWith(height: 1.7),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: ShadButton.raw(
          onPressed: () => launchUrl(
            Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {'rcpNo': receipt}),
          ),
          variant: ShadButtonVariant.outline,
          leading: Icon(Icons.open_in_new, size: 16),
          child: Flexible(child: Text('공시 원문')),
        ),
      ),
    ],
  );
}
