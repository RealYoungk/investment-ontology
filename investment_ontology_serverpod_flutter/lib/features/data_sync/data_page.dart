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
