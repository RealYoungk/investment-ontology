import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../formatters.dart';

/// 재무(DART)·시세(공공데이터포털) 수집 상태와 실행 버튼.
class DataSyncPanel extends StatelessWidget {
  const DataSyncPanel({super.key, required this.onFinished});

  /// 수집이 끝났을 때 (재무·트리맵 새로고침용).
  final Future<void> Function() onFinished;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JobRow(
          kind: 'financial_facts',
          label: 'DART 재무',
          action: '재무제표 수집',
          description:
              'DART 공시 목록에서 상장사 정기보고서를 찾아 연결·별도 전체 재무제표를 받습니다. '
              '사업보고서·분기·반기보고서 모두 최근 5개 사업연도. '
              'DART 일일 호출 18,000건까지 쓰고 나머지는 다음 날 이어서 받습니다. '
              '서버가 켜져 있으면 매일 18:30에 자동으로 수집합니다.',
          start: client.ingest.startFinancials,
          onFinished: onFinished,
        ),
        _JobRow(
          kind: 'market_snapshot',
          label: '시세',
          action: '시세 수집',
          description:
              '공공데이터포털 금융위원회 주식시세정보로 받지 않은 평일의 전 종목 시세를 받고 '
              '(처음에는 5년), 최근 기준일의 상장종목 정보로 종목을 기업에 연결합니다. '
              '서버가 켜져 있으면 매일 18:00에 자동으로 수집합니다.',
          start: client.ingest.startMarketSnapshot,
          onFinished: onFinished,
        ),
      ],
    );
  }
}

class _JobRow extends StatefulWidget {
  const _JobRow({
    required this.kind,
    required this.label,
    required this.action,
    required this.description,
    required this.start,
    required this.onFinished,
  });

  final String kind;
  final String label;
  final String action;
  final String description;
  final Future<IngestJob> Function() start;
  final Future<void> Function() onFinished;

  @override
  State<_JobRow> createState() => _JobRowState();
}

class _JobRowState extends State<_JobRow> {
  static const _pollInterval = Duration(seconds: 3);

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
      final wasRunning = _running;
      setState(() => _job = job);
      _syncPolling();
      if (wasRunning && !_running) await widget.onFinished();
    } catch (_) {
      // 일시적인 연결 오류는 다음 폴링에서 다시 시도.
    }
  }

  void _syncPolling() {
    if (_running && _poll == null) {
      _poll = Timer.periodic(_pollInterval, (_) => _refresh());
    } else if (!_running) {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final job = await widget.start();
      if (!mounted) return;
      setState(() => _job = job);
      _syncPolling();
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
              Tooltip(
                message: widget.description,
                child: StatusDot(
                  label: widget.label,
                  color: switch (job?.status) {
                    IngestStatus.running || IngestStatus.failed => c.accent,
                    IngestStatus.succeeded => c.success,
                    IngestStatus.cancelled || null => c.textMuted,
                  },
                  pulsing: _running,
                ),
              ),
              Text(_statusText(job), style: t.body(13, color: c.textSecondary)),
              if (_running)
                AppButton(
                  label: '취소',
                  variant: AppButtonVariant.link,
                  onPressed: _cancel,
                )
              else
                AppButton(
                  label: _starting ? '요청 중…' : widget.action,
                  onPressed: _starting ? null : _start,
                ),
            ],
          ),
          if (job?.message != null && !_running) ...[
            const SizedBox(height: AppSpace.xs),
            Text(job!.message!, style: t.body(12, color: c.textMuted)),
          ],
          if (_running) ...[
            const SizedBox(height: AppSpace.sm),
            LinearProgressIndicator(value: progress, minHeight: 3),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(_error!, style: t.body(13, color: c.accent)),
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
