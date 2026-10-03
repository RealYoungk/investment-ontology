import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../app/ingest_monitor.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';

/// Actual rule-extracted before/after clauses and dated filing history.
class ShareholderRightsCard extends StatefulWidget {
  const ShareholderRightsCard({super.key, required this.corpCode, this.load});
  final String corpCode;
  final Future<String> Function(String)? load;
  @override
  State<ShareholderRightsCard> createState() => _ShareholderRightsCardState();
}

class _ShareholderRightsCardState extends State<ShareholderRightsCard> {
  Map<String, dynamic>? _data;
  Object? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    IngestMonitor.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ShareholderRightsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) {
      _data = null;
      _error = null;
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() => _error = null);
    try {
      final raw =
          await (widget.load?.call(widget.corpCode) ??
              client.charter.summary(widget.corpCode));
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (mounted && request == _request) setState(() => _data = data);
    } catch (error) {
      if (mounted && request == _request) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (_error != null) {
      return ReadFailureNotice(subject: '정관 변경', retry: _load);
    }
    if (data == null) return const ShadProgress(minHeight: 2);
    if (data['state'] == 'noCompany') {
      return const SizedBox.shrink();
    }
    final history = data['history'] as Map<String, dynamic>?;
    final proposal = data['proposal'] as Map<String, dynamic>?;
    final notices = (data['notices'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final changes = ((proposal ?? history)?['changes'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    final combined = <String, Map<String, dynamic>>{};
    for (final row in changes) {
      final key = '${row['title']}|${row['meaning']}';
      final prior = combined[key];
      if (prior == null) {
        combined[key] = Map<String, dynamic>.from(row);
      } else {
        prior['before'] = '${prior['before']}\n\n${row['before']}';
        prior['after'] = '${prior['after']}\n\n${row['after']}';
        if (prior['reason'] != row['reason']) {
          prior['reason'] = '${prior['reason']}\n${row['reason']}';
        }
      }
    }
    changes.clear();
    changes.addAll(combined.values);
    final rows = (history?['history'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    // Lead with shareholder-facing substantive changes; keep every clause available.
    const topics = [
      '이사회 견제',
      '의결권',
      '주주 보호',
      '감사·견제',
      '주총 참여',
      '자기주식',
      '시행 시점',
      '이사회',
      '기타 변경',
    ];
    changes.sort(
      (a, b) => topics
          .indexOf(a['topic'] as String)
          .compareTo(topics.indexOf(b['topic'] as String)),
    );
    final t = context.typo, c = context.colors;
    return CompanyDataCard(
      child: Material(
        color: c.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CompanySectionHeading('정관은 어떻게 바뀌었나요?'),
            const SizedBox(height: AppSpace.md),
            if (data['noticeCount'] != null)
              Text(
                '${data['noticeFromDate'] ?? '최근 1년'}${data['noticeToDate'] == null ? '' : ' ~ ${data['noticeToDate']}'} 소집공고 · ${data['inspectedCount'] ?? 0}/${data['noticeCount']}건 확인',
                style: t.body(11, color: c.textMuted),
              ),
            if (changes.isNotEmpty) ...[
              Text(
                '${proposal?['meetingDate'] ?? proposal?['filingDate'] ?? ''} ${proposal?['meetingDate'] == null ? '소집공고' : '주총'} 개정안 · ${changes.length}가지 변경',
                style: t.body(12, color: c.textSecondary),
              ),
              const SizedBox(height: AppSpace.sm),
              for (final row in changes.take(3)) _Change(row: row),
              if (changes.length > 3)
                ShadAccordion<int>(
                  maintainState: true,
                  children: [
                    ShadAccordionItem<int>(
                      value: 0,
                      title: Text(
                        '나머지 ${changes.length - 3}개 변경 · 시행일 보기',
                        style: t.body(13, weight: FontWeight.w600),
                      ),
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final row in changes.skip(3)) _Change(row: row),
                        ],
                      ),
                    ),
                  ],
                ),
              if (proposal?['sourceUrl'] case final String url)
                _SourceLink(
                  label: proposal!['sourcePages'] is List
                      ? '신구조문 대비표 · ${(proposal['sourcePages'] as List).join(', ')}쪽'
                      : '신구조문 대비표 · DART 원문',
                  url: url,
                ),
              Text(
                '위 비교는 당시 소집공고의 개정안입니다. 변경 이력과 시행 시점은 아래 근거로 구분합니다.',
                style: t.body(11, color: c.textMuted),
              ),
            ],
            for (final notice in notices.where(
              (n) =>
                  n['receipt'] != proposal?['receipt'] &&
                  (n['changes'] as List).isNotEmpty,
            ))
              ShadAccordion<int>(
                maintainState: true,
                children: [
                  ShadAccordionItem<int>(
                    value: 0,
                    title: Text(
                      '${notice['filingDate']} 소집공고 · ${(notice['changes'] as List).length}개 조문',
                      style: t.body(13, weight: FontWeight.w600),
                    ),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final row
                            in (notice['changes'] as List)
                                .cast<Map<String, dynamic>>())
                          _Change(row: row),
                        _SourceLink(
                          label: '신구조문 대비표 · DART 원문',
                          url: notice['sourceUrl'] as String,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (changes.isEmpty)
              Text(
                data['noticeState'] == 'noNotice'
                    ? '최근 1년의 주총 소집공고가 검색되지 않았습니다.'
                    : data['noticeState'] == 'ready'
                    ? '소집공고 ${data['inspectedCount'] ?? 0}건을 확인했지만, 자동 추출 가능한 정관 비교표는 찾지 못했습니다.'
                    : '소집공고 비교표를 아직 모두 확인하지 못했습니다.',
                style: t.body(12, color: c.textSecondary),
              ),
            if (data['noticeState'] == 'partial' ||
                data['noticeState'] == 'unavailable')
              Text(
                '일부 소집공고 원문 확인 실패 · 변경이 없다는 뜻은 아닙니다.',
                style: t.body(11, color: c.textMuted),
              ),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              Text('공시에 기록된 변경 이력', style: t.body(14, weight: FontWeight.w600)),
              Text(
                '${data['reportName'] ?? ''} 기준',
                style: t.body(11, color: c.textMuted),
              ),
              for (final row in rows)
                ShadAccordion<int>(
                  maintainState: true,
                  children: [
                    ShadAccordionItem<int>(
                      value: 0,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row['date']} 정관 변경',
                            style: t.body(13, weight: FontWeight.w600),
                          ),
                          Text(
                            (row['reason'] as String).replaceAll(
                              RegExp(r'\s+'),
                              ' ',
                            ),
                            style: t.body(12, color: c.textSecondary),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(row['content'] as String, style: t.body(13)),
                          const SizedBox(height: AppSpace.sm),
                          if (history?['sourceUrl'] case final String url)
                            _SourceLink(label: '변경 이력 공시 원문', url: url),
                        ],
                      ),
                    ),
                  ],
                ),
            ] else if (changes.isEmpty) ...[
              Text(
                data['state'] == 'unavailable'
                    ? '정관 원문을 불러오지 못했습니다.'
                    : '이 공시의 정관 표는 아직 자동 비교하지 못했습니다.',
                style: t.body(13, color: c.textSecondary),
              ),
              ShadButton.raw(
                onPressed: _load,
                variant: ShadButtonVariant.link,
                child: Text('다시 불러오기'),
              ),
            ],
            if (data['historyState'] == 'unavailable' && changes.isNotEmpty)
              Text(
                '최신 보고서의 변경 이력 조회 실패 · 위 개정안은 보존된 원문 기준입니다.',
                style: t.body(11, color: c.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _Change extends StatelessWidget {
  const _Change({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final t = context.typo, c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(row['topic'] as String, style: t.body(11, color: c.textMuted)),
          Text(
            row['title'] as String,
            style: t.body(16, weight: FontWeight.w600),
          ),
          if (row['beforeShort'] != null && row['afterShort'] != null) ...[
            const SizedBox(height: AppSpace.sm),
            _Comparison(
              before: row['beforeShort'] as String,
              after: row['afterShort'] as String,
            ),
          ],
          if (row['meaning'] case final String meaning) ...[
            const SizedBox(height: AppSpace.sm),
            Text(meaning, style: t.body(13, color: c.textSecondary)),
          ],
          ShadAccordion<int>(
            maintainState: true,
            children: [
              ShadAccordionItem<int>(
                value: 0,
                title: Text(
                  '변경 전후 원문 · 변경 사유',
                  style: t.body(12, color: c.textSecondary),
                ),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Comparison(
                      before: row['before'] as String,
                      after: row['after'] as String,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      '회사 설명: ${row['reason']}',
                      style: t.body(12, color: c.textSecondary),
                    ),
                    const SizedBox(height: AppSpace.sm),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: c.border),
        ],
      ),
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.before, required this.after});
  final String before, after;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth >= 600
          ? (box.maxWidth - AppSpace.md) / 2
          : box.maxWidth;
      Widget side(String label, String value) => SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: context.colors.surfaceHover,
            borderRadius: context.shape.borderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.typo.body(11, color: context.colors.textMuted),
              ),
              const SizedBox(height: AppSpace.xs),
              SelectableText(
                value.replaceAllMapped(
                  RegExp(r'([가-힣0-9])\n([가-힣0-9])'),
                  (m) => '${m[1]}${m[2]}',
                ),
                style: context.typo.body(13),
              ),
            ],
          ),
        ),
      );
      return Wrap(
        spacing: AppSpace.md,
        runSpacing: AppSpace.sm,
        children: [side('변경 전', before), side('개정안', after)],
      );
    },
  );
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.label, required this.url});
  final String label, url;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ShadButton.raw(
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      variant: ShadButtonVariant.link,
      child: Text('$label →'),
    ),
  );
}
