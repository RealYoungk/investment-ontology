import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/ingest_monitor.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'widgets/ingest_job_row.dart';
import 'widgets/ingest_status_bar.dart';

/// 데이터: 원천별 수집 상태와 실행 버튼.
class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  Overview? _overview;
  String? _error;

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_loadOverview);
    _loadOverview();
  }

  @override
  void dispose() {
    IngestMonitor.instance.dataVersion.removeListener(_loadOverview);
    super.dispose();
  }

  Future<void> _loadOverview() async {
    try {
      final o = await client.company.overview();
      if (mounted) setState(() => (_overview = o, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _overview;
    return PageFrame(
      maxWidth: 960,
      children: [
        const PageHeading(
          eyebrow: 'INVESTMENT ONTOLOGY · 데이터',
          title: '데이터',
          subtitle:
              '숫자는 1차 출처(DART, 공공데이터포털)에서만 받습니다. '
              '서버가 켜져 있으면 예약된 시각에 스스로 수집하고, 끊기면 다음에 이어서 받습니다.',
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.lg),
          AppNotice(message: '서버에 연결하지 못했습니다 — $_error'),
        ],
        const SizedBox(height: AppSpace.section),
        const _Source(
          title: '상장사 마스터 · DART 기업개황',
          description:
              '상장사 목록(corpCode.xml)과 기업개황(company.json). 평소에는 DART 변경일이 '
              '바뀐 기업만 받고, 30일마다 전체를 다시 받습니다. 자동으로 돌지 않으니 '
              '필요할 때 누릅니다.',
        ),
        if (o != null)
          IngestStatusBar(
            lastJob: o.lastJob,
            nextFullRefreshAt: o.nextFullRefreshAt,
            onFinished: _loadOverview,
          )
        else
          const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: AppSpace.section),
        const _Source(
          title: '재무 · DART 정기보고서',
          description:
              'DART 공시 목록에서 상장사 정기보고서를 찾아 연결·별도 전체 재무제표를 받습니다. '
              '사업보고서·분기·반기보고서 모두 최근 5개 사업연도. DART 일일 호출 18,000건까지 '
              '쓰고 나머지는 다음 날 00:10에 이어서 받습니다. 매일 18:30에 자동 수집.',
        ),
        IngestJobRow(
          kind: 'financial_facts',
          label: 'DART 재무',
          action: '재무제표 수집',
          start: client.ingest.startFinancials,
        ),
        const SizedBox(height: AppSpace.section),
        const _Source(
          title: '정기보고서 주요정보 · DART 사업보고서 28종',
          description:
              '재무 수집이 찾은 사업보고서마다 최대주주·임원·타법인출자·배당·자기주식·주식 총수·증자 '
              '(핵심 9종)와 직원·보수·감사·채권 등 나머지 19종을 받습니다. 기업마다 가장 최근 '
              '사업보고서의 핵심 항목부터 받고, 재무 백필이 남아 있는 동안은 핵심 항목만 하루 '
              '9,000회까지 씁니다. 매일 19:00에 자동 수집, 한도를 다 쓰면 다음 날 00:05에 이어서 받습니다. '
              '받은 뒤에는 인물 연결과 관계 색인을 호출 없이 다시 만듭니다.',
        ),
        IngestJobRow(
          kind: 'disclosures',
          label: 'DART 주요정보',
          action: '주요정보 수집',
          start: client.ingest.startDisclosures,
        ),
        const SizedBox(height: AppSpace.sm),
        const _RebuildLinks(),
        const SizedBox(height: AppSpace.section),
        const _Source(
          title: '시세 · 공공데이터포털 금융위원회',
          description:
              '주식시세정보로 받지 않은 평일의 전 종목 시세를 받고(처음에는 5년), 최근 '
              '기준일의 상장종목 정보로 종목을 기업에 연결합니다. 매일 18:00에 자동 수집.',
        ),
        IngestJobRow(
          kind: 'market_snapshot',
          label: '시세',
          action: '시세 수집',
          start: client.ingest.startMarketSnapshot,
        ),
      ],
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(title, accent: true),
          const SizedBox(height: AppSpace.xs),
          Text(description, style: t.body(13, color: c.textSecondary)),
        ],
      ),
    );
  }
}

/// 인물 연결·관계 색인 다시 계산 (호출 없음).
class _RebuildLinks extends StatefulWidget {
  const _RebuildLinks();

  @override
  State<_RebuildLinks> createState() => _RebuildLinksState();
}

class _RebuildLinksState extends State<_RebuildLinks> {
  bool _running = false;
  String? _message;

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      final m = await client.ingest.rebuildDisclosureLinks();
      if (mounted) setState(() => _message = m);
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Wrap(
      spacing: AppSpace.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: '받아 둔 주요정보로 인물 연결(추정 포함)과 관계 색인을 다시 만듭니다. DART를 부르지 않습니다.',
          child: AppButton(
            label: _running ? '계산 중…' : '관계 다시 계산',
            variant: AppButtonVariant.link,
            onPressed: _running ? null : _run,
          ),
        ),
        if (_message != null)
          Text(_message!, style: t.body(12, color: c.textMuted)),
      ],
    );
  }
}
