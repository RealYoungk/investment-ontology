import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../app/ingest_monitor.dart';
import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';
import 'schedule_countdown.dart';

/// 지금 상태: 자동 수집마다 "실행 중 · 대기 중(다음 실행) · 끝남 · 실패"를 한 줄로.
///
/// 버튼으로 시작한 것이든 예약으로 스스로 돈 것이든 같은 작업 장부(IngestJob)에 남으므로
/// 여기에 다 보인다.
class ScheduleBoard extends StatefulWidget {
  const ScheduleBoard({super.key});

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
    final c = context.colors;
    final t = context.typo;
    final entries = _entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('지금 상태', accent: true),
        const SizedBox(height: AppSpace.xs),
        Text(
          '예약으로 스스로 도는 수집과 버튼으로 시작한 수집 모두 같은 장부에 남습니다. '
          '다음 수집까지 남은 시간은 매초 갱신됩니다. 실행 중에는 처리 현황을 보여줍니다.',
          style: t.body(12.5, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.sm),
        if (entries == null)
          const LinearProgressIndicator(minHeight: 2)
        else
          for (final e in entries) _Row(entry: e, now: _now),
      ],
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

    final (String state, Color color) = running
        ? ('실행 중', c.accent)
        : failed
        ? ('실패', c.accent)
        : entry.nextRunAt != null
        ? ('대기 중', c.textMuted)
        : ('예약 없음', c.textMuted);

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
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 210,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: t.body(13.5, weight: FontWeight.w600),
                    ),
                    Text(entry.timing, style: t.body(11.5, color: c.textMuted)),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
                child: StatusDot(label: state, color: color, pulsing: running),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      running
                          ? last()
                          : entry.nextRunAt == null
                          ? '다음 실행 예약 없음'
                          : scheduleCountdown(
                              entry.nextRunAt!,
                              now,
                              resuming: entry.resuming,
                            ),
                      style: t.body(13),
                    ),
                    if (!running && entry.nextRunAt != null)
                      Text(
                        '예약 ${formatDateTime(entry.nextRunAt!.toLocal())}',
                        style: t.numeric(12, color: c.textMuted),
                      ),
                    if (!running)
                      Text(
                        '마지막 ${last()}',
                        style: t.numeric(12, color: c.textSecondary),
                      ),
                    if (job?.message case final m? when !running)
                      Text(m, style: t.body(12, color: c.textMuted)),
                  ],
                ),
              ),
            ],
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
