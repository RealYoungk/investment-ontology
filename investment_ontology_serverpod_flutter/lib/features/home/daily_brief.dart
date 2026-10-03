import 'package:shad/shad.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/ingest_monitor.dart';
import '../../client.dart';
import '../../design/tokens.dart';
import '../../design/components/data_panel.dart';
import '../../design/components/read_failure_notice.dart';
import '../common/formatters.dart';

typedef FilingFeedLoad = Future<List<FilingFeedItem>> Function();

/// A dated, bounded feed; reception is distinct from completed extraction.
class DailyBrief extends StatefulWidget {
  const DailyBrief({super.key, this.load});
  final FilingFeedLoad? load;
  @override
  State<DailyBrief> createState() => _DailyBriefState();
}

class _DailyBriefState extends State<DailyBrief> {
  List<FilingFeedItem>? _items;
  bool _failed = false;
  bool _loading = false;
  int _request = 0;
  bool _correctionsOnly = false;
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

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final items =
          await (widget.load?.call() ??
              client.disclosure.recentFilings(limit: 12));
      if (mounted && request == _request) setState(() => _items = items);
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return DataPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.md,
            children: [
              Text('다시 읽어볼 공시', style: t.display(22)),
              ShadButton.ghost(
                onPressed: _loading ? null : _load,
                enabled: (_loading ? null : _load) != null,
                child: Flexible(child: const Text('새로고침')),
              ),
            ],
          ),
          Text(
            '최근 수집 정기보고서 · 접수일 순 · 실시간 전체 공시 피드가 아닙니다.',
            style: t.body(12, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.md),
          if (_loading) const ShadProgress(minHeight: 2),
          if (_failed) ReadFailureNotice(subject: '최근 공시', retry: _load),
          if (!_loading && !_failed && _items?.isEmpty == true)
            Text('수집된 최근 정기보고서가 아직 없습니다.', style: t.body(14)),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              IntrinsicWidth(
                child: ShadToggle.outline(
                  value: !_correctionsOnly,
                  onChanged: (_) => setState(() => _correctionsOnly = false),
                  child: const Text('전체'),
                ),
              ),
              IntrinsicWidth(
                child: ShadToggle.outline(
                  value: _correctionsOnly,
                  onChanged: (_) => setState(() => _correctionsOnly = true),
                  child: const Text('정정 보고서'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          LayoutBuilder(
            builder: (context, box) {
              final filtered = (_items ?? <FilingFeedItem>[])
                  .where(
                    (f) => !_correctionsOnly || f.reportName.contains('정정'),
                  )
                  .toList();
              final first = filtered.firstOrNull;
              if (first == null) {
                return _correctionsOnly && !_loading && !_failed
                    ? Text(
                        '조회한 최근 공시 중 정정 보고서가 없습니다.',
                        style: t.body(13, color: c.textSecondary),
                      )
                    : const SizedBox.shrink();
              }
              final featured = Container(
                padding: const EdgeInsets.all(AppSpace.xl),
                decoration: BoxDecoration(
                  color: c.inverse,
                  borderRadius: context.shape.borderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      first.reportName.contains('정정')
                          ? '정정 공시 / 원문 재확인'
                          : '새 정기보고서 / 실적 확인',
                      style: t.label(color: c.onInverse),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Text(
                      first.company.name,
                      style: t.display(25, color: c.onInverse),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      first.reportName,
                      style: t.body(13, color: c.onInverse),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Text(
                      first.reportName.contains('정정')
                          ? '이미 읽었던 보고서라면, 정정된 원문을 다시 확인해 보세요.'
                          : '새 보고 기간의 재무를 열고, 이전 기간과 흐름을 비교해 보세요.',
                      style: t
                          .body(15, color: c.onInverse)
                          .copyWith(height: 1.7),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Text(
                      '${formatDate(first.receivedDate)} 접수 · 재무 ${first.financialStored ? '수집 완료' : '수집 대기'}',
                      style: t.body(11, color: c.onInverse),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    ShadButton.ghost(
                      onPressed: () => context.push(
                        '/company/${first.company.corpCode}?tab=financials',
                      ),
                      child: Flexible(child: const Text('기업 실적 열기 →')),
                    ),
                  ],
                ),
              );
              final remaining = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in filtered.skip(1).take(5)) ...[
                    Material(
                      color: c.surface,
                      child: ShadButton.ghost(
                        width: double.infinity,
                        height: 0,
                        padding: EdgeInsets.zero,
                        onPressed: () => context.push(
                          '/company/${f.company.corpCode}?tab=financials',
                        ),
                        child: Flexible(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.company.name,
                                      style: t.body(
                                        15,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${formatDate(f.receivedDate)} · ${f.reportName}\n${f.reportName.contains('정정') ? '정정 원문 확인' : '보고 기간 실적 확인'} · 재무 ${f.financialStored ? '수집 완료' : '수집 대기'}',
                                      style: t.body(12, color: c.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Icon(
                                LucideIcons.arrowRight,
                                color: c.accent,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: c.border),
                  ],
                ],
              );
              return box.maxWidth >= 850
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: featured),
                        const SizedBox(width: AppSpace.xl),
                        Expanded(flex: 6, child: remaining),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        featured,
                        const SizedBox(height: AppSpace.md),
                        remaining,
                      ],
                    );
            },
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            '최근 수집 12건에서 최대 6건 표시 · 정정 여부는 보고서명 기준입니다.',
            style: t.body(11, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
