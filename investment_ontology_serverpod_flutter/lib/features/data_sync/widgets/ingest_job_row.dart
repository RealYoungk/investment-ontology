import '../safe_ingest_message.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../app/ingest_monitor.dart';
import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../auth/app_viewer.dart';
import '../../common/formatters.dart';

/// 수집 작업 한 종류의 상태 · 진행률 · 실행/취소 버튼.
///
/// 수집이 끝났을 때 다른 화면을 새로 고치는 일은 [IngestMonitor]가 한다.
class IngestJobRow extends StatefulWidget {
  const IngestJobRow({
    super.key,
    required this.kind,
    required this.label,
    required this.action,
    required this.start,
  });

  final String kind;
  final String label;
  final String action;
  final Future<IngestJob> Function() start;

  @override
  State<IngestJobRow> createState() => _JobRowState();
}

class _JobRowState extends State<IngestJobRow> {
  /// 수집 중일 때와 쉬고 있을 때의 상태 확인 간격. 예약·이어받기로 서버가 스스로 수집을
  /// 시작하기도 하므로 쉬고 있을 때도 가끔 확인한다.
  static const _runningInterval = Duration(seconds: 3);
  static const _idleInterval = Duration(seconds: 15);

  IngestJob? _job;
  String? _error;
  bool _starting = false;
  Timer? _poll;

  bool get _running => _job?.status == IngestStatus.running;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final job = await client.ingest.latestOf(widget.kind);
      if (!mounted) return;
      setState(() => _job = job);
      _syncPolling();
    } catch (_) {
      // 일시적인 연결 오류는 다음 폴링에서 다시 시도.
    }
  }

  /// 지금 걸린 타이머의 간격. 상태가 바뀌면 간격에 맞게 다시 건다.
  Duration? _pollEvery;

  void _syncPolling() {
    final every = _running ? _runningInterval : _idleInterval;
    if (_poll != null && _pollEvery == every) return;
    _poll?.cancel();
    _pollEvery = every;
    _poll = Timer.periodic(every, (_) => _refresh());
  }

  Future<void> _start() async {
    if (!context.ensureAdmin()) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final job = await widget.start();
      if (!mounted) return;
      setState(() => _job = job);
      _syncPolling();
      IngestMonitor.instance.poke();
    } on IngestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _cancel() async {
    if (!context.ensureAdmin()) return;
    final id = _job?.id;
    if (id == null) return;
    final job = await client.ingest.cancel(id);
    if (mounted) setState(() => _job = job);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final job = _job;
    final progress = job == null || job.total == 0
        ? null
        : job.processed / job.total;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusDot(
                label: widget.label,
                color: switch (job?.status) {
                  IngestStatus.running || IngestStatus.failed => c.accent,
                  IngestStatus.succeeded => c.success,
                  IngestStatus.cancelled || null => c.textMuted,
                },
                pulsing: _running,
              ),
              Text(_statusText(job), style: t.body(13, color: c.textSecondary)),
              if (_running)
                ShadButton.raw(
                  onPressed: _cancel,

                  variant: ShadButtonVariant.link,
                  child: Flexible(child: Text('취소')),
                )
              else
                ShadButton.raw(
                  onPressed: _starting ? null : _start,
                  enabled: (_starting ? null : _start) != null,
                  variant: ShadButtonVariant.outline,
                  child: Flexible(
                    child: Text(_starting ? '요청 중…' : widget.action),
                  ),
                ),
            ],
          ),
          if (job?.message != null && !_running) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              job!.kind == 'charter_notices' &&
                      job.status == IngestStatus.succeeded &&
                      job.failed == 0
                  ? '전체 대상 원문 확인 완료 · 미확보 0건'
                  : safeIngestMessage(job.message!),
              style: t.body(12, color: c.textMuted),
            ),
          ],
          if (_running) ...[
            const SizedBox(height: AppSpace.sm),
            ShadProgress(value: progress, minHeight: 3),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              safeIngestMessage(_error!),
              style: t.body(13, color: c.accent),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusText(IngestJob? job) {
    if (job == null) return '아직 수집한 적이 없습니다';
    final counts =
        '${formatCount(job.processed)}/${formatCount(job.total)} 처리 · '
        '저장 ${formatCount(job.updated)} · 실패 ${formatCount(job.failed)} · '
        'API ${formatCount(job.apiCalls)}회';
    return switch (job.status) {
      IngestStatus.running => '수집 중 — $counts',
      IngestStatus.succeeded =>
        '최근 수집 ${formatDateTime(job.finishedAt ?? job.startedAt)} — $counts',
      IngestStatus.failed => '수집 실패',
      IngestStatus.cancelled => '수집 취소됨 — $counts',
    };
  }
}
