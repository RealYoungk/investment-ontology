import 'dart:convert';

import 'statement_conflict_notice.dart';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';

/// Exact failed-source evidence; never a numerical or completion fallback.
class StatementAvailabilityNotice extends StatelessWidget {
  const StatementAvailabilityNotice({
    super.key,
    required this.corpCode,
    required this.sources,
    this.onOpen,
  });
  final String corpCode;
  final List<Source> sources;
  final void Function(Uri)? onOpen;
  static Map? evidence(Source source, String corp) {
    if (corp != '00442455' || source.kind != SourceKind.dartReport) return null;
    try {
      final j = jsonDecode(source.title);
      if (j is! Map ||
          j['action'] != 'verified-primary-statements-not-presented' ||
          j['targetReceipt'] != '20260324000091' ||
          j['corpCode'] != corp ||
          j['reportName'] != '사업보고서 (2025.12)' ||
          j['status'] != 'failed' ||
          j['financialFactsStored'] != false) {
        return null;
      }
      final cfs = j['fsDiv'] == 'consolidated';
      if (!cfs && j['fsDiv'] != 'separate') return null;
      final e = j['evidence'];
      final url = cfs
          ? 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260324000091&dcmNo=11171060&eleId=19&offset=202225&length=131779&dtd=dart4.xsd'
          : 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260324000091&dcmNo=11171060&eleId=25&offset=334347&length=115559&dtd=dart4.xsd';
      final sha = cfs
          ? '415e32d72cf2a6f1a9f3fb2f0504cae4f583fe3472fa4c307bd6329d8770d295'
          : '7a4f64c579187db2da4c1a8bc06ad52a56e626eb402fbaea7b19dabc633e8234';
      if (source.reference !=
              'financial-source-not-presented:20260324000091:${j['fsDiv']}' ||
          source.url != url ||
          e is! Map ||
          e['receipt'] != '20260324000091' ||
          e['corpCode'] != corp ||
          e['year'] != 2025 ||
          e['consolidated'] != cfs ||
          e['periodStart'] != '2025-01-01' ||
          e['periodEnd'] != '2025-12-31' ||
          e['statementSource'] != url ||
          e['statementSha256'] != sha ||
          e['financialFactsStored'] != false ||
          e['basisNotApplicable'] != false ||
          e['collectionComplete'] != false ||
          e['currentNumericCells'] != 0 ||
          e['printedUnit'] != '원' ||
          e['currentColumn'] != 1 ||
          e['notesVerified'] != false ||
          e['fullStatementCollected'] == true) {
        return null;
      }
      final audit = e['independentAuditEvidence'];
      final auditUrl = cfs
          ? 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260324000091&dcmNo=11171059&eleId=3&offset=7797&length=5144&dtd=dart4.xsd'
          : 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260324000091&dcmNo=11171058&eleId=3&offset=8601&length=5761&dtd=dart4.xsd';
      if (audit is! Map ||
          audit['source'] != auditUrl ||
          audit['sha256'] !=
              (cfs
                  ? 'ae1ebbd050fe6a75c9130d369958e4eae2c6809b2a70b236917abfae932b5385'
                  : 'c4453dcd957706779fdc99de6ce60d6a6c1e3097f73ffc3c19842f962ba0350c')) {
        return null;
      }
      return e;
    } on FormatException {
      return null;
    }
  }

  void open(Uri uri) {
    if (onOpen != null) {
      onOpen!(uri);
    } else {
      launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = [
      for (final s in sources)
        if (evidence(s, corpCode) != null) s,
    ];
    if (verified.isEmpty) {
      return StatementConflictNotice(
        corpCode: corpCode,
        sources: sources,
        onOpen: onOpen,
      );
    }
    final bases = verified
        .map(
          (s) => jsonDecode(s.title)['fsDiv'] == 'consolidated' ? '연결' : '별도',
        )
        .toSet()
        .join('·');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatementConflictNotice(
          corpCode: corpCode,
          sources: sources,
          onOpen: onOpen,
        ),
        AppNotice(
          message:
              '2025년 $bases 당기 재무제표가 원문에서 제시되지 않았습니다. 이 기간은 수집 실패로 남아 있습니다. 비교기간 숫자를 당기로 옮기거나 0으로 채우지 않습니다.',
        ),
        for (final s in verified)
          ExpansionTile(
            title: Text(
              '${jsonDecode(s.title)['fsDiv'] == 'consolidated' ? '연결' : '별도'} 미제시 근거 · 출처 #${s.id}',
              style: context.typo.body(12.5),
            ),
            childrenPadding: const EdgeInsets.all(AppSpace.md),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpace.sm,
                children: [
                  AppButton(
                    label: '공식 재무제표 원문',
                    variant: AppButtonVariant.link,
                    onPressed: () => open(Uri.parse(s.url!)),
                  ),
                  AppButton(
                    label: '공식 감사첨부',
                    variant: AppButtonVariant.link,
                    onPressed: () => open(
                      Uri.parse(
                        (evidence(s, corpCode)!['independentAuditEvidence']
                            as Map)['source'],
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '감사첨부와 재무제표 당기 칸을 확인한 실패 기록입니다. 전체 주석 검증 완료를 뜻하지 않습니다.',
                style: context.typo.body(12, color: context.colors.textMuted),
              ),
              SelectableText(
                const JsonEncoder.withIndent('  ').convert(jsonDecode(s.title)),
                style: context.typo.body(12),
              ),
            ],
          ),
      ],
    );
  }
}
