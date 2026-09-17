import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../theme/ledger_theme.dart';
import 'format.dart';

/// DART 수집 상태와 실행 버튼. 실행 중에는 진행률을 폴링한다.
class SyncBar extends StatefulWidget {
  const SyncBar({super.key, required this.lastJob, required this.onFinished});

  final IngestJob? lastJob;
  final Future<void> Function() onFinished;

  @override
  State<SyncBar> createState() => _SyncBarState();
}

class _SyncBarState extends State<SyncBar> {
  IngestJob? _job;
  String? _error;
  bool _starting = false;
  Timer? _poll;

  @override
  void didUpdateWidget(covariant SyncBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.lastJob;
    if (incoming != null &&
        (_job == null ||
            _job!.id != incoming.id ||
            _job!.status != IngestStatus.running)) {
      _job = incoming;
    }
    _ensurePolling();
  }

  @override
  void initState() {
    super.initState();
    _job = widget.lastJob;
    _ensurePolling();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _ensurePolling() {
    final running = _job?.status == IngestStatus.running;
    if (running && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
    } else if (!running) {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> _tick() async {
    try {
      final job = await client.ingest.latest();
      if (!mounted) return;
      final wasRunning = _job?.status == IngestStatus.running;
      setState(() => _job = job);
      _ensurePolling();
      if (wasRunning && job?.status != IngestStatus.running) {
        await widget.onFinished();
      }
    } catch (_) {
      // 일시적인 연결 오류는 다음 폴링에서 다시 시도.
    }
  }

  Future<void> _start({bool force = false}) async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final job = await client.ingest.startCompanyMaster(force: force);
      if (!mounted) return;
      setState(() => _job = job);
      _ensurePolling();
    } on IngestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _cancel() async {
    final id = _job?.id;
    if (id == null) return;
    final job = await client.ingest.cancel(id);
    if (mounted) setState(() => _job = job);
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final running = job?.status == IngestStatus.running;
    final progress = job == null || job.total == 0
        ? null
        : job.processed / job.total;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Pal.ink, width: 1.5),
          bottom: BorderSide(color: Pal.rule, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusDot(status: job?.status),
              Text(_statusText(job), style: Typo.body(13, color: Pal.inkSoft)),
              if (running)
                _ActionLink(label: '취소', onTap: _cancel)
              else ...[
                _ActionLink(
                  label: _starting ? '요청 중…' : 'DART에서 수집',
                  strong: true,
                  onTap: _starting ? null : () => _start(),
                ),
                if (job?.status == IngestStatus.succeeded)
                  Tooltip(
                    message: '변경일과 관계없이 모든 기업의 개황을 다시 받습니다 (호출 약 4,000건).',
                    child: _ActionLink(
                      label: '전체 다시 받기',
                      onTap: _starting ? null : () => _start(force: true),
                    ),
                  ),
              ],
            ],
          ),
          if (running) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress, minHeight: 3),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: Typo.body(13, color: Pal.seal)),
          ],
        ],
      ),
    );
  }

  String _statusText(IngestJob? job) {
    if (job == null) return '아직 수집한 적이 없습니다';
    final counts =
        '${formatCount(job.processed)}/${formatCount(job.total)} 처리 · '
        '갱신 ${formatCount(job.updated)} · 실패 ${formatCount(job.failed)} · '
        'API ${formatCount(job.apiCalls)}회';
    return switch (job.status) {
      IngestStatus.running => '수집 중 — $counts',
      IngestStatus.succeeded =>
        '최근 수집 ${formatDateTime(job.finishedAt ?? job.startedAt)} — $counts',
      IngestStatus.failed => '수집 실패 — ${job.message ?? ''}',
      IngestStatus.cancelled => '수집 취소됨 — $counts',
    };
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.status});

  final IngestStatus? status;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.status == IngestStatus.running) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.status) {
      IngestStatus.running => Pal.seal,
      IngestStatus.succeeded => Pal.moss,
      IngestStatus.failed => Pal.seal,
      _ => Pal.inkFaint,
    };
    return FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0).animate(_pulse),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('DART SYNC', style: Typo.label(color: Pal.ink)),
        ],
      ),
    );
  }
}

class _ActionLink extends StatelessWidget {
  const _ActionLink({required this.label, this.onTap, this.strong = false});

  final String label;
  final VoidCallback? onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: strong && enabled ? Pal.ink : Colors.transparent,
          child: Text(
            label,
            style: Typo.body(
              13,
              color: strong && enabled
                  ? Pal.paper
                  : enabled
                  ? Pal.ink
                  : Pal.inkFaint,
              weight: FontWeight.w600,
            ).copyWith(decoration: strong ? null : TextDecoration.underline),
          ),
        ),
      ),
    );
  }
}
