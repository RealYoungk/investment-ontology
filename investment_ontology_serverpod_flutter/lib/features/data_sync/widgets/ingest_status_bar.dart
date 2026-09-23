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

/// 상장사 마스터(DART 기업개황) 수집 상태와 실행 버튼. 실행 중에는 진행률을 폴링한다.
class IngestStatusBar extends StatefulWidget {
  const IngestStatusBar({
    super.key,
    required this.lastJob,
    required this.nextFullRefreshAt,
    required this.onFinished,
  });

  final IngestJob? lastJob;

  /// 이 시각 이후 첫 수집은 서버가 자동으로 전체 갱신한다. null이면 다음 수집이 전체 갱신.
  final DateTime? nextFullRefreshAt;

  /// 수집이 끝났을 때 (목록·집계 새로고침용).
  final Future<void> Function() onFinished;

  @override
  State<IngestStatusBar> createState() => _IngestStatusBarState();
}

class _IngestStatusBarState extends State<IngestStatusBar> {
  static const _pollInterval = Duration(seconds: 2);

  IngestJob? _job;
  String? _error;
  bool _starting = false;
  Timer? _poll;

  bool get _running => _job?.status == IngestStatus.running;

  @override
  void initState() {
    super.initState();
    _job = widget.lastJob;
    _syncPolling();
  }

  @override
  void didUpdateWidget(covariant IngestStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.lastJob;
    // 폴링 중인 작업의 진행 상태를 부모의 오래된 값으로 덮어쓰지 않는다.
    if (incoming != null && (!_running || _job?.id != incoming.id)) {
      _job = incoming;
    }
    _syncPolling();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _syncPolling() {
    if (_running && _poll == null) {
      _poll = Timer.periodic(_pollInterval, (_) => _tick());
    } else if (!_running) {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> _tick() async {
    try {
      final job = await client.ingest.latest();
      if (!mounted) return;
      final wasRunning = _running;
      setState(() => _job = job);
      _syncPolling();
      if (wasRunning && !_running) await widget.onFinished();
    } catch (_) {
      // 일시적인 연결 오류는 다음 폴링에서 다시 시도.
    }
  }

  Future<void> _start({bool force = false}) async {
    if (!context.ensureAdmin()) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final job = await client.ingest.startCompanyMaster(force: force);
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
    final job = _job;
    final progress = job == null || job.total == 0
        ? null
        : job.processed / job.total;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderStrong, width: 1.5),
          bottom: BorderSide(color: c.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusDot(
                label: 'DART SYNC',
                color: _statusColor(context, job?.status),
                pulsing: _running,
              ),
              Text(
                _statusText(job),
                style: context.typo.body(13, color: c.textSecondary),
              ),
              if (!_running)
                Tooltip(
                  message:
                      '평소에는 DART 변경일이 바뀐 기업만 받고, 30일마다 전체를 다시 받아 '
                      '변경일에 반영되지 않은 변경을 바로잡습니다.',
                  child: Text(
                    _fullRefreshText(widget.nextFullRefreshAt),
                    style: context.typo.body(12.5, color: c.textMuted),
                  ),
                ),
              if (_running)
                AppButton(
                  label: '취소',
                  variant: AppButtonVariant.link,
                  onPressed: _cancel,
                )
              else ...[
                AppButton(
                  label: _starting ? '요청 중…' : 'DART에서 수집',
                  variant: AppButtonVariant.primary,
                  onPressed: _starting ? null : _start,
                ),
                if (job?.status == IngestStatus.succeeded &&
                    widget.nextFullRefreshAt != null)
                  Tooltip(
                    message: '변경일과 관계없이 모든 기업의 개황을 지금 다시 받습니다 (호출 약 4,000건).',
                    child: AppButton(
                      label: '전체 다시 받기',
                      variant: AppButtonVariant.link,
                      onPressed: _starting ? null : () => _start(force: true),
                    ),
                  ),
              ],
            ],
          ),
          if (_running) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress, minHeight: 3),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              safeIngestMessage(_error!),
              style: context.typo.body(13, color: c.accent),
            ),
          ],
        ],
      ),
    );
  }

  static Color _statusColor(BuildContext context, IngestStatus? status) {
    final c = context.colors;
    return switch (status) {
      IngestStatus.running || IngestStatus.failed => c.accent,
      IngestStatus.succeeded => c.success,
      IngestStatus.cancelled || null => c.textMuted,
    };
  }

  static String _fullRefreshText(DateTime? next) {
    if (next == null || !next.isAfter(DateTime.now())) {
      return '다음 수집은 전체 갱신';
    }
    return '전체 갱신 예정 ${formatDate(next.toLocal())} 이후';
  }

  static String _statusText(IngestJob? job) {
    if (job == null) return '아직 수집한 적이 없습니다';
    final counts =
        '${formatCount(job.processed)}/${formatCount(job.total)} 처리 · '
        '갱신 ${formatCount(job.updated)} · 실패 ${formatCount(job.failed)} · '
        'API ${formatCount(job.apiCalls)}회';
    return switch (job.status) {
      IngestStatus.running =>
        '${job.fullRefresh ? '전체 갱신' : '변경분 수집'} 중 — $counts',
      IngestStatus.succeeded =>
        '최근 수집 ${formatDateTime(job.finishedAt ?? job.startedAt)} — $counts',
      IngestStatus.failed => '수집 실패 — ${safeIngestMessage(job.message ?? '')}',
      IngestStatus.cancelled => '수집 취소됨 — $counts',
    };
  }
}
