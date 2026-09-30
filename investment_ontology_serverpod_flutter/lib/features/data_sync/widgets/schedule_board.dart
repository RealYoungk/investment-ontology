import '../safe_ingest_message.dart';

import 'dart:async';

import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../app/ingest_monitor.dart';
import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';
import '../../auth/app_viewer.dart';

/// 지금 상태: 자동 수집마다 "실행 중 · 대기 중(다음 실행) · 끝남 · 실패"를 한 줄로.
///
/// 버튼으로 시작한 것이든 예약으로 스스로 돈 것이든 같은 작업 장부(IngestJob)에 남으므로
/// 여기에 다 보인다.
class ScheduleBoard extends StatefulWidget {
  const ScheduleBoard({required this.child, super.key});

  final Widget child;

  @override
  State<ScheduleBoard> createState() => _ScheduleBoardState();
}

class _ScheduleBoardState extends State<ScheduleBoard> {
  List<IngestScheduleEntry>? _entries;
  Timer? _timer;
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    IngestMonitor.instance.running.addListener(_load);
    _load();
    // 서버 조회 주기와 별개로 화면의 남은 시간만 매초 갱신한다.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock?.cancel();
    IngestMonitor.instance.dataVersion.removeListener(_load);
    IngestMonitor.instance.running.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final e = await client.ingest.schedule();
      if (mounted) setState(() => _entries = e);
    } catch (_) {
      // 위쪽 서버 연결 오류 표시로 충분하다.
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ScheduleData(entries: _entries, now: _now, child: widget.child);
  }
}

class _ScheduleData extends InheritedWidget {
  const _ScheduleData({
    required this.entries,
    required this.now,
    required super.child,
  });
  final List<IngestScheduleEntry>? entries;
  final DateTime now;

  @override
  bool updateShouldNotify(_ScheduleData oldWidget) =>
      entries != oldWidget.entries || now != oldWidget.now;
}

class DatasetCollectionControls extends StatefulWidget {
  const DatasetCollectionControls({required this.dataset, super.key});
  final String dataset;

  @override
  State<DatasetCollectionControls> createState() =>
      _DatasetCollectionControlsState();
}

class _DatasetCollectionControlsState extends State<DatasetCollectionControls> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    if (!context.ensureAdmin()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      IngestMonitor.instance.poke();
    } catch (e) {
      if (mounted) setState(() => _error = safeIngestMessage('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.dependOnInheritedWidgetOfExactType<_ScheduleData>();
    final kind = switch (widget.dataset) {
      'financial' => 'financial_facts',
      'market' => 'market_snapshot',
      'disclosure' || 'business' => 'disclosures',
      _ => 'company_master',
    };
    final entry = data?.entries?.where((e) => e.kind == kind).firstOrNull;
    final running = entry?.lastJob?.status == IngestStatus.running;
    final corpCode = GoRouterState.of(context).uri.queryParameters['corpCode'];
    final companyScoped =
        corpCode != null &&
        (kind == 'financial_facts' || kind == 'disclosures');
    final actions = Wrap(
      spacing: AppSpace.md,
      children: [
        AppButton(
          label: _busy
              ? '요청 중…'
              : running && !companyScoped
              ? '수집 중단'
              : widget.dataset == 'market'
              ? '금융위에서 갱신'
              : !companyScoped
              ? 'DART에서 갱신'
              : '이 기업 DART 갱신',
          onPressed: _busy
              ? null
              : () => _run(() async {
                  if (running && !companyScoped) {
                    await client.ingest.cancel(entry!.lastJob!.id!);
                  } else {
                    switch (kind) {
                      case 'financial_facts':
                        await client.ingest.startFinancials(corpCode: corpCode);
                      case 'market_snapshot':
                        await client.ingest.startMarketSnapshot();
                      case 'disclosures':
                        await client.ingest.startDisclosures(
                          corpCode: corpCode,
                        );
                      default:
                        await client.ingest.startCompanyMaster();
                    }
                  }
                }),
        ),
        if (widget.dataset == 'business')
          AppButton(
            label: corpCode == null ? '저장 원문 재처리' : '이 기업 원문 재처리',
            variant: AppButtonVariant.link,
            onPressed: _busy || running
                ? null
                : () => _run(() async {
                    await client.ingest.rebuildProductionFacts(
                      corpCode: corpCode,
                    );
                  }),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final status = entry == null
                ? Text('수집 상태 불러오는 중…', style: context.typo.body(12))
                : _Row(entry: entry, now: data!.now);
            if (box.maxWidth < 680) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [status, if (context.isAdmin) actions],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: status),
                if (context.isAdmin) ...[
                  const SizedBox(width: AppSpace.lg),
                  actions,
                ],
              ],
            );
          },
        ),
        if (widget.dataset == 'business')
          Text(
            '공시 주요정보와 같은 수집 작업',
            style: context.typo.body(11, color: context.colors.textMuted),
          ),
        if (_error != null)
          Text(
            _error!,
            style: context.typo.body(12, color: context.colors.textSecondary),
          ),
      ],
    );
  }
}

class DatasetRunHistory extends StatelessWidget {
  const DatasetRunHistory({required this.dataset, super.key});
  final String dataset;

  @override
  Widget build(BuildContext context) {
    final data = context.dependOnInheritedWidgetOfExactType<_ScheduleData>();
    final kind = switch (dataset) {
      'financial' => 'financial_facts',
      'market' => 'market_snapshot',
      'business' || 'disclosure' => 'disclosures',
      _ => 'company_master',
    };
    final entry = data?.entries?.where((e) => e.kind == kind).firstOrNull;
    final job = entry?.lastJob;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '수집 일정 · 최근 실행',
            style: context.typo.body(13, weight: FontWeight.w600),
          ),
          if (entry != null)
            Text(
              entry.timing,
              style: context.typo.body(12, color: context.colors.textSecondary),
            ),
          Text(
            job == null
                ? '실행 기록 없음'
                : '${formatDateTime(job.finishedAt ?? job.startedAt)} · ${switch (job.status) {
                    IngestStatus.running => '실행 중',
                    IngestStatus.succeeded => '완료',
                    IngestStatus.failed => '실패',
                    IngestStatus.cancelled => '취소',
                  }} · 처리 ${formatCount(job.processed)}/${formatCount(job.total)} · 실패 ${formatCount(job.failed)}',
            style: context.typo.body(12, color: context.colors.textSecondary),
          ),
          if (job?.message case final message?)
            Text(
              safeIngestMessage(message),
              style: context.typo.body(12, color: context.colors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.now});

  final IngestScheduleEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final job = entry.lastJob;
    final running = job?.status == IngestStatus.running;
    final failed = job?.status == IngestStatus.failed;

    final partial = job?.failed != null && job!.failed > 0;
    final (String state, Color color) = running
        ? ('수집 중', c.accent)
        : failed || partial
        ? ('일부 실패 · 확인 필요', c.accent)
        : job?.status == IngestStatus.succeeded
        ? ('최근 수집 완료', c.accent)
        : job?.status == IngestStatus.cancelled
        ? ('수집 취소됨', c.textMuted)
        : ('아직 수집 전', c.textMuted);

    final progress = job == null || job.total == 0
        ? null
        : job.processed / job.total;

    String last() {
      if (job == null) return '아직 돈 적이 없습니다';
      final at = formatDateTime(job.finishedAt ?? job.startedAt);
      return switch (job.status) {
        IngestStatus.running =>
          '${formatDateTime(job.startedAt)} 시작 · ${formatCount(job.processed)}/${formatCount(job.total)} 처리',
        IngestStatus.succeeded => '$at 완료',
        IngestStatus.failed => '$at 실패',
        IngestStatus.cancelled => '$at 취소',
      };
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.xs,
            children: [
              Icon(
                running
                    ? Icons.sync
                    : failed || partial
                    ? Icons.error_outline
                    : job?.status == IngestStatus.succeeded
                    ? Icons.check_circle_outline
                    : Icons.schedule,
                size: 16,
                color: color,
              ),
              Text(
                state,
                style: t.body(12, weight: FontWeight.w600, color: color),
              ),
              if (!running && job != null)
                Text(
                  formatDateTime(job.finishedAt ?? job.startedAt),
                  style: t.body(11, color: c.textMuted),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            running
                ? last()
                : entry.nextRunAt == null
                ? entry.kind == 'company_master'
                      ? '필요할 때 DART에서 갱신을 눌러 실행합니다.'
                      : '다음 수집 예약 없음'
                : '다음 수집 ${formatDateTime(entry.nextRunAt!.toLocal())}',
            style: t.body(12, color: c.textSecondary),
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Text(
                job?.message?.contains('Failed host lookup') == true
                    ? '지난 수집 실패 · 원천기관 주소 조회 오류'
                    : '지난 수집이 완료되지 않았습니다. 상세 기록을 확인하세요.',
                style: t.body(12, color: c.accent),
              ),
            ),
          if (running) ...[
            const SizedBox(height: AppSpace.sm),
            LinearProgressIndicator(value: progress, minHeight: 3),
          ],
        ],
      ),
    );
  }
}
