import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/ingest_monitor.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import 'filing_event.dart';

typedef FilingLoader = Future<List<DartDisclosure>> Function(String corpCode);

/// Reads stored public filings only. No external API, paid feed or auth needed.
class CompanyEventsSection extends StatefulWidget {
  const CompanyEventsSection({
    super.key,
    required this.corpCode,
    this.loader,
    this.openSource,
  });
  final String corpCode;
  final FilingLoader? loader;
  final void Function(Uri)? openSource;
  @override
  State<CompanyEventsSection> createState() => _CompanyEventsSectionState();
}

class _CompanyEventsSectionState extends State<CompanyEventsSection> {
  List<FilingEvent>? _events;
  bool _failed = false;
  int _sequence = 0, _visible = 6;
  FilingTopic? _topic;

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(covariant CompanyEventsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode ||
        oldWidget.loader != widget.loader) {
      _load();
    }
  }

  @override
  void dispose() {
    _sequence++;
    IngestMonitor.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final sequence = ++_sequence;
    setState(() {
      _events = null;
      _failed = false;
      _topic = null;
      _visible = 6;
    });
    try {
      final rows =
          await (widget.loader?.call(widget.corpCode) ??
              client.disclosure.recentOf(widget.corpCode, limit: 50));
      if (mounted && sequence == _sequence) {
        setState(() => _events = filingEvents(rows));
      }
    } catch (_) {
      if (mounted && sequence == _sequence) setState(() => _failed = true);
    }
  }

  void _select(FilingTopic? value) => setState(() {
    _topic = value;
    _visible = 6;
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final events = _events;
    final selected =
        events?.where((e) => _topic == null || e.topic == _topic).toList() ??
        [];
    final shown = selected.take(_visible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('최근 기업에 어떤 변화가 있었나요?', accent: true),
        const SizedBox(height: AppSpace.md),
        Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: context.shape.borderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_failed) ...[
                Text('공시를 불러오지 못했습니다.', style: t.body(14)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _load,
                    child: const Text('다시 시도'),
                  ),
                ),
              ] else if (events == null) ...[
                Text(
                  '기업의 공시 이력을 불러오는 중…',
                  style: t.body(13, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.sm),
                const LinearProgressIndicator(minHeight: 2),
              ] else if (events.isEmpty) ...[
                Text('아직 수집된 공시 이력이 없습니다.', style: t.body(14)),
                const SizedBox(height: AppSpace.xs),
                Text(
                  '공시나 기업 변화가 없다는 뜻은 아닙니다.',
                  style: t.body(12, color: c.textSecondary),
                ),
              ] else ...[
                Text(
                  '수집된 최근 ${events.length}건 · ${formatDate(events.last.filing.receivedDate)} ~ ${formatDate(events.first.filing.receivedDate)}',
                  style: t.body(12, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  '최대 50건의 공시를 제목으로 분류했습니다. 건수는 거래 횟수나 변화의 크기가 아닙니다.',
                  style: t.body(12, color: c.textMuted),
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    ChoiceChip(
                      label: Text('전체 ${events.length}'),
                      selected: _topic == null,
                      onSelected: (_) => _select(null),
                    ),
                    for (final topic in FilingTopic.values)
                      if (events.any((e) => e.topic == topic))
                        ChoiceChip(
                          label: Text(
                            '${topic.label} ${events.where((e) => e.topic == topic).length}',
                          ),
                          selected: _topic == topic,
                          onSelected: (_) => _select(topic),
                        ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  _topic?.guide ?? '관심 있는 변화를 고르고, 공시 원문에서 조건과 진행 상황을 확인하세요.',
                  style: t.body(13, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.lg),
                for (final (i, event) in shown.indexed) ...[
                  if (i == 0 || _month(event) != _month(shown[i - 1]))
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpace.sm,
                        top: AppSpace.sm,
                      ),
                      child: Text(
                        _month(event),
                        style: t.body(14, weight: FontWeight.w700),
                      ),
                    ),
                  _EventRow(event: event, openSource: widget.openSource),
                ],
                if (_visible < selected.length)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() => _visible += 12),
                      child: Text(
                        '공시 더 보기 · ${selected.length - shown.length}건 남음',
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '출처 DART · 접수일 기준. 정정 공시는 별도로 표시하며, 결정 공시만으로 실행 완료를 판단하지 않습니다.',
                  style: t.body(12, color: c.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _month(FilingEvent e) =>
      '${e.filing.receivedDate.year}년 ${e.filing.receivedDate.month}월';
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, this.openSource});
  final FilingEvent event;
  final void Function(Uri)? openSource;
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final uri = event.source;
    final tone = event.withdrawn ? c.textSecondary : c.accent;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 9),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tone,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(child: Container(width: 1, color: c.border)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        formatDate(event.filing.receivedDate),
                        style: t.numeric(12, color: c.textMuted),
                      ),
                      AppTag(label: event.topic.label),
                      if (event.stage != '공시')
                        AppTag(label: event.stage, color: tone),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    event.filing.reportName,
                    style: t
                        .body(14, weight: FontWeight.w600)
                        .copyWith(height: 1.5),
                  ),
                  if (event.filing.filerName?.isNotEmpty == true)
                    Text(
                      '제출인 ${event.filing.filerName}',
                      style: t.body(12, color: c.textSecondary),
                    ),
                  if (event.corrected || event.withdrawn)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.xs),
                      child: Text(
                        event.withdrawn
                            ? '철회 대상과 사유를 원문에서 확인하세요.'
                            : '변경된 조건을 원문에서 확인하세요. 기존 공시와 별도 건입니다.',
                        style: t.body(12, color: c.textSecondary),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: uri == null
                        ? null
                        : () {
                            if (openSource != null) {
                              openSource!(uri);
                            } else {
                              launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                    icon: const Icon(Icons.north_east, size: 14),
                    label: const Text('공시 원문'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
